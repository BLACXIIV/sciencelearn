import { Navigate, useParams } from "react-router-dom";

/**
 * Legacy route — the lesson-scoped activity list + question editor moved to
 * the Create Quiz picker (/quiz?lesson=) and the activity builder
 * (/quiz/a/:assessmentId). Keep the path working for old links.
 */
export default function LessonActivities() {
  const { classId = "", lessonId = "" } = useParams();
  return <Navigate to={`/teacher/c/${classId}/quiz?lesson=${lessonId}`} replace />;
}
