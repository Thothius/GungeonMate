#version 460 core

// =============================================================================
// Dark Neon Fog — ambient purple-black fog with slow-churning noise.
// Q3 Ambient Fragment Shader (genius audit v0.0.7).
//
// Procedural value-noise fog that drifts slowly. Purple-tinted to match
// the Gungeon aesthetic. Very low opacity — reads as atmosphere, not
// foreground. Pairs well with the digital rain shader (rain on top,
// fog behind).
//
// Uniforms:
//   uResolution — canvas size in pixels
//   uTime       — elapsed seconds (drives the drift)
// =============================================================================

uniform vec2 uResolution;
uniform float uTime;

out vec4 fragColor;

// --- Value noise ------------------------------------------------------------

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(
    mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
    mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
    u.y
  );
}

// Fractal Brownian Motion — layered noise for organic fog.
float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 4; i++) {
    v += a * noise(p);
    p *= 2.0;
    a *= 0.5;
  }
  return v;
}

// --- Main -------------------------------------------------------------------

void main() {
  vec2 uv = gl_FragCoord.xy / uResolution.xy;

  // Slow drift — fog moves diagonally over ~30s cycles.
  vec2 drift = vec2(uTime * 0.03, uTime * 0.02);

  // Scale noise to screen — 3 octaves of detail.
  float n = fbm(uv * 3.0 + drift);

  // Second noise layer at different scale for depth.
  float n2 = fbm(uv * 6.0 - drift * 1.5);

  // Combine — n is the broad fog, n2 adds fine detail.
  float fog = n * 0.7 + n2 * 0.3;

  // Purple Gungeon palette:
  //   Deep fog — dark purple (0xFF2A1A3E)
  //   Bright pockets — purple (0xFF6A4C9C)
  vec3 deepColor = vec3(0.16, 0.10, 0.24);
  vec3 brightColor = vec3(0.42, 0.30, 0.61);

  vec3 color = mix(deepColor, brightColor, fog);

  // Very low opacity — this is atmosphere, not a foreground layer.
  // Peak brightness ~0.15 alpha, average ~0.08.
  float alpha = fog * 0.15;

  fragColor = vec4(color, alpha);
}
