/* global React, Page, PosterCta, siteMono, microMono, pageGutter */
const { Button: TButton, Tag: TTag, Icon: TIcon, Eyebrow: TEyebrow, FlatCard: TCard, Waveform: TWave, Slider: TSlider, Switch: TSwitch, RadialRings: TRings } = window.MusicianSToolboxDesignSystem_332e2c;
const { useState: useTState } = React;

const STEMS = [["Vocals", "microphone", false], ["Piano", "piano", true], ["Guitar", "guitar_head", true], ["Bass", "bass_head", false], ["Drums", "snare", false], ["Other", "waveform", false]];
const CHORDS = ["Am", "F", "C", "G", "Am", "F", "C", "G"];

/* Alternating two-column tool section. `flip` puts the card on the left. */
function Split({ accent, flip, children }) {
  return (
    <section className={"mt-accent-" + accent} style={{ ...pageGutter, paddingTop: "var(--space-9)", paddingBottom: "var(--space-9)", borderBottom: "var(--rule)" }}>
      <div style={{ display: "grid", gridTemplateColumns: "minmax(0,1fr) minmax(0,1fr)", gap: "var(--space-8)", alignItems: "start", direction: flip ? "rtl" : "ltr" }}>
        {React.Children.map(children, (c) => <div style={{ direction: "ltr" }}>{c}</div>)}
      </div>
    </section>
  );
}

function Copy({ name, head, body, points }) {
  return (
    <div>
      <TEyebrow>{name}</TEyebrow>
      <h2 className="mt-display" style={{ fontSize: "var(--text-display-2)", margin: "var(--space-4) 0 var(--space-5)" }}>{head[0]}<br />{head[1]}</h2>
      <p className="mt-body" style={{ color: "var(--text-secondary)", maxWidth: "48ch", fontSize: "var(--text-body-lg)" }}>{body}</p>
      {points && (
        <div style={{ display: "grid", gap: "var(--space-4)", marginTop: "var(--space-7)", maxWidth: "48ch" }}>
          {points.map((t) => (
            <div key={t} style={{ display: "flex", gap: "12px", alignItems: "flex-start", borderTop: "var(--rule)", paddingTop: "var(--space-4)" }}>
              <TIcon name="check" size={18} style={{ color: "var(--text-accent)", flex: "none", marginTop: "3px" }} />
              <p className="mt-body" style={{ color: "var(--text-secondary)", margin: 0, fontSize: "var(--text-body-sm)" }}>{t}</p>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

function CardHead({ label, tag }) {
  return (
    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
      <div style={{ ...siteMono, color: "var(--text-secondary)" }}>{label}</div><TTag variant="quiet">{tag}</TTag>
    </div>
  );
}

function ToolsHero() {
  return (
    <section style={{ ...pageGutter, paddingTop: "var(--space-8)", paddingBottom: "var(--space-8)", borderBottom: "var(--rule)", position: "relative", overflow: "hidden" }}>
      <TRings size={820} style={{ top: "-10%", left: "68%" }} />
      <TEyebrow>The tools</TEyebrow>
      <h1 className="mt-display" style={{ fontSize: "var(--text-display-1)", margin: "var(--space-5) 0 var(--space-6)", maxWidth: "14ch", position: "relative" }}>Five tools. One app.</h1>
      <p className="mt-body" style={{ fontSize: "var(--text-body-lg)", color: "var(--text-secondary)", maxWidth: "56ch" }}>
        Load a song from SoundCloud or your own files, then work on it. Everything below runs on the same track, at the same time.
      </p>
    </section>
  );
}

function SpeedSection() {
  return (
    <Split accent="acid">
      <Copy name="Speed & Pitch" head={["Slow it", "down."]}
        body="Tempo and key are independent. Take a solo down to half speed with the key untouched, or move a song into your range without slowing it."
        points={["Speed from a crawl up to full tempo, adjusted while the song plays.",
          "Transpose by semitones — the chord chart follows into the new key.",
          "Set loop points and drill the same four bars until they stick."]} />
      <TCard tone="card" pad="var(--space-6)" style={{ display: "grid", gap: "var(--space-6)" }}>
        <CardHead label="Speed & pitch" tag="Playing" />
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "var(--space-5)" }}>
          {[["0.75×", "speed"], ["−2", "semitones"]].map(([n, l]) => (
            <div key={l} style={{ borderTop: "var(--rule)", paddingTop: "var(--space-4)" }}>
              <div className="mt-display" style={{ fontSize: "var(--text-display-3)", color: "var(--text-accent)" }}>{n}</div>
              <div style={{ ...microMono, color: "var(--text-secondary)", marginTop: "6px" }}>{l}</div>
            </div>
          ))}
        </div>
        <TWave bars={40} height={120} seed={3} gap={5} playedTo={0.42} />
        <div style={{ ...microMono, color: "var(--text-secondary)", display: "flex", justifyContent: "space-between" }}><span>Loop 01:12 — 01:28</span><span>A minor</span></div>
      </TCard>
    </Split>
  );
}

function DemixerSection() {
  const [on, setOn] = useTState({ Vocals: false, Piano: true, Guitar: true, Bass: true, Drums: true, Other: true });
  return (
    <Split accent="cyan" flip>
      <TCard tone="card" pad="var(--space-6)" style={{ display: "grid", gap: "var(--space-5)" }}>
        <CardHead label="Stems" tag="6 total" />
        {STEMS.map(([s, g, premium]) => (
          <div key={s} style={{ display: "grid", gridTemplateColumns: "28px 1fr auto", alignItems: "center", gap: "var(--space-4)", opacity: on[s] ? 1 : 0.38 }}>
            <TIcon name={g} size={24} style={{ color: "var(--text-accent)" }} />
            <div>
              <div style={{ ...microMono, color: "var(--text-secondary)", marginBottom: "6px", display: "flex", gap: "8px", alignItems: "center" }}>{s}{premium && <span style={{ color: "var(--text-accent)" }}>Premium</span>}</div>
              <TWave bars={26} height={34} seed={s.length * 7} gap={4} playedTo={on[s] ? 0.6 : 0} />
            </div>
            <TSwitch checked={on[s]} onChange={(v) => setOn({ ...on, [s]: v })} />
          </div>
        ))}
      </TCard>
      <Copy name="Demixer" head={["Pull it", "apart."]}
        body="The track is separated into six stems — vocals, piano, guitar, bass, drums, other. Mute the one you play and the rest keeps going. Mute everything else and study the part on its own."
        points={["Separation runs once on the server, then the stems cache on your phone.",
          "Every stem has its own level, so you can push a part forward instead of silencing it.",
          "Four stems and three songs a week are free; piano, guitar and unlimited songs come with the one-time purchase."]} />
    </Split>
  );
}

function ChordsSection() {
  const [pos, setPos] = useTState(0.35);
  const active = Math.min(CHORDS.length - 1, Math.floor(pos * CHORDS.length));
  return (
    <Split accent="ember">
      <Copy name="Chords" head={["Read it", "back."]}
        body="Chords are detected as the song loads and scroll in time under the waveform. You see the change one bar before it lands, which is the whole point."
        points={["Works with Speed & Pitch — slow the song down and the chart slows with it.",
          "Transpose and the symbols follow the new key.",
          "Sharps or flats, in the app's notation face."]} />
      <TCard tone="card" pad="var(--space-6)" style={{ display: "grid", gap: "var(--space-5)" }}>
        <CardHead label="Chart" tag="A minor" />
        <div style={{ display: "grid", gridTemplateColumns: "repeat(8,1fr)", gap: "6px" }}>
          {CHORDS.map((c, i) => (
            <div key={i} style={{ textAlign: "center", padding: "var(--space-4) 0", borderRadius: "var(--radius-sm)", background: i === active ? "var(--surface-accent)" : "var(--surface-inset)", color: i === active ? "var(--text-on-accent)" : "var(--text-secondary)", fontFamily: "var(--font-notation)", fontSize: "var(--text-heading-3)", transition: "background var(--dur-fast) var(--ease-standard)" }}>{c}</div>
          ))}
        </div>
        <TWave bars={40} height={90} seed={11} gap={5} playedTo={pos} />
        <TSlider value={pos} onChange={setPos} label="position" valueLabel={"BAR " + (active + 1)} />
      </TCard>
    </Split>
  );
}

function TunerSection() {
  const cents = [-50, -25, 0, 25, 50];
  return (
    <Split accent="acid" flip>
      <TCard tone="card" pad="var(--space-6)" style={{ display: "grid", gap: "var(--space-6)" }}>
        <CardHead label="Tuner" tag="Chromatic" />
        <div style={{ textAlign: "center" }}>
          <div style={{ fontFamily: "var(--font-notation)", fontSize: "84px", lineHeight: 1, color: "var(--text-accent)" }}>A</div>
          <div style={{ ...microMono, color: "var(--text-secondary)", marginTop: "var(--space-3)" }}>+2 cents · 440 Hz</div>
        </div>
        <div>
          <div style={{ position: "relative", height: "44px", borderTop: "var(--rule)", borderBottom: "var(--rule)" }}>
            {cents.map((c) => (
              <div key={c} style={{ position: "absolute", left: (50 + c) + "%", top: 0, bottom: 0, width: "1px", background: "var(--border-hairline)" }}></div>
            ))}
            <div style={{ position: "absolute", left: "52%", top: "6px", bottom: "6px", width: "3px", borderRadius: "2px", background: "var(--surface-accent)" }}></div>
          </div>
          <div style={{ ...microMono, color: "var(--text-secondary)", display: "flex", justifyContent: "space-between", marginTop: "var(--space-3)" }}><span>−50</span><span>In tune</span><span>+50</span></div>
        </div>
      </TCard>
      <Copy name="Tuner" head={["Land it", "in tune."]}
        body="Chromatic tuning straight off the built-in microphone. The needle settles when you land the note, so you can tune without staring at the screen."
        points={["Detects the nearest note automatically — no string selection.",
          "Reference pitch is adjustable if the ensemble tunes away from A = 440 Hz.",
          "Works on anything you can play into the phone."]} />
    </Split>
  );
}

function MetronomeSection() {
  const [beat, setBeat] = useTState(0);
  return (
    <Split accent="ember">
      <Copy name="Metronome" head={["Keep it", "steady."]}
        body="Set the tempo, the count and the subdivision, then let it run. Tap the tempo in if it is already in your hands."
        points={["Beats per bar and subdivision are set separately.",
          "Tap tempo for when you know the feel but not the number.",
          "Runs alongside a loaded song, so you can check a passage against the click."]} />
      <TCard tone="card" pad="var(--space-6)" style={{ display: "grid", gap: "var(--space-6)" }}>
        <CardHead label="Metronome" tag="4 / 4" />
        <div style={{ display: "flex", alignItems: "baseline", gap: "var(--space-4)" }}>
          <div className="mt-display" style={{ fontSize: "var(--text-display-2)", color: "var(--text-accent)" }}>120</div>
          <div style={{ ...microMono, color: "var(--text-secondary)" }}>BPM</div>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(4,1fr)", gap: "var(--space-3)" }}>
          {[0, 1, 2, 3].map((i) => (
            <button key={i} onClick={() => setBeat(i)} aria-label={"Beat " + (i + 1)}
              style={{ height: "56px", borderRadius: "var(--radius-sm)", border: "1px solid var(--border-hairline)", cursor: "pointer", background: i === beat ? "var(--surface-accent)" : "var(--surface-inset)", color: i === beat ? "var(--text-on-accent)" : "var(--text-secondary)", fontFamily: "var(--font-mono)", fontSize: "var(--text-label)", transition: "background var(--dur-fast) var(--ease-standard)" }}>{i + 1}</button>
          ))}
        </div>
        <div style={{ display: "flex", gap: "var(--space-5)", alignItems: "center", borderTop: "var(--rule)", paddingTop: "var(--space-4)" }}>
          {["crotchet", "quavers_two", "quavers_three", "semiquavers_four"].map((g, i) => (
            <TIcon key={g} name={g} size={26} style={{ color: i === 1 ? "var(--text-accent)" : "var(--text-secondary)" }} />
          ))}
          <div style={{ ...microMono, color: "var(--text-secondary)", marginLeft: "auto" }}>Subdivision</div>
        </div>
      </TCard>
    </Split>
  );
}

function SourcesStrip() {
  const cards = [["SoundCloud", "waveform", "Search a track and load it straight into the player."],
    ["Your files", "upload_file", "Upload any audio file from your device — recordings included."],
    ["Offline", "cloud_off", "Once a song is on the device, every tool keeps working without a connection."]];
  return (
    <section style={{ ...pageGutter, paddingTop: "var(--space-8)", paddingBottom: "var(--space-8)", borderBottom: "var(--rule)" }}>
      <TEyebrow marker="//">Where songs come from</TEyebrow>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(3,1fr)", gap: "var(--space-5)", marginTop: "var(--space-6)" }}>
        {cards.map(([t, g, d]) => (
          <TCard key={t} tone="outline" pad="var(--space-6)">
            <TIcon name={g} size={36} style={{ color: "var(--text-accent)" }} />
            <div className="mt-display" style={{ fontSize: "var(--text-heading-2)", marginTop: "var(--space-4)" }}>{t}</div>
            <p className="mt-body" style={{ color: "var(--text-secondary)", marginTop: "var(--space-2)", fontSize: "var(--text-body-sm)" }}>{d}</p>
          </TCard>
        ))}
      </div>
      <TButton as="a" href="get.html" variant="outline" style={{ marginTop: "var(--space-6)", textDecoration: "none" }}>Get the app</TButton>
    </section>
  );
}

function ToolsPage() {
  return <Page page="tools"><ToolsHero /><SpeedSection /><DemixerSection /><ChordsSection /><TunerSection /><MetronomeSection /><SourcesStrip /><PosterCta head={["Try it on", "your song."]} campaign="web-tools-cta" /></Page>;
}

Object.assign(window, { ToolsPage, SpeedSection, DemixerSection, ChordsSection, TunerSection, MetronomeSection, SourcesStrip });
