import { Link } from "react-router-dom";
import { useAuth } from "../../hooks/useAuth";
import learningCuate from "../../assets/illustrations/learning-cuate.svg";
import {
  Button, Card, Chip, Icon, ProgressBar, QuizCard, QuizOption,
  StickerBadge, type CardPastel, type IconName,
} from "../../design-system";
import "./landing.css";

/* Landing page — rebuilt on the design system only. landing.css carries
   layout + token references; every color/font/radius/shadow comes from a
   --ds-* token or a DS component. */

const NAV_LINKS = [
  { label: "Lessons", href: "#how" },
  { label: "Quizzes", href: "#quizzes" },
  { label: "Teachers", href: "#teachers" },
];

interface Mission {
  icon: IconName;
  pastel: CardPastel;
  title: string;
  mTitle: string;
  desc: string;
  mDesc: string;
  to: string;
}

const MISSIONS: Mission[] = [
  {
    icon: "lessons",
    pastel: "blue",
    title: "My Lessons",
    mTitle: "My Lessons",
    desc: "Read the lessons your teacher publishes: objectives, activities, downloadable materials, and mark each one complete.",
    mDesc: "Class lessons",
    to: "/student/classes",
  },
  {
    icon: "assessment",
    pastel: "yellow",
    title: "Assessment Center",
    mTitle: "Assessment",
    desc: "Pre-test, topic quizzes, problem solving, practice and the final challenge.",
    mDesc: "Pre and post-test",
    to: "/student/assessments",
  },
  {
    icon: "review",
    pastel: "purple",
    title: "Review Center",
    mTitle: "Review",
    desc: "Flashcards, formulas and key terms before the big test.",
    mDesc: "Flashcards, formulas",
    to: "/student/review",
  },
  {
    icon: "progress",
    pastel: "mint",
    title: "Progress Tracker",
    mTitle: "Progress",
    desc: "See your scores and your pre-test to post-test gain.",
    mDesc: "See your gain",
    to: "/student/progress",
  },
];

const STEPS: { pastel: CardPastel; title: string; text: string }[] = [
  { pastel: "blue", title: "Join your class", text: "Enter the 6-character code from your teacher." },
  { pastel: "yellow", title: "Learn and practice", text: "Read lessons, review key terms and take quizzes." },
  { pastel: "mint", title: "See your gain", text: "Compare your pre-test and post-test scores." },
];

const QUIZ_TYPES = ["Multiple-choice", "Identification", "True or false", "Problem-solving"];

const OPTIONS = [
  { letter: "A", text: "Momentum", selected: true },
  { letter: "B", text: "Velocity", selected: false },
  { letter: "C", text: "Force", selected: false },
  { letter: "D", text: "Acceleration", selected: false },
];

const TEACHER_TILES = [
  { title: "Class management", caption: "Join codes and approvals", mint: false },
  { title: "Assessment builder", caption: "Five question types", mint: false },
  { title: "Class dashboard", caption: "Average score and gain", mint: true },
];

export default function LandingPage() {
  const { session } = useAuth();
  const dest = (to: string) => (session ? to : "/login");

  return (
    <div className="ld">
      {/* ============ Section 1: hero ============ */}
      <header className="ld-hero">
        <div className="ld-hero-in">
          <nav className="ld-nav" aria-label="Main">
            <Link to="/" className="ld-word"><img className="ld-mark" src="/logo.png" alt="" />ScienceLearn</Link>
            <div className="ld-nav-r">
              {NAV_LINKS.map((l) => (
                <a key={l.label} className="ld-navlink d" href={l.href}>{l.label}</a>
              ))}
              <Link className="d" to="/signup"><Button variant="white" size="sm">Get started</Button></Link>
              <Link className="m" to="/login"><Button variant="white" size="sm">Sign in</Button></Link>
            </div>
          </nav>

          <div className="ld-hg">
            <div className="ld-hg-copy">
              <Chip className="ld-pill">Aligned to the DepEd MATATAG curriculum</Chip>
              <h1 className="ds-display ld-h1">Learn.<br />Explore.<br /><i>Excel.</i></h1>
              <p className="ds-body ld-sub d">Science lessons, quizzes and progress tracking for your class, on your phone or on the web.</p>
              <p className="ds-body ld-sub m">Science lessons, quizzes and progress tracking for your class.</p>
              <div className="ld-cta">
                <Link to="/signup"><Button variant="mint" fullWidth>Start learning</Button></Link>
                <Link className="d" to="/signup"><Button variant="ghost">I&rsquo;m a teacher</Button></Link>
              </div>
            </div>

            <div className="ld-ill">
              <img src={learningCuate} alt="" />
              <span className="ld-spark s1" aria-hidden="true" />
              <span className="ld-spark s2" aria-hidden="true" />
              <span className="ld-chip c1"><StickerBadge rotation={-5} pastel="blue">Join with a class code</StickerBadge></span>
              <span className="ld-chip c2"><StickerBadge rotation={5} pastel="mint">Pre → post gain</StickerBadge></span>
              <span className="ld-chip c3 d"><StickerBadge rotation={-3} pastel="yellow">Physics · Chemistry · Earth Science</StickerBadge></span>
              <span className="ld-chip c3 m"><StickerBadge rotation={-3} pastel="yellow">Physics · Chem · Earth</StickerBadge></span>
            </div>
          </div>
        </div>
      </header>

      <main>
        {/* ============ Section 2: pick your mission ============ */}
        <section className="ld-sec" id="mission">
          <h2 className="ds-h1 ld-h2">Pick your mission</h2>
          <p className="ds-body ld-secsub">Four stops, one clear path from first lesson to final challenge.</p>
          <div className="ld-ms">
            {MISSIONS.map((m, i) => (
              <Link key={m.title} className="ld-mc-link" to={dest(m.to)}>
                <Card variant="pastel" pastelColor={m.pastel} tilt data-tilt={i % 2 ? "left" : undefined} className="ld-mc">
                  <span className="ld-mc-ic d" aria-hidden="true"><Icon name={m.icon} size={24} /></span>
                  <h3 className="ds-h3"><span className="d">{m.title}</span><span className="m">{m.mTitle}</span></h3>
                  <p className="ds-body-sm"><span className="d">{m.desc}</span><span className="m">{m.mDesc}</span></p>
                  <span className="ds-label ld-mc-open d">Open →</span>
                </Card>
              </Link>
            ))}
          </div>
        </section>

        {/* ============ Section 3: how it works ============ */}
        <section className="ld-sec ld-sec-0" id="how">
          <h2 className="ds-h1 ld-h2">How it works</h2>
          <p className="ds-body ld-secsub">Built around your class, from the first code to the final score.</p>
          <div className="ld-stp">
            {STEPS.map((s, i) => (
              <Card key={s.title} className="ld-sc">
                <span className={`ld-num ld-num-${s.pastel}`} aria-hidden="true">{i + 1}</span>
                <h3 className="ds-h3">{s.title}</h3>
                <p className="ds-body-sm ld-dim">{s.text}</p>
              </Card>
            ))}
          </div>
        </section>

        {/* ============ Section 4: quizzes ============ */}
        <section className="ld-sec" id="quizzes">
          <div className="ld-qg">
            <div>
              <h2 className="ds-h1 ld-h2">Quizzes for every kind of question</h2>
              <p className="ds-body ld-secsub">Multiple-choice, identification, true or false, and problem-solving quizzes.</p>
              <div className="ld-ty">
                {QUIZ_TYPES.map((t) => <Chip key={t}>{t}</Chip>)}
              </div>
              <Card className="ld-gb">
                <p className="ds-caption ld-gb-cap">Example · Gain = post-test − pre-test</p>
                <div className="ld-gbrow ds-label"><span>Pre-test</span><span>70%</span></div>
                <ProgressBar value={70} />
                <div className="ld-gbrow ds-label"><span>Post-test</span><span>85%</span></div>
                <ProgressBar value={85} tone="success" />
              </Card>
            </div>

            <QuizCard
              tag="Sample · Multiple choice"
              title="Which quantity is conserved in an isolated system during a collision?"
              footer={<span>Momentum and Energy · Topic Quiz</span>}
            >
              {OPTIONS.map((o) => (
                <QuizOption key={o.letter} letter={o.letter} state={o.selected ? "selected" : "default"}>
                  {o.text}
                </QuizOption>
              ))}
            </QuizCard>
          </div>
        </section>

        {/* ============ Section 5: teachers ============ */}
        <div className="ld-band" id="teachers">
          <div className="ld-band-in">
            <div>
              <h2 className="ds-h1 ld-band-h">Teachers, you&rsquo;re covered</h2>
              <p className="ds-body ld-band-p">Manage. Monitor. Support. Create classes with a join code, publish lessons with files, build assessments and choose when scores are released.</p>
            </div>
            <div className="ld-st">
              {TEACHER_TILES.map((t) => (
                <div key={t.title} className={`ld-tile${t.mint ? " mint" : ""}`}>
                  <b className="ds-title">{t.title}</b>
                  <span className="ds-caption">{t.caption}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </main>

      {/* ============ Section 6: footer ============ */}
      <footer className="ld-ft">
        <b><img className="ld-mark ld-mark-ft" src="/logo.png" alt="" />ScienceLearn</b>
        <p>
          Developed by Regym R. Medina · With the support of The Notre Dame of Isulan, Inc.<br />
          References: DepEd MATATAG Curriculum, Trusted Scientific Resources · Together for a Brighter Future
        </p>
      </footer>
    </div>
  );
}
