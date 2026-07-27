const fs = require("fs");
const path = require("path");
const sharp = require("sharp");

const WIDTH = 1290;
const HEIGHT = 2796;
const OUTPUT_DIR = path.join(process.cwd(), "AppStore", "ru", "screenshots");
const DOWNLOADS = "/Users/aleksejmotorin/Downloads";
const backgroundPath = path.join(DOWNLOADS, "LaunchImage.png");

fs.mkdirSync(OUTPUT_DIR, { recursive: true });

const escapeXml = (value) =>
  value.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

function textSvg(title, subtitle, options = {}) {
  const y = options.y ?? 132;
  const titleSize = options.titleSize ?? 78;
  const subtitleSize = options.subtitleSize ?? 37;
  const align = options.align ?? "middle";
  const x = align === "middle" ? WIDTH / 2 : 86;
  const anchor = align === "middle" ? "middle" : "start";

  return Buffer.from(`
    <svg width="${WIDTH}" height="${HEIGHT}" xmlns="http://www.w3.org/2000/svg">
      <style>
        .title {
          font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", Arial, sans-serif;
          font-size: ${titleSize}px;
          font-weight: 750;
          fill: #ffffff;
        }
        .subtitle {
          font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", Arial, sans-serif;
          font-size: ${subtitleSize}px;
          font-weight: 520;
          fill: #b9c8dd;
        }
      </style>
      <text x="${x}" y="${y + titleSize}" text-anchor="${anchor}" class="title">${escapeXml(title)}</text>
      <text x="${x}" y="${y + titleSize + 76}" text-anchor="${anchor}" class="subtitle">${escapeXml(subtitle)}</text>
    </svg>
  `);
}

async function background() {
  return sharp(backgroundPath)
    .resize(WIDTH, HEIGHT, { fit: "cover" })
    .modulate({ brightness: 0.72, saturation: 0.9 })
    .blur(1.2)
    .composite([
      {
        input: Buffer.from(
          `<svg width="${WIDTH}" height="${HEIGHT}" xmlns="http://www.w3.org/2000/svg">
            <rect width="100%" height="100%" fill="#061326" opacity="0.34"/>
          </svg>`
        ),
      },
    ])
    .png()
    .toBuffer();
}

async function roundedImage(inputPath, width, height, radius = 48) {
  const image = await sharp(inputPath)
    .resize(width, height, { fit: "contain", background: "#0b1729" })
    .png()
    .toBuffer();
  const mask = Buffer.from(
    `<svg width="${width}" height="${height}" xmlns="http://www.w3.org/2000/svg">
      <rect width="${width}" height="${height}" rx="${radius}" fill="white"/>
    </svg>`
  );
  return sharp(image)
    .composite([{ input: mask, blend: "dest-in" }])
    .png()
    .toBuffer();
}

function frameSvg(x, y, width, height, radius = 54) {
  return Buffer.from(
    `<svg width="${WIDTH}" height="${HEIGHT}" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <filter id="shadow" x="-30%" y="-30%" width="160%" height="160%">
          <feDropShadow dx="0" dy="24" stdDeviation="28" flood-color="#000814" flood-opacity="0.7"/>
        </filter>
      </defs>
      <rect x="${x - 5}" y="${y - 5}" width="${width + 10}" height="${height + 10}"
        rx="${radius + 4}" fill="#263a55" stroke="#5d7393" stroke-width="3" filter="url(#shadow)"/>
    </svg>`
  );
}

async function makePortraitPreview(
  number,
  sourceName,
  title,
  subtitle,
  titleSize = 78
) {
  const base = await background();
  const imageWidth = 1010;
  const imageHeight = 2190;
  const x = Math.round((WIDTH - imageWidth) / 2);
  const y = 490;
  const screenshot = await roundedImage(
    path.join(DOWNLOADS, sourceName),
    imageWidth,
    imageHeight
  );

  await sharp(base)
    .composite([
      { input: textSvg(title, subtitle, { titleSize }), left: 0, top: 0 },
      { input: frameSvg(x, y, imageWidth, imageHeight), left: 0, top: 0 },
      { input: screenshot, left: x, top: y },
    ])
    .removeAlpha()
    .png({ compressionLevel: 9 })
    .toFile(path.join(OUTPUT_DIR, `${number}.png`));
}

async function makeCover() {
  const cover = await sharp(backgroundPath)
    .resize(WIDTH, HEIGHT, { fit: "cover" })
    .modulate({ brightness: 0.84, saturation: 1.05 })
    .png()
    .toBuffer();

  await sharp(cover)
    .composite([
      {
        input: textSvg(
          "Гриф. Аккорды. Гармония.",
          "Музыкальная карта для гитариста",
          { y: 150, titleSize: 76 }
        ),
      },
    ])
    .removeAlpha()
    .png({ compressionLevel: 9 })
    .toFile(path.join(OUTPUT_DIR, "01-cover.png"));
}

function featureSvg() {
  const labels = [
    ["Ноты и ступени", 120],
    ["Цветовая карта", 470],
    ["Любой строй", 820],
  ];
  return Buffer.from(`
    <svg width="${WIDTH}" height="${HEIGHT}" xmlns="http://www.w3.org/2000/svg">
      <style>
        .feature {
          font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", Arial, sans-serif;
          font-size: 35px;
          font-weight: 650;
          fill: #ffffff;
        }
      </style>
      ${labels
        .map(
          ([label, x]) => `
            <rect x="${x}" y="1525" width="300" height="108" rx="28"
              fill="#263956" fill-opacity="0.88" stroke="#607796" stroke-width="2"/>
            <text x="${x + 150}" y="1593" text-anchor="middle" class="feature">${label}</text>
          `
        )
        .join("")}
      <text x="645" y="1910" text-anchor="middle"
        font-family="-apple-system, BlinkMacSystemFont, 'SF Pro Display', Arial, sans-serif"
        font-size="64" font-weight="750" fill="#ffffff">Изучай гриф визуально</text>
      <text x="645" y="1980" text-anchor="middle"
        font-family="-apple-system, BlinkMacSystemFont, 'SF Pro Text', Arial, sans-serif"
        font-size="38" font-weight="520" fill="#b9c8dd">В портретном и горизонтальном режиме</text>
    </svg>
  `);
}

async function makeFretboardPreview() {
  const base = await background();
  const imageWidth = 1150;
  const imageHeight = 531;
  const x = 70;
  const y = 610;
  const screenshot = await roundedImage(
    path.join(DOWNLOADS, "IMG_2675.PNG"),
    imageWidth,
    imageHeight,
    38
  );

  const logo = await sharp(backgroundPath)
    .extract({ left: 170, top: 480, width: 600, height: 620 })
    .resize(620, 640, { fit: "contain" })
    .png()
    .toBuffer();

  await sharp(base)
    .composite([
      {
        input: textSvg(
          "Весь гриф перед глазами",
          "Ноты, ступени и интервалы — без лишних расчётов",
          { y: 135, titleSize: 72 }
        ),
        left: 0,
        top: 0,
      },
      { input: frameSvg(x, y, imageWidth, imageHeight, 42), left: 0, top: 0 },
      { input: screenshot, left: x, top: y },
      { input: featureSvg(), left: 0, top: 0 },
      { input: logo, left: 335, top: 2010 },
    ])
    .removeAlpha()
    .png({ compressionLevel: 9 })
    .toFile(path.join(OUTPUT_DIR, "02-fretboard.png"));
}

async function validateOutputs() {
  const files = fs
    .readdirSync(OUTPUT_DIR)
    .filter((file) => file.endsWith(".png"))
    .sort();
  for (const file of files) {
    const metadata = await sharp(path.join(OUTPUT_DIR, file)).metadata();
    if (
      metadata.width !== WIDTH ||
      metadata.height !== HEIGHT ||
      metadata.hasAlpha
    ) {
      throw new Error(`Invalid App Store image: ${file}`);
    }
  }
  return files;
}

async function main() {
  await makeCover();
  await makeFretboardPreview();
  await makePortraitPreview(
    "03-chords",
    "IMG_2676.PNG",
    "Находи нужную аппликатуру",
    "Основные формы, обращения и состав аккорда"
  );
  await makePortraitPreview(
    "04-harmony",
    "IMG_2674.PNG",
    "Создавай гармонию",
    "Популярные прогрессии, избранное и воспроизведение"
  );
  await makePortraitPreview(
    "05-navigation",
    "IMG_2673.PNG",
    "Всё для практики — в одном месте",
    "Аккорды, лады и гармония",
    58
  );
  const files = await validateOutputs();
  console.log(files.join("\n"));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
