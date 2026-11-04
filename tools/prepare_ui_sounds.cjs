// Local PCM synthesis for click variants/back, and bounded peak normalization.
// No downloads, microphone, user data or runtime generation.
const fs = require('node:fs');
const path = require('node:path');
const root = path.join(__dirname, '../assets/sounds');
const rate = 44100;
function wav(samples, sampleRate = rate, peakLevel = .92) {
  const out = Buffer.alloc(44 + samples.length * 2);
  out.write('RIFF'); out.writeUInt32LE(out.length - 8, 4); out.write('WAVEfmt ', 8);
  out.writeUInt32LE(16, 16); out.writeUInt16LE(1, 20); out.writeUInt16LE(1, 22);
  out.writeUInt32LE(sampleRate, 24); out.writeUInt32LE(sampleRate * 2, 28);
  out.writeUInt16LE(2, 32); out.writeUInt16LE(16, 34); out.write('data', 36);
  out.writeUInt32LE(samples.length * 2, 40);
  let peak = 0;
  for (const sample of samples) peak = Math.max(peak, Math.abs(sample));
  const gain = peak > 0 ? peakLevel / peak : 1;
  samples.forEach((sample, index) => out.writeInt16LE(
    peakLevel === .85 ? Math.round(sample / (peak || 1) * .85 * 32767) : Math.round(sample * gain * 32767), 44 + index * 2));
  return out;
}
for (let variant = 1; variant <= 4; variant++) {
  let seed = variant * 173, low = 0;
  const samples = Array.from({length: Math.round(rate * .085)}, (_, i) => {
    const t = i / rate;
    seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
    low += .24 * ((seed / 2147483648 - 1) - low);
    const envelope = (1 - Math.exp(-t * 2200)) * Math.exp(-t * 75) * Math.min(1, (.085 - t) / .012);
    return envelope * (.6 * Math.sin(2 * Math.PI * (920 + variant * 38) * t) + low * .25);
  });
  fs.writeFileSync(path.join(root, `tap_${variant}.wav`), wav(samples));
}
const back = Array.from({length: Math.round(rate * .18)}, (_, i) => {
  const t = i / rate;
  const envelope = Math.min(1, t / .008) * Math.exp(-t * 16) * Math.min(1, (.18 - t) / .025);
  // Descending two-tone cue, intentionally distinct from the short click family.
  const phase = 2 * Math.PI * (740 * t - 1100 * t * t);
  return envelope * (Math.sin(phase) + .25 * Math.sin(phase / 2));
});
fs.writeFileSync(path.join(root, 'back.wav'), wav(back));
for (let variant = 1; variant <= 4; variant++) {
  const frequency = 430 + variant * 19;
  const samples = Array.from({length: Math.round(rate * .105)}, (_, i) => {
    const t = i / rate;
    const envelope = Math.min(1, t / .003) * Math.exp(-t * 55) * Math.min(1, (.105 - t) / .015);
    // Warm rounded pluck, lower and less metallic than the existing menu clicks.
    const phase = 2 * Math.PI * frequency * t;
    return envelope * (Math.sin(phase) + .18 * Math.sin(phase * 2) + .06 * Math.sin(phase * 3));
  });
  fs.writeFileSync(path.join(root, `click_${variant}.wav`), wav(samples));
}
for (const name of ['typing', 'success', 'photo', 'warning']) {
  const file = path.join(root, `${name}.wav`);
  const bytes = fs.readFileSync(file);
  let data = null;
  for (let offset = 12; offset + 8 <= bytes.length;) {
    const size = bytes.readUInt32LE(offset + 4);
    if (bytes.toString('ascii', offset, offset + 4) === 'data') { data = {offset: offset + 8, size}; break; }
    offset += 8 + size + size % 2;
  }
  if (!data || bytes.readUInt16LE(20) !== 1 || bytes.readUInt16LE(34) !== 16) throw Error('Expected PCM16');
  const samples = Array.from({length: data.size / 2}, (_, i) => bytes.readInt16LE(data.offset + i * 2) / 32768);
  let peak = 0;
  for (const sample of samples) peak = Math.max(peak, Math.abs(sample));
  fs.writeFileSync(file, wav(samples, bytes.readUInt32LE(24)));
  console.log(`${name}: previous peak ${peak.toFixed(4)}, normalized peak 0.92`);
}
for (let variant = 1; variant <= 3; variant++) {
  // Selected by the user: Retro 6/7/8, previously C086/C087/C088.
  const v = (variant + 4) / 7;
  const length = .11;
  const samples = Array.from({length: Math.round(rate * length)}, (_, i) => {
    const t = i / rate;
    const envelope = Math.min(1, t / (.0005 + v * .002)) * Math.exp(-t * (35 + v * 55)) * Math.min(1, (length - t) / .01);
    const tone = hz => Math.sin(2 * Math.PI * hz * t);
    return envelope * (Math.tanh(tone(360 + v * 800) * 2) * .5 + tone(180 + v * 200) * .2);
  });
  fs.writeFileSync(path.join(root, `press_${variant}.wav`), wav(samples, rate, .85));
}
console.log('Three selected Retro 6/7/8 press variants (110 ms, peak 0.85); menu/back unchanged.');
