import { Navigate } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";

/** Landing route: sends each signed-in user to their role's portal. */
export default function RoleRedirect() {
  const { session, profile, loading } = useAuth();
  if (loading) return <p className="center">Loading…</p>;
  if (!session) return <Navigate to="/login" replace />;
  if (!profile) return <Navigate to="/login" replace />;
  return <Navigate to={profile.role === "student" ? "/student" : "/teacher"} replace />;
}
