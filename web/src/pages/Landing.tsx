import { Link, Navigate } from "react-router-dom";
import { E, I, type EmojiName } from "../components/icons";
import { useAuth } from "../hooks/useAuth";

const FEATURES: { emoji: EmojiName; title: string; text: string }[] = [
  { emoji: "lessons", title: "Lessons & Materials",
    text: "Topic lessons with objectives and downloadable materials, aligned to the DepEd MATATAG curriculum." },
  { emoji: "assessment", title: "Assessments",
    text: "Pre-tests, post-tests and quizzes in five formats: multiple choice, true or false, fill in the blank, identification and enumeration." },
  { emoji: "review", title: "Review Center",
    text: "Flashcards, formula guides and key terms to revise before any assessment." },
  { emoji: "progress", title: "Progress Tracking",
    text: "Students see completion and scores over time; teachers see the whole class at a glance." },
  { emoji: "school", title: "Classes",
    text: "Teachers create classes with auto-generated join codes. Students enter a code and they are in." },
  { emoji: "account", title: "Portals for Every Role",
    text: "One sign-in for students, teachers and admins, on both the mobile app and the web portal." },
];

const ROLES = [
  { name: "Students", icon: "school" as const,
    text: "Learn lessons, take assessments, review materials and track progress. Join classes with a code from the teacher." },
  { name: "Teachers", icon: "presentation" as const,
    text: "Create lessons and activities, build custom assessments, manage classes and monitor class performance." },
  { name: "Admins", icon: "userAdmin" as const,
    text: "Everything teachers do, plus manage user accounts and roles across the system." },
];

export default function Landing() {
  const { session, profile, loading } = useAuth();

  if (loading) return <div className="center"><p className="empty">Loading…</p></div>;
  if (session && profile) {
    return <Navigate to={profile.role === "student" ? "/student" : "/teacher"} replace />;
  }

  return (
    <div className="landing">
      <header className="l-nav">
        <span className="l-brand"><E name="science" size={26} /> ScienceLearn</span>
        <nav>
          <Link to="/login" className="link-btn">Sign in</Link>
          <Link to="/signup" className="btn-nav">Get started</Link>
        </nav>
      </header>

      <section className="l-hero">
        <E name="science" size={88} />
        <h1>ScienceLearn</h1>
        <p className="l-tag">Learn · Explore · Excel</p>
        <p className="l-sub">
          A science learning system for the DepEd MATATAG curriculum, with lessons,
          assessments, review tools and class management, on mobile and web.
        </p>
        <div className="l-cta">
          <Link to="/signup" className="btn-cta">Create an account</Link>
          <Link to="/login" className="btn-cta secondary">Sign in</Link>
        </div>
      </section>

      <section className="l-section">
        <h2>Everything in one system</h2>
        <div className="l-grid">
          {FEATURES.map((f) => (
            <div key={f.title} className="card l-feature">
              <E name={f.emoji} size={44} />
              <strong>{f.title}</strong>
              <p>{f.text}</p>
            </div>
          ))}
        </div>
      </section>

      <section className="l-section">
        <h2>Built for every role</h2>
        <div className="l-grid three">
          {ROLES.map((r) => (
            <div key={r.name} className="card l-feature">
              <span className="tile-ico" style={{ background: "#4c8dff29", color: "#4c8dff" }}>
                <I name={r.icon} size={22} />
              </span>
              <strong>{r.name}</strong>
              <p>{r.text}</p>
            </div>
          ))}
        </div>
      </section>

      <section className="l-section l-final">
        <h2>Ready to start?</h2>
        <p className="l-sub">Students learn, teachers manage, everyone signs in the same way.</p>
        <Link to="/signup" className="btn-cta">Get started</Link>
      </section>

      <footer className="l-footer">
        <p>Developed by Regym R. Medina · With the support of The Notre Dame of Isulan, Inc.</p>
        <p className="l-small">References: DepEd MATATAG Curriculum, Trusted Scientific Resources</p>
      </footer>
    </div>
  );
}
