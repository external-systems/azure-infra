// Draws the slide diagrams as hand-drawn (Excalidraw-style) SVG files with
// rough.js, in the Claude colour scheme, with real product icons from
// ../icons (dashboard-icons, Apache-2.0). The SVGs are committed; run this
// only to change a diagram:
//
//   cd documentation/slides/diagrams && bun add --no-save roughjs@4.6.6 && bun generate.mjs
//
// Every diagram is 1600 x 900 on the slide's cream background, so it also
// reads on the docs' dark theme. Fixed seeds keep the output stable.
import {readFileSync, writeFileSync} from "node:fs";
import {dirname, join} from "node:path";
import {fileURLToPath} from "node:url";
import rough from "roughjs/bundled/rough.esm.js";

const here = dirname(fileURLToPath(import.meta.url));
const gen = rough.generator();

const C = {
  ink: "#141413",
  slate: "#3D3D3A",
  grey: "#87867F",
  coral: "#D97757",
  oat: "#E3DACC",
  sage: "#BCD1CA",
  heather: "#CBCADB",
  sky: "#C9DCEB",
  rose: "#EBCECE",
};
const FONT = "system-ui, -apple-system, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif";

const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

function svgPaths(drawable) {
  return gen
    .toPaths(drawable)
    .map(
      (p) =>
        `<path d="${p.d}" stroke="${p.stroke}" stroke-width="${p.strokeWidth}" fill="${p.fill || "none"}" stroke-linecap="round" stroke-linejoin="round"/>`,
    )
    .join("");
}

class Diagram {
  constructor(seed) {
    this.seed = seed;
    this.parts = [];
  }
  opts(o = {}) {
    this.seed += 1;
    return {
      seed: this.seed,
      roughness: 1.3,
      bowing: 1,
      stroke: C.ink,
      strokeWidth: 2.5,
      fillStyle: "hachure",
      hachureGap: 9,
      fillWeight: 2,
      ...o,
    };
  }
  box(x, y, w, h, o = {}) {
    this.parts.push(svgPaths(gen.rectangle(x, y, w, h, this.opts(o))));
    return this;
  }
  ellipse(cx, cy, w, h, o = {}) {
    this.parts.push(svgPaths(gen.ellipse(cx, cy, w, h, this.opts(o))));
    return this;
  }
  line(x1, y1, x2, y2, o = {}) {
    this.parts.push(svgPaths(gen.line(x1, y1, x2, y2, this.opts(o))));
    return this;
  }
  arrow(x1, y1, x2, y2, o = {}) {
    const color = o.stroke || C.slate;
    this.line(x1, y1, x2, y2, {stroke: color, strokeWidth: 3, ...o});
    const a = Math.atan2(y2 - y1, x2 - x1);
    const s = 22;
    for (const d of [0.45, -0.45]) {
      this.line(x2, y2, x2 - s * Math.cos(a + d), y2 - s * Math.sin(a + d), {stroke: color, strokeWidth: 3});
    }
    return this;
  }
  cloud(cx, cy, w, h, o = {}) {
    // A cloud from overlapping ellipses, drawn as one hachured shape.
    const pts = [];
    for (let i = 0; i < 360; i += 6) {
      const t = (i * Math.PI) / 180;
      const bump = 1 + 0.09 * Math.sin(t * 7);
      pts.push([cx + (w / 2) * bump * Math.cos(t), cy + (h / 2) * bump * Math.sin(t)]);
    }
    this.parts.push(svgPaths(gen.polygon(pts, this.opts(o))));
    return this;
  }
  text(x, y, s, o = {}) {
    const {size = 34, color = C.ink, anchor = "middle", weight = 600} = o;
    this.parts.push(
      `<text x="${x}" y="${y}" font-family="${FONT}" font-size="${size}" font-weight="${weight}" fill="${color}" text-anchor="${anchor}" dominant-baseline="middle">${esc(s)}</text>`,
    );
    return this;
  }
  icon(name, cx, cy, size = 110) {
    const data = readFileSync(join(here, "..", "icons", `${name}.svg`)).toString("base64");
    this.parts.push(
      `<image href="data:image/svg+xml;base64,${data}" x="${cx - size / 2}" y="${cy - size / 2}" width="${size}" height="${size}"/>`,
    );
    return this;
  }
  person(cx, cy, o = {}) {
    const color = o.stroke || C.ink;
    this.ellipse(cx, cy - 55, 50, 50, {fill: o.fill || C.oat, stroke: color});
    this.line(cx, cy - 30, cx, cy + 30, {stroke: color});
    this.line(cx - 35, cy - 5, cx + 35, cy - 5, {stroke: color});
    this.line(cx, cy + 30, cx - 28, cy + 75, {stroke: color});
    this.line(cx, cy + 30, cx + 28, cy + 75, {stroke: color});
    return this;
  }
  check(cx, cy, s = 40, color = C.coral) {
    this.line(cx - s, cy, cx - s / 3, cy + s * 0.7, {stroke: color, strokeWidth: 7});
    this.line(cx - s / 3, cy + s * 0.7, cx + s, cy - s * 0.8, {stroke: color, strokeWidth: 7});
    return this;
  }
  cross(cx, cy, s = 40, color = C.coral) {
    this.line(cx - s, cy - s, cx + s, cy + s, {stroke: color, strokeWidth: 7});
    this.line(cx + s, cy - s, cx - s, cy + s, {stroke: color, strokeWidth: 7});
    return this;
  }
  save(name) {
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1600 900" width="1600" height="900"><rect width="1600" height="900" rx="24" fill="#FAF9F5"/>${this.parts.join("")}</svg>\n`;
    writeFileSync(join(here, `${name}.svg`), svg);
  }
}

// 1. The move: Rackspace -> Azure (Texas)
{
  const d = new Diagram(100);
  d.box(120, 300, 380, 300, {fill: C.heather});
  d.icon("windows-11", 230, 400, 100).icon("microsoft-sql-server", 390, 400, 100);
  d.text(310, 520, "Old server");
  d.text(310, 650, "Rackspace", {size: 30, color: C.grey, weight: 500});
  d.arrow(560, 450, 860, 450, {stroke: C.coral, strokeWidth: 5});
  d.text(710, 400, "moving", {size: 30, color: C.coral});
  d.cloud(1180, 450, 560, 420, {fill: C.sky});
  d.icon("azure", 1180, 340, 110);
  d.icon("windows-11", 1100, 480, 90).icon("microsoft-sql-server", 1260, 480, 90);
  d.text(1180, 600, "Microsoft Azure");
  d.text(1180, 720, "San Antonio, Texas", {size: 30, color: C.grey, weight: 500});
  d.save("move");
}

// 2. What gets built
{
  const d = new Diagram(200);
  d.box(60, 60, 1480, 780, {fill: "none", stroke: C.grey, strokeLineDash: [14, 12]});
  d.icon("azure", 130, 120, 70).text(185, 120, "Azure, Texas", {anchor: "start", size: 30, color: C.slate});
  // firewall
  d.box(300, 230, 40, 460, {fill: C.rose});
  d.icon("azure-firewall", 320, 180, 80);
  d.text(320, 730, "Firewall", {size: 28});
  d.person(150, 470, {fill: C.oat});
  d.arrow(200, 470, 290, 470);
  d.text(150, 600, "Developers", {size: 28});
  // server
  d.box(420, 230, 560, 460, {fill: C.oat});
  d.icon("azure-vm", 520, 320, 100).icon("windows-11", 680, 320, 90).icon("microsoft-sql-server", 860, 320, 100);
  d.text(700, 420, "The server", {size: 36});
  for (const [i, label] of ["Windows", "Database", "Log"].entries()) {
    const x = 470 + i * 170;
    d.ellipse(x + 65, 520, 130, 34, {fill: C.sage});
    d.line(x, 520, x, 600).line(x + 130, 520, x + 130, 600);
    d.ellipse(x + 65, 600, 130, 34, {fill: "none"});
    d.text(x + 65, 650, label, {size: 26, weight: 500});
  }
  // backups
  d.arrow(990, 460, 1130, 460, {stroke: C.coral});
  d.box(1140, 300, 340, 320, {fill: C.sky});
  d.icon("azure-storage-accounts", 1310, 390, 100);
  d.text(1310, 490, "Backups", {size: 36});
  d.text(1310, 545, "kept 30 days", {size: 26, color: C.slate, weight: 500});
  d.text(1310, 585, "+ copy far away", {size: 26, color: C.slate, weight: 500});
  d.save("built");
}

// 3. How a change happens
{
  const d = new Diagram(300);
  const y = 380;
  d.person(160, y + 10);
  d.text(160, y + 150, "You ask", {size: 32});
  d.arrow(240, y, 380, y);
  d.box(400, y - 110, 260, 220, {fill: C.oat});
  d.icon("claude-ai", 530, y - 20, 110);
  d.text(530, y + 160, "Claude prepares", {size: 32});
  d.arrow(680, y, 820, y);
  d.box(840, y - 110, 260, 220, {fill: C.heather});
  d.icon("github", 970, y - 20, 110);
  d.text(970, y + 160, "Preview", {size: 32});
  d.arrow(1120, y, 1260, y);
  d.ellipse(1370, y, 200, 200, {fill: C.sage});
  d.check(1370, y, 45);
  d.text(1370, y + 160, "You approve", {size: 32});
  // build arrow below
  d.arrow(1370, y + 200, 1370, 690, {stroke: C.coral});
  d.box(560, 700, 900, 150, {fill: C.sky});
  d.icon("opentofu", 680, 775, 90).icon("azure", 1250, 775, 90);
  d.text(965, 775, "The robot builds it", {size: 34});
  d.save("change");
}

// 4. Blueprint, not clicking
{
  const d = new Diagram(400);
  d.box(80, 140, 640, 600, {fill: C.rose});
  d.text(400, 210, "Clicking by hand", {size: 38});
  for (let i = 0; i < 4; i++) d.box(160 + i * 25, 290 + i * 40, 380, 200, {fill: "none", stroke: C.grey});
  d.cross(400, 470, 70);
  d.text(400, 680, "Forgotten, error-prone", {size: 30, color: C.slate, weight: 500});
  d.box(880, 140, 640, 600, {fill: C.sage});
  d.text(1200, 210, "Written blueprint", {size: 38});
  d.box(960, 290, 220, 280, {fill: "#FFFFFF"});
  for (let i = 0; i < 6; i++) d.line(990, 330 + i * 38, 1150 - (i % 2) * 40, 330 + i * 38, {stroke: C.grey, strokeWidth: 2});
  d.arrow(1200, 430, 1290, 430);
  d.icon("opentofu", 1360, 400, 100);
  d.check(1360, 520, 40);
  d.text(1200, 680, "Previewed, recorded, repeatable", {size: 30, color: C.slate, weight: 500});
  d.save("blueprint");
}

// 5. Where the keys live
{
  const d = new Diagram(500);
  d.box(560, 120, 480, 660, {fill: C.oat});
  d.icon("1password", 800, 200, 110);
  d.text(800, 290, "1Password", {size: 38});
  d.box(610, 340, 380, 170, {fill: C.heather});
  d.text(800, 395, "Keys to Azure", {size: 30});
  d.text(800, 455, "only you, Andrew, the robot", {size: 24, color: C.slate, weight: 500});
  d.box(610, 560, 380, 170, {fill: C.sage});
  d.text(800, 615, "Server passwords", {size: 30});
  d.text(800, 675, "made automatically", {size: 24, color: C.slate, weight: 500});
  d.arrow(990, 425, 1180, 330, {stroke: C.coral});
  d.icon("opentofu", 1290, 300, 110);
  d.text(1290, 400, "Robot reads keys", {size: 30});
  d.arrow(990, 645, 1180, 640, {stroke: C.coral});
  d.person(1290, 640);
  d.text(1290, 770, "Developers", {size: 30});
  // left: who puts keys in
  d.person(220, 360);
  d.text(220, 490, "You, once", {size: 30});
  d.arrow(310, 425, 595, 425, {stroke: C.slate});
  d.icon("opentofu", 220, 640, 100);
  d.text(220, 730, "Robot saves", {size: 30});
  d.arrow(310, 645, 595, 645, {stroke: C.slate});
  d.save("keys");
}

// 6. Backups
{
  const d = new Diagram(600);
  d.box(80, 260, 360, 340, {fill: C.oat});
  d.icon("microsoft-sql-server", 260, 380, 120);
  d.text(260, 520, "Database", {size: 36});
  d.arrow(460, 430, 660, 430, {stroke: C.coral, strokeWidth: 4});
  d.text(560, 380, "automatic", {size: 28, color: C.coral});
  d.box(680, 260, 360, 340, {fill: C.sky});
  d.icon("azure-storage-accounts", 860, 370, 110);
  d.text(860, 500, "Backups, Texas", {size: 34});
  d.text(860, 550, "30 days", {size: 28, color: C.slate, weight: 500});
  d.arrow(1060, 430, 1160, 430, {stroke: C.slate, strokeWidth: 4});
  d.box(1180, 260, 360, 340, {fill: C.sky});
  d.icon("azure-storage-accounts", 1360, 370, 110);
  d.text(1360, 500, "Copy, Illinois", {size: 34});
  d.text(1360, 550, "if Texas is down", {size: 28, color: C.slate, weight: 500});
  d.text(800, 740, "Get the database back as it was at any minute", {size: 34, color: C.ink});
  d.save("backups");
}

// 7. Letting a developer in
{
  const d = new Diagram(700);
  d.person(180, 430);
  d.text(180, 570, "Abdus", {size: 34});
  d.icon("azure-virtual-desktop", 180, 680, 90);
  d.arrow(260, 420, 560, 420, {stroke: C.coral, strokeWidth: 4});
  d.box(580, 200, 70, 460, {fill: C.rose});
  d.icon("azure-firewall", 615, 150, 80);
  d.text(615, 710, "Guest list", {size: 30});
  d.arrow(670, 420, 960, 420, {stroke: C.coral, strokeWidth: 4});
  d.box(980, 260, 440, 320, {fill: C.oat});
  d.icon("azure-vm", 1100, 380, 100).icon("windows-11", 1300, 380, 90);
  d.text(1200, 500, "The server", {size: 34});
  d.icon("1password", 1200, 720, 80);
  d.text(1200, 800, "Login from 1Password", {size: 28, color: C.slate, weight: 500});
  d.arrow(1200, 680, 1200, 600, {stroke: C.slate});
  d.save("remote");
}

// 8. Just ask
{
  const d = new Diagram(800);
  d.icon("claude-ai", 800, 450, 170);
  const qs = [
    [380, 200, "Add my developer Abdus"],
    [1220, 200, "More disk space?"],
    [380, 700, "Restore a backup"],
    [1220, 700, "Remove it all (Kubernetes)"],
  ];
  for (const [x, y, q] of qs) {
    d.box(x - 290, y - 70, 580, 140, {fill: C.oat});
    d.text(x, y, q, {size: 34});
    d.arrow(x + (x < 800 ? 200 : -200), y + (y < 450 ? 80 : -80), 800 + (x < 800 ? -110 : 110), 450 + (y < 450 ? -60 : 60), {stroke: C.grey});
  }
  d.save("ask");
}

// 9. Your part
{
  const d = new Diagram(900);
  const items = [
    [300, "azure", "Make the Azure account", "with your card"],
    [800, "1password", "Put the codes in 1Password", "no typing passwords"],
    [1300, "github", "Click Approve", "when it looks right"],
  ];
  for (const [x, ic, a, b] of items) {
    d.ellipse(x, 360, 300, 300, {fill: C.oat});
    d.icon(ic, x, 360, 140);
    d.text(x, 580, a, {size: 34});
    d.text(x, 635, b, {size: 28, color: C.slate, weight: 500});
  }
  d.arrow(470, 360, 630, 360, {stroke: C.coral}).arrow(970, 360, 1130, 360, {stroke: C.coral});
  d.text(800, 780, "Everything else: Andrew, Claude and the robot", {size: 32, color: C.coral});
  d.save("your-part");
}

// 10. Cost
{
  const d = new Diagram(1000);
  d.text(800, 170, "About $385 a month", {size: 64, weight: 700});
  const parts = [
    ["Server + Windows", 275, C.oat],
    ["SQL license", 25, C.heather],
    ["Disks", 78, C.sage],
    ["Backups, address", 9, C.sky],
  ];
  let x = 140;
  const total = 387;
  const W = 1320;
  for (const [label, v, fill] of parts) {
    const w = Math.max((v / total) * W, 70);
    d.box(x, 330, w - 10, 180, {fill});
    d.text(x + (w - 10) / 2, 420, `$${v}`, {size: w > 120 ? 40 : 26});
    d.text(x + (w - 10) / 2, 570, label, {size: w > 200 ? 30 : 22, weight: 500, color: C.slate});
    x += w;
  }
  d.icon("azure-cost-management", 800, 730, 100);
  d.text(800, 820, "Smaller server: about $240", {size: 30, color: C.slate, weight: 500});
  d.save("cost");
}
