import {
  ArrowDown, ArrowLeft, ArrowUp, Atom, Award, BarChart3, BookOpen, Camera, Check, CheckCircle2,
  ChevronRight, CircleAlert, ClipboardCheck, ClipboardList, Clock, CloudOff,
  Copy, Download, Ellipsis, ExternalLink, Eye, EyeOff, FlaskConical, Globe, GraduationCap,
  GripVertical, Home, Inbox,
  Info, KeyRound, Layers, LayoutDashboard, Lightbulb, ListChecks, Lock,
  LogIn, LogOut, Mail, MailCheck, Pencil, Play, Plus, Presentation, Puzzle,
  RefreshCw, School, Search, Settings, Shield, Sigma, Timer, Trash2,
  TrendingUp, Trophy, User, UserCog, Users, X, type LucideIcon,
} from "lucide-react";

/** Single icon registry — one line-icon set (lucide), stroke width 2.
 *  Only these names may be used in product UI; no emoji, no other sets. */
const registry = {
  home: Home, lessons: BookOpen, progress: BarChart3, account: User,
  dashboard: LayoutDashboard, students: Users, userAdmin: UserCog,
  assessment: ClipboardCheck, quiz: ListChecks, preTest: ClipboardList,
  postTest: Trophy, review: Layers, formulas: Sigma, keyTerms: KeyRound,
  puzzle: Puzzle, science: FlaskConical, atom: Atom, school: GraduationCap,
  university: School, presentation: Presentation, shield: Shield, globe: Globe,
  back: ArrowLeft, login: LogIn, signOut: LogOut, camera: Camera,
  done: CheckCircle2, settings: Settings, gain: TrendingUp, retry: RefreshCw,
  offline: CloudOff, history: Clock, inbox: Inbox, info: Info, lock: Lock,
  mail: Mail, mailVerified: MailCheck, show: Eye, hide: EyeOff, edit: Pencil,
  chevron: ChevronRight, alert: CircleAlert, openExternal: ExternalLink,
  copy: Copy, play: Play, add: Plus, tip: Lightbulb, pending: Timer,
  award: Award, delete: Trash2, search: Search, close: X, check: Check,
  more: Ellipsis, export: Download, up: ArrowUp, down: ArrowDown,
  grip: GripVertical,
} as const;

export type IconName = keyof typeof registry;

export interface IconProps {
  /** Registered semantic name — the only legal icon vocabulary. */
  name: IconName;
  /** Pixel size. Default 20. */
  size?: number;
  /** CSS color. Defaults to currentColor. */
  color?: string;
  className?: string;
}

/** Renders a registered line icon at strokeWidth 2.2. */
export function Icon({ name, size = 20, color, className }: IconProps) {
  const C: LucideIcon = registry[name];
  return (
    <C
      size={size}
      strokeWidth={2.2}
      color={color}
      className={className}
      aria-hidden="true"
      focusable="false"
    />
  );
}
