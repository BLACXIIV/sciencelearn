// Domain contracts mirroring supabase/migrations/0001_init.sql.
// Update these if the schema changes — services and components both depend on them.

export type Role = "student" | "teacher" | "admin";

export interface Profile {
  id: string;
  full_name: string;
  role: Role;
  avatar_url: string | null;
}

export const SUBJECTS = ["Physics", "Chemistry", "Earth Science"] as const;
// Teachers can add/remove subjects at runtime (lesson picker + filters), so
// Subject is not a closed union — the `| (string & {})` keeps autocomplete
// for the built-ins while accepting any custom name.
export type Subject = (typeof SUBJECTS)[number] | (string & {});

export interface Lesson {
  id: string;
  class_id: string | null;
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
  /** 'immediate' = score shown after submit; 'manual' = teacher releases. */
  release_scores: "immediate" | "manual";
  scores_released: boolean;
  created_at: string;
}

export type QuestionType = "multiple_choice" | "true_false" | "fill_blank" | "enumeration" | "identification";

/** questions_public shape — answer keys are never exposed to students. */
export interface QuizQuestion {
  id: string;
  assessment_id: string;
  qtype: QuestionType;
  prompt: string;
  choices: string[] | null;
  meta: { n?: number };
  position: number;
}

/** Full questions row for the teacher builder — includes the answer key. */
export interface Question extends QuizQuestion {
  correct_index: number | null;
  answer: { correct?: boolean; accepted?: string[]; items?: string[]; ordered?: boolean; partial?: boolean } | null;
  explanation: string;
}

/** Student answer payload per question id, keyed by qtype. */
export type AnswerValue = { i: number } | { b: boolean } | { t: string } | { items: string[] };

export interface AttemptResult {
  attempt_id: string;
  /** null while the teacher holds scores back (manual release). */
  score: number | null;
  total: number;
  released: boolean;
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
