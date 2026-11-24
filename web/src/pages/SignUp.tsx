import { FormEvent, useRef, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { signUp } from "../services/auth";
import type { Role } from "../types";
import { AuthLayout } from "./auth/AuthLayout";
import studentArt from "../assets/illustrations/student.svg";
import teacherArt from "../assets/illustrations/teacher.svg";
import { Button, Icon, OptionTile, PasswordField, TextField } from "../design-system";

export default function SignUp() {
  const nav = useNavigate();
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [role, setRole] = useState<Role>("student");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const [sent, setSent] = useState(false);
  const [ferr, setFerr] = useState<{ name?: string; email?: string; pass?: string; confirm?: string }>({});
  const nameRef = useRef<HTMLInputElement>(null);
  const emailRef = useRef<HTMLInputElement>(null);
  const passRef = useRef<HTMLInputElement>(null);
  const confirmRef = useRef<HTMLInputElement>(null);

  async function submit(e: FormEvent) {
    e.preventDefault();
    const next: typeof ferr = {};
    if (!fullName.trim()) next.name = "Enter your full name";
    if (!email.trim()) next.email = "Enter your email or username";
    if (!password) next.pass = "Create a password";
    if (password !== confirm) next.confirm = "Passwords don't match";
    setFerr(next);
    setErr(null);
    // Focus the first invalid field.
    if (next.name) return nameRef.current?.focus();
    if (next.email) return emailRef.current?.focus();
    if (next.pass) return passRef.current?.focus();
    if (next.confirm) return confirmRef.current?.focus();

    setBusy(true);
    try {
      const signedIn = await signUp(email, password, fullName, role);
      if (signedIn) return nav("/");
      setSent(true);
    } catch (error) {
      setErr(error instanceof Error ? error.message : String(error));
    } finally {
      setBusy(false);
    }
  }

  const art = role === "teacher" ? teacherArt : studentArt;

  if (sent)
    return (
      <AuthLayout
        art={art}
        title="Check your email"
        subtitle={`We sent a confirmation link to ${email}. Open it to activate your account, then sign in.`}
        footer={<Link to="/login" className="a-link">Back to sign in</Link>}
      >
        <p className="a-success" style={{ margin: 0 }}>
          <Icon name="mailVerified" size={56} />
        </p>
      </AuthLayout>
    );

  return (
    <AuthLayout
      art={art}
      title="Create your account"
      subtitle="Join as a student or a teacher."
      footer={
        <>
          <span className="cap">Already have an account?</span>
          <Link to="/login" className="a-link">Log in</Link>
        </>
      }
    >
      <form onSubmit={submit} noValidate className="a-form">
        <div className="a-pair">
          <TextField
            ref={nameRef}
            label="Full name"
            autoComplete="name"
            placeholder="Enter your full name"
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            error={ferr.name}
            disabled={busy}
          />
          <TextField
            ref={emailRef}
            label="Email or username"
            type="text"
            autoComplete="username"
            placeholder="Email or username"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            error={ferr.email}
            disabled={busy}
          />
        </div>
        <PasswordField
          ref={passRef}
          label="Password"
          autoComplete="new-password"
          placeholder="Create a password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          error={ferr.pass}
          disabled={busy}
        />
        <PasswordField
          ref={confirmRef}
          label="Confirm password"
          autoComplete="new-password"
          placeholder="Re-enter your password"
          value={confirm}
          onChange={(e) => setConfirm(e.target.value)}
          error={ferr.confirm}
          disabled={busy}
        />
        <fieldset className="ds-radio-group">
          <legend className="ds-label">I am a…</legend>
          <div className="a-role-grid">
            <OptionTile
              icon="school"
              label="Student"
              tone="mint"
              selected={role === "student"}
              disabled={busy}
              onClick={() => setRole("student")}
            />
            <OptionTile
              icon="presentation"
              label="Teacher"
              tone="yellow"
              selected={role === "teacher"}
              disabled={busy}
              onClick={() => setRole("teacher")}
            />
          </div>
        </fieldset>
        {err && (
          <p className="a-err" role="alert">
            <Icon name="alert" size={16} />
            {err}
          </p>
        )}
        <Button type="submit" fullWidth loading={busy}>Create account</Button>
      </form>
    </AuthLayout>
  );
}
