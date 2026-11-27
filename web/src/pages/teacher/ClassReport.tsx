import { useEffect } from "react";
import { useQuery } from "@tanstack/react-query";
import { useNavigate, useParams } from "react-router-dom";
import { useAuth } from "../../hooks/useAuth";
import {
  fetchClass, fetchClassAssessmentRows, fetchClassLessonAvgs,
  fetchClassMembers, fetchClassStudentProgress,
  type ClassStudentProgress,
} from "../../services/classes";
import reportEmptyArt from "../../assets/illustrations/report-empty.png";
import { Avatar, Button, Card, Icon, ProgressBar } from "../../design-system";
import {
  ReportRing, ScoreRow, csvCell, pct,
} from "./reportShared";
import "../teacher.css";

const mean = (xs: number[]) =>
  xs.length ? Math.round(xs.reduce((s, v) => s + v, 0) / xs.length) : null;

/** Class-wide report as CSV — aggregates, per-assessment averages,
 *  per-lesson averages and one row per student. Same shape as mobile. */
function buildClassReportCsv(opts: {
  className: string;
  students: number;
  lessonsAvg: number | null;
  quizAvg: number | null;
  assessments: { title: string; avg: number | null; attempts: number; released: boolean }[];
  lessons: { title: string; avg: number }[];
  roster: ClassStudentProgress[];
}): string {
  const pctN = (v: number | null) => (v == null ? "—" : `${v}%`);
  const lines = [
    "Class report",
    `Class,${csvCell(opts.className)}`,
    `Students,${opts.students}`,
    `Lessons,${pctN(opts.lessonsAvg)}`,
    `Quiz average,${pctN(opts.quizAvg)}`,
    "",
    "Assessment,Class average,Attempts,Visibility",
    ...opts.assessments.map((a) =>
      [
        csvCell(a.title),
        a.avg == null ? "No attempts" : `${a.avg}%`,
        a.attempts,
        a.avg != null && !a.released ? "Not released" : "",
      ].join(",")),
    "",
    "Lesson,Class average",
    ...opts.lessons.map((l) => `${csvCell(l.title)},${l.avg}%`),
    "",
    "Student,Lessons,Quiz average",
    ...opts.roster.map((r) => [
      csvCell(r.full_name),
      pct(r.lessons_pct),
      pct(r.quizzes_pct),
    ].join(",")),
  ];
  return lines.join("\n");
}

/** Class-level report: aggregate pre/post chart, rings, per-assessment and
 *  per-lesson averages, plus the full roster (tap through to each student). */
export default function ClassReport() {
  const { classId = "" } = useParams();
  const nav = useNavigate();
  const { profile } = useAuth();
  const cls = useQuery({ queryKey: ["class", classId], queryFn: () => fetchClass(classId) });
  const members = useQuery({
    queryKey: ["class-members", classId],
    queryFn: () => fetchClassMembers(classId),
  });
  const progress = useQuery({
    queryKey: ["class-progress", classId],
    queryFn: () => fetchClassStudentProgress(classId),
  });
  const assessments = useQuery({
    queryKey: ["class-assessments", classId],
    queryFn: () => fetchClassAssessmentRows(classId),
  });
  const lessons = useQuery({
    queryKey: ["class-lesson-avgs", classId],
    queryFn: () => fetchClassLessonAvgs(classId),
  });

  // Guard: the class must belong to this teacher (or admin).
  useEffect(() => {
    if (!cls.data || !profile) return;
    const owns = cls.data.teacher_id === profile?.id || profile?.role === "admin";
    if (!owns) {
      nav(`/teacher/c/${classId}/students`, {
        replace: true,
        state: { toast: "That class isn't yours." },
      });
    }
  }, [cls.data, profile, classId, nav]);

  const roster = progress.data ?? [];
  const studentCount = members.data?.filter((m) => m.status === "active").length
    ?? roster.length;
  const avg = (pick: (r: ClassStudentProgress) => number | null) =>
    mean(roster.map(pick).filter((v): v is number => v != null));
  const lessonsAvg = avg((r) => r.lessons_pct);
  const quizAvg = avg((r) => r.quizzes_pct);
  const acts = assessments.data ?? [];
  const anyAttempt = acts.some((a) => a.avg != null);

  if (cls.error || members.error) {
    return (
      <p className="td-err">
        Couldn't load this report: {String(cls.error ?? members.error)}
      </p>
    );
  }
  if (!cls.data || !profile) {
    return <p className="ds-body">Loading report…</p>;
  }
  const owns = cls.data.teacher_id === profile?.id || profile?.role === "admin";
  if (!owns) return null;

  const exportCsv = () => {
    const csv = buildClassReportCsv({
      className: cls.data.name,
      students: studentCount,
      lessonsAvg, quizAvg,
      assessments: acts,
      lessons: lessons.data ?? [],
      roster,
    });
    const url = URL.createObjectURL(
      new Blob(["﻿" + csv], { type: "text/csv" })); // ﻿ = UTF-8 BOM
    const a = document.createElement("a");
    a.href = url;
    a.download = `class-report-${cls.data.name.toLowerCase().replace(/[^a-z0-9]+/g, "-")}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <>
      <div className="sr-head edge-8">
        <Avatar name={cls.data.name} pastelColor="blue" size={64} />
        <div className="sr-head-id">
          <span className="sr-head-name">{cls.data.name}</span>
          <span className="sr-head-sub">Class report</span>
        </div>
        <div className="sr-head-stats">
          <span className="sr-tile edge-4">
            <span className="sr-tile-val">{studentCount}</span>
            <span className="sr-tile-lab">Students</span>
          </span>
          <span className="sr-tile edge-4">
            <span className="sr-tile-val">{pct(quizAvg)}</span>
            <span className="sr-tile-lab">Quiz average</span>
          </span>
          <span className="sr-tile sr-tile-mint edge-4">
            <span className="sr-tile-val">{pct(lessonsAvg)}</span>
            <span className="sr-tile-lab">Lessons</span>
          </span>
          <Button variant="white" size="sm" leadingIcon="export" onClick={exportCsv}>
            Export <span className="sr-new">NEW</span>
          </Button>
        </div>
      </div>

      <div className="bento">
        <Card variant="white">
          <h3 className="ds-h3" style={{ marginTop: 0 }}>Class averages</h3>
          <div className="sr-rings bento-cols">
            <ReportRing label="Lessons" value={lessonsAvg} series={1} />
            <ReportRing label="Quizzes" value={quizAvg} series={2} />
          </div>
        </Card>
        <Card variant="white">
          <h3 className="ds-h3" style={{ marginTop: 0 }}>Assessment averages</h3>
          {acts.length > 0 && !anyAttempt && (
            <div className="sr-empty" data-slot="report-empty">
              <img src={reportEmptyArt} alt="" width={120} height={90} />
              <p className="ds-body" style={{ color: "var(--ds-muted)" }}>
                No attempts yet — class averages appear once students take an assessment.
              </p>
            </div>
          )}
          {acts.map((a) => (
            <ScoreRow key={a.id} title={a.title} kind={a.kind}
              score={a.avg} released={a.released} emptyLabel="No attempts"
              caption={`${a.attempts} ${a.attempts === 1 ? "student" : "students"} attempted`} />
          ))}
          {acts.length === 0 && assessments.data && (
            <div className="sr-empty" data-slot="report-empty">
              <img src={reportEmptyArt} alt="" width={120} height={90} />
              <p className="ds-body" style={{ color: "var(--ds-muted)" }}>
                No assessments in this class yet.
              </p>
            </div>
          )}
        </Card>
        <Card variant="white">
          <h3 className="ds-h3" style={{ marginTop: 0 }}>Lesson averages</h3>
          {(lessons.data ?? []).map((l) => (
            <div key={l.id} className="sr-score">
              <span className="sr-score-name">{l.title}</span>
              <ProgressBar size="lg"
                tone={l.avg >= 100 ? "teal" : l.avg > 0 ? "sun" : "blue"}
                value={l.avg} label={l.title} />
              <span className="sr-score-val">{l.avg}%</span>
            </div>
          ))}
          {lessons.data?.length === 0 && (
            <p className="ds-body" style={{ color: "var(--ds-muted)" }}>
              No lessons in this class yet.
            </p>
          )}
        </Card>
        <Card variant="white" className="cr-roster bento-wide">
          <div className="td-spread">
            <h3 className="ds-h3" style={{ margin: 0 }}>Students</h3>
            <span className="ds-caption" style={{ color: "var(--ds-muted)" }}>
              Tap a student for their full report
            </span>
          </div>
          <div className="td-stack" style={{ marginTop: "var(--ds-s4)" }}>
            {roster.map((r) => {
              const go = () => nav(`/teacher/c/${classId}/reports/${r.student_id}`);
              return (
                <div key={r.student_id} className="ts-row edge-4" role="link" tabIndex={0}
                  aria-label={`Open report for ${r.full_name}`}
                  onClick={go}
                  onKeyDown={(e) => {
                    if (e.key === "Enter" || e.key === " ") { e.preventDefault(); go(); }
                  }}>
                  <Avatar name={r.full_name} size={44} />
                  <div className="ts-row-id">
                    <span className="ts-row-name">{r.full_name}</span>
                    <span className="ts-row-sub">Tap to open the report</span>
                  </div>
                  <div className="ts-stat">
                    <span className="ts-stat-cap">Lessons</span>
                    <span className="ts-stat-val">{pct(r.lessons_pct)}</span>
                    <ProgressBar size="sm" tone="success" value={r.lessons_pct} label="Lessons" />
                  </div>
                  <div className="ts-stat">
                    <span className="ts-stat-cap">Quiz</span>
                    <span className="ts-stat-val">{pct(r.quizzes_pct)}</span>
                    <ProgressBar size="sm" tone="blue" value={r.quizzes_pct ?? 0} label="Quiz average" />
                  </div>
                  <span className="ts-report">
                    View report <Icon name="chevron" size={16} />
                  </span>
                </div>
              );
            })}
            {roster.length === 0 && progress.data && (
              <p className="ds-body" style={{ color: "var(--ds-muted)" }}>
                No active students in this class yet.
              </p>
            )}
          </div>
        </Card>
      </div>
      {assessments.error != null || lessons.error != null || progress.error != null ? (
        <p className="td-err">
          {String(assessments.error ?? lessons.error ?? progress.error)}
        </p>
      ) : null}
    </>
  );
}
