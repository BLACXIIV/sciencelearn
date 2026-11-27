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

/** Activity-level quiz mode picked at creation; presets each new question's type.
 *  The first five are supported by the student runner today. */
export type ActivityMode =
  | "multiple_choice" | "true_false" | "fill_blank" | "identification" | "enumeration"
  | "multi_select" | "classification" | "matching" | "ordering"
  | "table_fill" | "hotspot" | "scenario";

export interface Assessment {
  id: string;
  lesson_id: string | null;
  kind: AssessmentKind;
  mode: ActivityMode;
  title: string;
  description: string;
  time_limit_sec: number | null;
  is_published: boolean;
  /** 'immediate' = score shown after submit; 'manual' = teacher releases. */
  release_scores: "immediate" | "manual";
  scores_released: boolean;
  created_at: string;
  /** Teacher list embed — number of parts inside the activity. */
  part_count?: number;
  /** Teacher list embed — number of questions inside the activity. */
  question_count?: number;
}

/** A part inside an activity (its own directions + quiz mode + items).
 *  scored=false parts are practice/written work that don't count toward the score. */
export interface AssessmentPart {
  id: string;
  assessment_id: string;
  title: string;
  directions: string;
  mode: ActivityMode;
  scored: boolean;
  /** Points each item in this part is worth (1 = default). */
  points: number;
  position: number;
}

export type QuestionType =
  "multiple_choice" | "multi_select" | "true_false" | "fill_blank"
  | "enumeration" | "identification" | "classification" | "ordering";

/** questions_public shape — answer keys are never exposed to students. */
export interface QuizQuestion {
  id: string;
  assessment_id: string;
  /** Which part this item belongs to; null = ungrouped (legacy flat quiz). */
  part_id: string | null;
  qtype: QuestionType;
  prompt: string;
  choices: string[] | null;
  /** n = enumeration blanks; min/max = multi_select required picks;
   *  buckets = classification zone names; context = student-facing body;
   *  shuffle = ordering re-shuffles per open (default true). */
  meta: { n?: number; min?: number; max?: number; buckets?: string[];
    context?: string; shuffle?: boolean };
  position: number;
}

/** Full questions row for the teacher builder — includes the answer key. */
export interface Question extends QuizQuestion {
  correct_index: number | null;
  answer: {
    /** true_false: the key. ordering: choice indexes in correct order —
     *  one key name, disjoint qtypes. */
    correct?: boolean | number[]; accepted?: string[]; items?: string[];
    ordered?: boolean; partial?: boolean;
    /** multi_select: indexes of correct choices + required pick range. */
    indexes?: number[]; min?: number; max?: number;
    /** classification: bucket names + correct bucket index per choice. */
    buckets?: string[]; zones?: number[];
    /** Student-facing body shown above the items (equations, a table, …). */
    context?: string;
    /** ordering: re-shuffle the shown order per open (default true). */
    shuffle?: boolean;
  } | null;
  explanation: string;
}

/** Student answer payload per question id, keyed by qtype. */
export type AnswerValue =
  { i: number } | { b: boolean } | { t: string } | { items: string[] }
  | { sel: number[] } | { z: number[] } | { o: number[] };

export interface AttemptResult {
  attempt_id: string;
  /** null while the teacher holds scores back (manual release). */
  score: number | null;
  total: number;
  released: boolean;
  /** Point totals (sum of earned*part points / part points); null when all parts unscored. */
  points_earned: number | null;
  points_total: number | null;
}

/** review_attempt() payload (migration 0020): student's picks + answer keys,
 *  only once scores are visible. */
export interface ReviewItem {
  question_id: string;
  /** The question's answer key: {correct} tf, {accepted} text, {items,ordered} enum. */
  key: Question["answer"];
  correct_index: number | null;
  student: AnswerValue | null;
  is_correct: boolean | null;
  earned: number | null;
}

export interface ReviewResult {
  attempted: boolean;
  released?: boolean;
  score?: number | null;
  total?: number;
  points_earned?: number | null;
  points_total?: number | null;
  items?: ReviewItem[];
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
