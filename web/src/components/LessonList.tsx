import { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import {
  Button, Icon, IconButton, StatusBadge, Switch, type IconName,
} from "../design-system";
import { getR2Url } from "../services/storage";
import type { Lesson, Subject } from "../types";

interface Props {
  lessons: Lesson[];
  /** lesson_id → assessment count (fetchLessonActivityCounts). */
  counts: Record<string, number>;
  onTogglePublish: (lesson: Lesson) => void;
  onEdit: (lesson: Lesson) => void;
  /** Caller owns the confirm dialog; delete must be guarded by counts. */
  onDelete: (lesson: Lesson) => void;
  /** Toast callback for the blocked delete ("has activities"). */
  onBlockedDelete: () => void;
}

const SUBJECT_TILE: Record<Subject, { icon: IconName; cls: string }> = {
  Physics: { icon: "atom", cls: "tl-thumb-phys" },
  Chemistry: { icon: "science", cls: "tl-thumb-chem" },
  "Earth Science": { icon: "globe", cls: "tl-thumb-earth" },
};

/** 118px hero: uploaded thumbnail or the subject pastel + white icon tile. */
function Thumb({ lesson }: { lesson: Lesson }) {
  const url = useQuery({
    queryKey: ["r2-url", lesson.thumbnail_key],
    queryFn: () => getR2Url(lesson.thumbnail_key!),
    enabled: !!lesson.thumbnail_key,
    staleTime: 5 * 60 * 1000,
  });
  const tile = SUBJECT_TILE[lesson.subject]
    ?? { icon: "lessons" as IconName, cls: "tl-thumb-def" };
  return (
    <>
      {lesson.thumbnail_key && url.data
        ? <img src={url.data} alt="" />
        : <span className="tl-thumb-tile"><Icon name={tile.icon} size={26} /></span>}
    </>
  );
}

/** One curriculum card: hero thumb + corner chips, subject/title/objectives,
 *  footer with Activities, publish switch and the "···" menu. */
function LessonCard({
  lesson, activities, onTogglePublish, onEdit, onDelete, onBlockedDelete,
}: {
  lesson: Lesson;
  activities: number;
  onTogglePublish: Props["onTogglePublish"];
  onEdit: Props["onEdit"];
  onDelete: Props["onDelete"];
  onBlockedDelete: Props["onBlockedDelete"];
}) {
  const nav = useNavigate();
  const [menuOpen, setMenuOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!menuOpen) return;
    const close = (e: MouseEvent) => {
      if (!menuRef.current?.contains(e.target as Node)) setMenuOpen(false);
    };
    const esc = (e: KeyboardEvent) => e.key === "Escape" && setMenuOpen(false);
    document.addEventListener("mousedown", close);
    document.addEventListener("keydown", esc);
    return () => {
      document.removeEventListener("mousedown", close);
      document.removeEventListener("keydown", esc);
    };
  }, [menuOpen]);

  const pub = lesson.is_published;
  const tile = SUBJECT_TILE[lesson.subject] ?? { icon: "lessons" as IconName, cls: "tl-thumb-def" };
  const deletable = activities === 0;

  return (
    <article className="tl-card edge-4">
      <div className={`tl-thumb ${tile.cls}`}>
        <Thumb lesson={lesson} />
        <span className="tl-chip">
          <StatusBadge status={pub ? "published" : "draft"} />
        </span>
        {lesson.content_key && <span className="tl-pdf">PDF</span>}
      </div>
      <div className="tl-card-body">
        <span className="tl-subject">{lesson.subject}</span>
        <h4 className="tl-title">{lesson.title}</h4>
        {lesson.objectives ? <p className="tl-objs">{lesson.objectives}</p> : null}
      </div>
      <div className="tl-card-foot">
        <Button size="sm"
          onClick={() =>
            nav(`/teacher/c/${lesson.class_id}/lessons/${lesson.id}/activities`)}>
          Activities
        </Button>
        <div className="tl-foot-side">
          <Switch
            tone="teal"
            checked={pub}
            aria-label={`Publish ${lesson.title}`}
            onChange={() => onTogglePublish(lesson)}
          />
          <div className="ts-menu" ref={menuRef}>
            <IconButton icon="more" label={`More actions for ${lesson.title}`}
              onClick={() => setMenuOpen((o) => !o)} />
            {menuOpen && (
              <div className="ts-menu-pop edge-pop" role="menu">
                <button type="button" role="menuitem" className="tl-menu-item"
                  onClick={() => { setMenuOpen(false); onEdit(lesson); }}>
                  <Icon name="edit" size={16} /> Edit
                </button>
                <button type="button" role="menuitem"
                  className="ts-menu-item"
                  aria-disabled={!deletable}
                  title={deletable ? undefined : "Delete or move its activities first."}
                  onClick={() => {
                    if (!deletable) { onBlockedDelete(); return; }
                    setMenuOpen(false);
                    onDelete(lesson);
                  }}>
                  <Icon name="delete" size={16} /> Delete
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </article>
  );
}

export default function LessonList({
  lessons, counts, onTogglePublish, onEdit, onDelete, onBlockedDelete,
}: Props) {
  return (
    <div className="bento bento-fit bento-gap-sm">
      {lessons.map((l) => (
        <LessonCard key={l.id} lesson={l} activities={counts[l.id] ?? 0}
          onTogglePublish={onTogglePublish} onEdit={onEdit}
          onDelete={onDelete} onBlockedDelete={onBlockedDelete} />
      ))}
    </div>
  );
}
