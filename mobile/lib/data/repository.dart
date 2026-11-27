import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/text_clean.dart';

typedef Json = Map<String, dynamic>;
final sb = Supabase.instance.client;

class Repo {
  String get uid => sb.auth.currentUser!.id;

  Future<Json> me() async =>
      await sb.from('profiles').select().eq('id', uid).single();

  Future<Json?> myProgress() async => await sb
      .from('v_student_progress')
      .select()
      .eq('student_id', uid)
      .maybeSingle();

  /// Published lessons the student can see (own classes + legacy shared).
  /// Pass classId to scope to one class.
  Future<List<Json>> lessons({String? subject, String? classId}) async {
    var q = sb
        .from('lessons')
        .select('*, lesson_progress(percent)')
        .eq('is_published', true);
    if (classId != null) q = q.eq('class_id', classId);
    if (subject != null) q = q.eq('subject', subject);
    return List<Json>.from(await q.order('position'));
  }

  Future<Json> lesson(String id) async =>
      await sb.from('lessons').select().eq('id', id).single();

  Future<void> setProgress(String lessonId, int percent) async {
    await sb.from('lesson_progress').upsert({
      'student_id': uid,
      'lesson_id': lessonId,
      'percent': percent,
      'updated_at': DateTime.now().toIso8601String(),
      if (percent >= 100) 'completed_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Json>> recentActivity() async => List<Json>.from(await sb
      .from('lesson_progress')
      .select('percent, updated_at, lessons(title)')
      .eq('student_id', uid)
      .order('updated_at', ascending: false)
      .limit(3));

  Future<List<Json>> assessments(List<String> kinds) async =>
      List<Json>.from(await sb
          .from('assessments')
          .select()
          .inFilter('kind', kinds)
          .eq('is_published', true)
          .order('created_at'));

  Future<List<Json>> questions(String assessmentId) async =>
      List<Json>.from(await sb
          .from('questions_public')
          .select()
          .eq('assessment_id', assessmentId)
          .order('position'));

  /// Published activities inside one lesson (student view, RLS hides drafts).
  Future<List<Json>> lessonActivities(String lessonId) async =>
      List<Json>.from(await sb
          .from('assessments')
          .select()
          .eq('lesson_id', lessonId)
          .eq('is_published', true)
          .order('created_at'));

  Future<Json> submit(String assessmentId, Map<String, dynamic> answers) async {
    final r = Map<String, dynamic>.from(await sb.rpc('submit_attempt',
        params: {'p_assessment': assessmentId, 'p_answers': answers}));
    if (r['error'] != null) throw Exception(r['error']);
    return r;
  }

  /// Post-submit review: {attempted:false} | {attempted:true, released:false}
  /// | {attempted:true, released:true, score, total, items:[{question_id,
  /// key, correct_index, student, is_correct, earned}]} (migration 0020).
  Future<Json> reviewAttempt(String assessmentId) async =>
      Map<String, dynamic>.from(await sb.rpc('review_attempt',
          params: {'p_assessment': assessmentId}));

  Future<List<Json>> flashcards() async =>
      List<Json>.from(await sb.from('flashcards').select());
  Future<List<Json>> formulas() async =>
      List<Json>.from(await sb.from('formulas').select());
  Future<List<Json>> keyTerms() async =>
      List<Json>.from(await sb.from('key_terms').select());

  // ---------- teacher portal ----------

  /// All lessons (staff bypass the is_published filter via RLS).
  Future<List<Json>> allLessons() async =>
      List<Json>.from(await sb.from('lessons').select().order('position'));

  Future<void> createLesson(
      String classId, String title, String subject, String objectives,
      {String? thumbnailKey, String? contentKey}) async {
    final existing =
        await sb.from('lessons').select('id').eq('class_id', classId);
    await sb.from('lessons').insert({
      'class_id': classId,
      'title': title,
      'subject': subject,
      'objectives': objectives,
      if (thumbnailKey != null) 'thumbnail_key': thumbnailKey,
      if (contentKey != null) 'content_key': contentKey,
      'position': existing.length + 1,
      'is_published': false,
      'created_by': uid,
    });
  }

  /// Edit a lesson's fields; key params replace stored R2 keys only when
  /// non-null (null = keep the existing key).
  Future<void> updateLesson(String lessonId,
      {required String title,
      required String subject,
      required String objectives,
      String? thumbnailKey,
      String? contentKey}) async {
    await sb.from('lessons').update({
      'title': title,
      'subject': subject,
      'objectives': objectives,
      if (thumbnailKey != null) 'thumbnail_key': thumbnailKey,
      if (contentKey != null) 'content_key': contentKey,
    }).eq('id', lessonId);
  }

  /// Delete a lesson row. lesson_progress cascades; assessments detach
  /// (ON DELETE SET NULL) — callers must block when activities exist.
  /// R2 objects are intentionally left in place.
  Future<void> deleteLesson(String lessonId) async =>
      await sb.from('lessons').delete().eq('id', lessonId);

  /// lesson_id -> count of submitted attempts on that lesson's assessments.
  /// Drives the unpublish confirm (warn when students already took it).
  Future<Map<String, int>> lessonAttemptCounts(String classId) async {
    final acts = List<Json>.from(await sb
        .from('assessments')
        .select('id, lesson_id, lessons!inner(class_id)')
        .eq('lessons.class_id', classId));
    if (acts.isEmpty) return const {};
    final ids = [for (final a in acts) '${a['id']}'];
    final atts = List<Json>.from(await sb
        .from('attempts')
        .select('assessment_id')
        .inFilter('assessment_id', ids)
        .not('submitted_at', 'is', null));
    final lessonOf = {
      for (final a in acts) '${a['id']}': a['lesson_id'] as String?
    };
    final counts = <String, int>{};
    for (final a in atts) {
      final lid = lessonOf['${a['assessment_id']}'];
      if (lid != null) counts[lid] = (counts[lid] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> setPublished(String lessonId, bool publish) async => await sb
      .from('lessons')
      .update({'is_published': publish}).eq('id', lessonId);

  /// Every student's progress row (teachers read all via RLS).
  Future<List<Json>> classProgress() async => List<Json>.from(
      await sb.from('v_student_progress').select().order('full_name'));

  /// Count of fully completed lesson_progress rows (dashboard stat).
  Future<int> completedLessonsCount() async =>
      (await sb.from('lesson_progress').select('lesson_id').eq('percent', 100))
          .length;

  // ---------- activity builder (teacher) ----------

  /// Assessments attached to a lesson, published or not (staff bypass via RLS).
  Future<List<Json>> lessonAssessments(String lessonId) async =>
      List<Json>.from(await sb
          .from('assessments')
          .select('*, assessment_parts(count)')
          .eq('lesson_id', lessonId)
          .order('created_at'));

  Future<Json> createAssessment(
          String lessonId, String kind, String title, String desc,
          {String mode = 'multiple_choice'}) async =>
      Map<String, dynamic>.from(await sb
          .from('assessments')
          .insert({
            'lesson_id': lessonId,
            'kind': kind,
            'mode': mode,
            'title': cleanText(title),
            'description': cleanText(desc),
          })
          .select()
          .single());

  Future<void> setAssessmentPublished(String id, bool published) async =>
      await sb
          .from('assessments')
          .update({'is_published': published}).eq('id', id);

  /// 'immediate' = score shows after submit; 'manual' = teacher releases it.
  Future<void> setScoreRelease(String id, String mode) async => await sb
      .from('assessments')
      .update({'release_scores': mode}).eq('id', id);

  /// Teacher releases scores for a manual-release assessment.
  Future<void> releaseScores(String id) async => await sb
      .from('assessments')
      .update({'scores_released': true}).eq('id', id);

  /// assessment_id -> latest released score for the current student.
  /// RLS only returns released attempts, so hidden scores never reach the app.
  Future<Map<String, num>> myAttemptScores() async {
    final rows = await sb
        .from('attempts')
        .select('assessment_id, score, submitted_at')
        .eq('student_id', uid)
        .order('submitted_at');
    final m = <String, num>{};
    for (final r in rows) {
      final s = r['score'] as num?;
      if (s != null) m['${r['assessment_id']}'] = s;
    }
    return m;
  }

  Future<void> deleteAssessment(String id) async =>
      await sb.from('assessments').delete().eq('id', id);

  /// Parts inside an activity ("Activity 1 / Activity 2" sections, each with
  /// its own mode + scored flag). Teacher read/write via RLS.
  Future<List<Json>> parts(String assessmentId) async =>
      List<Json>.from(await sb
          .from('assessment_parts')
          .select()
          .eq('assessment_id', assessmentId)
          .order('position'));

  /// Parts of a published assessment — student view (no answer keys).
  Future<List<Json>> partsPublic(String assessmentId) async =>
      List<Json>.from(await sb
          .from('parts_public')
          .select()
          .eq('assessment_id', assessmentId)
          .order('position'));

  Future<void> upsertPart(Json p) async {
    final id = p.remove('id');
    if (p['title'] is String) p['title'] = cleanText(p['title'] as String);
    if (p['directions'] is String) {
      p['directions'] = cleanText(p['directions'] as String);
    }
    if (id != null) {
      await sb.from('assessment_parts').update(p).eq('id', id);
    } else {
      await sb.from('assessment_parts').insert(p);
    }
  }

  /// Deletes the part AND its questions (FK cascade).
  Future<void> deletePart(String id) async =>
      await sb.from('assessment_parts').delete().eq('id', id);

  /// Full questions incl. answer keys — teacher policy only, never student-visible.
  Future<List<Json>> questionsFull(String assessmentId) async =>
      List<Json>.from(await sb
          .from('questions')
          .select()
          .eq('assessment_id', assessmentId)
          .order('position'));

  Future<void> upsertQuestion(Json q) async {
    final id = q.remove('id');
    if (q['prompt'] is String) q['prompt'] = cleanText(q['prompt'] as String);
    if (q['choices'] is List) {
      q['choices'] = cleanDeep(q['choices']);
    }
    if (q['answer'] is Map) q['answer'] = cleanDeep(q['answer']);
    if (id != null) {
      await sb.from('questions').update(q).eq('id', id);
    } else {
      await sb.from('questions').insert(q);
    }
  }

  Future<void> deleteQuestion(String id) async =>
      await sb.from('questions').delete().eq('id', id);

  // ---------- classes ----------

  /// Teacher's own classes with enrollments (status counted client-side).
  Future<List<Json>> myClasses() async => List<Json>.from(await sb
      .from('classes')
      .select('id, name, code, teacher_id, join_policy, enrollments(status)')
      .eq('teacher_id', uid)
      .order('created_at'));

  Future<Json> createClass(String name, String joinPolicy) async =>
      Map<String, dynamic>.from(await sb
          .from('classes')
          .insert({'name': name, 'teacher_id': uid, 'join_policy': joinPolicy})
          .select()
          .single());

  /// Roster for a class: student rows with enrollment status.
  Future<List<Json>> classMembers(String classId) async =>
      List<Json>.from(await sb
          .from('enrollments')
          .select('student_id, status, profiles(full_name)')
          .eq('class_id', classId));

  Future<void> approveMember(String classId, String studentId) async => await sb
      .from('enrollments')
      .update({'status': 'active'})
      .eq('class_id', classId)
      .eq('student_id', studentId);

  /// Reject a pending request or remove an enrolled student.
  Future<void> removeMember(String classId, String studentId) async => await sb
      .from('enrollments')
      .delete()
      .eq('class_id', classId)
      .eq('student_id', studentId);

  Future<void> deleteClass(String id) async =>
      await sb.from('classes').delete().eq('id', id);

  /// Lessons in one class (teacher view: includes drafts).
  Future<List<Json>> classLessons(String classId) async =>
      List<Json>.from(await sb
          .from('lessons')
          .select()
          .eq('class_id', classId)
          .order('created_at'));

  /// Per-class progress rows — one per active member, metrics filtered to
  /// this class's lessons (v_class_student_progress, migration 0011).
  Future<List<Json>> classStudentProgress(String classId) async =>
      List<Json>.from(await sb
          .from('v_class_student_progress')
          .select()
          .eq('class_id', classId)
          .order('full_name'));

  /// Fully completed lesson_progress rows inside one class.
  Future<int> classCompletedCount(String classId) async => (await sb
          .from('lesson_progress')
          .select('lesson_id, lessons!inner(class_id)')
          .eq('lessons.class_id', classId)
          .eq('percent', 100))
      .length;

  // ---------- student report ----------

  /// Guard: this student's enrollment row in this class (null = not enrolled).
  Future<Json?> classMembership(String classId, String studentId) async =>
      await sb
          .from('enrollments')
          .select('student_id, status, profiles(full_name)')
          .eq('class_id', classId)
          .eq('student_id', studentId)
          .maybeSingle();

  /// This class's published assessments + the student's latest score on each.
  /// Teacher RLS reads all attempts; `released` flags manual-unreleased rows
  /// for the "Not released" chip.
  Future<List<Json>> studentAssessmentRows(
      String classId, String studentId) async {
    final acts = List<Json>.from(await sb
        .from('assessments')
        .select(
            'id, title, kind, release_scores, scores_released, lessons!inner(class_id, title)')
        .eq('lessons.class_id', classId)
        .eq('is_published', true)
        .order('created_at'));
    final atts = List<Json>.from(await sb
        .from('attempts')
        .select('assessment_id, score, points_earned, points_total, submitted_at')
        .eq('student_id', studentId)
        .not('submitted_at', 'is', null)
        .order('submitted_at', ascending: false));
    final latest = <String, Json>{};
    for (final a in atts) {
      final id = '${a['assessment_id']}';
      if (a['score'] != null && !latest.containsKey(id)) {
        latest[id] = a;
      }
    }
    return [
      for (final a in acts)
        {
          'id': a['id'],
          'title': a['title'],
          'kind': a['kind'],
          'lesson_title': '${a['lessons']?['title'] ?? 'No lesson'}',
          'score': latest['${a['id']}']?['score'],
          'points_earned': latest['${a['id']}']?['points_earned'],
          'points_total': latest['${a['id']}']?['points_total'],
          'released':
              a['release_scores'] != 'manual' || a['scores_released'] == true,
        }
    ];
  }

  /// Display name for any profile (teacher picks it for the paper header).
  Future<String> profileName(String uid) async =>
      '${(await sb.from('profiles').select('full_name').eq('id', uid).maybeSingle())?['full_name'] ?? 'Teacher'}';

  /// The student's paper for one assessment — teacher sees everything:
  /// full questions + keys, and the latest submitted attempt's answers.
  /// Returns {assessmentTitle, lessonTitle, publishedAt, parts, questions,
  /// attempt: {score, submitted_at}|null, answers: {question_id: row}}.
  Future<Json> attemptPaper(String assessmentId, String studentId) async {
    final a = Map<String, dynamic>.from(await sb
        .from('assessments')
        .select('title, created_at, lessons(title)')
        .eq('id', assessmentId)
        .single());
    final parts = List<Json>.from(await sb
        .from('assessment_parts')
        .select('id, title, directions, scored, points')
        .eq('assessment_id', assessmentId)
        .order('position'));
    final qs = List<Json>.from(await sb
        .from('questions')
        .select('id, part_id, qtype, prompt, choices, correct_index, answer')
        .eq('assessment_id', assessmentId)
        .order('position'));
    final att = await sb
        .from('attempts')
        .select(
            'score, points_earned, points_total, submitted_at, attempt_answers(question_id, answer, is_correct, earned)')
        .eq('assessment_id', assessmentId)
        .eq('student_id', studentId)
        .not('submitted_at', 'is', null)
        .order('submitted_at', ascending: false)
        .limit(1)
        .maybeSingle();
    final answers = <String, Json>{};
    for (final r
        in List<Json>.from(att?['attempt_answers'] as List? ?? const [])) {
      answers['${r['question_id']}'] = r;
    }
    return {
      'assessmentTitle': a['title'],
      'lessonTitle': a['lessons']?['title'] ?? 'No lesson',
      'publishedAt': a['created_at'],
      'parts': parts,
      'questions': qs,
      'attempt': att == null
          ? null
          : {
              'score': att['score'],
              'points_earned': att['points_earned'],
              'points_total': att['points_total'],
              'submitted_at': att['submitted_at'],
            },
      'answers': answers,
    };
  }

  /// Per-lesson activity (assessment) counts for the curriculum cards
  /// ("3 activities") — one joined query grouped client-side.
  Future<Map<String, int>> lessonActivityCounts(String classId) async {
    final rows = List<Json>.from(await sb
        .from('assessments')
        .select('lesson_id, lessons!inner(class_id)')
        .eq('lessons.class_id', classId));
    final counts = <String, int>{};
    for (final r in rows) {
      final lid = r['lesson_id'] as String?;
      if (lid != null) counts[lid] = (counts[lid] ?? 0) + 1;
    }
    return counts;
  }

  /// This class's published lessons + the student's lesson_progress percent
  /// (0 when never opened).
  Future<List<Json>> studentLessonRows(String classId, String studentId) async {
    final lessons = List<Json>.from(await sb
        .from('lessons')
        .select('id, title')
        .eq('class_id', classId)
        .eq('is_published', true)
        .order('position'));
    final prog = List<Json>.from(await sb
        .from('lesson_progress')
        .select('lesson_id, percent')
        .eq('student_id', studentId));
    final pct = {
      for (final p in prog) '${p['lesson_id']}': (p['percent'] as num?) ?? 0,
    };
    return [
      for (final l in lessons)
        {
          'id': l['id'],
          'title': l['title'],
          'percent': pct['${l['id']}'] ?? 0,
        }
    ];
  }

  // ---------- class report ----------

  /// Class-wide assessment rollup: published assessments + every student's
  /// submitted attempts reduced to latest-per-student average + count.
  /// Rows: {id, title, kind, avg (null = no attempts), attempts, released}.
  Future<List<Json>> classAssessmentRows(String classId) async {
    final acts = List<Json>.from(await sb
        .from('assessments')
        .select(
            'id, title, kind, release_scores, scores_released, lessons!inner(class_id)')
        .eq('lessons.class_id', classId)
        .eq('is_published', true)
        .order('created_at'));
    if (acts.isEmpty) return const [];
    final ids = [for (final a in acts) '${a['id']}'];
    final atts = List<Json>.from(await sb
        .from('attempts')
        .select('assessment_id, student_id, score, submitted_at')
        .inFilter('assessment_id', ids)
        .not('submitted_at', 'is', null)
        .order('submitted_at', ascending: false));
    // Only active members count — removed students' attempts stay out of
    // the rollup, consistent with the rest of the portal.
    final members = List<Json>.from(await sb
        .from('enrollments')
        .select('student_id')
        .eq('class_id', classId)
        .eq('status', 'active'));
    final activeIds = {for (final m in members) '${m['student_id']}'};
    // Latest score per student per assessment (rows arrive newest-first).
    final latest = <String, Map<String, num>>{};
    for (final a in atts) {
      if (a['score'] == null || !activeIds.contains('${a['student_id']}')) {
        continue;
      }
      final per = latest.putIfAbsent('${a['assessment_id']}', () => {});
      per.putIfAbsent('${a['student_id']}', () => a['score'] as num);
    }
    return [
      for (final a in acts)
        {
          'id': a['id'],
          'title': a['title'],
          'kind': a['kind'],
          'avg': latest.containsKey('${a['id']}')
              ? (latest['${a['id']}']!.values.reduce((s, v) => s + v) /
                      latest['${a['id']}']!.length)
                  .round()
              : null,
          'attempts': latest['${a['id']}']?.length ?? 0,
          'released':
              a['release_scores'] != 'manual' || a['scores_released'] == true,
        }
    ];
  }

  /// Class-wide lesson rollup: published lessons + all member progress rows
  /// averaged across ACTIVE enrollments (unstarted counts as 0).
  /// Rows: {id, title, avg}.
  Future<List<Json>> classLessonAvgs(String classId) async {
    final lessons = List<Json>.from(await sb
        .from('lessons')
        .select('id, title')
        .eq('class_id', classId)
        .eq('is_published', true)
        .order('position'));
    if (lessons.isEmpty) return const [];
    final members = List<Json>.from(await sb
        .from('enrollments')
        .select('student_id')
        .eq('class_id', classId)
        .eq('status', 'active'));
    final activeIds = {for (final m in members) '${m['student_id']}'};
    final ids = [for (final l in lessons) '${l['id']}'];
    // lesson_progress rows outlive enrollment removal — only sum progress
    // from currently-active students so the average never exceeds 100%.
    final prog = List<Json>.from(await sb
        .from('lesson_progress')
        .select('lesson_id, student_id, percent')
        .inFilter('lesson_id', ids));
    final sum = <String, num>{};
    for (final p in prog) {
      if (!activeIds.contains('${p['student_id']}')) continue;
      final id = '${p['lesson_id']}';
      sum[id] = (sum[id] ?? 0) + ((p['percent'] as num?) ?? 0);
    }
    final denom = activeIds.isEmpty ? 1 : activeIds.length;
    return [
      for (final l in lessons)
        {
          'id': l['id'],
          'title': l['title'],
          'avg': ((sum['${l['id']}'] ?? 0) / denom).round(),
        }
    ];
  }

  /// Student: classes they belong to (status = active | pending).
  /// profiles!classes_teacher_id_fkey embeds the teacher's name
  /// (FK hint required — classes↔profiles also joins via enrollments;
  /// migration 0009's read policy lets students see it). The nested
  /// enrollments(status) gives each class's roster (migration 0010).
  /// Filtered to OWN rows: 0010's member-read policy returns the whole
  /// roster, so without the eq the picker duplicates a card per classmate.
  Future<List<Json>> enrolledClasses() async => List<Json>.from(await sb
      .from('enrollments')
      .select(
          'class_id, status, classes(name, code, profiles!classes_teacher_id_fkey(full_name), enrollments(status))')
      .eq('student_id', uid));

  /// class_id -> count of published assessments the student hasn't
  /// attempted yet ("N to do" on the picker's class cards).
  Future<Map<String, int>> awaitingByClass() async {
    final acts = List<Json>.from(await sb
        .from('assessments')
        .select('id, lessons!inner(class_id)')
        .eq('is_published', true));
    // The RPC (not an attempts read) counts submitted-but-unreleased attempts
    // that "attempts own read" hides — otherwise they show as still to do.
    final done = {
      for (final a in (await sb.rpc('my_attempted_assessment_ids') as List))
        '$a'
    };
    final m = <String, int>{};
    for (final a in acts) {
      if (done.contains('${a['id']}')) continue;
      final cid = '${a['lessons']?['class_id']}';
      if (cid == 'null') continue;
      m[cid] = (m[cid] ?? 0) + 1;
    }
    return m;
  }

  /// Redeem a class code -> {name, status}. Throws on invalid code.
  Future<Json> joinClass(String code) async {
    final r = Map<String, dynamic>.from(
        await sb.rpc('join_class', params: {'p_code': code}));
    if (r['error'] != null) throw Exception(r['error']);
    return r;
  }

  // ---------- admin ----------

  Future<List<Json>> allProfiles() async => List<Json>.from(await sb
      .from('profiles')
      .select('id, full_name, role')
      .order('full_name'));

  /// Change a user's role. Needs the "profiles admin write" policy (0004).
  Future<void> setRole(String userId, String role) async =>
      await sb.from('profiles').update({'role': role}).eq('id', userId);

  /// Uploads bytes to R2 via presigned PUT; returns the object key.
  /// Folders are allowlisted by the edge function (avatars/thumbnails/lessons).
  Future<String> uploadToR2(List<int> bytes, String filename,
      String contentType, String folder) async {
    final res = await sb.functions.invoke('r2-presign', body: {
      'action': 'put',
      'folder': folder,
      'filename': filename,
      'contentType': contentType,
    });
    final url = (res.data as Map)['url'] as String;
    final key = (res.data as Map)['key'] as String;
    final put = await http.put(Uri.parse(url),
        body: bytes, headers: {'Content-Type': contentType});
    if (put.statusCode >= 300) {
      throw Exception('Upload failed (${put.statusCode})');
    }
    return key;
  }

  /// Uploads an avatar image to R2; returns the object key.
  Future<String> uploadAvatar(
          List<int> bytes, String filename, String contentType) =>
      uploadToR2(bytes, filename, contentType, 'avatars');

  /// Stores the avatar's R2 object key on the user's own profile row.
  Future<void> setAvatar(String key) async =>
      await sb.from('profiles').update({'avatar_url': key}).eq('id', uid);

  /// Signed GET URL for a Cloudflare R2 object (via Supabase Edge Function).
  Future<String?> signedUrl(String? key) async {
    if (key == null || key.isEmpty) return null;
    final res = await sb.functions
        .invoke('r2-presign', body: {'action': 'get', 'key': key});
    return (res.data as Map)['url'] as String?;
  }
}

final repoProvider = Provider((_) => Repo());

/// Subject list shown in the lesson form + filter chips — built-ins plus
/// teacher-added customs, synced per-teacher in profiles.settings.subjects.
final subjectsN = ValueNotifier<List<String>>(
    const ['Physics', 'Chemistry', 'Earth Science']);

Future<void> loadSubjects() async {
  try {
    final row = await sb
        .from('profiles')
        .select('settings')
        .eq('id', sb.auth.currentUser!.id)
        .maybeSingle();
    final l = (row?['settings'] as Map?)?['subjects'];
    if (l is List && l.isNotEmpty) subjectsN.value = l.cast<String>();
  } catch (e) {
    // No session/backend (e.g. widget tests) — keep the defaults.
    debugPrint('loadSubjects failed: $e');
  }
}

/// Applies [list] locally right away, then tries to sync it. Returns whether
/// the remote write succeeded so callers can say "saved locally only".
Future<bool> saveSubjects(List<String> list) async {
  subjectsN.value = List.of(list);
  try {
    final id = sb.auth.currentUser!.id;
    final row = await sb
        .from('profiles')
        .select('settings')
        .eq('id', id)
        .maybeSingle();
    final s = Map<String, dynamic>.from(
        (row?['settings'] as Map?)?.cast<String, dynamic>() ?? {});
    s['subjects'] = list;
    await sb.from('profiles').update({'settings': s}).eq('id', id);
    return true;
  } catch (e) {
    debugPrint('saveSubjects sync failed: $e');
    return false;
  }
}

/// Set once the user leaves /select-class by entering (or creating) a class.
/// A plain notifier (not widget-scoped) so the GoRouter redirect can read it;
/// resets on app restart, matching "choose a classroom after sign-in".
final classPicked = ValueNotifier<bool>(false);

/// The class a teacher/admin opened at /select-class this session — drives
/// the whole /teacher portal (4 tabs are all scoped to this row). Null until
/// picked; cleared on "Switch class" so the router re-gates.
final currentClass = ValueNotifier<Json?>(null);

/// Emits on every auth change; user-scoped providers watch it so a sign-out
/// + sign-in as a different user never shows the previous user's data.
final authChangesProvider = StreamProvider((ref) =>
    Supabase.instance.client.auth.onAuthStateChange.map((e) => e.event));

final meProvider = FutureProvider((ref) {
  ref.watch(authChangesProvider);
  return ref.read(repoProvider).me();
});
final progressProvider = FutureProvider((ref) {
  ref.watch(authChangesProvider);
  return ref.read(repoProvider).myProgress();
});
final recentProvider = FutureProvider((ref) {
  ref.watch(authChangesProvider);
  return ref.read(repoProvider).recentActivity();
});
final subjectProvider = StateProvider<String?>((_) => null);
final lessonsProvider = FutureProvider((ref) {
  ref.watch(authChangesProvider);
  return ref.read(repoProvider).lessons(subject: ref.watch(subjectProvider));
});

// teacher portal — all scoped to the class in currentClass
final classMembersProvider = FutureProvider.autoDispose
    .family<List<Json>, String>(
        (ref, id) => ref.read(repoProvider).classMembers(id));
final classLessonsProvider = FutureProvider.autoDispose
    .family<List<Json>, String>(
        (ref, id) => ref.read(repoProvider).classLessons(id));
final classProgressProvider = FutureProvider.autoDispose
    .family<List<Json>, String>(
        (ref, id) => ref.read(repoProvider).classStudentProgress(id));
final classCompletedProvider = FutureProvider.autoDispose.family<int, String>(
    (ref, id) => ref.read(repoProvider).classCompletedCount(id));

// student report — keyed by (classId, studentId). Record keys have value
// equality; List keys would rebuild a new provider on every watch.
final classMembershipProvider = FutureProvider.autoDispose
    .family<Json?, (String, String)>(
        (ref, ids) => ref.read(repoProvider).classMembership(ids.$1, ids.$2));
final studentAssessmentsProvider = FutureProvider.autoDispose
    .family<List<Json>, (String, String)>((ref, ids) =>
        ref.read(repoProvider).studentAssessmentRows(ids.$1, ids.$2));
final studentLessonsProvider = FutureProvider.autoDispose
    .family<List<Json>, (String, String)>(
        (ref, ids) => ref.read(repoProvider).studentLessonRows(ids.$1, ids.$2));
final classAssessmentsProvider = FutureProvider.autoDispose
    .family<List<Json>, String>(
        (ref, id) => ref.read(repoProvider).classAssessmentRows(id));
final classLessonAvgsProvider = FutureProvider.autoDispose
    .family<List<Json>, String>(
        (ref, id) => ref.read(repoProvider).classLessonAvgs(id));
final lessonActivityCountsProvider = FutureProvider.autoDispose
    .family<Map<String, int>, String>(
        (ref, id) => ref.read(repoProvider).lessonActivityCounts(id));
final lessonAttemptCountsProvider = FutureProvider.autoDispose
    .family<Map<String, int>, String>(
        (ref, id) => ref.read(repoProvider).lessonAttemptCounts(id));
final allLessonsProvider = FutureProvider((ref) {
  ref.watch(authChangesProvider);
  return ref.read(repoProvider).allLessons();
});

// admin
final profilesProvider = FutureProvider((ref) {
  ref.watch(authChangesProvider);
  return ref.read(repoProvider).allProfiles();
});
