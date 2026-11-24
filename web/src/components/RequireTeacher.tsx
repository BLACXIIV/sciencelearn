import { Navigate, Outlet } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";
import { signOut } from "../services/auth";
import { Button } from "../design-system";

/** Route guard: teacher/admin only — students go to the student portal. */
export default function RequireTeacher() {
  const { session, profile, loading } = useAuth();
  if (loading) return <p className="ds-body" style={{ padding: "80px 24px", textAlign: "center" }}>Loading…</p>;
  if (!session) return <Navigate to="/login" replace />;
  if (!profile)
    return (
      <p className="ds-body" style={{ padding: "80px 24px", textAlign: "center" }}>
        Couldn't load your profile. Check your connection and refresh.
        <br />
        <Button variant="ghost" onClick={() => signOut()}>Sign out</Button>
      </p>
    );
  if (profile.role === "student") return <Navigate to="/student" replace />;
  return <Outlet />;
}
