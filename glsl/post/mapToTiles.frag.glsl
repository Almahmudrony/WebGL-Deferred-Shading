#version 100
precision highp float;
precision highp int;

uniform float u_nlights;
uniform float u_ntiles;
uniform vec2 u_tilesize;
uniform vec2 u_resolution;
uniform mat4 u_viewMat;
uniform mat4 u_projMat;
uniform sampler2D u_lightbuffer;
varying vec2 v_uv;

bool inBound(vec2 min1, vec2 max1, vec2 pt) {
  return (min1.x < pt.x && pt.x <= max1.x && min1.y < pt.y && pt.y <= max1.y);
}

bool intersect(vec2 min1, vec2 max1, vec2 min2, vec2 max2) {
  return (
    inBound(min1, max1, vec2(min2.x, min2.y)) ||
    inBound(min1, max1, vec2(min2.x, max2.y)) ||
    inBound(min1, max1, vec2(max2.x, min2.y)) ||
    inBound(min1, max1, vec2(max2.x, max2.y))
  );
}

void main() {
  float l4idx = ceil(v_uv.x * u_nlights);
  float t_idx = ceil(v_uv.y * u_ntiles);

  if (t_idx >= u_ntiles) return;

  // ivec2 tileDim = int(ceil(u_resolution / u_tilesize));
  // int tx = int(mod(t_idx, int(tileDim.x)));
  float tilesX = ceil(u_resolution.x / u_tilesize.x);
  // int tx = t_idx - tilesX * t_idx / tilesX;
  // int ty = t_idx / tilesX;

  vec2 t_xy = vec2(t_idx - tilesX * floor(t_idx / tilesX), floor(t_idx / tilesX));

  vec2 min = t_xy * u_tilesize;
  vec2 max = min + u_tilesize;

  vec4 col = vec4(0.0, 0.0, 0.0, 0.0);

  for (float i = 0.0; i < 4.0; i += 1.0) {
    float l_idx = l4idx * 4.0 + i;
    if (l_idx >= u_nlights) continue;

    vec4 v1 = texture2D(u_lightbuffer, vec2(l_idx / float(u_nlights), 0.0));
    vec4 v2 = texture2D(u_lightbuffer, vec2(l_idx / float(u_nlights), 0.5));
    // vec3 col = v2.rgb;
    float rad = v2.a;
    vec4 pos = u_viewMat * vec4(v1.xyz, 1);

    vec4 p1 = u_projMat * (pos + vec4(-rad, -rad, rad, 0));
    vec4 p2 = u_projMat * (pos + vec4(rad, rad, rad, 0));

    p1 /= p1.w;
    p2 /= p2.w;

    if (intersect(min, max, p1.xy, p2.xy)) {
      col[int(i)] = 1.0;
    }
  }
}