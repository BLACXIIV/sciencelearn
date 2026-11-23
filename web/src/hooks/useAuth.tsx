import { createContext, useContext, useEffect, useState, ReactNode } from "react";
import type { Session } from "@supabase/supabase-js";
import type { Profile } from "../types";
import { fetchProfile, getSession, onAuthStateChange } from "../services/auth";

type Ctx = { session: Session | null; profile: Profile | null; loading: boolean };
const AuthCtx = createContext<Ctx>({ session: null, profile: null, loading: true });

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getSession().then((s) => { setSession(s); if (!s) setLoading(false); });
    const subscription = onAuthStateChange(setSession);
    return () => subscription.unsubscribe();
  }, []);

  useEffect(() => {
    if (!session) { setProfile(null); return; }
    fetchProfile(session.user.id)
      .catch(() => null)
      .then((p) => { setProfile(p); setLoading(false); });
  }, [session]);

  return <AuthCtx.Provider value={{ session, profile, loading }}>{children}</AuthCtx.Provider>;
}
export const useAuth = () => useContext(AuthCtx);
