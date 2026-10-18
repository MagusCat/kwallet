// Export actual app pixels for phone review. Requires ImageMagick, no packages.
import { spawnSync } from 'node:child_process';
import { copyFileSync, mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
mkdirSync(root + 'docs-ia/art', { recursive: true });
function magick(args) {
  const result = spawnSync('magick', args, { cwd: root, encoding: 'utf8' });
  if (result.status !== 0) throw new Error(result.stderr);
}
const originalPets = [
  ['Gato original', 'assets/pets/cat.png'], ['Gato bebé', 'assets/pets/cat_baby.png'],
  ['Rata', 'assets/pets/rat.png'], ['Rata bebé', 'assets/pets/rat_baby.png'],
  ['Mapache', 'assets/pets/raccoon.png'], ['Mapache bebé', 'assets/pets/raccoon_baby.png'],
];
const newPets = [
 ['Zarigüeya', 'assets/pets/opossum.png'], ['Zarigüeya bebé', 'assets/pets/opossum_baby.png'],
 ['Roca', 'assets/pets/rock.png'], ['Piedrita', 'assets/pets/rock_baby.png'],
 ['Planta', 'assets/pets/plant.png'], ['Brote', 'assets/pets/plant_baby.png'],
];
for (const [suffix, pets] of [['', originalPets], ['-new', newPets]]) {
for (const dark of [true, false]) {
  const args = ['-size', '600x710', `xc:${dark ? '#0c0e10' : '#f2efe8'}`,
    '-font', 'DejaVu-Sans', '-fill', dark ? '#e0e0e0' : '#2f2f2e',
    '-pointsize', '24', '-draw', 'text 24,36 "Atlas · píxeles de la app"'];
  pets.forEach(([name, asset], index) => {
    const x = (index % 2) * 300, y = 62 + Math.floor(index / 2) * 210;
    args.push('-pointsize', '20', '-draw', `text ${x + 22},${y + 24} "${name}"`);
    [[0, 0, 'Reposo'], [4, 2, 'Caminar']].forEach(([row, frame, label], state) => {
      // The full cell keeps ears and tails visible. Nearest-neighbor only.
      args.push('(', asset, '-crop', `32x32+${frame * 32}+${row * 32}`, '+repage',
        '-filter', 'point', '-resize', '400%', ')', '-geometry',
        `+${x + 10 + state * 146}+${y + 28}`, '-composite', '-pointsize', '17',
        '-draw', `text ${x + 42 + state * 146},${y + 179} "${label}"`);
    });
  });
  args.push(`docs-ia/art/pet-atlas-mobile${suffix}${dark ? '' : '-light'}.png`);
  magick(args);
}
copyFileSync(root + 'docs-ia/art/pet-atlas-mobile-light.png', root + 'docs-ia/art/pet-atlas-comparison.png');
// An animated alternative to the local HTML page, using the app's sequences.
const temp = '/tmp/kwall-pet-gif' + suffix;
mkdirSync(temp, { recursive: true });
const timeline = [[0, 4, 32, 'Reposo'], [4, 8, 12, 'Caminar'],
  [5, 8, 9, 'Correr'], [8, 7, 10, 'Celebrar'], [6, 4, 42, 'Dormir']];
const output = ['-loop', '0'];
let number = 0;
for (const [row, count, delay, label] of timeline) {
  for (let frame = 0; frame < count; frame++) {
    const args = ['-size', '480x760', 'xc:#0c0e10', '-font', 'DejaVu-Sans',
      '-fill', '#e0e0e0', '-pointsize', '24', '-draw', `text 24,34 "${label}"`];
    pets.forEach(([name, asset], index) => {
      const x = (index % 2) * 240, y = 54 + Math.floor(index / 2) * 230;
      args.push('-pointsize', '17', '-draw', `text ${x + 16},${y + 24} "${name}"`,
        '(', asset, '-crop', `32x32+${frame * 32}+${row * 32}`, '+repage',
        '-filter', 'point', '-resize', '600%', ')', '-geometry',
        `+${x + 24}+${y + 24}`, '-composite');
    });
    const path = `${temp}/${number++}.png`;
    magick([...args, path]);
    output.push('-delay', String(delay), path);
  }
}
magick([...output, '-layers', 'Optimize', `docs-ia/art/pet-atlas-mobile${suffix}.gif`]);
}
console.log('Exported dark/light PNG comparisons and animated GIF.');
