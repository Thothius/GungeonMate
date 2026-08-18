#version 460 core

// =============================================================================
// Gungeon Digital Rain — purple Matrix-style falling glyph columns.
// Q3 Ambient Fragment Shader (genius audit v0.0.7).
//
// Procedural — no textures needed. Each column has a deterministic
// speed, offset, and brightness via hash functions. The "head" of each
// column is brighter (white-purple) and the trail fades behind it.
//
// Uniforms:
//   uResolution — canvas size in pixels
//   uTime       — elapsed seconds (drives the fall animation)
// =============================================================================

uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

// --- Hash functions for per-column determinism ------------------------------

float hash11(float n) {
  return fract(sin(n) * 43758.5453123);
}

float hash12(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// --- Main -------------------------------------------------------------------

void main() {
  vec2 uv = gl_FragCoord.xy / uResolution.xy;

  // Column grid — ~40 columns across the screen width.
  float columns = 40.0;
  float col = floor(uv.x * columns);

  // Per-column deterministic speed + offset.
  float speed  = 0.3 + hash11(col * 0.7) * 0.7;  // 0.3–1.0
  float offset = hash11(col * 1.3) * 10.0;       // 0–10

  // Falling y-position: wraps in [0, 1+trail).
  float trail = 0.15;
  float y = fract(uv.y + uTime * speed * 0.5 + offset);

  // Brightness: bright at the head (y near 1.0), fading behind.
  // Head is at y=1.0 (top of the wrap), trail extends downward.
  float head = smoothstep(1.0 - 0.02, 1.0, y);
  float body = smoothstep(1.0 - trail, 1.0 - 0.02, y) * (1.0 - head);
  float fade = body * 0.6;

  // Per-column flicker — glyphs pulse subtly.
  float flicker = 0.85 + 0.15 * sin(uTime * 8.0 + col * 2.7);

  // Brightness combines head + body + flicker.
  float brightness = (head + fade) * flicker;

  // Purple Gungeon palette:
  //   Head (brightest) — white-purple (0xFFE0FF)
  //   Body             — purple (0xFFBCA0F8 → 0xFF9D5CDB)
  vec3 headColor = vec3(0.88, 0.75, 1.0);       // white-purple
  vec3 bodyColor = vec3(0.74, 0.63, 0.97);       // purple
  vec3 trailColor = vec3(0.62, 0.36, 0.86);      // deep purple

  vec3 color = mix(trailColor, bodyColor, fade / 0.6);
  color = mix(color, headColor, head);

  // Alpha — low overall so the shader reads as ambient, not foreground.
  // Head is more opaque, body/trail much less.
  float alpha = brightness * 0.35;

  // Column-level variation — some columns are dimmer (sparse rain).
  float colDim = 0.5 + 0.5 * hash11(col * 3.1);
  alpha *= colDim;

  fragColor = vec4(color * brightness, alpha);
}
