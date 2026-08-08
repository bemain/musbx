/* @ds-bundle: {"format":4,"namespace":"MusicianSToolboxDesignSystem_332e2c","components":[{"name":"Slider","sourcePath":"components/controls/Slider.jsx"},{"name":"Switch","sourcePath":"components/controls/Switch.jsx"},{"name":"Button","sourcePath":"components/core/Button.jsx"},{"name":"IconButton","sourcePath":"components/core/IconButton.jsx"},{"name":"Tag","sourcePath":"components/core/Tag.jsx"},{"name":"Icon","sourcePath":"components/media/Icon.jsx"},{"name":"Logo","sourcePath":"components/media/Logo.jsx"},{"name":"RadialRings","sourcePath":"components/media/RadialRings.jsx"},{"name":"StoreBadge","sourcePath":"components/media/StoreBadge.jsx"},{"name":"Waveform","sourcePath":"components/media/Waveform.jsx"},{"name":"CUSTOM_ICONS","sourcePath":"components/media/customIcons.js"},{"name":"LOGO_VIEWBOX","sourcePath":"components/media/logoMark.js"},{"name":"LOGO_PATHS","sourcePath":"components/media/logoMark.js"},{"name":"Eyebrow","sourcePath":"components/surfaces/Eyebrow.jsx"},{"name":"FeatureRow","sourcePath":"components/surfaces/FeatureRow.jsx"},{"name":"FlatCard","sourcePath":"components/surfaces/FlatCard.jsx"}],"sourceHashes":{"components/controls/Slider.jsx":"a3086cfc6513","components/controls/Switch.jsx":"696b5c62deca","components/core/Button.jsx":"83b1e8173fbd","components/core/IconButton.jsx":"7952a77c5397","components/core/Tag.jsx":"0b78299a0907","components/media/Icon.jsx":"a3a68cc77a76","components/media/Logo.jsx":"66e9fc598c30","components/media/RadialRings.jsx":"007ec3828f91","components/media/StoreBadge.jsx":"f797b053acef","components/media/Waveform.jsx":"739cc773ad00","components/media/customIcons.js":"2c167d486b23","components/media/logoMark.js":"045c7bbb5223","components/surfaces/Eyebrow.jsx":"a49a4b11d6bf","components/surfaces/FeatureRow.jsx":"29cbe8fc92bc","components/surfaces/FlatCard.jsx":"006437b9d132","ui_kits/website/Site.jsx":"183a5a0ff477"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.MusicianSToolboxDesignSystem_332e2c = window.MusicianSToolboxDesignSystem_332e2c || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/controls/Slider.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Material 3 (2024) slider shape as the app ships it: thick track, pill thumb, inset gap. */
function Slider({
  value = 0.5,
  min = 0,
  max = 1,
  label,
  valueLabel,
  disabled = false,
  onChange,
  style,
  ...rest
}) {
  const pct = Math.max(0, Math.min(1, (value - min) / (max - min || 1))) * 100;
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      display: "grid",
      gap: "8px",
      opacity: disabled ? 0.38 : 1,
      ...style
    }
  }, rest), (label || valueLabel) && /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      justifyContent: "space-between",
      fontFamily: "var(--font-mono)",
      fontSize: "var(--text-label)",
      letterSpacing: "var(--label-tracking)",
      textTransform: "uppercase",
      color: "var(--text-secondary)"
    }
  }, /*#__PURE__*/React.createElement("span", null, label), /*#__PURE__*/React.createElement("span", {
    style: {
      color: "var(--text-primary)"
    }
  }, valueLabel)), /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative",
      height: "16px",
      display: "flex",
      alignItems: "center",
      gap: "6px"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      height: "16px",
      width: `calc(${pct}% - 6px)`,
      minWidth: "4px",
      background: "var(--surface-accent)",
      borderRadius: "var(--radius-sm) 2px 2px var(--radius-sm)"
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      width: "4px",
      height: "28px",
      borderRadius: "2px",
      background: "var(--surface-accent)",
      flex: "none"
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      height: "16px",
      flex: 1,
      background: "var(--surface-inset)",
      borderRadius: "2px var(--radius-sm) var(--radius-sm) 2px"
    }
  }), /*#__PURE__*/React.createElement("input", {
    type: "range",
    min: min,
    max: max,
    step: (max - min) / 100,
    value: value,
    disabled: disabled,
    onChange: e => onChange && onChange(parseFloat(e.target.value)),
    style: {
      position: "absolute",
      inset: 0,
      width: "100%",
      height: "100%",
      opacity: 0,
      cursor: disabled ? "not-allowed" : "pointer",
      margin: 0
    }
  })));
}
Object.assign(__ds_scope, { Slider });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/controls/Slider.jsx", error: String((e && e.message) || e) }); }

// components/core/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Primary action. Accent fill on dark, ink fill on paper, or a hairline ghost. */
function Button({
  variant = "solid",
  size = "md",
  full = false,
  icon,
  iconAfter,
  disabled = false,
  as = "button",
  children,
  style,
  ...rest
}) {
  const pad = {
    sm: "10px 16px",
    md: "14px 22px",
    lg: "18px 28px"
  }[size] || "14px 22px";
  const fs = {
    sm: "var(--text-label)",
    md: "var(--text-label-lg)",
    lg: "16px"
  }[size] || "var(--text-label-lg)";
  const base = {
    display: "inline-flex",
    alignItems: "center",
    justifyContent: "center",
    gap: "10px",
    width: full ? "100%" : "auto",
    minHeight: size === "sm" ? "40px" : "var(--touch-min)",
    padding: pad,
    border: "1px solid transparent",
    borderRadius: "var(--radius-pill)",
    fontFamily: "var(--font-mono)",
    fontSize: fs,
    fontWeight: 500,
    letterSpacing: "var(--label-tracking)",
    textTransform: "uppercase",
    cursor: disabled ? "not-allowed" : "pointer",
    textDecoration: "none",
    opacity: disabled ? 0.38 : 1,
    transition: "background var(--dur-fast) var(--ease-standard), color var(--dur-fast) var(--ease-standard), border-color var(--dur-fast) var(--ease-standard), transform var(--dur-fast) var(--ease-standard)"
  };
  const variants = {
    solid: {
      background: "var(--surface-accent)",
      color: "var(--text-on-accent)"
    },
    paper: {
      background: "var(--surface-paper)",
      color: "var(--text-on-paper)"
    },
    outline: {
      background: "transparent",
      color: "var(--text-primary)",
      borderColor: "var(--border-strong)"
    },
    ghost: {
      background: "transparent",
      color: "var(--text-secondary)"
    }
  };
  const El = as;
  return /*#__PURE__*/React.createElement(El, _extends({
    disabled: as === "button" ? disabled : undefined,
    style: {
      ...base,
      ...(variants[variant] || variants.solid),
      ...style
    },
    onMouseDown: e => {
      if (!disabled) e.currentTarget.style.transform = "scale(var(--press-scale))";
    },
    onMouseUp: e => {
      e.currentTarget.style.transform = "none";
    },
    onMouseLeave: e => {
      e.currentTarget.style.transform = "none";
    }
  }, rest), icon, children, iconAfter);
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Button.jsx", error: String((e && e.message) || e) }); }

// components/core/Tag.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Mono uppercase capsule — feature names, tool labels, campaign metadata. */
function Tag({
  variant = "outline",
  dot = false,
  children,
  style,
  ...rest
}) {
  const variants = {
    outline: {
      background: "transparent",
      color: "var(--text-primary)",
      border: "1px solid var(--border-hairline)"
    },
    accent: {
      background: "var(--surface-accent)",
      color: "var(--text-on-accent)",
      border: "1px solid transparent"
    },
    quiet: {
      background: "var(--surface-inset)",
      color: "var(--text-secondary)",
      border: "1px solid transparent"
    }
  };
  return /*#__PURE__*/React.createElement("span", _extends({
    style: {
      display: "inline-flex",
      alignItems: "center",
      gap: "8px",
      padding: "6px 12px",
      borderRadius: "var(--radius-pill)",
      fontFamily: "var(--font-mono)",
      fontSize: "var(--text-label)",
      letterSpacing: "var(--label-tracking)",
      textTransform: "uppercase",
      whiteSpace: "nowrap",
      ...(variants[variant] || variants.outline),
      ...style
    }
  }, rest), dot && /*#__PURE__*/React.createElement("span", {
    style: {
      width: "8px",
      height: "8px",
      background: "var(--surface-accent)",
      display: "block"
    }
  }), children);
}
Object.assign(__ds_scope, { Tag });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Tag.jsx", error: String((e && e.message) || e) }); }

// components/media/RadialRings.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * The posters' background detail: concentric accent discs, each at a low flat opacity,
 * stacked so the overlaps step up in value. Reads as a soft radial gradient but is
 * three hard-edged rings — 5% each on the A2 sheets, giving 5 / 9.8 / 14.3%.
 * Radii on the poster: 479 / 375 / 271pt of a 1191pt-wide page (ratio 1 : 0.78 : 0.57).
 */
function RadialRings({
  size = 960,
  rings = 3,
  opacity = 0.05,
  ratio = 0.782,
  color = "var(--surface-accent)",
  style,
  ...rest
}) {
  const radii = [];
  for (let i = 0; i < rings; i++) radii.push(0.5 * Math.pow(ratio, i));
  return /*#__PURE__*/React.createElement("div", _extends({
    "aria-hidden": "true",
    style: {
      position: "absolute",
      width: size + "px",
      height: size + "px",
      pointerEvents: "none",
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("svg", {
    viewBox: "0 0 1 1",
    width: "100%",
    height: "100%",
    style: {
      display: "block",
      overflow: "visible"
    }
  }, radii.map((r, i) => /*#__PURE__*/React.createElement("circle", {
    key: i,
    cx: "0.5",
    cy: "0.5",
    r: r,
    fill: color,
    opacity: opacity
  }))));
}
Object.assign(__ds_scope, { RadialRings });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/media/RadialRings.jsx", error: String((e && e.message) || e) }); }

// components/media/Waveform.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** The poster's hero graphic: a bar waveform in the accent colour. Deterministic from a seed.
    Bars carry randomised opacity (0.52–0.98), as measured off the A2 sheets. */
function Waveform({
  bars = 56,
  height = 200,
  seed = 7,
  gap = 6,
  min = 0.18,
  playedTo = null,
  style,
  ...rest
}) {
  const vals = [];
  let s = seed * 9301 + 49297;
  for (let i = 0; i < bars; i++) {
    s = (s * 9301 + 49297) % 233280;
    const n = s / 233280;
    const env = Math.sin(i / Math.max(bars - 1, 1) * Math.PI);
    s = (s * 9301 + 49297) % 233280;
    vals.push({
      h: min + (0.35 + n * 0.65) * env * (1 - min),
      o: 0.52 + s / 233280 * 0.46
    });
  }
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      display: "flex",
      alignItems: "center",
      gap: gap + "px",
      height: height + "px",
      ...style
    }
  }, rest), vals.map((v, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      flex: 1,
      height: Math.max(v.h * 100, 4) + "%",
      background: playedTo != null && i / bars > playedTo ? "var(--ink-500)" : "var(--surface-accent)",
      opacity: playedTo != null && i / bars > playedTo ? 1 : v.o
    }
  })));
}
Object.assign(__ds_scope, { Waveform });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/media/Waveform.jsx", error: String((e && e.message) || e) }); }

// components/media/customIcons.js
try { (() => {
/* Codepoints for the app's own icon font (assets/fonts/CustomIcons.ttf),
   generated by tool/generate_icons.dart from assets/icons/*.svg. */
const CUSTOM_ICONS = {
  "youtube": 61697,
  "waveform_triangle": 61698,
  "waveform_square": 61699,
  "waveform_sine": 61700,
  "waveform_sawtooth": 61701,
  "waveform": 61702,
  "tuning_fork_rounded": 61703,
  "tuning_fork": 61704,
  "trumpet": 61705,
  "snare": 61706,
  "semiquavers_four": 61707,
  "quavers_two": 61708,
  "quavers_three": 61709,
  "microphone": 61710,
  "metronome": 61711,
  "guitar_head": 61712,
  "googleplay": 61713,
  "crotchet": 61714,
  "bass_head": 61715,
  "appstore": 61716,
  "accidentals": 61717
};
Object.assign(__ds_scope, { CUSTOM_ICONS });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/media/customIcons.js", error: String((e && e.message) || e) }); }

// components/media/Icon.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * One glyph. Names in the app's custom font (metronome, tuning_fork, snare, waveform, …)
 * render from MTCustomIcons; anything else is a Material Symbols Rounded name.
 */
function Icon({
  name,
  size = 24,
  weight = 600,
  fill = 0,
  style,
  ...rest
}) {
  const code = __ds_scope.CUSTOM_ICONS[name];
  if (code != null) {
    return /*#__PURE__*/React.createElement("span", _extends({
      "aria-hidden": "true",
      style: {
        fontFamily: "var(--font-icons)",
        fontSize: size + "px",
        lineHeight: 1,
        display: "inline-block",
        fontWeight: 400,
        ...style
      }
    }, rest), String.fromCharCode(code));
  }
  return /*#__PURE__*/React.createElement("span", _extends({
    "aria-hidden": "true",
    className: "material-symbols-rounded",
    style: {
      fontFamily: "'Material Symbols Rounded'",
      fontSize: size + "px",
      lineHeight: 1,
      display: "inline-block",
      fontVariationSettings: `'FILL' ${fill}, 'wght' ${weight}, 'GRAD' 0, 'opsz' ${size}`,
      fontWeight: "normal",
      fontStyle: "normal",
      letterSpacing: "normal",
      textTransform: "none",
      whiteSpace: "nowrap",
      wordWrap: "normal",
      direction: "ltr",
      ...style
    }
  }, rest), name);
}
Object.assign(__ds_scope, { Icon });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/media/Icon.jsx", error: String((e && e.message) || e) }); }

// components/controls/Switch.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** M3 switch with a glyph in the thumb — check when on, close when off, as the app's theme sets. */
function Switch({
  checked = false,
  disabled = false,
  label,
  onChange,
  style,
  ...rest
}) {
  const body = /*#__PURE__*/React.createElement("span", {
    onClick: () => !disabled && onChange && onChange(!checked),
    style: {
      width: "52px",
      height: "32px",
      borderRadius: "var(--radius-pill)",
      flex: "none",
      background: checked ? "var(--surface-accent)" : "var(--surface-inset)",
      border: checked ? "2px solid var(--surface-accent)" : "2px solid var(--border-hairline)",
      display: "flex",
      alignItems: "center",
      justifyContent: checked ? "flex-end" : "flex-start",
      padding: "2px",
      cursor: disabled ? "not-allowed" : "pointer",
      opacity: disabled ? 0.38 : 1,
      transition: "background var(--dur-base) var(--ease-standard)"
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: checked ? "24px" : "20px",
      height: checked ? "24px" : "20px",
      margin: checked ? 0 : "2px",
      borderRadius: "var(--radius-pill)",
      background: checked ? "var(--ink-900)" : "var(--ink-300)",
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      transition: "all var(--dur-base) var(--ease-standard)"
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: checked ? "check" : "close",
    size: 14,
    style: {
      color: checked ? "var(--surface-accent)" : "var(--ink-900)"
    }
  })));
  if (!label) return /*#__PURE__*/React.createElement("span", _extends({
    style: style
  }, rest), body);
  return /*#__PURE__*/React.createElement("label", _extends({
    style: {
      display: "flex",
      alignItems: "center",
      gap: "var(--space-3)",
      justifyContent: "space-between",
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: "var(--text-body)"
    }
  }, label), body);
}
Object.assign(__ds_scope, { Switch });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/controls/Switch.jsx", error: String((e && e.message) || e) }); }

// components/core/IconButton.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Square 48px icon target, as used throughout the app's app bars and transport rows. */
function IconButton({
  name,
  label,
  variant = "plain",
  selected = false,
  size = 24,
  disabled = false,
  style,
  ...rest
}) {
  const variants = {
    plain: {
      background: "transparent",
      color: selected ? "var(--text-accent)" : "var(--text-primary)"
    },
    tonal: {
      background: selected ? "var(--surface-accent)" : "var(--surface-inset)",
      color: selected ? "var(--text-on-accent)" : "var(--text-primary)"
    },
    filled: {
      background: "var(--surface-accent)",
      color: "var(--text-on-accent)"
    }
  };
  return /*#__PURE__*/React.createElement("button", _extends({
    "aria-label": label,
    disabled: disabled,
    style: {
      display: "inline-flex",
      alignItems: "center",
      justifyContent: "center",
      width: "var(--touch-min)",
      height: "var(--touch-min)",
      padding: 0,
      border: "none",
      borderRadius: "var(--radius-pill)",
      cursor: disabled ? "not-allowed" : "pointer",
      opacity: disabled ? 0.38 : 1,
      transition: "background var(--dur-fast) var(--ease-standard), color var(--dur-fast) var(--ease-standard)",
      ...(variants[variant] || variants.plain),
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: name,
    size: size
  }));
}
Object.assign(__ds_scope, { IconButton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/IconButton.jsx", error: String((e && e.message) || e) }); }

// components/media/StoreBadge.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** The posters' two download pills: one accent, one paper. */
function StoreBadge({
  store = "ios",
  variant = "solid",
  href = "#",
  style,
  ...rest
}) {
  const label = store === "ios" ? "iOS" : "Android";
  const glyph = store === "ios" ? "appstore" : "googleplay";
  const tones = {
    solid: {
      background: "var(--surface-accent)",
      color: "var(--text-on-accent)"
    },
    paper: {
      background: "var(--surface-paper)",
      color: "var(--text-on-paper)"
    },
    outline: {
      background: "transparent",
      color: "var(--text-primary)",
      border: "1px solid var(--border-strong)"
    }
  };
  return /*#__PURE__*/React.createElement("a", _extends({
    href: href,
    style: {
      display: "inline-flex",
      alignItems: "center",
      gap: "12px",
      padding: "14px 26px",
      borderRadius: "var(--radius-pill)",
      border: "1px solid transparent",
      textDecoration: "none",
      fontFamily: "var(--font-mono)",
      fontSize: "var(--text-label-lg)",
      letterSpacing: "var(--label-tracking)",
      ...(tones[variant] || tones.solid),
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: glyph,
    size: 22
  }), /*#__PURE__*/React.createElement("span", null, label));
}
Object.assign(__ds_scope, { StoreBadge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/media/StoreBadge.jsx", error: String((e && e.message) || e) }); }

// components/media/logoMark.js
try { (() => {
/** The brand mark's path data, lifted from assets/logo/logo.svg so it can be
    painted in any colour inline. Keep in sync if the mark ever changes. */
const LOGO_VIEWBOX = "0 0 1024 1024";
const LOGO_PATHS = ["m 435.21061,1022.7005 c -18.19548,-3.0586 -42.4422,-13.3528 -54.99757,-23.34953 -41.75074,-33.24236 -48.07539,-88.66093 -14.15036,-123.99029 14.44035,-15.03815 30.53066,-21.60719 52.52128,-21.44226 15.80133,0.1186 25.73695,3.36434 38.72332,12.65076 20.42405,14.60485 31.04453,36.24318 29.64606,60.4012 -1.26456,21.84407 -15.50241,42.53413 -35.98841,52.29764 -5.3946,2.57094 -9.84503,5.16237 -9.88976,5.75879 -0.15474,2.06255 27.82055,1.11085 37.41696,-1.2728 33.39122,-8.29405 59.77224,-35.37336 67.42492,-69.20972 3.05406,-13.50358 3.35659,-36.14776 0.71467,-53.49443 -1.7583,-11.545 -11.56018,-61.82727 -12.17159,-62.43871 -0.17747,-0.17749 -5.17747,0.92855 -11.11104,2.4578 -26.09973,6.72687 -66.37182,7.38064 -93.92165,1.52478 -30.47892,-6.47844 -63.25778,-20.8338 -88.90126,-38.93385 -14.16766,-9.99996 -44.10041,-39.50805 -53.00197,-52.24996 -26.16488,-37.45307 -39.37652,-72.06651 -43.25586,-113.32664 -3.57882,-38.06439 4.29838,-80.33585 21.25677,-114.07006 20.66845,-41.11436 51.83204,-74.34389 125.58872,-133.91421 43.96891,-35.51193 63.81053,-53.11668 83.80558,-74.35757 41.05515,-43.61322 61.09431,-76.43195 71.65319,-117.34857 3.20104,-12.40444 5.38747,-42.91611 3.71436,-51.83446 -0.93496,-4.98394 -1.29605,-5.27448 -6.55488,-5.27448 -7.05918,0 -22.84271,4.8427 -34.06298,10.45124 -33.73472,16.86262 -61.07244,46.36383 -69.61264,75.12179 -2.77369,9.33999 -2.21666,14.30016 6.1396,54.66916 3.53893,17.09657 6.78142,32.80944 7.20559,34.91751 0.68999,3.42917 -0.95072,5.31087 -15.57745,17.86552 -21.56268,18.50809 -22.76692,19.50682 -23.52067,19.50682 -1.99191,0 -15.91678,-69.47098 -18.2858,-91.22744 -2.38743,-21.92594 -0.96083,-59.30799 2.94648,-77.20783 9.34877,-42.82789 26.99304,-79.123912 54.57154,-112.259199 11.43112,-13.734355 30.79966,-31.171488 36.10259,-32.50241951 2.33587,-0.58627729 6.55998,1.15514781 14.55257,5.99942951 38.53083,23.353332 67.31945,59.750053 81.92173,103.571549 7.96399,23.89986 10.15574,38.71456 10.23285,69.16684 0.0816,32.27293 -1.64343,43.2788 -11.10486,70.84401 -14.03943,40.90288 -35.50837,74.52554 -74.52154,116.70858 l -15.00644,16.22575 1.6869,8.35279 c 2.56813,12.71627 17.27376,79.83808 18.97239,86.59681 l 1.49644,5.95421 17.58729,0.81656 c 19.07508,0.88558 31.41226,3.64226 48.44913,10.82571 18.77853,7.91783 30.44695,15.96499 46.48828,32.06088 21.67939,21.75304 32.71925,41.82197 39.25331,71.35696 4.1267,18.65336 3.19874,49.03448 -2.11509,69.2474 -8.14546,30.98383 -23.26934,57.09026 -46.35252,80.01234 -11.21266,11.13437 -32.28912,27.49525 -41.11215,31.91381 -0.24561,0.12305 1.82147,11.84206 4.59344,26.04244 7.67094,39.29658 8.69366,47.33228 8.71425,68.46975 0.0461,47.45204 -15.17889,86.62992 -44.05473,113.36383 -19.96876,18.48737 -41.41654,29.14057 -68.47049,34.00937 -8.18184,1.4725 -37.99813,1.8268 -45.6385,0.5424 z m 77.35013,-262.87168 c 6.36147,-1.34214 12.01941,-2.86369 12.57313,-3.38117 0.87871,-0.82127 -5.18399,-30.98503 -30.84676,-153.47246 -3.24878,-15.50616 -6.171,-28.63813 -6.49386,-29.18221 -0.70921,-1.19513 -17.8496,4.49716 -25.86315,8.58913 -17.64366,9.00942 -33.72662,26.12602 -39.95825,42.52636 -8.35025,21.97605 -2.49456,49.96349 14.18434,67.79456 8.58904,9.18242 13.16252,12.47044 23.47746,16.87884 l 8.10739,3.46491 -11.56638,-0.75792 c -38.89649,-2.54882 -72.95965,-32.02931 -82.43964,-71.34869 -3.44711,-14.29719 -2.32635,-42.8893 2.25318,-57.48324 11.5775,-36.89475 42.26101,-68.08067 81.25512,-82.58562 8.84417,-3.28979 11.19254,-4.77098 11.20492,-7.06708 0.0117,-2.26889 -9.63439,-49.19264 -13.75506,-66.90805 -1.00249,-4.30995 -0.58535,-4.61565 -30.697,22.49674 -62.84254,56.58325 -89.97443,92.0946 -102.42932,134.06401 -5.35015,18.02846 -5.64917,44.36088 -0.72238,63.61508 6.51467,25.45967 18.08741,45.85997 37.45823,66.03101 23.54403,24.5166 56.2277,42.42508 86.30559,47.2897 5.56631,0.90023 11.74709,1.9126 13.73508,2.24968 7.85093,1.33114 43.28893,-0.50786 54.21736,-2.81358 z m 69.74312,-32.02308 c 9.02488,-7.71023 21.43447,-23.72156 26.98477,-34.81681 10.16768,-20.32573 11.29046,-49.84318 2.68145,-70.49549 -6.86088,-16.4586 -22.09588,-32.73015 -38.92563,-41.57393 -9.92117,-5.21343 -30.62031,-11.81989 -34.26011,-10.93463 -2.03196,0.49419 -0.20192,9.8485 21.58664,110.34042 12.14361,56.0081 11.7118,54.21735 13.07339,54.21735 0.5356,0 4.52235,-3.03164 8.85949,-6.73691 z M 101.87811,835.16547 C 82.292082,829.03095 66.79249,815.24331 56.502838,794.80199 50.748087,783.36975 45.278133,762.48345 47.465729,760.29516 c 0.546935,-0.54713 8.47639,-4.19705 17.621046,-8.11096 9.144672,-3.91391 28.988222,-12.69028 44.096795,-19.50307 23.3784,-10.54186 82.6302,-36.60442 122.50551,-53.88542 l 11.17917,-4.84479 8.08115,15.79848 c 10.95864,21.424 23.08942,38.12539 40.78368,56.14998 8.16043,8.31274 14.66649,15.21327 14.45796,15.33442 -1.90973,1.10986 -30.21253,13.79114 -30.77977,13.79114 -0.76369,0 -32.23776,13.76267 -97.5524,42.65666 -20.27728,8.97037 -39.47022,17.02669 -42.65098,17.90311 -7.65438,2.10895 -25.99446,1.87823 -33.32978,-0.41924 z m 68.98451,-61.30714 c 4.81472,-5.1616 5.55046,-6.85632 5.55046,-12.78443 0,-12.08698 -8.85147,-20.75462 -21.18254,-20.74265 -15.51651,0.0155 -24.80866,17.48692 -16.47312,30.97407 4.54522,7.35435 9.32736,9.6592 18.73158,9.02827 7.00104,-0.4697 8.40642,-1.15014 13.37362,-6.47526 z M 51.30498,725.13 c 4.729542,-12.56513 10.900876,-21.21764 20.072114,-28.142 4.988393,-3.76628 25.605628,-13.59971 60.284506,-28.75282 70.84662,-30.95684 96.0341,-41.83812 96.29814,-41.60194 0.12152,0.10886 1.84261,6.13356 3.82473,13.38862 l 3.60383,13.191 -15.39109,6.59904 c -25.16553,10.78988 -82.15671,35.65798 -122.851537,53.60632 -20.934201,9.23296 -39.645329,17.18455 -41.580275,17.67018 -1.934946,0.48566 -3.875641,1.46153 -4.312671,2.16861 -0.437008,0.70713 -1.401186,1.28564 -2.142588,1.28564 -0.741445,0 0.246274,-4.23567 2.194841,-9.41265 z M 795.93676,608.07928 c -5.56629,-1.02517 -19.2291,-4.58683 -30.3617,-7.91482 -31.346,-9.37059 -44.32832,-9.36813 -65.2589,0.0116 l -8.87282,3.97655 -0.89673,-5.60781 c -1.50581,-9.41681 -8.11207,-28.90746 -13.99121,-41.27873 -4.70486,-9.90021 -12.34296,-21.21494 -26.37468,-39.07024 l -2.62226,-3.33679 14.91152,-6.84669 c 16.62026,-7.63126 38.81985,-18.9261 40.74053,-20.72815 0.68776,-0.64527 -0.875,-2.27236 -3.47275,-3.61574 -3.50133,-1.8106 -7.19104,-2.28373 -14.26266,-1.82887 -7.94497,0.51106 -13.16105,2.2509 -31.20746,10.40932 -13.46938,6.0892 -22.31666,9.33318 -23.38225,8.57335 -0.94283,-0.67228 -6.62457,-4.47536 -12.62608,-8.4513 -6.00154,-3.97595 -10.92685,-7.55428 -10.94524,-7.95187 -0.0175,-0.39762 5.95751,-3.65064 13.27962,-7.229 24.58165,-12.01315 33.91734,-25.30875 41.7594,-59.47257 5.16934,-22.52008 7.38305,-29.38556 13.2233,-41.01026 15.7283,-31.30631 45.82156,-58.83181 79.17852,-72.42252 33.08997,-13.48192 75.52863,-15.84167 112.19297,-6.2384 12.84022,3.36321 29.47169,9.81484 29.47169,11.43262 0,0.62674 -6.66864,4.88421 -14.81932,9.46105 -8.15069,4.57681 -25.55454,14.62595 -38.6751,22.33132 -13.12058,7.70539 -33.0615,19.41791 -44.31312,26.02785 l -20.45747,12.01805 -3.04131,10.2614 c -1.67271,5.64372 -3.03922,11.52431 -3.03669,13.06793 0.004,2.53078 35.81484,69.45482 53.95527,100.83302 l 7.25801,12.55445 9.72233,2.38258 c 11.76211,2.88245 5.14684,5.86486 63.46554,-28.61271 38.72261,-22.89312 68.9069,-40.08451 70.37841,-40.08451 0.69283,0 -0.82794,16.31433 -2.62843,28.19299 -1.68811,11.13782 -9.00213,33.92741 -14.15225,44.0968 -17.46919,34.49447 -48.49426,63.60337 -82.14559,77.07205 -25.62053,10.25446 -56.66705,13.66098 -81.99309,8.99662 z"];
Object.assign(__ds_scope, { LOGO_VIEWBOX, LOGO_PATHS });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/media/logoMark.js", error: String((e && e.message) || e) }); }

// components/media/Logo.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * The brand mark, drawn inline so it paints in the live accent colour —
 * `tone="accent"` follows `--surface-accent`, so it recolours inside
 * `.mt-accent-cyan` / `-ember` / `-acid` scopes without swapping files.
 */
function Logo({
  size = 40,
  tone = "accent",
  withWordmark = false,
  style,
  ...rest
}) {
  const color = tone === "accent" ? "var(--surface-accent)" : tone === "primary" ? "var(--text-primary)" : tone === "blue" ? "var(--blue)" : "currentColor";
  const mark = /*#__PURE__*/React.createElement("svg", {
    viewBox: __ds_scope.LOGO_VIEWBOX,
    width: size,
    height: size,
    "aria-hidden": "true",
    focusable: "false",
    style: {
      display: "block",
      flex: "none",
      fill: color,
      transition: "fill var(--dur-base) var(--ease-standard)"
    }
  }, __ds_scope.LOGO_PATHS.map((d, i) => /*#__PURE__*/React.createElement("path", {
    key: i,
    d: d
  })));
  if (!withWordmark) return /*#__PURE__*/React.createElement("span", _extends({
    role: "img",
    "aria-label": "Musician's Toolbox",
    style: {
      display: "inline-flex",
      ...style
    }
  }, rest), mark);
  return /*#__PURE__*/React.createElement("span", _extends({
    role: "img",
    "aria-label": "Musician's Toolbox",
    style: {
      display: "inline-flex",
      alignItems: "center",
      gap: "12px",
      ...style
    }
  }, rest), mark, /*#__PURE__*/React.createElement("span", {
    className: "mt-display",
    style: {
      fontSize: size * 0.62 + "px",
      color: "var(--text-primary)",
      whiteSpace: "nowrap"
    }
  }, "Musician's Toolbox"));
}
Object.assign(__ds_scope, { Logo });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/media/Logo.jsx", error: String((e && e.message) || e) }); }

// components/surfaces/Eyebrow.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** The poster's slash kicker: "// THE ALL-IN-ONE APP FOR MUSICIANS". */
function Eyebrow({
  marker = "//",
  tone = "accent",
  children,
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      display: "flex",
      alignItems: "center",
      gap: "10px",
      fontFamily: "var(--font-mono)",
      fontSize: "var(--text-label-lg)",
      letterSpacing: "var(--label-tracking)",
      textTransform: "uppercase",
      color: tone === "accent" ? "var(--text-accent)" : tone === "muted" ? "var(--text-muted)" : "var(--text-primary)",
      ...style
    }
  }, rest), marker && /*#__PURE__*/React.createElement("span", {
    "aria-hidden": "true"
  }, marker), /*#__PURE__*/React.createElement("span", null, children));
}
Object.assign(__ds_scope, { Eyebrow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/surfaces/Eyebrow.jsx", error: String((e && e.message) || e) }); }

// components/surfaces/FeatureRow.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** The poster's hairline-ruled row of tool names: CHORDS · DEMIXER · SPEED & PITCH · TUNER · METRONOME. */
function FeatureRow({
  items = [],
  icons = false,
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      display: "grid",
      gridTemplateColumns: `repeat(${items.length || 1},1fr)`,
      gap: "var(--space-4)",
      borderTop: "var(--rule)",
      borderBottom: "var(--rule)",
      padding: "var(--space-4) 0",
      ...style
    }
  }, rest), items.map((it, i) => {
    const label = typeof it === "string" ? it : it.label;
    const icon = typeof it === "string" ? null : it.icon;
    return /*#__PURE__*/React.createElement("div", {
      key: i,
      style: {
        display: "flex",
        alignItems: "center",
        gap: "10px",
        fontFamily: "var(--font-mono)",
        fontSize: "var(--text-label-lg)",
        letterSpacing: "var(--label-tracking)",
        textTransform: "uppercase",
        color: "var(--text-primary)"
      }
    }, icons && icon ? /*#__PURE__*/React.createElement(__ds_scope.Icon, {
      name: icon,
      size: 20,
      style: {
        color: "var(--text-accent)"
      }
    }) : /*#__PURE__*/React.createElement("span", {
      "aria-hidden": "true",
      style: {
        width: "8px",
        height: "8px",
        background: "var(--surface-accent)",
        flex: "none"
      }
    }), /*#__PURE__*/React.createElement("span", null, label));
  }));
}
Object.assign(__ds_scope, { FeatureRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/surfaces/FeatureRow.jsx", error: String((e && e.message) || e) }); }

// components/surfaces/FlatCard.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** The app's FlatCard: elevation 0, radius 32, clipped. Pair corners to group stacked cards. */
function FlatCard({
  tone = "card",
  radius = "lg",
  pad = "var(--space-4)",
  children,
  style,
  ...rest
}) {
  const tones = {
    card: {
      background: "var(--surface-card)",
      color: "var(--text-primary)"
    },
    raised: {
      background: "var(--surface-raised)",
      color: "var(--text-primary)"
    },
    inset: {
      background: "var(--surface-inset)",
      color: "var(--text-primary)"
    },
    paper: {
      background: "var(--surface-paper)",
      color: "var(--text-on-paper)"
    },
    accent: {
      background: "var(--surface-accent)",
      color: "var(--text-on-accent)"
    },
    outline: {
      background: "transparent",
      color: "var(--text-primary)",
      border: "1px solid var(--border-hairline)"
    }
  };
  const radii = {
    lg: "var(--radius-lg)",
    md: "var(--radius-md)",
    sm: "var(--radius-sm)",
    top: "var(--radius-lg) var(--radius-lg) var(--radius-xs) var(--radius-xs)",
    bottom: "var(--radius-xs) var(--radius-xs) var(--radius-lg) var(--radius-lg)"
  };
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      borderRadius: radii[radius] || radii.lg,
      overflow: "hidden",
      padding: pad,
      boxShadow: "var(--shadow-none)",
      ...(tones[tone] || tones.card),
      ...style
    }
  }, rest), children);
}
Object.assign(__ds_scope, { FlatCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/surfaces/FlatCard.jsx", error: String((e && e.message) || e) }); }

// ui_kits/website/Site.jsx
try { (() => {
/* global React */
const {
  Button,
  Tag,
  Icon,
  IconButton,
  Eyebrow,
  FeatureRow,
  FlatCard,
  StoreBadge,
  Waveform,
  Slider,
  Logo,
  RadialRings
} = window.MusicianSToolboxDesignSystem_332e2c;
const {
  useState,
  useEffect
} = React;
const siteMono = {
  fontFamily: "var(--font-mono)",
  fontSize: "var(--text-label)",
  letterSpacing: "var(--label-tracking)",
  textTransform: "uppercase"
};
const pageGutter = {
  paddingLeft: "var(--gutter-page)",
  paddingRight: "var(--gutter-page)"
};
const TOOLS = [{
  id: "speed",
  name: "Speed & Pitch",
  accent: "acid",
  glyph: "accidentals",
  head: ["Slow it", "down."],
  body: "Drop any track to half speed without touching the key. Or move the key without touching the tempo."
}, {
  id: "demixer",
  name: "Demixer",
  accent: "cyan",
  glyph: "snare",
  head: ["Pull it", "apart."],
  body: "Vocals, piano, guitar, bass, drums, other. Mute the guitar and play the part yourself."
}, {
  id: "chords",
  name: "Chords",
  accent: "ember",
  glyph: "guitar_head",
  head: ["Read it", "back."],
  body: "The song is analysed as it loads. Chord symbols scroll under the waveform, in time, so you can see the change coming."
}];
function Nav({
  onNav,
  page
}) {
  const links = [["Tools", "tools"], ["Pricing", "pricing"], ["Support", "support"]];
  return /*#__PURE__*/React.createElement("header", {
    style: {
      ...pageGutter,
      position: "sticky",
      top: 0,
      zIndex: 10,
      height: "var(--nav-height)",
      display: "flex",
      alignItems: "center",
      gap: "var(--space-6)",
      background: "var(--surface-page)",
      borderBottom: "var(--rule)"
    }
  }, /*#__PURE__*/React.createElement("a", {
    href: "#",
    onClick: e => {
      e.preventDefault();
      onNav("home");
    },
    style: {
      display: "flex",
      alignItems: "center",
      gap: "12px",
      borderBottom: "none"
    }
  }, /*#__PURE__*/React.createElement(Logo, {
    size: 32,
    withWordmark: true
  })), /*#__PURE__*/React.createElement("nav", {
    style: {
      display: "flex",
      gap: "var(--space-5)",
      marginLeft: "auto"
    }
  }, links.map(([l, p]) => /*#__PURE__*/React.createElement("a", {
    key: p,
    href: "#",
    onClick: e => {
      e.preventDefault();
      onNav(p);
    },
    style: {
      ...siteMono,
      borderBottom: "none",
      color: page === p ? "var(--text-accent)" : "var(--text-secondary)"
    }
  }, l))), /*#__PURE__*/React.createElement(Button, {
    variant: "solid",
    size: "sm",
    onClick: () => onNav("pricing"),
    style: {
      whiteSpace: "nowrap"
    }
  }, "Get the app"));
}
function Hero({
  onNav
}) {
  return /*#__PURE__*/React.createElement("section", {
    style: {
      ...pageGutter,
      paddingTop: "var(--space-9)",
      paddingBottom: "var(--space-8)",
      borderBottom: "var(--rule)",
      position: "relative",
      overflow: "hidden"
    }
  }, /*#__PURE__*/React.createElement(RadialRings, {
    size: 1000,
    style: {
      top: "18%",
      left: "58%"
    }
  }), /*#__PURE__*/React.createElement(Eyebrow, null, "The all-in-one app for musicians"), /*#__PURE__*/React.createElement("h1", {
    className: "mt-display",
    style: {
      fontSize: "var(--text-poster)",
      margin: "var(--space-5) 0 0",
      maxWidth: "16ch",
      position: "relative"
    }
  }, "Any song.", /*#__PURE__*/React.createElement("br", null), "Any tempo.", /*#__PURE__*/React.createElement("br", null), "Any key."), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "minmax(0,1fr) minmax(0,1.1fr)",
      gap: "var(--space-8)",
      alignItems: "end",
      marginTop: "var(--space-7)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gap: "var(--space-5)",
      maxWidth: "var(--measure)"
    }
  }, /*#__PURE__*/React.createElement("p", {
    className: "mt-body",
    style: {
      fontSize: "var(--text-body-lg)",
      color: "var(--text-secondary)"
    }
  }, "Five tools in one app. Slow a track down, split it into stems, read its chords, tune up, keep time. Free to start, on iOS and Android."), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: "var(--space-3)",
      flexWrap: "wrap"
    }
  }, /*#__PURE__*/React.createElement(StoreBadge, {
    store: "ios",
    variant: "solid"
  }), /*#__PURE__*/React.createElement(StoreBadge, {
    store: "android",
    variant: "paper"
  }))), /*#__PURE__*/React.createElement(Waveform, {
    bars: 40,
    height: 210,
    seed: 4,
    gap: 7,
    playedTo: 0.55
  })), /*#__PURE__*/React.createElement(FeatureRow, {
    style: {
      marginTop: "var(--space-8)"
    },
    icons: true,
    items: [{
      label: "Speed & Pitch",
      icon: "accidentals"
    }, {
      label: "Demixer",
      icon: "snare"
    }, {
      label: "Chords",
      icon: "guitar_head"
    }, {
      label: "Tuner",
      icon: "tuning_fork"
    }, {
      label: "Metronome",
      icon: "metronome"
    }]
  }));
}
function ToolSection({
  tool,
  flip
}) {
  const [speed, setSpeed] = useState(0.75);
  return /*#__PURE__*/React.createElement("section", {
    className: "mt-accent-" + tool.accent,
    style: {
      ...pageGutter,
      paddingTop: "var(--space-8)",
      paddingBottom: "var(--space-8)",
      borderBottom: "var(--rule)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "minmax(0,1fr) minmax(0,1fr)",
      gap: "var(--space-8)",
      alignItems: "center",
      direction: flip ? "rtl" : "ltr"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      direction: "ltr"
    }
  }, /*#__PURE__*/React.createElement(Eyebrow, null, tool.name), /*#__PURE__*/React.createElement("h2", {
    className: "mt-display",
    style: {
      fontSize: "var(--text-display-2)",
      margin: "var(--space-4) 0 var(--space-5)"
    }
  }, tool.head[0], /*#__PURE__*/React.createElement("br", null), tool.head[1]), /*#__PURE__*/React.createElement("p", {
    className: "mt-body",
    style: {
      color: "var(--text-secondary)",
      maxWidth: "46ch",
      fontSize: "var(--text-body-lg)"
    }
  }, tool.body)), /*#__PURE__*/React.createElement(FlatCard, {
    tone: "card",
    style: {
      direction: "ltr",
      aspectRatio: "4/3",
      display: "flex",
      flexDirection: "column",
      justifyContent: "center",
      gap: "var(--space-5)"
    },
    pad: "var(--space-6)"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      justifyContent: "space-between"
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: tool.glyph,
    size: 40,
    style: {
      color: "var(--text-accent)"
    }
  }), /*#__PURE__*/React.createElement(Tag, {
    variant: "quiet"
  }, tool.name)), /*#__PURE__*/React.createElement(Waveform, {
    bars: 28,
    height: 110,
    seed: tool.id.length * 5,
    gap: 6,
    playedTo: speed
  }), /*#__PURE__*/React.createElement(Slider, {
    value: speed,
    onChange: setSpeed,
    label: tool.id === "speed" ? "speed" : "level",
    valueLabel: tool.id === "speed" ? (0.5 + speed).toFixed(2) + "×" : Math.round(speed * 100) + "%"
  }))));
}
function PhoneStrip() {
  return /*#__PURE__*/React.createElement("section", {
    style: {
      ...pageGutter,
      paddingTop: "var(--space-8)",
      paddingBottom: "var(--space-8)",
      borderBottom: "var(--rule)"
    }
  }, /*#__PURE__*/React.createElement(Eyebrow, {
    marker: "//"
  }, "In your pocket"), /*#__PURE__*/React.createElement("h2", {
    className: "mt-display",
    style: {
      fontSize: "var(--text-display-3)",
      margin: "var(--space-4) 0 var(--space-6)",
      maxWidth: "24ch"
    }
  }, "Practice tools that fit on a music stand."), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "repeat(3,1fr)",
      gap: "var(--space-5)"
    }
  }, [["Tuner", "tuning_fork", "Chromatic, with a needle that settles green when you land it."], ["Metronome", "metronome", "Set the beat, the count and the subdivision. Then tap it in."], ["Drone", "trumpet", "Hold a root and any interval against it."]].map(([t, g, d]) => /*#__PURE__*/React.createElement(FlatCard, {
    key: t,
    tone: "outline",
    pad: "var(--space-6)"
  }, /*#__PURE__*/React.createElement(Icon, {
    name: g,
    size: 36,
    style: {
      color: "var(--text-accent)"
    }
  }), /*#__PURE__*/React.createElement("div", {
    className: "mt-display",
    style: {
      fontSize: "var(--text-heading-2)",
      marginTop: "var(--space-4)"
    }
  }, t), /*#__PURE__*/React.createElement("p", {
    className: "mt-body",
    style: {
      color: "var(--text-secondary)",
      marginTop: "var(--space-2)",
      fontSize: "var(--text-body-sm)"
    }
  }, d)))));
}
function PosterCta() {
  return /*#__PURE__*/React.createElement("section", {
    style: {
      ...pageGutter,
      paddingTop: "var(--space-9)",
      paddingBottom: "var(--space-9)",
      background: "var(--surface-accent)",
      color: "var(--text-on-accent)",
      position: "relative",
      overflow: "hidden"
    }
  }, /*#__PURE__*/React.createElement(RadialRings, {
    size: 880,
    color: "var(--ink-900)",
    style: {
      top: "-30%",
      left: "62%"
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: "var(--space-8)",
      alignItems: "flex-end",
      flexWrap: "wrap"
    }
  }, /*#__PURE__*/React.createElement("h2", {
    className: "mt-display",
    style: {
      fontSize: "var(--text-display-1)",
      flex: 1,
      minWidth: "12ch",
      margin: 0
    }
  }, "Get in", /*#__PURE__*/React.createElement("br", null), "the room."), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: "var(--space-3)"
    }
  }, /*#__PURE__*/React.createElement(StoreBadge, {
    store: "ios",
    variant: "outline",
    style: {
      borderColor: "var(--ink-900)",
      color: "var(--ink-900)"
    }
  }), /*#__PURE__*/React.createElement(StoreBadge, {
    store: "android",
    variant: "outline",
    style: {
      borderColor: "var(--ink-900)",
      color: "var(--ink-900)"
    }
  }))));
}
function Footer({
  onNav
}) {
  const cols = [["Product", ["Tools", "Pricing", "What's new"]], ["Support", ["Contact", "Licenses", "Privacy"]], ["Source", ["GitHub", "Open source", "Contribute"]]];
  return /*#__PURE__*/React.createElement("footer", {
    style: {
      ...pageGutter,
      paddingTop: "var(--space-8)",
      paddingBottom: "var(--space-7)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "1.4fr repeat(3,1fr)",
      gap: "var(--space-6)"
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(Logo, {
    size: 40
  }), /*#__PURE__*/React.createElement("p", {
    className: "mt-body",
    style: {
      color: "var(--text-secondary)",
      marginTop: "var(--space-4)",
      fontSize: "var(--text-body-sm)",
      maxWidth: "28ch"
    }
  }, "An open-source practice toolbox. Built by Benjamin Agardh.")), cols.map(([h, items]) => /*#__PURE__*/React.createElement("div", {
    key: h
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      ...siteMono,
      color: "var(--text-secondary)",
      fontSize: "var(--text-micro)",
      letterSpacing: "var(--micro-tracking)"
    }
  }, h), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gap: "var(--space-3)",
      marginTop: "var(--space-4)"
    }
  }, items.map(i => /*#__PURE__*/React.createElement("a", {
    key: i,
    href: "#",
    onClick: e => e.preventDefault(),
    style: {
      ...siteMono,
      borderBottom: "none",
      color: "var(--text-secondary)"
    }
  }, i)))))), /*#__PURE__*/React.createElement("div", {
    style: {
      ...siteMono,
      fontSize: "var(--text-micro)",
      letterSpacing: "var(--micro-tracking)",
      color: "var(--text-secondary)",
      borderTop: "var(--rule)",
      marginTop: "var(--space-7)",
      paddingTop: "var(--space-4)",
      display: "flex",
      justifyContent: "space-between"
    }
  }, /*#__PURE__*/React.createElement("span", null, "\xA9 2026 Musician's Toolbox"), /*#__PURE__*/React.createElement("span", null, "Made for practice")));
}
function PricingPage() {
  const plans = [{
    name: "Free",
    price: "0",
    per: "forever",
    accent: false,
    items: ["All five tools", "Limited stems in the Demixer", "Ads between sessions"],
    cta: "Download"
  }, {
    name: "Premium",
    price: "3.99",
    per: "per month",
    accent: true,
    items: ["Unlimited songs", "All six stems", "No ads", "Offline demix cache"],
    cta: "Go premium"
  }];
  return /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("section", {
    style: {
      ...pageGutter,
      paddingTop: "var(--space-8)",
      paddingBottom: "var(--space-8)",
      borderBottom: "var(--rule)"
    }
  }, /*#__PURE__*/React.createElement(Eyebrow, null, "Pricing"), /*#__PURE__*/React.createElement("h1", {
    className: "mt-display",
    style: {
      fontSize: "var(--text-display-2)",
      margin: "var(--space-4) 0 var(--space-7)",
      maxWidth: "20ch"
    }
  }, "Free to practise. Pay to go further."), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "repeat(2,1fr)",
      gap: "var(--space-5)",
      maxWidth: "900px"
    }
  }, plans.map(p => /*#__PURE__*/React.createElement(FlatCard, {
    key: p.name,
    tone: p.accent ? "accent" : "outline",
    pad: "var(--space-6)"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      ...siteMono
    }
  }, p.name), /*#__PURE__*/React.createElement("div", {
    className: "mt-display",
    style: {
      fontSize: "var(--text-display-3)",
      marginTop: "var(--space-4)"
    }
  }, p.price === "0" ? "Free" : "€" + p.price), /*#__PURE__*/React.createElement("div", {
    style: {
      ...siteMono,
      fontSize: "var(--text-micro)",
      letterSpacing: "var(--micro-tracking)",
      opacity: 0.7,
      marginTop: "6px"
    }
  }, p.per), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gap: "var(--space-3)",
      margin: "var(--space-6) 0"
    }
  }, p.items.map(i => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      display: "flex",
      gap: "10px",
      alignItems: "center",
      fontSize: "var(--text-body-sm)"
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "check",
    size: 18
  }), /*#__PURE__*/React.createElement("span", null, i)))), /*#__PURE__*/React.createElement(Button, {
    full: true,
    variant: p.accent ? "paper" : "outline"
  }, p.cta))))), /*#__PURE__*/React.createElement(PosterCta, null));
}
function SupportPage() {
  const faqs = [["Why does splitting a song take a while?", "Source separation runs on our server the first time a song is demixed. After that the stems are cached on your device and load instantly."], ["Does changing the speed change the key?", "No. Speed and pitch are independent. Move one and the other holds."], ["Can I use my own files?", "Yes — upload any audio file from your device, or search and load a track directly in the app."], ["Is it really open source?", "Yes. The app is built in Flutter and the source is public on GitHub."]];
  const [open, setOpen] = useState(0);
  return /*#__PURE__*/React.createElement("section", {
    style: {
      ...pageGutter,
      paddingTop: "var(--space-8)",
      paddingBottom: "var(--space-9)"
    }
  }, /*#__PURE__*/React.createElement(Eyebrow, null, "Support"), /*#__PURE__*/React.createElement("h1", {
    className: "mt-display",
    style: {
      fontSize: "var(--text-display-2)",
      margin: "var(--space-4) 0 var(--space-7)"
    }
  }, "Questions."), /*#__PURE__*/React.createElement("div", {
    style: {
      maxWidth: "var(--measure)",
      borderTop: "var(--rule)"
    }
  }, faqs.map(([q, a], i) => /*#__PURE__*/React.createElement("div", {
    key: q,
    style: {
      borderBottom: "var(--rule)"
    }
  }, /*#__PURE__*/React.createElement("button", {
    onClick: () => setOpen(open === i ? -1 : i),
    style: {
      width: "100%",
      display: "flex",
      alignItems: "center",
      justifyContent: "space-between",
      gap: "var(--space-4)",
      padding: "var(--space-5) 0",
      background: "none",
      border: "none",
      color: "var(--text-primary)",
      cursor: "pointer",
      textAlign: "left",
      fontFamily: "var(--font-body)",
      fontSize: "var(--text-heading-3)"
    }
  }, /*#__PURE__*/React.createElement("span", null, q), /*#__PURE__*/React.createElement(Icon, {
    name: open === i ? "remove" : "add",
    size: 22,
    style: {
      color: "var(--text-accent)",
      flex: "none"
    }
  })), open === i && /*#__PURE__*/React.createElement("p", {
    className: "mt-body",
    style: {
      color: "var(--text-secondary)",
      paddingBottom: "var(--space-5)",
      maxWidth: "52ch"
    }
  }, a)))));
}
function ToolsPage() {
  return /*#__PURE__*/React.createElement("div", null, TOOLS.map((t, i) => /*#__PURE__*/React.createElement(ToolSection, {
    key: t.id,
    tool: t,
    flip: i % 2 === 1
  })), /*#__PURE__*/React.createElement(PhoneStrip, null), /*#__PURE__*/React.createElement(PosterCta, null));
}
function Site() {
  const [page, setPage] = useState("home");
  useEffect(() => {
    window.scrollTo(0, 0);
  }, [page]);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      minHeight: "100vh",
      background: "var(--surface-page)"
    }
  }, /*#__PURE__*/React.createElement(Nav, {
    onNav: setPage,
    page: page
  }), page === "home" && /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(Hero, {
    onNav: setPage
  }), TOOLS.map((t, i) => /*#__PURE__*/React.createElement(ToolSection, {
    key: t.id,
    tool: t,
    flip: i % 2 === 1
  })), /*#__PURE__*/React.createElement(PhoneStrip, null), /*#__PURE__*/React.createElement(PosterCta, null)), page === "tools" && /*#__PURE__*/React.createElement(ToolsPage, null), page === "pricing" && /*#__PURE__*/React.createElement(PricingPage, null), page === "support" && /*#__PURE__*/React.createElement(SupportPage, null), /*#__PURE__*/React.createElement(Footer, {
    onNav: setPage
  }));
}
Object.assign(window, {
  Site,
  Nav,
  Hero,
  ToolSection,
  PhoneStrip,
  PosterCta,
  Footer,
  PricingPage,
  SupportPage,
  ToolsPage,
  TOOLS
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/website/Site.jsx", error: String((e && e.message) || e) }); }

__ds_ns.Slider = __ds_scope.Slider;

__ds_ns.Switch = __ds_scope.Switch;

__ds_ns.Button = __ds_scope.Button;

__ds_ns.IconButton = __ds_scope.IconButton;

__ds_ns.Tag = __ds_scope.Tag;

__ds_ns.Icon = __ds_scope.Icon;

__ds_ns.Logo = __ds_scope.Logo;

__ds_ns.RadialRings = __ds_scope.RadialRings;

__ds_ns.StoreBadge = __ds_scope.StoreBadge;

__ds_ns.Waveform = __ds_scope.Waveform;

__ds_ns.CUSTOM_ICONS = __ds_scope.CUSTOM_ICONS;

__ds_ns.LOGO_VIEWBOX = __ds_scope.LOGO_VIEWBOX;

__ds_ns.LOGO_PATHS = __ds_scope.LOGO_PATHS;

__ds_ns.Eyebrow = __ds_scope.Eyebrow;

__ds_ns.FeatureRow = __ds_scope.FeatureRow;

__ds_ns.FlatCard = __ds_scope.FlatCard;

})();
