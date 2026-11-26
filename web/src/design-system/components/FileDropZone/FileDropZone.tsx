import { DragEvent, MouseEvent, useRef, useState } from "react";
import { Icon, type IconName } from "../../icons/Icon";
import { IconButton } from "../IconButton/IconButton";
import "./FileDropZone.css";

export interface FileDropZoneProps {
  /** Icon in the 44px pastel tile. */
  icon: IconName;
  /** Primary text before a file is picked (also the input's aria-label). */
  label: string;
  /** Secondary text before a file is picked. */
  hint: string;
  /** Native accept attribute, e.g. "image/*". */
  accept?: string;
  /** Currently picked file — shows name + size + remove control. */
  file: File | null;
  onChange: (f: File | null) => void;
}

const fmtSize = (bytes: number) =>
  bytes >= 1048576
    ? `${(bytes / 1048576).toFixed(1)} MB`
    : `${Math.max(1, Math.round(bytes / 1024))} KB`;

/**
 * FileDropZone — dashed 2px edge-white tile (radius 14) for picking one
 * file. The transparent file input covers the tile so any click opens the
 * picker and focus lands on the input; real drag-and-drop on the wrapper
 * sets the `on` state. The clear button stacks above the input.
 */
export function FileDropZone({ icon, label, hint, accept, file, onChange }: FileDropZoneProps) {
  const ref = useRef<HTMLInputElement>(null);
  const [over, setOver] = useState(false);

  function clear(e: MouseEvent) {
    e.preventDefault();
    e.stopPropagation();
    if (ref.current) ref.current.value = "";
    onChange(null);
  }
  function onDragOver(e: DragEvent) {
    e.preventDefault();
    setOver(true);
  }
  function onDrop(e: DragEvent) {
    e.preventDefault();
    setOver(false);
    const f = e.dataTransfer.files?.[0];
    if (f) onChange(f);
  }

  return (
    <label
      className={`ds-drop${over ? " on" : ""}`}
      onDragOver={onDragOver}
      onDragEnter={onDragOver}
      onDragLeave={() => setOver(false)}
      onDrop={onDrop}
    >
      <input
        ref={ref}
        className="ds-drop-input"
        type="file"
        accept={accept}
        aria-label={label}
        onChange={(e) => onChange(e.target.files?.[0] ?? null)}
      />
      <span className="ds-drop-ic"><Icon name={icon} size={20} /></span>
      <span className="ds-drop-body">
        <span className="ds-drop-name">{file ? file.name : label}</span>
        <span className="ds-drop-hint">{file ? fmtSize(file.size) : hint}</span>
      </span>
      {file ? (
        <span className="ds-drop-x">
          <IconButton icon="close" label={`Remove ${label.toLowerCase()}`} onClick={clear} />
        </span>
      ) : (
        <span className="ds-drop-browse">Browse</span>
      )}
    </label>
  );
}
