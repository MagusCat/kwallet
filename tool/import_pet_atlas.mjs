import { spawnSync } from 'node:child_process';
import { writeFileSync, unlinkSync } from 'node:fs';

const [source, destination, maxWidth = '22', maxHeight = '21', orientation = 'rows', paletteName = 'pet'] = process.argv.slice(2);
const palettes = {
  pet: ['2f2f2e','777777','b5b5b5','e0e0e0','de7586'],
  rock: ['2f2f2e','777777','b5b5b5'],
  plant: ['2f2f2e','855641','bc7956','dca27d','49684b','7da66b','e0e0e0'],
};
const palette = palettes[paletteName].map(hex=>[0,2,4].map(i=>parseInt(hex.slice(i,i+2),16)));
const flatColor = (r,g,b) => palette.reduce((best,c)=>{
  const distance = p => (r-p[0])**2+(g-p[1])**2+(b-p[2])**2;
  return distance(c)<distance(best)?c:best;
});
const run = args => {
  const result = spawnSync('magick', args, { maxBuffer: 64 * 1024 * 1024 });
  if (result.status) throw new Error(result.stderr.toString());
  return result.stdout;
};
const [width, height] = run(['identify', '-format', '%w %h', source]).toString().split(' ').map(Number);
const data = run([source, '-depth', '8', 'rgba:-']);
const solid = (x, y) => {
  const i = (y * width + x) * 4;
  return data[i + 3] >= 200;
};
function bands(counts, minimum, merge = 10) {
  const result = [];
  let start;
  for (let i = 0; i <= counts.length; i++) {
    if (counts[i] >= minimum) start ??= i;
    else if (start !== undefined) {
      if (i - start > 3) {
        if (result.length && start - result.at(-1)[1] <= merge) result.at(-1)[1] = i;
        else result.push([start, i]);
      }
      start = undefined;
    }
  }
  return result;
}
const counts = Array(height).fill(0);
for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) if (solid(x, y)) counts[y]++;
const rows = bands(counts, 20).map(([a,b]) => [Math.max(0,a-8),Math.min(height,b+8)]);
const frames = rows.map(([top,bottom],row) => {
  const counts = Array(width).fill(0);
  for(let x=0;x<width;x++)for(let y=top;y<bottom;y++)if(solid(x,y))counts[x]++;
  const columns = bands(counts, 3, 1);
  const expected = orientation==='transpose'?10:8;
  while(columns.length > expected){
    let closest=0;
    for(let i=1;i<columns.length-1;i++)if(columns[i+1][0]-columns[i][1]<columns[closest+1][0]-columns[closest][1])closest=i;
    columns.splice(closest,2,[columns[closest][0],columns[closest+1][1]]);
  }
  // A reviewed source may omit a trailing pose. Explicitly opt in to hold it.
  if(process.env.PET_HOLD_LAST_ROW === String(row) && columns.length === expected-1) {
    columns.push([...columns.at(-1)]);
  }
  if(columns.length !== expected)throw new Error(`Row${row}: ${columns.length}columns ${JSON.stringify(columns)}`);
  return columns.map(([a,b])=>{
    let left=width,right=0,t=height,bot=0;
    for(let y=top;y<bottom;y++)for(let x=Math.max(0,a-5);x<Math.min(width,b+5);x++)if(solid(x,y)){
      left=Math.min(left,x);right=Math.max(right,x+1);t=Math.min(t,y);bot=Math.max(bot,y+1);
    }
    return {left,top:t,width:right-left,height:bot-t};
  });
});
if(orientation==='rows'&&frames.length!==10)throw Error(`Expected10 rows, found${frames.length}`);
if(orientation==='transpose'&&frames.length<8)throw Error('Need8 source animation frames');
const scale = Math.min(Number(maxWidth)/Math.max(...frames.flat().map(f=>f.width)),Number(maxHeight)/Math.max(...frames.flat().map(f=>f.height)));
const out = Buffer.alloc(256*320*4);
for(let row=0;row<10;row++)for(let col=0;col<8;col++){
  const sourceRow=orientation==='nine'?[0,1,2,3,4,4,5,6,7,8][row]:row;
  const sourceCol=orientation==='nine'&&row===5?[0,2,4,6,0,2,4,6][col]:col;
  const f=orientation==='transpose'?frames[col][row]:frames[sourceRow][sourceCol];
  const w=Math.round(f.width*scale),h=Math.round(f.height*scale);
  // Retain the generated jump arc instead of grounding every airborne pose.
  const rowFrames = orientation==='transpose' ? frames.map(r=>r[row]) : frames[sourceRow];
  const baseline = Math.max(...rowFrames.map(p=>p.top+p.height));
  const lift = Math.min(row===8?4:row===5?2:0, Math.max(0,Math.round((baseline-f.top-f.height)*scale)));
  const ox=col*32+Math.floor((32-w)/2),oy=row*32+29-h-lift;
  for(let y=0;y<h;y++)for(let x=0;x<w;x++){
    const sx=f.left+Math.min(f.width-1,Math.floor((x+.5)*f.width/w));
    const sy=f.top+Math.min(f.height-1,Math.floor((y+.5)*f.height/h));
    if(!solid(sx,sy))continue;
    const si=(sy*width+sx)*4,di=((oy+y)*256+ox+x)*4;
    // Point sampling plus nearest flat swatch: no averaging, dithering or thickening.
    const color = flatColor(data[si],data[si+1],data[si+2]);
    out[di]=color[0];out[di+1]=color[1];out[di+2]=color[2];out[di+3]=255;
  }
}
writeFileSync(destination+'.rgba',out);
run(['-size','256x320','-depth','8','rgba:'+destination+'.rgba','-define','png:color-type=6',destination]);
unlinkSync(destination+'.rgba');
console.log(JSON.stringify({destination,sourceRows:rows.length,sourceColumns:frames[0].length,scale}));
