attribute vec3 aVertex;
attribute vec2 aTexcoord;
attribute vec3 aNormal;
attribute vec3 aColor;
attribute vec3 aPick;

uniform mat4 uMVP;
uniform mat4 uProj;
uniform float uPick;

varying highp vec2 vTexcoord;
varying highp vec3 vColor;
varying highp vec3 vNormal;
varying highp vec4 vPick;

void main(void)
{
  gl_Position = uProj * uMVP * vec4(aVertex, 1.0);
  vTexcoord = aTexcoord;
  vColor = aColor;
  vNormal = aNormal;
  vPick = vec4(aPick, uPick);
}