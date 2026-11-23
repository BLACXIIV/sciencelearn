import { FormEvent, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { signUp } from "../services/auth";
import type { Role } from "../types";

export default function SignUp() {
  const nav = useNavigate();
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [role, setRole] = useState<Role>("student");
  const [err, setErr] = useState<string | null>(null);
  const [sent, setSent] = useState(false);

  async function submit(e: FormEvent) {
    e.preventDefault();
    if (password !== confirm) return setErr("Passwords don't match");
    try {
      const signedIn = await signUp(email, password, fullName, role);
      if (signedIn) return nav("/");
      setSent(true);
    } catch (error) {
      setErr(error instanceof Error ? error.message : String(error));
    }
  }

  if (sent)
    return (
      <div className="card login">
        <h1>Check your email</h1>
        <p>We sent a confirmation link to <strong>{email}</strong>. Click it to activate your account, then sign in.</p>
        <Link to="/login">Back to sign in</Link>
      </div>
    );

  return (
    <form className="card login" onSubmit={submit}>
      <h1>ScienceLearn</h1>
      <p>Create an account</p>
      <label className="field"><span>Full name</span>
        <input autoComplete="name" value={fullName} onChange={(e) => setFullName(e.target.value)} required />
      </label>
      <label className="field"><span>Email</span>
        <input type="email" autoComplete="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
      </label>
      <label className="field"><span>Password</span>
        <input type="password" minLength={6} autoComplete="new-password" value={password} onChange={(e) => setPassword(e.target.value)} required />
      </label>
      <label className="field"><span>Confirm password</span>
        <input type="password" autoComplete="new-password" value={confirm} onChange={(e) => setConfirm(e.target.value)} required />
      </label>
      <div>
        <span className="field-label">I am a…</span>
        <div className="role-picker" role="radiogroup">
          <label className={role === "student" ? "role active" : "role"}>
            <input type="radio" name="role" value="student" checked={role === "student"} onChange={() => setRole("student")} />
            Student
          </label>
          <label className={role === "teacher" ? "role active" : "role"}>
            <input type="radio" name="role" value="teacher" checked={role === "teacher"} onChange={() => setRole("teacher")} />
            Teacher
          </label>
        </div>
      </div>
      {err && <p className="err">{err}</p>}
      <button>Sign up</button>
      <div className="links"><Link to="/login">Already have an account? Sign in</Link></div>
    </form>
  );
}
