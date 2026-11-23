import { createContext, useContext, useEffect, useState, ReactNode } from "react";
import type { Session } from "@supabase/supabase-js";
import { supabase } from "./supabase";

type Profile = { id: string; full_name: string; role: "student" | "teacher" | "admin" };
type Ctx = { session: Session | null; profile: Profile | null; loading: boolean };
const AuthCtx = createContext<Ctx>({ session: null, profile: null, loading: true });

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => { setSession(data.session); if (!data.session) setLoading(false); });
    const { data: sub } = supabase.auth.onAuthStateChange((_e, s) => setSession(s));
    return () => sub.subscription.unsubscribe();
  }, []);

  useEffect(() => {
    if (!session) { setProfile(null); return; }
    supabase.from("profiles").select("id, full_name, role").eq("id", session.user.id).single()
      .then(({ data }) => { setProfile(data as Profile); setLoading(false); });
  }, [session]);

  return <AuthCtx.Provider value={{ session, profile, loading }}>{children}</AuthCtx.Provider>;
}
export const useAuth = () => useContext(AuthCtx);
