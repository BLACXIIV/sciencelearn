import { NavLink, Navigate, Outlet, Route, Routes } from "react-router-dom";
import { useAuth } from "./lib/useAuth";
import { supabase } from "./lib/supabase";
import Login from "./pages/Login";
import Dashboard from "./pages/Dashboard";
import ManageLessons from "./pages/ManageLessons";

function Layout() {
  const { session, profile, loading } = useAuth();
  if (loading) return <p className="center">Loading…</p>;
  if (!session) return <Navigate to="/login" replace />;
  if (profile?.role === "student")
    return <p className="center">This portal is for teachers. Please use the ScienceLearn mobile app.</p>;

  return (
    <div className="shell">
      <aside>
        <h2>ScienceLearn</h2>
        <nav>
          <NavLink to="/" end>Dashboard</NavLink>
          <NavLink to="/lessons">Manage Lessons</NavLink>
          <a href="#" onClick={(e) => { e.preventDefault(); supabase.auth.signOut(); }}>Sign out</a>
        </nav>
      </aside>
      <main>
        <header><h1>Good Day, {profile?.full_name}!</h1><p>Manage. Monitor. Support.</p></header>
        <Outlet />
      </main>
    </div>
  );
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route element={<Layout />}>
        <Route index element={<Dashboard />} />
        <Route path="lessons" element={<ManageLessons />} />
      </Route>
    </Routes>
  );
}
