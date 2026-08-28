/* global React, TOOLS, Page, PosterCta, siteMono, microMono, pageGutter, iosUrl, playUrl, useNarrow, devicePlatform */
const { Button: HButton, Tag: HTag, Icon: HIcon, Eyebrow: HEyebrow, FeatureRow: HFeatureRow, FlatCard: HCard, StoreBadge: HBadge, Waveform: HWave, RadialRings: HRings } = window.MusicianSToolboxDesignSystem_332e2c;

function Hero() {
  const narrow = useNarrow();
  return (
    <section style={{ ...pageGutter, paddingTop: "var(--space-9)", paddingBottom: "var(--space-8)", borderBottom: "var(--rule)", position: "relative", overflow: "hidden" }}>
      <HRings size={1000} style={{ top: "18%", left: "58%" }} />
      <HEyebrow>The all-in-one app for musicians</HEyebrow>
      <h1 className="mt-display" style={{ fontSize: "var(--text-poster)", margin: "var(--space-5) 0 0", maxWidth: "16ch", position: "relative" }}>Any song.<br />Any tempo.<br />Any key.</h1>
      <div className="hero-grid" style={{ display: "grid", gridTemplateColumns: "minmax(0,1fr) minmax(0,1.1fr)", gap: "var(--space-8)", alignItems: "end", marginTop: "var(--space-7)" }}>
        <div style={{ display: "grid", gap: "var(--space-5)", maxWidth: "var(--measure)" }}>
          <p className="mt-body" style={{ fontSize: "var(--text-body-lg)", color: "var(--text-secondary)" }}>
            Load a track from SoundCloud or your own files. Slow it down, split it into stems, read its chords, tune up, keep time. Five tools, one app, free to get.
          </p>
          <div style={{ display: "flex", gap: "var(--space-3)", flexWrap: "wrap" }}>
            <HBadge store="ios" href={iosUrl("web-home-hero")} variant={devicePlatform === "ios" ? "solid" : "paper"} />
            <HBadge store="android" href={playUrl("web-home-hero")} variant={devicePlatform === "android" ? "solid" : "paper"} />
          </div>
        </div>
        <HWave bars={narrow ? 16 : 40} height={narrow ? 120 : 210} seed={4} gap={narrow ? 8 : 7} playedTo={0.55} />
      </div>
      <div className="feature-row-wrap"><HFeatureRow style={{ marginTop: "var(--space-8)" }} icons items={[
        { label: "Speed & Pitch", icon: "accidentals" }, { label: "Demixer", icon: "snare" },
        { label: "Chords", icon: "guitar_head" }, { label: "Tuner", icon: "tuning_fork" }, { label: "Metronome", icon: "metronome" },
      ]} /></div>
    </section>
  );
}

function ToolSection({ tool, flip }) {
  const narrow = useNarrow();
  return (
    <section className={"mt-accent-" + tool.accent} style={{ ...pageGutter, paddingTop: "var(--space-8)", paddingBottom: "var(--space-8)", borderBottom: "var(--rule)" }}>
      <div className="split" style={{ display: "grid", gridTemplateColumns: "minmax(0,1fr) minmax(0,1fr)", gap: "var(--space-8)", alignItems: "center", direction: flip ? "rtl" : "ltr" }}>
        <div style={{ direction: "ltr" }}>
          <HEyebrow>{tool.name}</HEyebrow>
          <h2 className="mt-display" style={{ fontSize: "var(--text-display-2)", margin: "var(--space-4) 0 var(--space-5)" }}>{tool.head[0]}<br />{tool.head[1]}</h2>
          <p className="mt-body" style={{ color: "var(--text-secondary)", maxWidth: "46ch", fontSize: "var(--text-body-lg)" }}>{tool.body}</p>
        </div>
        <HCard tone="card" style={{ direction: "ltr", aspectRatio: "4/3", display: "flex", flexDirection: "column", justifyContent: "center", gap: "var(--space-5)" }} pad="var(--space-6)">
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            <HIcon name={tool.glyph} size={40} style={{ color: "var(--text-accent)" }} />
            <HTag variant="quiet">{tool.name}</HTag>
          </div>
          <HWave bars={narrow ? 14 : 28} height={narrow ? 96 : 130} seed={tool.id.length * 5} gap={narrow ? 8 : 6} playedTo={0.62} />
        </HCard>
      </div>
    </section>
  );
}

function PracticeStrip() {
  const cards = [
    ["Tuner", "tuning_fork", "Chromatic, straight off the microphone. A = 440 Hz, or set your own reference."],
    ["Metronome", "metronome", "Set the beat, the count and the subdivision. Then tap it in."],
    ["Your library", "waveform", "Search SoundCloud or upload a file from your device. Every tool works on both."],
  ];
  return (
    <section style={{ ...pageGutter, paddingTop: "var(--space-8)", paddingBottom: "var(--space-8)", borderBottom: "var(--rule)" }}>
      <HEyebrow marker="//">In your pocket</HEyebrow>
      <h2 className="mt-display" style={{ fontSize: "var(--text-display-3)", margin: "var(--space-4) 0 var(--space-6)", maxWidth: "24ch" }}>Practice tools that fit on a music stand.</h2>
      <div className="cards-3" style={{ display: "grid", gridTemplateColumns: "repeat(3,1fr)", gap: "var(--space-5)" }}>
        {cards.map(([t, g, d]) => (
          <HCard key={t} tone="outline" pad="var(--space-6)">
            <HIcon name={g} size={36} style={{ color: "var(--text-accent)" }} />
            <div className="mt-display" style={{ fontSize: "var(--text-heading-2)", marginTop: "var(--space-4)" }}>{t}</div>
            <p className="mt-body" style={{ color: "var(--text-secondary)", marginTop: "var(--space-2)", fontSize: "var(--text-body-sm)" }}>{d}</p>
          </HCard>
        ))}
      </div>
    </section>
  );
}

function PriceBand() {
  const plans = [
    { name: "Free", head: "Everything, most of the time.", items: ["All five tools", "Speed, pitch, chords, tuner and metronome — no limits", "Demixer: four stems, three songs a week"], cta: "Download", variant: "outline", tone: "outline" },
    { name: "Premium", head: "One payment. That's it.", items: ["All six stems, including piano and guitar", "Demixer without the weekly limit", "No subscription, no renewal — and it supports an independent developer"], cta: "Upgrade in the app", variant: "paper", tone: "accent" },
  ];
  return (
    <section style={{ ...pageGutter, paddingTop: "var(--space-8)", paddingBottom: "var(--space-8)", borderBottom: "var(--rule)" }}>
      <HEyebrow>Free & Premium</HEyebrow>
      <h2 className="mt-display" style={{ fontSize: "var(--text-display-3)", margin: "var(--space-4) 0 var(--space-6)", maxWidth: "22ch" }}>Free to practise. Pay once if it earns it.</h2>
      <div className="cards-2" style={{ display: "grid", gridTemplateColumns: "repeat(2,1fr)", gap: "var(--space-5)", maxWidth: "980px" }}>
        {plans.map((p) => (
          <HCard key={p.name} tone={p.tone} pad="var(--space-6)">
            <div style={siteMono}>{p.name}</div>
            <div className="mt-display" style={{ fontSize: "var(--text-heading-1)", marginTop: "var(--space-4)", maxWidth: "16ch" }}>{p.head}</div>
            <div style={{ display: "grid", gap: "var(--space-3)", margin: "var(--space-6) 0" }}>
              {p.items.map((i) => (
                <div key={i} style={{ display: "flex", gap: "10px", alignItems: "flex-start", fontSize: "var(--text-body-sm)", lineHeight: 1.35 }}>
                  <HIcon name="check" size={18} style={{ flex: "none", marginTop: "2px" }} /><span>{i}</span>
                </div>
              ))}
            </div>
            <HButton as="a" href="get.html" full variant={p.variant} style={{ textDecoration: "none" }}>{p.cta}</HButton>
          </HCard>
        ))}
      </div>
    </section>
  );
}

function Home() {
  return (
    <Page page="home">
      <Hero />
      {TOOLS.map((t, i) => <ToolSection key={t.id} tool={t} flip={i % 2 === 1} />)}
      <PracticeStrip />
      <PriceBand />
      <PosterCta campaign="web-home-cta" />
    </Page>
  );
}

Object.assign(window, { Home, Hero, ToolSection, PracticeStrip, PriceBand });
