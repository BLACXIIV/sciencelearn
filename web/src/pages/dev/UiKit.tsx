import { ReactNode, useState } from "react";
import {
  Avatar, Badge, BottomSheet, Button, Card, Checkbox, Chip, CodeInput,
  Divider, EmptyState, Icon, IconButton, Modal, OptionTile, PageHeader,
  Panel, PasswordField, ProgressBar, QuizCard, QuizOption, RadioCard,
  RadioGroup, RingChart, SearchField, SegmentedControl, Select, Skeleton,
  StatCard, StickerBadge, Switch, TextArea, TextField, Toast, type IconName,
} from "../../design-system";
import "./UiKit.css";

/* ————— helpers ————— */

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="uik-sec">
      <h2 className="uik-h2">{title}</h2>
      {children}
    </section>
  );
}

function Row({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="uik-row">
      <p className="uik-row-label">{label}</p>
      <div className="uik-row-body">{children}</div>
    </div>
  );
}

function Swatch({ name }: { name: string }) {
  return (
    <div className="uik-swatch">
      <span className="uik-swatch-chip" style={{ background: `var(--ds-${name})` }} />
      <span className="uik-swatch-name">--ds-{name}</span>
    </div>
  );
}

function EdgeBox({ height, edge }: { height: 3 | 4 | 5 | 6; edge: string }) {
  return (
    <div className="uik-edge-wrap">
      <span className="uik-edge" style={{ boxShadow: `0 ${height}px 0 var(--ds-${edge})` }} />
      <span className="uik-swatch-name">edge({edge}, {height})</span>
    </div>
  );
}

/* ————— page ————— */

export default function UiKit() {
  const [pw, setPw] = useState("hunter2");
  const [seg, setSeg] = useState("login");
  const [role, setRole] = useState("student");
  const [code, setCode] = useState("");
  const [check, setCheck] = useState(true);
  const [sw, setSw] = useState(true);
  const [sheet, setSheet] = useState(false);
  const [modal, setModal] = useState(false);
  const [toast, setToast] = useState(true);
  const [nav, setNav] = useState("home");
  const [island, setIsland] = useState("home");

  return (
    <div className="uik">
      <PageHeader compact>
        <h1 className="uik-title">ScienceLearn UI Kit</h1>
        <p className="uik-sub">Design-system gallery — every token and component. Dev builds only.</p>
      </PageHeader>

      {/* ——— Tokens ——— */}
      <Section title="Tokens — colors">
        <Row label="Brand">
          {["navy", "navy-deep", "blue", "blue-dark", "mint", "sun", "paper"].map((n) => <Swatch key={n} name={n} />)}
        </Row>
        <Row label="Pastels">
          {["pastel-blue", "pastel-yellow", "pastel-purple", "pastel-mint"].map((n) => <Swatch key={n} name={n} />)}
        </Row>
        <Row label="Ink & line">
          {["ink-soft", "muted", "line", "surface", "track"].map((n) => <Swatch key={n} name={n} />)}
        </Row>
        <Row label="Edges">
          {["edge-card", "edge-white", "edge-blue", "edge-mint", "edge-navy"].map((n) => <Swatch key={n} name={n} />)}
        </Row>
        <Row label="Status & charts">
          {["success", "warning", "error", "error-surface", "chart-1", "chart-2", "chart-3", "chart-4"].map((n) => <Swatch key={n} name={n} />)}
        </Row>
      </Section>

      <Section title="Tokens — type scale">
        <p className="ds-display uik-type">Display 76</p>
        <p className="ds-h1 uik-type">Heading 1 — 38</p>
        <p className="ds-h2 uik-type">Heading 2 — 27</p>
        <p className="ds-h3 uik-type">Heading 3 — 21</p>
        <p className="ds-title uik-type">Title — Lexend 600 / 16</p>
        <p className="ds-body uik-type">Body — Inter 16: the quick brown fox jumps over the lazy dog.</p>
        <p className="ds-body-sm uik-type">Body small — Inter 14</p>
        <p className="ds-label uik-type">Label — Lexend 600 / 13</p>
        <p className="ds-button uik-type">Button — Lexend 700 / 15</p>
        <p className="ds-caption uik-type">Caption — Inter 12</p>
      </Section>

      <Section title="Tokens — radii, spacing, edges">
        <Row label="Radii">
          {[["button", 16], ["input", 14], ["card", 22], ["panel", 32], ["chip", 14], ["pill", 999]].map(([n]) => (
            <div key={n} className="uik-radius">
              <span className="uik-radius-box" style={{ borderRadius: `var(--ds-r-${n})` }} />
              <span className="uik-swatch-name">--ds-r-{n}</span>
            </div>
          ))}
        </Row>
        <Row label="Spacing">
          {[1, 2, 3, 4, 5, 6, 7, 8].map((n) => (
            <div key={n} className="uik-space">
              <span className="uik-space-bar" style={{ width: `var(--ds-s${n})` }} />
              <span className="uik-swatch-name">{n}</span>
            </div>
          ))}
        </Row>
        <Row label="Edge heights (3–6 only)">
          <EdgeBox height={3} edge="edge-card" />
          <EdgeBox height={4} edge="edge-card" />
          <EdgeBox height={5} edge="edge-blue" />
          <EdgeBox height={6} edge="edge-navy" />
        </Row>
      </Section>

      {/* ——— Actions ——— */}
      <Section title="Button">
        <Row label="Variants (md)">
          <Button>Primary</Button>
          <Button variant="mint">Mint</Button>
          <Button variant="white">White</Button>
          <Button variant="outline">Outline</Button>
          <Button variant="danger">Danger</Button>
          <span className="uik-on-navy"><Button variant="ghost">Ghost</Button></span>
        </Row>
        <Row label="Size sm / loading / disabled / leading icon">
          <Button size="sm">Small</Button>
          <Button loading>Loading</Button>
          <Button disabled>Disabled</Button>
          <Button leadingIcon="add">With icon</Button>
        </Row>
        <Row label="Full width">
          <div className="uik-col"><Button fullWidth>Full width</Button></div>
        </Row>
      </Section>

      <Section title="IconButton">
        <Row label="Icons">
          <IconButton icon="close" label="Close" />
          <IconButton icon="edit" label="Edit" />
          <IconButton icon="delete" label="Delete" />
          <IconButton icon="settings" label="Settings" disabled />
        </Row>
      </Section>

      <Section title="Icon registry">
        <div className="uik-icons">
          {(["home","lessons","progress","account","dashboard","students","userAdmin","assessment","quiz","preTest","postTest","review","formulas","keyTerms","puzzle","science","atom","school","university","presentation","shield","back","login","signOut","camera","done","settings","gain","retry","offline","history","inbox","info","lock","mail","mailVerified","show","hide","edit","chevron","alert","openExternal","copy","play","add","tip","pending","award","delete","search","close","check"] as IconName[]).map((n) => (
            <div key={n} className="uik-icon"><Icon name={n} size={20} /><span className="uik-icon-name">{n}</span></div>
          ))}
        </div>
      </Section>

      {/* ——— Forms ——— */}
      <Section title="Text fields">
        <div className="uik-form">
          <TextField label="Display name" placeholder="Ada Lovelace" />
          <TextField label="With error" defaultValue="bad@" error="Enter a valid email address." />
          <TextField label="With helper" placeholder="you@school.edu" helper="We never share your email." />
          <TextField label="Disabled" placeholder="Locked" disabled />
          <PasswordField label="Password" value={pw} onChange={(e) => setPw(e.target.value)} />
          <TextArea label="About" placeholder="Tell the class…" />
          <Select label="Grade" options={[{ value: "7", label: "Grade 7" }, { value: "8", label: "Grade 8" }, { value: "9", label: "Grade 9" }]} />
          <SearchField label="Search" placeholder="Students, classes…" />
          <CodeInput label="Class code" value={code} onChange={setCode} error={code.length > 0 && code.length < 6 ? "Enter all 6 characters." : undefined} />
        </div>
      </Section>

      <Section title="Choice controls">
        <Row label="Checkbox / Switch">
          <Checkbox label="Remember me" checked={check} onChange={(e) => setCheck(e.target.checked)} />
          <Switch label="Daily reminders" checked={sw} onChange={(e) => setSw(e.target.checked)} />
          <Switch checked={false} onChange={() => {}} disabled />
        </Row>
        <Row label="SegmentedControl">
          <div className="uik-col uik-w-360">
            <SegmentedControl ariaLabel="Auth mode" options={[{ value: "login", label: "Log in" }, { value: "signup", label: "Sign up" }]} value={seg} onChange={setSeg} />
          </div>
        </Row>
        <Row label="RadioGroup">
          <div className="uik-col uik-w-360">
            <RadioGroup
              label="I am a…"
              value={role}
              onChange={setRole}
              options={[
                { value: "student", content: <span className="uik-tile"><Icon name="school" size={20} /> Student</span> },
                { value: "teacher", content: <span className="uik-tile"><Icon name="presentation" size={20} /> Teacher</span> },
              ]}
            />
          </div>
        </Row>
        <Row label="OptionTile">
          <OptionTile icon="school" label="Student" selected={role === "student"} onClick={() => setRole("student")} />
          <OptionTile icon="presentation" label="Teacher" selected={role === "teacher"} onClick={() => setRole("teacher")} />
          <OptionTile icon="university" label="Admin" disabled />
        </Row>
      </Section>

      {/* ——— Surfaces ——— */}
      <Section title="Card">
        <Row label="Variants">
          <Card className="uik-card-demo"><strong>White</strong></Card>
          <Card variant="pastel" pastelColor="blue" tilt className="uik-card-demo"><strong>Pastel + tilt</strong></Card>
          <Card variant="pastel" pastelColor="yellow" className="uik-card-demo"><strong>Pastel yellow</strong></Card>
          <Card variant="pastel" pastelColor="purple" className="uik-card-demo"><strong>Pastel purple</strong></Card>
          <Card variant="pastel" pastelColor="mint" className="uik-card-demo"><strong>Pastel mint</strong></Card>
          <Card variant="trivia" className="uik-card-demo"><strong>Trivia</strong><p className="uik-dim">Did you know? Honey never spoils.</p></Card>
          <Card variant="flat" className="uik-card-demo"><strong>Flat</strong></Card>
        </Row>
        <Row label="Navy + Panel">
          <Card variant="navy" className="uik-card-demo"><strong>Navy card</strong></Card>
          <Panel className="uik-card-demo"><strong>Panel — navy, radius 32</strong></Panel>
        </Row>
      </Section>

      <Section title="Sheet / Modal / Toast">
        <Row label="Openers">
          <Button variant="outline" onClick={() => setSheet(true)}>Open BottomSheet</Button>
          <Button variant="outline" onClick={() => setModal(true)}>Open Modal</Button>
          <Button variant="outline" onClick={() => setToast(true)}>Show Toast</Button>
        </Row>
      </Section>

      <BottomSheet open={sheet} onClose={() => setSheet(false)} ariaLabel="Example sheet">
        <h3 className="ds-h3">Bottom sheet</h3>
        <p className="ds-body-sm uik-dim">Radius 32 top, drag handle, dim backdrop. Esc or backdrop closes.</p>
      </BottomSheet>
      <Modal
        open={modal}
        onClose={() => setModal(false)}
        title="Delete class?"
        actions={<><Button variant="outline" onClick={() => setModal(false)}>Cancel</Button><Button variant="danger">Delete</Button></>}
      >
        <p>This removes the class and its roster. This cannot be undone.</p>
      </Modal>
      <Toast open={toast} message="Class code copied." tone="success" onClose={() => setToast(false)} />

      {/* ——— Display ——— */}
      <Section title="Chip / StickerBadge / Badge">
        <Row label="Chips">
          <Chip>White</Chip>
          <Chip variant="pastel" pastelColor="yellow">Pastel</Chip>
          <Chip variant="navy">Navy</Chip>
          <Chip variant="mint">Mint</Chip>
        </Row>
        <Row label="StickerBadge (rotations −5 / +5)">
          <StickerBadge rotation={-5}>New unit</StickerBadge>
          <StickerBadge rotation={5}>Top score</StickerBadge>
        </Row>
        <Row label="Badges">
          <Badge>3</Badge>
          <Badge tone="mint">12</Badge>
          <Badge tone="sun">!</Badge>
          <Badge tone="error">9+</Badge>
        </Row>
      </Section>

      <Section title="ProgressBar / RingChart">
        <Row label="Sizes & tones">
          <div className="uik-col uik-w-360">
            <ProgressBar value={68} label="Lesson progress" />
            <ProgressBar value={68} size="sm" label="Small" />
            <ProgressBar value={90} tone="success" label="Post-test" />
            <ProgressBar value={45} tone="sun" label="Sun" />
          </div>
        </Row>
        <Row label="RingChart (chart1..4)">
          <RingChart slices={[{ value: 40, series: 1 }, { value: 25, series: 2 }, { value: 20, series: 3 }, { value: 15, series: 4 }]} size={120}>
            <div><strong className="uik-ring-num">85%</strong><br /><span className="uik-dim">mastered</span></div>
          </RingChart>
          <RingChart slices={[{ value: 70, series: 2 }]} />
        </Row>
      </Section>

      <Section title="StatCard / Avatar / EmptyState / Skeleton / Divider">
        <Row label="StatCards">
          <StatCard icon="progress" value="82%" label="Avg. score" />
          <StatCard icon="students" value="128" label="Students" pastelColor="mint" />
          <StatCard icon="quiz" value="24" label="Quizzes" pastelColor="purple" />
        </Row>
        <Row label="Avatars">
          <Avatar name="Ada Lovelace" />
          <Avatar name="Marie Curie" pastelColor="purple" />
          <Avatar name="Alan Turing" pastelColor="mint" size={56} />
        </Row>
        <Row label="EmptyState">
          <Card variant="flat" className="uik-col uik-w-360">
            <EmptyState icon="inbox" title="No classes yet" body="Join a class with a code from your teacher." action={<Button size="sm" leadingIcon="add">Join class</Button>} />
          </Card>
        </Row>
        <Row label="Skeleton">
          <div className="uik-col uik-w-360">
            <Skeleton shape="line" />
            <Skeleton shape="line" width="70%" />
            <Skeleton shape="card" />
          </div>
        </Row>
        <Divider label="or" />
      </Section>

      {/* ——— Quiz ——— */}
      <Section title="Quiz">
        <QuizCard
          tag="Pre-test"
          title="Which planet has the most moons?"
          footer={<><span>Question 2 of 10</span><span>Hint available</span></>}
        >
          <QuizOption letter="A" state="default">Earth</QuizOption>
          <QuizOption letter="B" state="selected">Saturn</QuizOption>
          <QuizOption letter="C" state="correct">Saturn — correct!</QuizOption>
          <QuizOption letter="D" state="wrong">Jupiter</QuizOption>
          <QuizOption letter="E" state="disabled">Mars</QuizOption>
        </QuizCard>
      </Section>

      {/* ——— Layout ——— */}
      <Section title="NavBar / IslandNavBar">
        <Row label="NavBar (sidebar)">
          <div className="uik-nav-demo">
            <nav className="ds-nav" style={{ minHeight: 360 }}>
              <div className="ds-nav-brand"><strong>ScienceLearn</strong></div>
              <ul className="ds-nav-list">
                {[{ key: "home", label: "Home", icon: "home" as IconName }, { key: "lessons", label: "Lessons", icon: "lessons" as IconName }, { key: "progress", label: "Progress", icon: "progress" as IconName }].map((it) => (
                  <li key={it.key}>
                    <button type="button" className={`ds-nav-item${nav === it.key ? " on" : ""}`} onClick={() => setNav(it.key)}>
                      <Icon name={it.icon} size={20} /><span className="ds-nav-label">{it.label}</span>
                    </button>
                  </li>
                ))}
              </ul>
            </nav>
          </div>
        </Row>
        <Row label="IslandNavBar (fixed bottom — preview inline)">
          <div className="ds-island uik-island-demo">
            {[{ key: "home", label: "Home", icon: "home" as IconName }, { key: "classes", label: "Classes", icon: "lessons" as IconName }, { key: "progress", label: "Progress", icon: "progress" as IconName }, { key: "account", label: "Account", icon: "account" as IconName }].map((it) => (
              <button key={it.key} type="button" className={`ds-island-item${island === it.key ? " on" : ""}`} onClick={() => setIsland(it.key)}>
                <Icon name={it.icon} size={22} /><span className="ds-island-label">{it.label}</span>
              </button>
            ))}
          </div>
        </Row>
      </Section>
    </div>
  );
}
