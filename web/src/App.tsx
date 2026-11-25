import { Navigate, Route, Routes } from "react-router-dom";
import RequireTeacher from "./components/RequireTeacher";
import RequireStudent from "./components/RequireStudent";
import Landing from "./pages/Landing";
import AppLayout from "./components/AppLayout";
import StudentLayout from "./components/StudentLayout";
import Login from "./pages/Login";
import SignUp from "./pages/SignUp";
import ForgotPassword from "./pages/ForgotPassword";
import ResetPassword from "./pages/ResetPassword";
import SelectClassroom from "./pages/SelectClassroom";
import LessonActivities from "./pages/LessonActivities";
import ClassDashboard from "./pages/teacher/ClassDashboard";
import ClassLessons from "./pages/teacher/ClassLessons";
import ClassQuiz from "./pages/teacher/ClassQuiz";
import ClassStudents from "./pages/teacher/ClassStudents";
import Users from "./pages/Users";
import { pickedClassId } from "./services/classes";
import StudentHome from "./pages/student/Home";
import StudentClasses from "./pages/student/Classes";
import StudentClassDetail from "./pages/student/ClassDetail";
import StudentLessonDetail from "./pages/student/LessonDetail";
import StudentAssessments from "./pages/student/Assessments";
import StudentQuiz from "./pages/student/Quiz";
import StudentReview from "./pages/student/Review";
import StudentProgressPage from "./pages/student/Progress";
import StudentAccount from "./pages/student/Account";
import UiKit from "./pages/dev/UiKit";

/** /teacher root: drop into the class picked this session, else re-gate. */
function TeacherHome() {
  const id = pickedClassId();
  return <Navigate to={id ? `/teacher/c/${id}` : "/select-classroom"} replace />;
}

export default function App() {
  return (
    <Routes>
      {import.meta.env.DEV && <Route path="/dev/ui-kit" element={<UiKit />} />}
      <Route path="/login" element={<Login />} />
      <Route path="/signup" element={<SignUp />} />
      <Route path="/forgot-password" element={<ForgotPassword />} />
      <Route path="/reset-password" element={<ResetPassword />} />

      {/* Post-login gate: pick a classroom before entering the portal. */}
      <Route path="/select-classroom" element={<SelectClassroom />} />

      {/* Landing for visitors; signed-in users bounce to their portal. */}
      <Route index element={<Landing />} />

      {/* Student portal (mirrors the mobile app). */}
      <Route element={<RequireStudent />}>
        <Route path="/student/quiz/:id" element={<StudentQuiz />} />
        <Route element={<StudentLayout />}>
          <Route path="/student" element={<StudentHome />} />
          <Route path="/student/classes" element={<StudentClasses />} />
          <Route path="/student/classes/:id" element={<StudentClassDetail />} />
          <Route path="/student/lessons/:id" element={<StudentLessonDetail />} />
          <Route path="/student/assessments" element={<StudentAssessments />} />
          <Route path="/student/review" element={<StudentReview />} />
          <Route path="/student/progress" element={<StudentProgressPage />} />
          <Route path="/student/account" element={<StudentAccount />} />
        </Route>
      </Route>

      {/* Teacher/admin portal — class-scoped after /select-classroom. */}
      <Route element={<RequireTeacher />}>
        <Route element={<AppLayout />}>
          <Route path="/teacher" element={<TeacherHome />} />
          {/* Compat redirects for the removed cross-class pages. */}
          <Route path="/teacher/classes" element={<Navigate to="/teacher" replace />} />
          <Route path="/teacher/classes/:id" element={<Navigate to="/teacher" replace />} />
          <Route path="/teacher/lessons/:lessonId/activities" element={<Navigate to="/teacher" replace />} />
          <Route path="/teacher/users" element={<Users />} />
          <Route path="/teacher/c/:classId">
            <Route index element={<ClassDashboard />} />
            <Route path="lessons" element={<ClassLessons />} />
            <Route path="lessons/:lessonId/activities" element={<LessonActivities />} />
            <Route path="quiz" element={<ClassQuiz />} />
            <Route path="students" element={<ClassStudents />} />
          </Route>
        </Route>
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
