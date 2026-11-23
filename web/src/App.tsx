import { Navigate, Route, Routes } from "react-router-dom";
import RequireTeacher from "./components/RequireTeacher";
import RequireStudent from "./components/RequireStudent";
import RoleRedirect from "./components/RoleRedirect";
import AppLayout from "./components/AppLayout";
import StudentLayout from "./components/StudentLayout";
import Login from "./pages/Login";
import SignUp from "./pages/SignUp";
import ForgotPassword from "./pages/ForgotPassword";
import ResetPassword from "./pages/ResetPassword";
import Dashboard from "./pages/Dashboard";
import ManageLessons from "./pages/ManageLessons";
import LessonActivities from "./pages/LessonActivities";
import Users from "./pages/Users";
import StudentHome from "./pages/student/Home";
import StudentLessons from "./pages/student/Lessons";
import StudentLessonDetail from "./pages/student/LessonDetail";
import StudentAssessments from "./pages/student/Assessments";
import StudentQuiz from "./pages/student/Quiz";
import StudentReview from "./pages/student/Review";
import StudentProgressPage from "./pages/student/Progress";
import StudentAccount from "./pages/student/Account";

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/signup" element={<SignUp />} />
      <Route path="/forgot-password" element={<ForgotPassword />} />
      <Route path="/reset-password" element={<ResetPassword />} />

      {/* Landing: send each account to its role's portal. */}
      <Route index element={<RoleRedirect />} />

      {/* Student portal (mirrors the mobile app). */}
      <Route element={<RequireStudent />}>
        <Route path="/student/quiz/:id" element={<StudentQuiz />} />
        <Route element={<StudentLayout />}>
          <Route path="/student" element={<StudentHome />} />
          <Route path="/student/lessons" element={<StudentLessons />} />
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
          <Route path="/teacher/lessons" element={<ManageLessons />} />
          <Route path="/teacher/lessons/:lessonId/activities" element={<LessonActivities />} />
          <Route path="/teacher/users" element={<Users />} />
        </Route>
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
