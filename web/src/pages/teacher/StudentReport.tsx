import { useEffect } from "react";
import { useQuery } from "@tanstack/react-query";
import { useNavigate, useParams } from "react-router-dom";
import { useAuth } from "../../hooks/useAuth";
import {
  fetchClass, fetchClassStudentProgress, fetchMembership,
  fetchStudentAssessmentRows, fetchStudentLessonRows, type ReportAssessment,
} from "../../services/classes";
import reportEmptyArt from "../../assets/illustrations/report-empty.png";
import {
  Avatar, Button, Card, IconButton, ProgressBar,
} from "../../design-system";
import {
  PrePostChart, ReportRing, ScoreRow, csvCell,
} from "./reportShared";
import "../teacher.css";

/** The student's report as CSV — same shape as the mobile export. */
function buildReportCsv(opts: {
  studentName: string;
  className: string;
  lessons_pct?: number | null;
  quizzes_pct?: number | null;
  pre_score?: number | null;
  post_score?: number | null;
  assessments: ReportAssessment[];
  lessons: { title: string; percent: number }[];
}): string {
  const { pre_score: pre, post_score: post } = opts;
  const gain = pre != null && post != null ? post - pre : null;
  const pct = (v: number | null | undefined) => (v == null ? "—" : `${Math.round(v)}%`);
  const lines = [
    "Student report",
    `Student,${csvCell(opts.studentName)}`,
    `Class,${csvCell(opts.className)}`,
    `Lessons,${pct(opts.lessons_pct)}`,
    `Quiz average,${pct(opts.quizzes_pct)}`,
    `Pre-test,${pct(pre)}`,
    `Post-test,${pct(post)}`,
    `Gain,${gain == null ? "—" : `${gain >= 0 ? "+" : ""}${gain}%`}`,
    "",
    "Assessment,Score,Visibility",
    ...opts.assessments.map((a) =>
      [
        csvCell(a.title),
        a.score == null ? "Not taken" : `${a.score}%`,
        a.score != null && !a.released ? "Not released" : "",
      ].join(",")),
    "",
    "Lesson,Progress",
    ...opts.lessons.map((l) => `${csvCell(l.title)},${Math.round(l.percent)}%`),
  ];
  return lines.join("\n");
}

/** Per-student report: header tiles, pre→post chart, rings, assessment
 *  scores and lesson progress for one active member of this class. */
export default function StudentReport() {
  const { classId = "", studentId = "" } = useParams();
  const nav = useNavigate();
  const { profile } = useAuth();
  const cls = useQuery({ queryKey: ["class", classId], queryFn: () => fetchClass(classId) });
  const member = useQuery({
    queryKey: ["class-member", classId, studentId],
    queryFn: () => fetchMembership(classId, studentId),
  });
  const progress = useQuery({
    queryKey: ["class-progress", classId],
    queryFn: () => fetchClassStudentProgress(classId),
  });
  const assessments = useQuery({
    queryKey: ["student-assessments", classId, studentId],
    queryFn: () => fetchStudentAssessmentRows(classId, studentId),
  });
  const lessons = useQuery({
    queryKey: ["student-lessons", classId, studentId],
    queryFn: () => fetchStudentLessonRows(classId, studentId),
  });

  // Guard: class must be this teacher's (or admin's), student an active member.
  // profile arrives async — don't judge ownership until it's loaded.
  useEffect(() => {
    if (!cls.data || member.data === undefined || !profile) return;
    const owns = cls.data.teacher_id === profile?.id || profile?.role === "admin";
    if (!owns || member.data?.status !== "active") {
      nav(`/teacher/c/${classId}/students`, {
        replace: true,
        state: { toast: "That student isn't in this class." },
      });
    }
  }, [cls.data, member.data, profile, classId, nav]);

  const p = progress.data?.find((r) => r.student_id === studentId);
  const gain = p?.pre_score != null && p?.post_score != null
    ? p.post_score - p.pre_score : null;
  const name = member.data?.profiles?.full_name || p?.full_name || "Student";
  const rows: ReportAssessment[] = assessments.data ?? [];
  const anyAttempt = rows.some((r) => r.score != null);

  if (cls.error || member.error) {
    return (
      <p className="td-err">
        Couldn't load this report: {String(cls.error ?? member.error)}
      </p>
    );
  }
  if (!cls.data || member.data === undefined || !profile) {
    return <p className="ds-body">Loading report…</p>;
  }
  // Guard redirect in flight — render nothing rather than a wrong report.
  const owns = cls.data.teacher_id === profile?.id || profile?.role === "admin";
  if (!owns || member.data?.status !== "active") return null;

  return (
    <>
      <div className="sr-head edge-8">
        <IconButton icon="back" label="Back to students"
          className="sr-back"
          onClick={() => nav(`/teacher/c/${classId}/students`)} />
        <Avatar name={name} pastelColor="mint" size={64} />
        <div className="sr-head-id">
          <span className="sr-head-name">{name}</span>
          <span className="sr-head-sub">{cls.data.name} · Student report</span>
        </div>
        <div className="sr-head-stats">
          <span className="sr-tile edge-4">
            <span className="sr-tile-val">{p ? `${Math.round(p.lessons_pct)}%` : "—"}</span>
            <span className="sr-tile-lab">Lessons</span>
          </span>
          <span className="sr-tile edge-4">
            <span className="sr-tile-val">{p?.quizzes_pct != null ? `${p.quizzes_pct}%` : "—"}</span>
            <span className="sr-tile-lab">Quiz average</span>
          </span>
          <span className="sr-tile sr-tile-mint edge-4">
            <span className="sr-tile-val">{gain != null ? `${gain >= 0 ? "+" : ""}${gain}%` : "—"}</span>
            <span className="sr-tile-lab">Class gain</span>
          </span>
          <Button variant="white" size="sm" leadingIcon="export"
            onClick={() => {
              const csv = buildReportCsv({
                studentName: name,
                className: cls.data.name,
                lessons_pct: p?.lessons_pct,
                quizzes_pct: p?.quizzes_pct,
                pre_score: p?.pre_score,
                post_score: p?.post_score,
                assessments: rows,
                lessons: lessons.data ?? [],
              });
              const url = URL.createObjectURL(
                new Blob(["﻿" + csv], { type: "text/csv" })); // ﻿ = UTF-8 BOM
              const a = document.createElement("a");
              a.href = url;
              a.download = `student-report-${name.toLowerCase().replace(/[^a-z0-9]+/g, "-")}.csv`;
              a.click();
              URL.revokeObjectURL(url);
            }}>
            Export <span className="sr-new">NEW</span>
          </Button>
        </div>
      </div>

      <div className="sr-grid">
        <Card variant="white">
          <div className="td-spread">
            <h3 className="ds-h3" style={{ margin: 0 }}>Pre-test to post-test</h3>
            {gain != null && (
              <span className="sr-gain edge-3">{gain >= 0 ? "+" : ""}{gain}% gain</span>
            )}
          </div>
          <PrePostChart pre={p?.pre_score ?? null} post={p?.post_score ?? null} />
        </Card>
        <Card variant="white">
          <h3 className="ds-h3" style={{ marginTop: 0 }}>Overall progress</h3>
          <div className="sr-rings">
            <ReportRing label="Lessons" value={p?.lessons_pct ?? null} series={1} />
            <ReportRing label="Quizzes" value={p?.quizzes_pct ?? null} series={2} />
            <ReportRing label="Pre-test" value={p?.pre_score ?? null} series={2} />
            <ReportRing label="Post-test" value={p?.post_score ?? null} series={4} />
          </div>
        </Card>
        <Card variant="white">
          <h3 className="ds-h3" style={{ marginTop: 0 }}>Scores by assessment</h3>
          {rows.length > 0 && !anyAttempt && (
            <div className="sr-empty" data-slot="report-empty">
              <img src={reportEmptyArt} alt="" width={120} height={90} />
              <p className="ds-body" style={{ color: "var(--ds-muted)" }}>
                No attempts yet — scores appear here once the student takes an assessment.
              </p>
            </div>
          )}
          {rows.map((r) => (
            <ScoreRow key={r.id} title={r.title} kind={r.kind}
              score={r.score} released={r.released} />
          ))}
          {rows.length === 0 && assessments.data && (
            <div className="sr-empty" data-slot="report-empty">
              <img src={reportEmptyArt} alt="" width={120} height={90} />
              <p className="ds-body" style={{ color: "var(--ds-muted)" }}>
                No assessments in this class yet.
              </p>
            </div>
          )}
        </Card>
        <Card variant="white">
          <h3 className="ds-h3" style={{ marginTop: 0 }}>Lessons</h3>
          {(lessons.data ?? []).map((l) => (
            <div key={l.id} className="sr-score">
              <span className="sr-score-name">{l.title}</span>
              <ProgressBar size="lg"
                tone={l.percent >= 100 ? "teal" : l.percent > 0 ? "sun" : "blue"}
                value={l.percent} label={l.title} />
              <span className="sr-score-val">{Math.round(l.percent)}%</span>
            </div>
          ))}
          {lessons.data?.length === 0 && (
            <p className="ds-body" style={{ color: "var(--ds-muted)" }}>
              No lessons in this class yet.
            </p>
          )}
        </Card>
      </div>
      {assessments.error != null || lessons.error != null ? (
        <p className="td-err">
          {String(assessments.error ?? lessons.error)}
        </p>
      ) : null}
    </>
  );
}
