// Central icon registry (lucide-react): semantic name -> glyph component.
// Every icon used in the app is imported once here so the set stays consistent.
import {
  Atom,
  Award,
  BarChart3,
  BookOpen,
  Camera,
  CheckCircle2,
  ChevronRight,
  ClipboardCheck,
  ClipboardList,
  Clock,
  CloudOff,
  ExternalLink,
  Eye,
  FlaskConical,
  GraduationCap,
  Home,
  Inbox,
  Info,
  KeyRound,
  Layers,
  LayoutDashboard,
  Lightbulb,
  ListChecks,
  Lock,
  LogOut,
  Mail,
  MailCheck,
  Pencil,
  Play,
  Plus,
  Presentation,
  Puzzle,
  RefreshCw,
  School,
  Sigma,
  Timer,
  Trash2,
  TrendingUp,
  Trophy,
  User,
  UserCog,
  Users,
  type LucideIcon,
} from "lucide-react";

export const Icons = {
  home: Home,
  lessons: BookOpen,
  progress: BarChart3,
  account: User,
  dashboard: LayoutDashboard,
  students: Users,
  userAdmin: UserCog,
  assessment: ClipboardCheck,
  quiz: ListChecks,
  preTest: ClipboardList,
  postTest: Trophy,
  review: Layers,
  formulas: Sigma,
  keyTerms: KeyRound,
  puzzle: Puzzle,
  science: FlaskConical,
  atom: Atom,
  school: GraduationCap,
  university: School,
  presentation: Presentation,
  signOut: LogOut,
  camera: Camera,
  done: CheckCircle2,
  gain: TrendingUp,
  retry: RefreshCw,
  offline: CloudOff,
  history: Clock,
  inbox: Inbox,
  info: Info,
  lock: Lock,
  mail: Mail,
  mailVerified: MailCheck,
  show: Eye,
  edit: Pencil,
  delete: Trash2,
  chevron: ChevronRight,
  openExternal: ExternalLink,
  play: Play,
  add: Plus,
  tip: Lightbulb,
  pending: Timer,
  award: Award,
} as const;

export type IconName = keyof typeof Icons;

/** Renders a registered icon at a given pixel size. */
export function I({ name, size = 18, className }: { name: IconName; size?: number; className?: string }) {
  const C: LucideIcon = Icons[name];
  return <C size={size} strokeWidth={1.8} className={className} aria-hidden="true" />;
}

// 3D emoji assets (Microsoft Fluent Emoji, MIT) for large feature tiles.
// Functional UI (nav, actions, states) stays on Icons: emoji can't be tinted.
export const Emoji = {
  lessons: "open_book_3d.png",
  assessment: "clipboard_3d.png",
  review: "spiral_notepad_3d.png",
  progress: "chart_increasing_3d.png",
  account: "bust_in_silhouette_3d.png",
  preTest: "memo_3d.png",
  postTest: "trophy_3d.png",
  flashcards: "card_index_dividers_3d.png",
  formulas: "abacus_3d.png",
  keyTerms: "key_3d.png",
  science: "test_tube_3d.png",
  school: "graduation_cap_3d.png",
} as const;

export type EmojiName = keyof typeof Emoji;

/** Renders a bundled 3D emoji asset by its Emoji registry name. */
export function E({ name, size = 40, className }: { name: EmojiName; size?: number; className?: string }) {
  return <img src={`/emoji/${Emoji[name]}`} width={size} height={size} className={className} alt="" aria-hidden="true" />;
}
