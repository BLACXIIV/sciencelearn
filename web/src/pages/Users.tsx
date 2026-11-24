import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { fetchProfiles, setProfileRole } from "../services/users";
import { useAuth } from "../hooks/useAuth";
import { Avatar, Badge, Card, EmptyState, ListItemCard, SearchField, Select } from "../design-system";
import type { Role } from "../types";
import "./teacher.css";

const ROLES: Role[] = ["student", "teacher", "admin"];
const ROLE_TONES = { student: "blue", teacher: "mint", admin: "sun" } as const;

/** Admin: list every profile and change its role (profiles admin write policy, 0004). */
export default function Users() {
  const { profile } = useAuth();
  const qc = useQueryClient();
  const users = useQuery({ queryKey: ["profiles"], queryFn: fetchProfiles });
  const [q, setQ] = useState("");
  const setRole = useMutation({
    mutationFn: ({ id, role }: { id: string; role: Role }) => setProfileRole(id, role),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["profiles"] }),
  });

  if (profile?.role !== "admin") {
    return (
      <Card variant="white">
        <EmptyState icon="lock" title="Admins only" />
      </Card>
    );
  }
  if (users.isLoading) return <p className="ds-body">Loading users…</p>;
  if (users.error) return <p className="td-err">{String(users.error)}</p>;

  const needle = q.trim().toLowerCase();
  const rows = (users.data ?? []).filter((u) =>
    !needle || (u.full_name ?? "").toLowerCase().includes(needle) || u.id.toLowerCase().startsWith(needle));

  return (
    <div className="td-stack">
      <SearchField label="Search" placeholder="Name or ID" value={q} onChange={(e) => setQ(e.target.value)} />
      {setRole.error && <p className="td-err">{String(setRole.error)}</p>}
      {rows.length === 0 && (
        <Card variant="white">
          <EmptyState icon="students" title={users.data?.length ? "No matches" : "No users yet"} />
        </Card>
      )}
      {rows.map((u) => (
        <ListItemCard
          key={u.id}
          leading={<Avatar name={u.full_name || "?"} />}
          title={u.full_name || "(no name)"}
          subtitle={
            <span className="td-row">
              <Badge tone={ROLE_TONES[u.role]}>{u.role}</Badge>
              {u.id === profile.id && <span className="ds-caption">you</span>}
              <span className="ds-caption">{u.id.slice(0, 8)}…</span>
            </span>
          }
          trailing={
            <Select label="Role" value={u.role}
              onChange={(e) => setRole.mutate({ id: u.id, role: e.target.value as Role })}
              disabled={u.id === profile.id || setRole.isPending}
              options={ROLES.map((r) => ({ value: r, label: r }))} />
          }
        />
      ))}
    </div>
  );
}
