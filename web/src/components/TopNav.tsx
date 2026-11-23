import { useEffect, useRef, useState } from "react";
import Avatar from "./Avatar";
import { I } from "./icons";
import { useAuth } from "../hooks/useAuth";
import {
  ACCENTS, SURFACES, loadPrefs, savePrefs, applyPrefs, watchSystem,
  type Prefs, type Mode, type Surface,
} from "../theme";

const MODES: { id: Mode; label: string }[] = [
  { id: "system", label: "System" },
  { id: "dark", label: "Dark" },
  { id: "light", label: "Light" },
];

/** Top bar: profile block on the right + settings popover (theme, accent, surface). */
export default function TopNav() {
  const { profile } = useAuth();
  const [open, setOpen] = useState(false);
  const [prefs, setPrefs] = useState<Prefs>(loadPrefs);
  const wrapRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    applyPrefs(prefs);
    return watchSystem(() => applyPrefs(loadPrefs()));
  }, [prefs]);

  useEffect(() => {
    if (!open) return;
    const close = (e: MouseEvent) => {
      if (!wrapRef.current?.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener("mousedown", close);
    return () => document.removeEventListener("mousedown", close);
  }, [open]);

  const set = (p: Partial<Prefs>) => {
    const next = { ...prefs, ...p };
    setPrefs(next);
    savePrefs(next);
  };

  return (
    <div className="topnav">
      <span className="spacer" />
      <div className="tn-wrap" ref={wrapRef}>
        <div className="tn-user">
          <div style={{ textAlign: "right" }}>
            <div className="nm">{profile?.full_name ?? "…"}</div>
            <div className="rl">{profile?.role ?? ""}</div>
          </div>
          <Avatar name={profile?.full_name ?? ""} avatarKey={profile?.avatar_url ?? null} size={38} />
          <button
            type="button" className="tn-btn" aria-label="Settings"
            onClick={() => setOpen((o) => !o)}
          >
            <I name="settings" size={18} />
          </button>
        </div>
        {open && (
          <div className="tn-pop">
            <h4>Appearance</h4>
            <div className="tn-sec">
              <span>Mode</span>
              <div className="seg">
                {MODES.map((m) => (
                  <button
                    key={m.id} type="button"
                    className={prefs.mode === m.id ? "on" : ""}
                    onClick={() => set({ mode: m.id })}
                  >{m.label}</button>
                ))}
              </div>
            </div>
            <div className="tn-sec">
              <span>Accent color</span>
              <div className="swatches">
                {ACCENTS.map((a) => (
                  <button
                    key={a.id} type="button" title={a.label}
                    className={`swatch${prefs.accent === a.id ? " on" : ""}`}
                    style={{ background: a.hex }}
                    onClick={() => set({ accent: a.id })}
                  />
                ))}
              </div>
            </div>
            <div className="tn-sec">
              <span>Panel style</span>
              <div className="seg">
                {SURFACES.map((s) => (
                  <button
                    key={s.id} type="button" title={s.hint}
                    className={prefs.surface === s.id ? "on" : ""}
                    onClick={() => set({ surface: s.id as Surface })}
                  >{s.label}</button>
                ))}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
