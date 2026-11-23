import { Navigate, Outlet } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";

/** Route guard: requires a signed-in non-student (teacher/admin per RLS) before rendering children. */
export default function RequireTeacher() {
  const { session, profile, loading } = useAuth();
  if (loading) return <p className="center">Loading…</p>;
  if (!session) return <Navigate to="/login" replace />;
  if (profile?.role === "student")
    return <p className="center">This portal is for teachers. Please use the ScienceLearn mobile app.</p>;
  return <Outlet />;
}
