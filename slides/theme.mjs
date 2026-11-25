// Plantilla visual de las diapositivas de investigación.
// Estilo "doodle": papel claro, trazos lila dibujados a mano, títulos en Chewy y texto en Mali,
// igual que la presentación "Feedback del optimizador y clustering factor".

const LILA = "#ad9ee0";

// Generador pseudoaleatorio con semilla: cada diapositiva sale igual en cada build.
function rng(seed) {
  let s = seed >>> 0;
  return () => ((s = (s * 1664525 + 1013904223) >>> 0) / 2 ** 32);
}

const esc = (s) => String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
// **negrita** dentro del texto
const fmt = (s) => esc(s).replace(/\*\*(.+?)\*\*/g, "<b>$1</b>").replace(/\*(.+?)\*/g, "<i>$1</i>").replace(/`(.+?)`/g, "<code>$1</code>");

// ── Doodles (SVG) ───────────────────────────────────────────────
const stroke = (w = 9) => `fill="none" stroke="${LILA}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round" filter="url(#rough)"`;

const doodles = {
  loopArrow: (x, y, s = 1, r = 0) => `<svg class="d" style="left:${x}px;top:${y}px;width:${200 * s}px;transform:rotate(${r}deg)" viewBox="0 0 200 170">
    <path ${stroke()} d="M12 40 C 60 -5, 130 5, 118 62 C 108 112, 42 104, 58 62 C 74 18, 160 30, 172 118"/>
    <path ${stroke()} d="M150 104 L173 124 L186 94"/></svg>`,
  scribble: (x, y, s = 1, r = 0) => `<svg class="d" style="left:${x}px;top:${y}px;width:${170 * s}px;transform:rotate(${r}deg)" viewBox="0 0 170 90">
    <path ${stroke()} d="M8 50 C 22 4, 46 4, 36 46 C 26 88, 60 88, 66 46 C 72 4, 104 4, 96 46 C 88 88, 122 88, 128 46 C 134 6, 160 10, 162 40"/></svg>`,
  spiral: (x, y, s = 1, r = 0) => `<svg class="d" style="left:${x}px;top:${y}px;width:${150 * s}px;transform:rotate(${r}deg)" viewBox="0 0 150 150">
    <path ${stroke()} d="M75 75 C 85 70, 88 88, 75 90 C 58 92, 55 66, 75 60 C 100 54, 106 92, 80 104 C 50 116, 36 72, 58 48 C 84 22, 132 44, 126 86"/>
    <path ${stroke()} d="M112 78 L127 90 L138 72"/></svg>`,
  bulb: (x, y, s = 1) => `<svg class="d" style="left:${x}px;top:${y}px;width:${190 * s}px" viewBox="0 0 190 200">
    <path ${stroke(8)} d="M70 150 C 70 128, 48 116, 48 86 C 48 56, 72 40, 96 40 C 122 40, 144 58, 142 88 C 140 116, 120 126, 120 150 Z"/>
    <path ${stroke(8)} d="M74 164 L118 164 M78 178 L114 178 M88 190 L104 190"/>
    <path ${stroke(7)} d="M84 150 C 84 128, 80 118, 88 112 C 94 108, 100 116, 94 122 C 88 128, 104 128, 106 116 M106 116 C 108 124, 106 136, 106 150"/>
    <path ${stroke(8)} d="M96 18 L96 4 M40 40 L28 28 M152 40 L164 28 M22 92 L6 92 M170 92 L186 92"/></svg>`,
  book: (x, y, s = 1, r = -12) => `<svg class="d" style="left:${x}px;top:${y}px;width:${210 * s}px;transform:rotate(${r}deg);opacity:.85" viewBox="0 0 210 140">
    <path fill="${LILA}" fill-opacity=".28" stroke="${LILA}" stroke-width="7" stroke-linejoin="round" filter="url(#rough)" d="M10 30 L100 18 L104 120 L14 128 Z M104 18 L196 30 L192 128 L108 120 Z"/>
    <path ${stroke(5)} d="M28 48 L84 42 M28 66 L70 62 M28 84 L84 78 M122 46 L176 52 M122 64 L176 70 M136 90 L172 94"/></svg>`,
  database: (x, y, s = 1, r = 0) => `<svg class="d" style="left:${x}px;top:${y}px;width:${150 * s}px;transform:rotate(${r}deg)" viewBox="0 0 150 170">
    <ellipse ${stroke(8)} cx="75" cy="30" rx="60" ry="20"/>
    <path ${stroke(8)} d="M15 30 L15 140 C 15 166, 135 166, 135 140 L135 30 M15 66 C 15 92, 135 92, 135 66 M15 103 C 15 129, 135 129, 135 103"/></svg>`,
  pencil: (x, y, s = 1, r = -35) => `<svg class="d" style="left:${x}px;top:${y}px;width:${240 * s}px;transform:rotate(${r}deg)" viewBox="0 0 240 60">
    <path fill="${LILA}" fill-opacity=".35" stroke="${LILA}" stroke-width="6" stroke-linejoin="round" filter="url(#rough)" d="M40 12 L210 12 L210 48 L40 48 Z"/>
    <path ${stroke(6)} d="M40 12 L6 30 L40 48 M210 12 L232 12 L232 48 L210 48 M60 30 L190 30"/></svg>`,
  star: (x, y, s = 1) => `<svg class="d" style="left:${x}px;top:${y}px;width:${70 * s}px" viewBox="0 0 70 70">
    <path ${stroke(6)} d="M35 6 L42 27 L64 28 L46 41 L53 63 L35 50 L17 63 L24 41 L6 28 L28 27 Z"/></svg>`,
  gear: (x, y, s = 1) => `<svg class="d" style="left:${x}px;top:${y}px;width:${130 * s}px" viewBox="0 0 130 130">
    <circle ${stroke(8)} cx="65" cy="65" r="34"/><circle ${stroke(7)} cx="65" cy="65" r="12"/>
    <path ${stroke(9)} d="M65 10 L65 26 M65 104 L65 120 M10 65 L26 65 M104 65 L120 65 M26 26 L37 37 M93 93 L104 104 M104 26 L93 37 M37 93 L26 104"/></svg>`,
  pin: (x, y, s = 1) => `<svg class="d" style="left:${x}px;top:${y}px;width:${110 * s}px" viewBox="0 0 110 150">
    <path ${stroke(8)} d="M55 140 C 40 110, 14 84, 14 54 C 14 28, 34 10, 55 10 C 78 10, 96 28, 96 54 C 96 84, 70 110, 55 140 Z"/>
    <circle ${stroke(7)} cx="55" cy="54" r="16"/></svg>`,
  leaf: (x, y, s = 1, r = 0) => `<svg class="d" style="left:${x}px;top:${y}px;width:${120 * s}px;transform:rotate(${r}deg)" viewBox="0 0 120 150">
    <path fill="${LILA}" fill-opacity=".3" stroke="${LILA}" stroke-width="7" filter="url(#rough)" d="M60 140 C 10 100, 10 40, 60 8 C 110 40, 110 100, 60 140 Z"/>
    <path ${stroke(6)} d="M60 140 L60 30 M60 70 L40 54 M60 96 L84 78"/></svg>`,
  funnel: (x, y, s = 1) => `<svg class="d" style="left:${x}px;top:${y}px;width:${140 * s}px" viewBox="0 0 140 160">
    <path ${stroke(8)} d="M10 20 L130 20 L82 86 L82 140 L58 152 L58 86 Z"/>
    <path ${stroke(6)} d="M30 6 L36 0 M70 4 L70 -4 M104 6 L110 0"/></svg>`,
};

function burst(seed, w = 760, h = 420) {
  const rand = rng(seed);
  const pts = [];
  const n = 18;
  for (let i = 0; i < n; i++) {
    const a = (i / n) * Math.PI * 2;
    const outer = i % 2 === 0;
    const rx = (outer ? 0.5 : 0.34) * w * (0.9 + rand() * 0.18);
    const ry = (outer ? 0.5 : 0.34) * h * (0.9 + rand() * 0.18);
    pts.push(`${(w / 2 + Math.cos(a) * rx * 0.95).toFixed(0)},${(h / 2 + Math.sin(a) * ry * 0.95).toFixed(0)}`);
  }
  return `<svg class="burst" viewBox="-20 -20 ${w + 40} ${h + 40}"><polygon points="${pts.join(" ")}" fill="none" stroke="${LILA}" stroke-width="13" stroke-linejoin="round" filter="url(#rough)"/></svg>`;
}

const underline = (w = 330) =>
  `<svg class="uline" style="width:${w}px" viewBox="0 0 330 26"><path fill="none" stroke="${LILA}" stroke-width="9" stroke-linecap="round" filter="url(#rough)" d="M6 16 C 80 8, 200 6, 324 10 M30 20 C 120 16, 220 14, 300 15"/></svg>`;

// Distintas composiciones de esquina para que las diapositivas no se vean iguales
const corners = [
  () => doodles.loopArrow(-20, -10, 0.9, -8) + doodles.scribble(1100, 30, 1, -30) + doodles.spiral(1120, 560, 1.1, 10) + doodles.scribble(-40, 590, 1.1, 20),
  () => doodles.pencil(-30, 90, 0.85, -35) + doodles.scribble(1080, 10, 1.1, 10) + doodles.book(1090, 560, 0.85, -8),
  () => doodles.scribble(-30, 10, 1.1, 0) + doodles.loopArrow(1080, 20, 0.85, 70) + doodles.bulb(-10, 540, 0.75) + doodles.scribble(1110, 610, 1, -15),
  () => doodles.spiral(-20, 20, 1, 0) + doodles.pencil(1050, 80, 0.8, 30) + doodles.scribble(-40, 610, 1.1, 10) + doodles.spiral(1140, 590, 0.9, 120),
  () => doodles.loopArrow(1070, -20, 0.9, 80) + doodles.scribble(-50, 40, 1, -20) + doodles.loopArrow(1100, 540, 0.9, 160) + doodles.scribble(-30, 600, 1.1, 15),
];

const ICONS = { database: doodles.database, gear: doodles.gear, pin: doodles.pin, leaf: doodles.leaf, funnel: doodles.funnel, bulb: doodles.bulb, star: doodles.star };

// ── Tipos de diapositiva ─────────────────────────────────────────
function title(t, size) {
  return `<h2 class="t" style="${size ? `font-size:${size}px` : ""}">${fmt(t)}</h2>${underline()}`;
}

const render = {
  cover: (s, i, deck) => `
    ${doodles.loopArrow(40, -10, 1.1, 0)}${doodles.book(990, 10, 1.1, -12)}${doodles.bulb(30, 470, 1.15)}${doodles.loopArrow(1010, 470, 1.15, 200)}
    ${burst(deck.seed || 7)}
    <div class="cover"><h1>${fmt(s.title)}</h1>${s.subtitle ? `<p class="sub">${fmt(s.subtitle)}</p>` : ""}</div>
    <p class="byline">${fmt(deck.byline)}</p>`,

  text: (s, i) => `${corners[i % corners.length]()}
    <div class="center">${title(s.title)}
      <p class="lead">${fmt(s.text)}</p>
      ${s.note ? `<p class="note">${fmt(s.note)}</p>` : ""}</div>
    ${s.icon ? ICONS[s.icon](1140, 290, 0.72) : ""}`,

  bullets: (s, i) => `${corners[i % corners.length]()}
    <div class="frame">${title(s.title)}
      <ul class="bl ${s.cols === 2 || (s.items.length > 5 && s.cols !== 1) ? "two" : ""}">${s.items.map((x) => `<li>${fmt(x)}</li>`).join("")}</ul>
      ${s.note ? `<p class="note">${fmt(s.note)}</p>` : ""}</div>`,

  compare: (s, i) => `${corners[i % corners.length]()}
    <div class="frame">${title(s.title)}
      <div class="cmp">${s.cols.map((c) => `<div class="box"><h3>${fmt(c.title)}</h3><ul>${c.items.map((x) => `<li>${fmt(x)}</li>`).join("")}</ul></div>`).join("")}</div>
      ${s.note ? `<p class="note">${fmt(s.note)}</p>` : ""}</div>`,

  steps: (s, i) => `${corners[i % corners.length]()}
    <div class="frame">${title(s.title)}
      <div class="steps">${s.steps.map((st, k) => `${k ? `<span class="arrow">➜</span>` : ""}<div class="step"><span class="n">${k + 1}</span><h3>${fmt(st.t)}</h3><p>${fmt(st.d)}</p></div>`).join("")}</div>
      ${s.note ? `<p class="note">${fmt(s.note)}</p>` : ""}</div>`,

  code: (s, i) => `${corners[i % corners.length]()}
    <div class="frame">${title(s.title)}
      <div class="codewrap ${s.side ? "with-side" : ""}">
        <pre class="code" style="font-size:${Math.min(16, Math.floor((s.side ? 560 : 900) / (0.62 * Math.max(...s.code.trim().split("\n").map((l) => l.length)))))}px">${esc(s.code.trim())}</pre>
        ${s.side ? `<ul class="side">${s.side.map((x) => `<li>${fmt(x)}</li>`).join("")}</ul>` : ""}
      </div>
      ${s.note ? `<p class="note">${fmt(s.note)}</p>` : ""}</div>`,

  table: (s, i) => `${corners[i % corners.length]()}
    <div class="frame">${title(s.title)}
      <table class="tb"><thead><tr>${s.head.map((h) => `<th>${fmt(h)}</th>`).join("")}</tr></thead>
      <tbody>${s.rows.map((r) => `<tr>${r.map((c) => `<td>${fmt(c)}</td>`).join("")}</tr>`).join("")}</tbody></table>
      ${s.note ? `<p class="note">${fmt(s.note)}</p>` : ""}</div>`,

  section: (s, i, deck) => `${doodles.spiral(60, 60, 1.2, 0)}${doodles.scribble(1000, 80, 1.3, -20)}${doodles.pencil(880, 560, 1.1, -20)}${doodles.star(220, 560, 1.2)}${doodles.star(1040, 300, 0.8)}
    <div class="center"><h1 class="sec">${fmt(s.title)}</h1>${s.text ? `<p class="lead">${fmt(s.text)}</p>` : ""}</div>`,

  refs: (s, i) => `${corners[i % corners.length]()}
    <div class="frame">${title(s.title || "REFERENCIAS")}
      <ol class="refs">${s.items.map((x) => `<li>${fmt(x)}</li>`).join("")}</ol></div>`,

  thanks: (s, i, deck) => `
    ${doodles.loopArrow(40, -10, 1.1, 0)}${doodles.book(990, 10, 1.1, -12)}${doodles.bulb(30, 470, 1.15)}${doodles.loopArrow(1010, 470, 1.15, 200)}
    ${burst((deck.seed || 7) + 3, 640, 430)}
    <div class="cover"><h1 style="font-size:92px;line-height:.95">MUCHAS<br/>GRACIAS</h1></div>`,
};

export function buildHtml(deck) {
  const slides = deck.slides.map((s, i) => `<section class="slide">${render[s.type](s, i, deck)}</section>`).join("\n");
  return `<!doctype html><html lang="es"><head><meta charset="utf-8"/><title>${esc(deck.file)}</title>
<link href="https://fonts.googleapis.com/css2?family=Chewy&family=Mali:wght@400;500;600;700&family=JetBrains+Mono:wght@400;600&display=block" rel="stylesheet">
<style>
@page { size: 1280px 720px; margin: 0; }
* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; }
body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
.slide { position: relative; width: 1280px; height: 720px; overflow: hidden; page-break-after: always; break-after: page;
  background-color: #eeedeb; font-family: 'Mali', cursive; color: #111; }
.slide::before { content: ""; position: absolute; inset: 0; opacity: .55; pointer-events: none;
  background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='400' height='400'><filter id='n'><feTurbulence type='fractalNoise' baseFrequency='.85' numOctaves='3' stitchTiles='stitch'/><feColorMatrix values='0 0 0 0 .4  0 0 0 0 .4  0 0 0 0 .4  0 0 0 .22 0'/></filter><rect width='400' height='400' filter='url(%23n)'/></svg>"); }
.slide::after { content: ""; position: absolute; inset: 0; pointer-events: none;
  background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='1280' height='720'><g fill='%23333'><circle cx='150' cy='500' r='1.6'/><circle cx='990' cy='160' r='1.4'/><circle cx='590' cy='640' r='1.3'/><circle cx='1120' cy='460' r='1.5'/><circle cx='420' cy='110' r='1.2'/><circle cx='760' cy='380' r='1'/></g></svg>"); }
.d { position: absolute; z-index: 1; }
.burst { position: absolute; left: 50%; top: 50%; width: 800px; transform: translate(-50%, -50%) rotate(-4deg); z-index: 1; }
.cover { position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; z-index: 2; text-align: center; }
.cover h1 { font-family: 'Chewy', cursive; font-weight: 400; font-size: 64px; line-height: 1.05; margin: 0; max-width: 700px; letter-spacing: .5px; }
.cover .sub { font-size: 24px; margin: 14px 0 0; max-width: 560px; font-weight: 500; }
.byline { position: absolute; bottom: 26px; left: 0; right: 0; text-align: center; font-size: 17px; font-weight: 600; z-index: 2; color: #333; }
h2.t { font-family: 'Chewy', cursive; font-weight: 400; font-size: 52px; line-height: 1.05; margin: 0; text-align: center; letter-spacing: .5px; }
.uline { display: block; margin: 6px auto 0; }
.center { position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 0 200px; text-align: center; z-index: 2; }
.center .lead { font-size: 29px; line-height: 1.42; margin: 34px 0 0; letter-spacing: .3px; }
h1.sec { font-family: 'Chewy', cursive; font-weight: 400; font-size: 84px; margin: 0; }
.frame { position: absolute; left: 150px; right: 150px; top: 46px; bottom: 34px; z-index: 2; display: flex; flex-direction: column; }
.frame > ul.bl, .frame > .cmp, .frame > .codewrap, .frame > table.tb, .frame > ol.refs { margin-top: auto !important; margin-bottom: auto; }
.note { font-size: 20px; margin: auto 0 0; padding-top: 10px; text-align: center; color: #333; font-weight: 500; }
.center .note { margin-top: 26px; }
b { font-weight: 700; }
code { font-family: 'JetBrains Mono', monospace; font-size: .82em; background: rgba(173,158,224,.28); padding: 1px 6px; border-radius: 5px; }
ul.bl { font-size: 28px; line-height: 1.38; margin: 26px 0 0; padding-left: 34px; }
ul.bl li { margin: 0 0 14px; padding-left: 6px; }
ul.bl.two { columns: 2; column-gap: 60px; font-size: 24px; }
ul.bl.two li { break-inside: avoid; }
ul.bl li::marker, .box li::marker, .side li::marker { color: #111; }
.cmp { display: flex; gap: 34px; margin-top: 26px; }
.box { flex: 1; border: 4px solid #ad9ee0; border-radius: 22px 30px 18px 34px / 30px 18px 34px 20px; padding: 16px 22px 6px; background: rgba(255,255,255,.35); }
.box h3 { font-family: 'Chewy', cursive; font-weight: 400; font-size: 30px; margin: 0 0 8px; text-align: center; }
.box ul { font-size: 22px; line-height: 1.32; margin: 0; padding-left: 24px; }
.box li { margin: 0 0 9px; }
.steps { display: flex; align-items: stretch; gap: 10px; margin: auto 0; }
.step { flex: 1; border: 4px solid #ad9ee0; border-radius: 26px 18px 30px 20px / 18px 30px 20px 26px; padding: 30px 16px 14px; position: relative; text-align: center; background: rgba(255,255,255,.35); }
.step .n { position: absolute; top: -22px; left: 50%; transform: translateX(-50%); width: 44px; height: 44px; border-radius: 50%; background: #ad9ee0; color: #fff; font-family: 'Chewy'; font-size: 26px; display: grid; place-items: center; }
.step h3 { font-family: 'Chewy', cursive; font-weight: 400; font-size: 27px; margin: 0 0 8px; }
.step p { font-size: 20px; line-height: 1.35; margin: 0; }
.arrow { align-self: center; font-size: 34px; color: #ad9ee0; }
.codewrap { display: flex; gap: 26px; margin-top: 22px; min-height: 0; }
pre.code { flex: 1; margin: 0; font-family: 'JetBrains Mono', monospace; font-size: 16px; line-height: 1.42; background: #fbfaf7; border: 4px solid #ad9ee0;
  border-radius: 18px 26px 16px 24px / 24px 16px 26px 18px; padding: 16px 20px; white-space: pre; overflow: hidden; color: #1f1b2e; }
.side { width: 340px; flex-shrink: 0; font-size: 21px; line-height: 1.35; margin: 0; padding-left: 26px; }
.side li { margin-bottom: 12px; }
table.tb { border-collapse: separate; border-spacing: 0; margin-top: 24px; font-size: 21px; width: 100%; background: rgba(255,255,255,.35);
  border: 4px solid #ad9ee0; border-radius: 18px; overflow: hidden; }
.tb th { font-family: 'Chewy', cursive; font-weight: 400; font-size: 24px; text-align: left; padding: 10px 16px; background: rgba(173,158,224,.35); }
.tb td { padding: 9px 16px; border-top: 2px solid rgba(173,158,224,.55); vertical-align: top; line-height: 1.3; }
ol.refs { font-size: 22px; line-height: 1.4; margin: 26px 0 0; padding-left: 30px; }
ol.refs li { margin-bottom: 12px; }
</style></head><body>
<svg width="0" height="0" style="position:absolute"><filter id="rough"><feTurbulence type="fractalNoise" baseFrequency="0.035" numOctaves="2" seed="4"/><feDisplacementMap in="SourceGraphic" scale="5"/></filter></svg>
${slides}
</body></html>`;
}
