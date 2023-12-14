in vec3 vertexPosition;
// in vec2 vertexTexCoord;
// in vec3 vertexNormal;
in vec4 vertexColor;

out fragColor;

void main() {
  fragColor = vertexColor;
  gl_Position = mvp * vec4(vertexPosition, 1.0);
}
