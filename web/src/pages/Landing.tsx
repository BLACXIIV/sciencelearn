import { Navigate } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";
import LandingPage from "./landing/LandingPage";

/** Landing route — signed-in users bounce to their portal (unchanged auth logic). */
export default function Landing() {
  const { session, profile, loading } = useAuth();

  if (loading) return <div style={{ padding: "80px 24px", textAlign: "center" }}><p className="ds-body">Loading…</p></div>;
  if (session && profile) {
    return <Navigate to={profile.role === "student" ? "/student" : "/teacher"} replace />;
  }

  return <LandingPage />;
}
