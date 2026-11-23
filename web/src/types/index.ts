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

export type R2Folder = "thumbnails" | "lessons" | "avatars";
