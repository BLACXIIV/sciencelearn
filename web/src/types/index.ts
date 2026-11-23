// Domain contracts mirroring supabase/migrations/0001_init.sql.
// Update these if the schema changes — services and components both depend on them.

export type Role = "student" | "teacher" | "admin";

export interface Profile {
  id: string;
  full_name: string;
  role: Role;
}

export const SUBJECTS = ["Physics", "Chemistry", "Earth Science"] as const;
export type Subject = (typeof SUBJECTS)[number];

export interface Lesson {
  id: string;
  subject: Subject;
  title: string;
  objectives: string;
  content_md: string;
  thumbnail_key: string | null;
  content_key: string | null;
  position: number;
  is_published: boolean;
  created_by: string | null;
  created_at: string;
}

/** Input collected by the lesson form; services turn this into a lessons row. */
export interface NewLessonInput {
  title: string;
  subject: Subject;
  objectives: string;
  thumbnail: File | null;
  material: File | null;
}

/** Row shape of the v_student_progress view. */
export interface StudentProgress {
  student_id: string;
  full_name: string;
  lessons_pct: number;
  quizzes_pct: number | null;
  pre_score: number | null;
  post_score: number | null;
}

export interface ClassDashboard {
  students: StudentProgress[];
  completedLessons: number;
}

// ---------- Student portal ----------

/** lessons row joined with the caller's own lesson_progress (0 or 1 rows). */
export type LessonWithProgress = Lesson & { lesson_progress: { percent: number }[] };

export type AssessmentKind =
  | "pre_test" | "post_test" | "topic_quiz" | "problem_solving" | "final_challenge" | "practice";

export interface Assessment {
  id: string;
  lesson_id: string | null;
  kind: AssessmentKind;
  title: string;
  description: string;
  time_limit_sec: number | null;
  is_published: boolean;
  created_at: string;
}

/** questions_public shape — correct_index is never exposed to students. */
export interface QuizQuestion {
  id: string;
  assessment_id: string;
  prompt: string;
  choices: string[];
  position: number;
}

export interface AttemptResult {
  attempt_id: string;
  score: number;
  correct: number;
  total: number;
}

export interface RecentActivity {
  percent: number;
  updated_at: string;
  lessons: { title: string } | null;
}

export interface Flashcard { id: string; lesson_id: string | null; front: string; back: string }
export interface Formula { id: string; lesson_id: string | null; title: string; expression: string; notes: string | null }
export interface KeyTerm { id: string; lesson_id: string | null; term: string; definition: string }

export type R2Folder = "thumbnails" | "lessons" | "avatars";
