import { FormEvent, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { signInWithPassword } from "../services/auth";

export default function Login() {
  const nav = useNavigate();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [err, setErr] = useState<string | null>(null);

  async function submit(e: FormEvent) {
    e.preventDefault();
    try {
      await signInWithPassword(email, password);
      nav("/");
    } catch (error) {
      setErr(error instanceof Error ? error.message : String(error));
    }
  }

  return (
    <form className="card login" onSubmit={submit}>
      <h1>ScienceLearn</h1>
      <p>Sign in to your portal</p>
      <label className="field"><span>Email or username</span>
        <input type="text" autoComplete="username" value={email} onChange={(e) => setEmail(e.target.value)} required />
      </label>
      <label className="field"><span>Password</span>
        <input type="password" autoComplete="current-password" value={password} onChange={(e) => setPassword(e.target.value)} required />
      </label>
      {err && <p className="err">{err}</p>}
      <button>Sign in</button>
      <Link to="/signup" className="btn-secondary">Create an account</Link>
      <div className="links">
        <Link to="/forgot-password">Forgot password?</Link>
      </div>
    </form>
  );
}
