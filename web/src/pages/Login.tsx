import { FormEvent, useState } from "react";
import { useNavigate } from "react-router-dom";
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
      <p>Teacher Portal</p>
      <input placeholder="Email" type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
      <input placeholder="Password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} required />
      {err && <p className="err">{err}</p>}
      <button>Sign in</button>
    </form>
  );
}
