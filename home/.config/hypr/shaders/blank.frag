#version 300 es
// Idle "screens off" without switching the screens off (screen-blank on): every pixel black. On the OLED black pixels
// are off, so it protects the panel like real power-off, without the NVIDIA display power path that froze on wake-up.
precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    fragColor = vec4(texture(tex, v_texcoord).rgb * 0.0, 1.0);
}
