/* global React */
const { Button, Tag, Icon, Eyebrow, FeatureRow, FlatCard, StoreBadge, Waveform, Slider, Logo, RadialRings } = window.MusicianSToolboxDesignSystem_332e2c;
const { useState, useEffect } = React;

/* Store links carry a campaign id per placement, so downloads can be attributed
   in App Store Connect / Play Console. Keep the musbx-website- prefix. */
const iosUrl = (c) => "https://apps.apple.com/app/apple-store/id1670009655?pt=126057612&ct=" + c + "&mt=8";
const playUrl = (c) => "https://play.google.com/store/apps/details?id=se.agardh.musbx&pcampaignid=" + c;
const IOS_URL = iosUrl("web-generic");
const PLAY_URL = playUrl("web-generic");
const REPO_URL = "https://github.com/bemain/musbx";
const DEV_URL = "https://bemain.github.io";
const MAIL = "mailto:bemain.dev@gmail.com";

const siteMono = { fontFamily: "var(--font-mono)", fontSize: "var(--text-label)", letterSpacing: "var(--label-tracking)", textTransform: "uppercase" };
const microMono = { ...siteMono, fontSize: "var(--text-micro)", letterSpacing: "var(--micro-tracking)" };
const pageGutter = { paddingLeft: "var(--gutter-page)", paddingRight: "var(--gutter-page)" };

const TOOLS = [
  { id: "speed", name: "Speed & Pitch", accent: "acid", glyph: "accidentals", head: ["Slow it", "down."], body: "Drop any track to half speed without touching the key. Or move the key without touching the tempo." },
  { id: "demixer", name: "Demixer", accent: "cyan", glyph: "snare", head: ["Pull it", "apart."], body: "Vocals, piano, guitar, bass, drums. Mute the part you play, keep the band behind you." },
  { id: "chords", name: "Chords", accent: "ember", glyph: "guitar_head", head: ["Read it", "back."], body: "The song is analysed as it loads. Chord symbols scroll under the waveform, in time, so you can see the change coming." },
];

function Nav({ page }) {
  const links = [["Tools", "tools.html"], ["Support", "support.html"]];
  return (
    <header className="site-nav" style={{ ...pageGutter, position: "sticky", top: 0, zIndex: 10, height: "var(--nav-height)", display: "flex", alignItems: "center", gap: "var(--space-6)", background: "var(--surface-page)", borderBottom: "var(--rule)" }}>
      <a href="index.html" className="brand" style={{ display: "flex", alignItems: "center", gap: "12px", borderBottom: "none" }}><Logo size={32} withWordmark /></a>
      <nav style={{ display: "flex", gap: "var(--space-5)", marginLeft: "auto" }}>
        {links.map(([l, href]) => (
          <a key={l} href={href} style={{ ...siteMono, borderBottom: "none", color: page === l.toLowerCase() ? "var(--text-accent)" : "var(--text-secondary)" }}>{l}</a>
        ))}
      </nav>
      <Button as="a" href="get.html" variant="solid" size="sm" style={{ whiteSpace: "nowrap", textDecoration: "none" }}>Get the app</Button>
    </header>
  );
}

function PosterCta({ head = ["Get in", "the room."], actions, campaign = "web-cta" }) {
  return (
    <section style={{ ...pageGutter, paddingTop: "var(--space-9)", paddingBottom: "var(--space-9)", background: "var(--surface-accent)", color: "var(--text-on-accent)", position: "relative", overflow: "hidden" }}>
      <RadialRings size={880} color="var(--ink-900)" style={{ top: "-30%", left: "62%" }} />
      <div style={{ display: "flex", gap: "var(--space-8)", alignItems: "flex-end", flexWrap: "wrap", position: "relative" }}>
        <h2 className="mt-display" style={{ fontSize: "var(--text-display-1)", flex: 1, minWidth: "12ch", margin: 0 }}>{head[0]}<br />{head[1]}</h2>
        <div style={{ display: "flex", gap: "var(--space-3)" }}>
          {actions || <React.Fragment>
            <StoreBadge store="ios" href={iosUrl(campaign)} variant="outline" style={{ borderColor: "var(--ink-900)", color: "var(--ink-900)" }} />
            <StoreBadge store="android" href={playUrl(campaign)} variant="outline" style={{ borderColor: "var(--ink-900)", color: "var(--ink-900)" }} />
          </React.Fragment>}
        </div>
      </div>
    </section>
  );
}

function Footer() {
  const cols = [
    ["Product", [["Tools", "tools.html"], ["Get the app", "get.html"], ["App Store", iosUrl("web-footer")], ["Google Play", playUrl("web-footer")]]],
    ["Support", [["FAQ", "support.html"], ["Email the developer", MAIL], ["Privacy policy", "privacy.html"], ["Terms of service", "terms.html"]]],
    ["Source", [["Open source on GitHub", REPO_URL], ["Report an issue", REPO_URL + "/issues"], ["Benjamin Agardh", DEV_URL]]],
  ];
  return (
    <footer style={{ ...pageGutter, paddingTop: "var(--space-8)", paddingBottom: "var(--space-7)", borderTop: "var(--rule)" }}>
      <div className="footer-grid" style={{ display: "grid", gridTemplateColumns: "1.4fr repeat(3,1fr)", gap: "var(--space-6)" }}>
        <div>
          <Logo size={40} />
          <p className="mt-body" style={{ color: "var(--text-secondary)", marginTop: "var(--space-4)", fontSize: "var(--text-body-sm)", maxWidth: "28ch" }}>
            An open-source practice toolbox, built in Flutter by Benjamin Agardh.
          </p>
        </div>
        {cols.map(([h, items]) => (
          <div key={h}>
            <div style={{ ...microMono, color: "var(--text-secondary)" }}>{h}</div>
            <div style={{ display: "grid", gap: "var(--space-3)", marginTop: "var(--space-4)" }}>
              {items.map(([label, href]) => <a key={label} href={href} style={{ ...siteMono, borderBottom: "none", color: "var(--text-secondary)" }}>{label}</a>)}
            </div>
          </div>
        ))}
      </div>
      <div style={{ ...microMono, color: "var(--text-secondary)", borderTop: "var(--rule)", marginTop: "var(--space-7)", paddingTop: "var(--space-4)", display: "flex", justifyContent: "space-between" }}>
        <span>© 2026 Musician's Toolbox</span><span>Made for practice</span>
      </div>
    </footer>
  );
}

function Page({ page, children }) {  useEffect(() => { window.scrollTo(0, 0); }, []);
  return <div style={{ minHeight: "100vh", background: "var(--surface-page)" }}><Nav page={page} />{children}<Footer /></div>;
}

/* Long-form legal / prose layout — hairline-ruled, single measure column */
function Prose({ eyebrow, title, updated, children }) {
  return (
    <section style={{ ...pageGutter, paddingTop: "var(--space-8)", paddingBottom: "var(--space-9)" }}>
      <Eyebrow>{eyebrow}</Eyebrow>
      <h1 className="mt-display" style={{ fontSize: "var(--text-display-2)", margin: "var(--space-4) 0 var(--space-5)", maxWidth: "18ch" }}>{title}</h1>
      <div style={{ ...microMono, color: "var(--text-secondary)", borderBottom: "var(--rule)", paddingBottom: "var(--space-5)", marginBottom: "var(--space-7)" }}>Last updated {updated}</div>
      <div className="mt-body prose" style={{ maxWidth: "68ch", color: "var(--text-secondary)" }}>{children}</div>
    </section>
  );
}

/* "ios" | "android" | null — used to accent only the badge for the visitor's device */
const devicePlatform = (() => {
  const ua = navigator.userAgent || "";
  if (/android/i.test(ua)) return "android";
  if (/iPad|iPhone|iPod/.test(ua)) return "ios";
  return null;
})();

/* true under 640px — used to thin out dense graphics on phones */
function useNarrow(q = "(max-width:640px)") {
  const [narrow, setNarrow] = useState(() => window.matchMedia(q).matches);
  useEffect(() => {
    const m = window.matchMedia(q);
    const on = () => setNarrow(m.matches);
    m.addEventListener("change", on);
    return () => m.removeEventListener("change", on);
  }, [q]);
  return narrow;
}

Object.assign(window, { Nav, Footer, Page, PosterCta, Prose, useNarrow, devicePlatform, TOOLS, siteMono, microMono, pageGutter, IOS_URL, PLAY_URL, iosUrl, playUrl, REPO_URL, DEV_URL, MAIL });
