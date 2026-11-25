// Genera los PDF de las presentaciones de investigación.
// Uso:  node slides/build.mjs            (todas)
//       node slides/build.mjs etl-        (solo las que empiezan por "etl-")
// Requiere Google Chrome (o Edge) instalado; usa su modo headless para imprimir a PDF.
import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";
import { fileURLToPath, pathToFileURL } from "node:url";
import { buildHtml } from "./theme.mjs";
import decks from "./decks/index.mjs";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, "..");
const outHtml = path.join(here, ".build");
fs.mkdirSync(outHtml, { recursive: true });

const browsers = [
  process.env.CHROME_PATH,
  "C:/Program Files/Google/Chrome/Application/chrome.exe",
  "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
  "/usr/bin/google-chrome",
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
].filter(Boolean);
const chrome = browsers.find((b) => fs.existsSync(b));
if (!chrome) throw new Error("No se encontró Chrome/Edge. Define CHROME_PATH.");

const filter = process.argv[2] ?? "";
for (const deck of decks.filter((d) => d.file.startsWith(filter))) {
  const html = path.join(outHtml, `${deck.file}.html`);
  fs.writeFileSync(html, buildHtml(deck));
  const pdf = path.join(root, "public", deck.out, `${deck.file}.pdf`);
  fs.mkdirSync(path.dirname(pdf), { recursive: true });
  execFileSync(chrome, [
    "--headless=new", "--disable-gpu", "--no-pdf-header-footer", "--no-first-run",
    `--user-data-dir=${path.join(outHtml, "chrome-profile")}`,
    "--virtual-time-budget=10000", `--print-to-pdf=${pdf}`, pathToFileURL(html).href,
  ], { stdio: "ignore", timeout: 90000 });
  console.log(`✔ ${deck.out}/${deck.file}.pdf (${deck.slides.length} diapositivas)`);
}
