import { FormEvent, useRef, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { signInWithPassword } from "../services/auth";
import { AuthLayout } from "./auth/AuthLayout";
import loginArt from "../assets/illustrations/login.svg";
import { Button, Checkbox, Icon, PasswordField, TextField } from "../design-system";

export default function Login() {
  const nav = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [remember, setRemember] = useState(true);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const [emailErr, setEmailErr] = useState<string | null>(null);
  const [passErr, setPassErr] = useState<string | null>(null);
  const emailRef = useRef<HTMLInputElement>(null);
  const passRef = useRef<HTMLInputElement>(null);

  async function submit(e: FormEvent) {
    e.preventDefault();
    const emailEmpty = !email.trim();
    const passEmpty = !password;
    setEmailErr(emailEmpty ? "Enter your email or username" : null);
    setPassErr(passEmpty ? "Enter your password" : null);
    setErr(null);
    if (emailEmpty) return emailRef.current?.focus();
    if (passEmpty) return passRef.current?.focus();

    setBusy(true);
    try {
      await signInWithPassword(email, password);
      nav("/");
    } catch (error) {
      setErr(error instanceof Error ? error.message : String(error));
    } finally {
      setBusy(false);
    }
  }

  return (
    <AuthLayout
      art={loginArt}
      title="Welcome back"
      subtitle="Pick up where you left off."
      footer={
        <>
          <span className="cap">New to ScienceLearn?</span>
          <Link to="/signup" className="a-link">Create an account</Link>
        </>
      }
    >
      <form onSubmit={submit} noValidate className="a-form">
        <TextField
          ref={emailRef}
          label="Email or username"
          type="text"
          autoComplete="username"
          placeholder="Enter your email or username"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          error={emailErr}
          disabled={busy}
        />
        <PasswordField
          ref={passRef}
          label="Password"
          autoComplete="current-password"
          placeholder="Enter your password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          error={passErr}
          disabled={busy}
        />
        <div className="a-row">
          <Checkbox
            label="Remember me"
            checked={remember}
            onChange={(e) => setRemember(e.target.checked)}
            disabled={busy}
          />
          <Link to="/forgot-password" className="a-link">Forgot password?</Link>
        </div>
        {err && (
          <p className="a-err" role="alert">
            <Icon name="alert" size={16} />
            {err}
          </p>
        )}
        <Button type="submit" fullWidth loading={busy}>Sign in</Button>
      </form>
    </AuthLayout>
  );
}
