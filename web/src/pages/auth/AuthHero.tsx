import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { Card, IconButton, StickerBadge } from "../../design-system";
import "./auth.css";

const TRIVIA = [
  "Momentum is conserved in an isolated system, even in a collision.",
  "Honey never spoils. Archaeologists have tasted 3,000-year-old honey found in Egyptian tombs — and it's still edible.",
  "A bolt of lightning is about five times hotter than the surface of the Sun.",
  "Your body makes around 25 million new cells every single second.",
  "There are more atoms in a glass of water than there are glasses of water in all of Earth's oceans.",
  "Octopuses have three hearts — and two of them stop beating when they swim.",
  "Hot water can freeze faster than cold water. It's called the Mpemba effect, and scientists still debate why.",
];

/** Navy hero panel content for the DS AuthShell: brand + curriculum pill,
 *  orbiting Storyset art circle with sticker badges, "Did you know?" card.
 *  `art` is the SVG shown in the paper circle (login.svg on the login page;
 *  student/teacher.svg swapped by the signup role picker). */
export function AuthHero({ art }: { art?: string }) {
  const [fact, setFact] = useState(() => Math.floor(Math.random() * TRIVIA.length));
  const nextFact = () => setFact((i) => (i + 1) % TRIVIA.length);
  useEffect(() => {
    if (matchMedia("(prefers-reduced-motion: reduce)").matches) return;
    const t = setInterval(nextFact, 7000);
    return () => clearInterval(t);
  }, []);

  return (
    <div className="a-hero">
      <div className="a-hero-top">
        <Link to="/" className="a-brand" aria-label="ScienceLearn home">
          <img src="/logo.png" alt="" />
          <strong>ScienceLearn</strong>
        </Link>
        <span className="a-align"><i />DepEd MATATAG aligned</span>
      </div>

      <div className="a-hero-body">
        <div className="a-orb">
          <div className="a-orbit" aria-hidden="true">
            <div className="spin"><i /></div>
            <div className="spin s2"><i /></div>
          </div>
          {art && (
            <div className="a-ill">
              <img src={art} alt="" />
              <span className="a-chip c1"><StickerBadge rotation={-5} pastel="blue">Join with a class code</StickerBadge></span>
              <span className="a-chip c2"><StickerBadge rotation={5} pastel="mint">Pre → post gain</StickerBadge></span>
            </div>
          )}
        </div>

        <div className="a-trivia">
          <Card variant="trivia">
            <p className="a-trivia-cap">Did you know?</p>
            <span className="a-trivia-shuffle">
              <IconButton icon="retry" label="Show another fact" onClick={nextFact} />
            </span>
            <p className="a-trivia-fact" key={fact}>{TRIVIA[fact]}</p>
          </Card>
        </div>
      </div>
    </div>
  );
}
