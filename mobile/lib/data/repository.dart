import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

typedef Json = Map<String, dynamic>;
final sb = Supabase.instance.client;

class Repo {
  String get uid => sb.auth.currentUser!.id;

  Future<Json> me() async => await sb.from('profiles').select().eq('id', uid).single();

  Future<Json?> myProgress() async =>
      await sb.from('v_student_progress').select().eq('student_id', uid).maybeSingle();

  /// Published lessons the student can see (own classes + legacy shared).
  /// Pass classId to scope to one class.
  Future<List<Json>> lessons({String? subject, String? classId}) async {
    var q = sb.from('lessons').select('*, lesson_progress(percent)').eq('is_published', true);
    if (classId != null) q = q.eq('class_id', classId);
    if (subject != null) q = q.eq('subject', subject);
    return List<Json>.from(await q.order('position'));
  }

  Future<Json> lesson(String id) async => await sb.from('lessons').select().eq('id', id).single();

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

  Future<List<Json>> assessments(List<String> kinds) async => List<Json>.from(await sb
      .from('assessments')
      .select()
      .inFilter('kind', kinds)
      .eq('is_published', true)
      .order('created_at'));

  Future<List<Json>> questions(String assessmentId) async => List<Json>.from(
      await sb.from('questions_public').select().eq('assessment_id', assessmentId).order('position'));

  /// Published activities inside one lesson (student view, RLS hides drafts).
  Future<List<Json>> lessonActivities(String lessonId) async => List<Json>.from(await sb
      .from('assessments').select().eq('lesson_id', lessonId).eq('is_published', true).order('created_at'));

  Future<Json> submit(String assessmentId, Map<String, dynamic> answers) async {
    final r = Map<String, dynamic>.from(
        await sb.rpc('submit_attempt', params: {'p_assessment': assessmentId, 'p_answers': answers}));
    if (r['error'] != null) throw Exception(r['error']);
    return r;
  }

  Future<List<Json>> flashcards() async => List<Json>.from(await sb.from('flashcards').select());
  Future<List<Json>> formulas() async => List<Json>.from(await sb.from('formulas').select());
  Future<List<Json>> keyTerms() async => List<Json>.from(await sb.from('key_terms').select());

  // ---------- teacher portal ----------

  /// All lessons (staff bypass the is_published filter via RLS).
  Future<List<Json>> allLessons() async =>
      List<Json>.from(await sb.from('lessons').select().order('position'));

  Future<void> createLesson(String classId, String title, String subject, String objectives) async {
    final existing = await sb.from('lessons').select('id').eq('class_id', classId);
    await sb.from('lessons').insert({
      'class_id': classId,
      'title': title,
      'subject': subject,
      'objectives': objectives,
      'position': existing.length + 1,
      'is_published': false,
      'created_by': uid,
    });
  }

  Future<void> setPublished(String lessonId, bool publish) async =>
      await sb.from('lessons').update({'is_published': publish}).eq('id', lessonId);

  /// Every student's progress row (teachers read all via RLS).
  Future<List<Json>> classProgress() async =>
      List<Json>.from(await sb.from('v_student_progress').select().order('full_name'));

  /// Count of fully completed lesson_progress rows (dashboard stat).
  Future<int> completedLessonsCount() async =>
      (await sb.from('lesson_progress').select('lesson_id').eq('percent', 100)).length;

  // ---------- activity builder (teacher) ----------

  /// Assessments attached to a lesson, published or not (staff bypass via RLS).
  Future<List<Json>> lessonAssessments(String lessonId) async => List<Json>.from(
      await sb.from('assessments').select().eq('lesson_id', lessonId).order('created_at'));

  Future<Json> createAssessment(String lessonId, String kind, String title, String desc) async =>
      Map<String, dynamic>.from(await sb.from('assessments').insert({
        'lesson_id': lessonId, 'kind': kind, 'title': title, 'description': desc,
      }).select().single());

  Future<void> setAssessmentPublished(String id, bool published) async =>
      await sb.from('assessments').update({'is_published': published}).eq('id', id);

  /// 'immediate' = score shows after submit; 'manual' = teacher releases it.
  Future<void> setScoreRelease(String id, String mode) async =>
      await sb.from('assessments').update({'release_scores': mode}).eq('id', id);

  /// Teacher releases scores for a manual-release assessment.
  Future<void> releaseScores(String id) async =>
      await sb.from('assessments').update({'scores_released': true}).eq('id', id);

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

  /// Full questions incl. answer keys — teacher policy only, never student-visible.
  Future<List<Json>> questionsFull(String assessmentId) async => List<Json>.from(
      await sb.from('questions').select().eq('assessment_id', assessmentId).order('position'));

  Future<void> upsertQuestion(Json q) async {
    final id = q.remove('id');
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
      .select('id, name, code, join_policy, enrollments(status)')
      .eq('teacher_id', uid)
      .order('created_at'));

  Future<Json> createClass(String name, String joinPolicy) async =>
      Map<String, dynamic>.from(await sb.from('classes')
          .insert({'name': name, 'teacher_id': uid, 'join_policy': joinPolicy})
          .select().single());

  /// Roster for a class: student rows with enrollment status.
  Future<List<Json>> classMembers(String classId) async => List<Json>.from(await sb
      .from('enrollments')
      .select('student_id, status, profiles(full_name)')
      .eq('class_id', classId));

  Future<void> approveMember(String classId, String studentId) async => await sb
      .from('enrollments').update({'status': 'active'})
      .eq('class_id', classId).eq('student_id', studentId);

  /// Reject a pending request or remove an enrolled student.
  Future<void> removeMember(String classId, String studentId) async => await sb
      .from('enrollments').delete()
      .eq('class_id', classId).eq('student_id', studentId);

  Future<void> deleteClass(String id) async =>
      await sb.from('classes').delete().eq('id', id);

  /// Lessons in one class (teacher view: includes drafts).
  Future<List<Json>> classLessons(String classId) async => List<Json>.from(await sb
      .from('lessons').select().eq('class_id', classId).order('created_at'));

  /// Student: classes they belong to (status = active | pending).
  Future<List<Json>> enrolledClasses() async => List<Json>.from(
      await sb.from('enrollments').select('class_id, status, classes(name, code)'));

  /// Redeem a class code -> {name, status}. Throws on invalid code.
  Future<Json> joinClass(String code) async {
    final r = Map<String, dynamic>.from(
        await sb.rpc('join_class', params: {'p_code': code}));
    if (r['error'] != null) throw Exception(r['error']);
    return r;
  }

  // ---------- admin ----------

  Future<List<Json>> allProfiles() async =>
      List<Json>.from(await sb.from('profiles').select('id, full_name, role').order('full_name'));

  /// Change a user's role. Needs the "profiles admin write" policy (0004).
  Future<void> setRole(String userId, String role) async =>
      await sb.from('profiles').update({'role': role}).eq('id', userId);

  /// Uploads an avatar image to R2 via presigned PUT; returns the object key.
  Future<String> uploadAvatar(List<int> bytes, String filename, String contentType) async {
    final res = await sb.functions.invoke('r2-presign', body: {
      'action': 'put', 'folder': 'avatars', 'filename': filename, 'contentType': contentType,
    });
    final url = (res.data as Map)['url'] as String;
    final key = (res.data as Map)['key'] as String;
    final put = await http.put(Uri.parse(url), body: bytes, headers: {'Content-Type': contentType});
    if (put.statusCode >= 300) throw Exception('Upload failed (${put.statusCode})');
    return key;
  }

  /// Stores the avatar's R2 object key on the user's own profile row.
  Future<void> setAvatar(String key) async =>
      await sb.from('profiles').update({'avatar_url': key}).eq('id', uid);

  /// Signed GET URL for a Cloudflare R2 object (via Supabase Edge Function).
  Future<String?> signedUrl(String? key) async {
    if (key == null || key.isEmpty) return null;
    final res = await sb.functions.invoke('r2-presign', body: {'action': 'get', 'key': key});
    return (res.data as Map)['url'] as String?;
  }
}

final repoProvider = Provider((_) => Repo());

/// Emits on every auth change; user-scoped providers watch it so a sign-out
/// + sign-in as a different user never shows the previous user's data.
final authChangesProvider = StreamProvider(
    (ref) => Supabase.instance.client.auth.onAuthStateChange.map((e) => e.event));

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

// teacher portal
final classProgressProvider = FutureProvider((ref) {
  ref.watch(authChangesProvider);
  return ref.read(repoProvider).classProgress();
});
final completedCountProvider = FutureProvider((ref) {
  ref.watch(authChangesProvider);
  return ref.read(repoProvider).completedLessonsCount();
});
final allLessonsProvider = FutureProvider((ref) {
  ref.watch(authChangesProvider);
  return ref.read(repoProvider).allLessons();
});

// admin
final profilesProvider = FutureProvider((ref) {
  ref.watch(authChangesProvider);
  return ref.read(repoProvider).allProfiles();
});
