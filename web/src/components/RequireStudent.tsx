import { Navigate, Outlet } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";

/** Route guard: students only — staff accounts go to the teacher portal. */
export default function RequireStudent() {
  const { session, profile, loading } = useAuth();
  if (loading) return <p className="center">Loading…</p>;
  if (!session) return <Navigate to="/login" replace />;
  if (!profile)
    return <p className="center">Couldn't load your profile. Check your connection and refresh.</p>;
  if (profile.role !== "student") return <Navigate to="/teacher" replace />;
  return <Outlet />;
}
