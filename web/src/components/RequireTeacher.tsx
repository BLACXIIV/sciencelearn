import { Navigate, Outlet, useLocation } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";
import { signOut } from "../services/auth";
import { hasPickedClass } from "../services/classes";
import { Button } from "../design-system";

/** Route guard: teacher/admin only — students go to the student portal,
 *  and everyone picks a classroom first each session. */
export default function RequireTeacher() {
  const { session, profile, loading } = useAuth();
  const path = useLocation().pathname;
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
  // Class-scoped portal: every teacher route needs a picked class, except the
  // global admin Users page which has no class context.
  const classless = path === "/teacher/users" && profile.role === "admin";
  if (!hasPickedClass() && !classless) return <Navigate to="/select-classroom" replace />;
  return <Outlet />;
}
