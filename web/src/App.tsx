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
import Dashboard from "./pages/Dashboard";
import LessonActivities from "./pages/LessonActivities";
import Classes from "./pages/Classes";
import ClassDetail from "./pages/ClassDetail";
import Users from "./pages/Users";
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

export default function App() {
  return (
    <Routes>
      {import.meta.env.DEV && <Route path="/dev/ui-kit" element={<UiKit />} />}
      <Route path="/login" element={<Login />} />
      <Route path="/signup" element={<SignUp />} />
      <Route path="/forgot-password" element={<ForgotPassword />} />
      <Route path="/reset-password" element={<ResetPassword />} />

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

      {/* Teacher/admin portal. */}
      <Route element={<RequireTeacher />}>
        <Route element={<AppLayout />}>
          <Route path="/teacher" element={<Dashboard />} />
          <Route path="/teacher/lessons/:lessonId/activities" element={<LessonActivities />} />
          <Route path="/teacher/classes" element={<Classes />} />
          <Route path="/teacher/classes/:id" element={<ClassDetail />} />
          <Route path="/teacher/users" element={<Users />} />
        </Route>
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
