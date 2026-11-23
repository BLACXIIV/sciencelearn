import { Navigate, Outlet } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";
import { signOut } from "../services/auth";

/** Route guard: teacher/admin only — students go to the student portal. */
export default function RequireTeacher() {
  const { session, profile, loading } = useAuth();
  if (loading) return <p className="center">Loading…</p>;
  if (!session) return <Navigate to="/login" replace />;
  if (!profile)
    return (
      <p className="center">
        Couldn't load your profile. Check your connection and refresh.
        <br />
        <button className="link-btn" onClick={() => signOut()}>Sign out</button>
      </p>
    );
  if (profile.role === "student") return <Navigate to="/student" replace />;
  return <Outlet />;
}
