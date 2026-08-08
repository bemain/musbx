/* global React, Page, PosterCta, siteMono, microMono, pageGutter, REPO_URL, MAIL, DEV_URL */
const { Button: SButton, Icon: SIcon, Eyebrow: SEyebrow, FlatCard: SCard } = window.MusicianSToolboxDesignSystem_332e2c;const { useState: useSState } = React;

const FAQS = [
  ["Why does splitting a song take a while the first time?", "Separation runs on a server the first time a song is demixed. After that the stems are cached on your device and load instantly."],
  ["Does changing the speed change the key?", "No. Speed and pitch are independent. Move one and the other holds."],
  ["What do I get for free?", "All five tools. Speed & Pitch, Chords, Tuner and Metronome have no limits at all. The Demixer gives you four stems — vocals, bass, drums, other — for three songs a week."],
  ["What does the one-time purchase unlock?", "Two more stems in the Demixer — piano and guitar — and no weekly song limit. There is no subscription and nothing renews. Mostly it is a way to support an independent developer who builds this in the open."],
  ["Can I use my own audio files?", "Yes. Upload any audio file from your device, or search and load a track from SoundCloud inside the app."],
  ["Does the app work offline?", "The tools work offline once a song is on your device. Loading a new song from SoundCloud, and demixing it the first time, both need a connection."],
  ["Which permissions does it ask for, and why?", "Microphone for the tuner and recording, file access to open your own songs, notifications for updates. All of them are optional and the app works without them."],
  ["Is it really open source?", "Yes. The app is built in Flutter and the full source is public on GitHub. Bug reports and pull requests are welcome."],
];

function Faq() {
  const [open, setOpen] = useSState(0);
  return (
    <section style={{ ...pageGutter, paddingTop: "var(--space-8)", paddingBottom: "var(--space-8)", borderBottom: "var(--rule)" }}>
      <SEyebrow>Support</SEyebrow>
      <h1 className="mt-display" style={{ fontSize: "var(--text-display-2)", margin: "var(--space-4) 0 var(--space-7)" }}>Questions.</h1>
      <div style={{ maxWidth: "var(--measure)", borderTop: "var(--rule)" }}>
        {FAQS.map(([q, a], i) => (
          <div key={q} style={{ borderBottom: "var(--rule)" }}>
            <button onClick={() => setOpen(open === i ? -1 : i)} style={{ width: "100%", display: "flex", alignItems: "center", justifyContent: "space-between", gap: "var(--space-4)", padding: "var(--space-5) 0", background: "none", border: "none", color: "var(--text-primary)", cursor: "pointer", textAlign: "left", fontFamily: "var(--font-body)", fontSize: "var(--text-heading-3)" }}>
              <span>{q}</span><SIcon name={open === i ? "remove" : "add"} size={22} style={{ color: "var(--text-accent)", flex: "none" }} />
            </button>
            {open === i && <p className="mt-body" style={{ color: "var(--text-secondary)", paddingBottom: "var(--space-5)", maxWidth: "58ch", margin: 0 }}>{a}</p>}
          </div>
        ))}
      </div>
    </section>
  );
}

function ContactStrip() {
  const cards = [
    ["Email", "mail", "Questions, bug reports, anything else. Written by a person, answered by the same one.", "bemain.dev@gmail.com", MAIL],
    ["GitHub issues", "code", "Reproducible bugs and feature requests are best filed on the repository.", "bemain/musbx", REPO_URL + "/issues"],
    ["The developer", "person", "Musician's Toolbox is built and maintained by Benjamin Agardh.", "bemain.github.io", DEV_URL],
  ];
  return (
    <section style={{ ...pageGutter, paddingTop: "var(--space-8)", paddingBottom: "var(--space-9)" }}>
      <SEyebrow marker="//">Get in touch</SEyebrow>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(3,1fr)", gap: "var(--space-5)", marginTop: "var(--space-6)" }}>
        {cards.map(([t, g, d, label, href]) => (
          <SCard key={t} tone="outline" pad="var(--space-6)">
            <SIcon name={g} size={32} style={{ color: "var(--text-accent)" }} />
            <div className="mt-display" style={{ fontSize: "var(--text-heading-2)", marginTop: "var(--space-4)" }}>{t}</div>
            <p className="mt-body" style={{ color: "var(--text-secondary)", margin: "var(--space-2) 0 var(--space-5)", fontSize: "var(--text-body-sm)" }}>{d}</p>
            <a href={href} style={{ ...siteMono, color: "var(--text-accent)" }}>{label}</a>
          </SCard>
        ))}
      </div>
      <div style={{ ...microMono, color: "var(--text-secondary)", marginTop: "var(--space-7)", borderTop: "var(--rule)", paddingTop: "var(--space-4)" }}>
        Also see <a href="privacy.html">privacy policy</a> · <a href="terms.html">terms of service</a>
      </div>
    </section>
  );
}

function SupportPage() {
  const contactActions = (
    <React.Fragment>
      <SButton as="a" href={MAIL} variant="paper" style={{ textDecoration: "none" }}>Email the developer</SButton>
      <SButton as="a" href={REPO_URL + "/issues"} variant="outline" style={{ textDecoration: "none", borderColor: "var(--ink-900)", color: "var(--ink-900)" }}>File an issue</SButton>
    </React.Fragment>
  );
  return <Page page="support"><Faq /><ContactStrip /><PosterCta head={["Still stuck?", "Write in."]} actions={contactActions} /></Page>;
}
Object.assign(window, { SupportPage, Faq, ContactStrip });
