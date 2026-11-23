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

  Future<List<Json>> lessons({String? subject}) async {
    var q = sb.from('lessons').select('*, lesson_progress(percent)').eq('is_published', true);
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

  Future<Json> submit(String assessmentId, Map<String, dynamic> answers) async =>
      Map<String, dynamic>.from(
          await sb.rpc('submit_attempt', params: {'p_assessment': assessmentId, 'p_answers': answers}));

  Future<List<Json>> flashcards() async => List<Json>.from(await sb.from('flashcards').select());
  Future<List<Json>> formulas() async => List<Json>.from(await sb.from('formulas').select());
  Future<List<Json>> keyTerms() async => List<Json>.from(await sb.from('key_terms').select());

  // ---------- teacher portal ----------

  /// All lessons (staff bypass the is_published filter via RLS).
  Future<List<Json>> allLessons() async =>
      List<Json>.from(await sb.from('lessons').select().order('position'));

  Future<void> createLesson(String title, String subject, String objectives) async {
    final existing = await sb.from('lessons').select('id');
    await sb.from('lessons').insert({
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
final meProvider = FutureProvider((ref) => ref.read(repoProvider).me());
final progressProvider = FutureProvider((ref) => ref.read(repoProvider).myProgress());
final recentProvider = FutureProvider((ref) => ref.read(repoProvider).recentActivity());
final subjectProvider = StateProvider<String?>((_) => null);
final lessonsProvider = FutureProvider((ref) =>
    ref.read(repoProvider).lessons(subject: ref.watch(subjectProvider)));

// teacher portal
final classProgressProvider = FutureProvider((ref) => ref.read(repoProvider).classProgress());
final completedCountProvider = FutureProvider((ref) => ref.read(repoProvider).completedLessonsCount());
final allLessonsProvider = FutureProvider((ref) => ref.read(repoProvider).allLessons());

// admin
final profilesProvider = FutureProvider((ref) => ref.read(repoProvider).allProfiles());
