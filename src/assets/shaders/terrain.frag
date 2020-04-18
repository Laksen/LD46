varying highp vec2 vTexcoord;
varying highp vec3 vColor;
varying highp vec3 vNormal;
varying highp vec4 vPick;

uniform sampler2D uSampler;

const highp vec3 light_dir = vec3(1,0,0);

void main(void)
{
    highp float light = dot(vNormal, light_dir)*0.9+0.1;
    gl_FragColor = (vPick.w > 0.5) ? vec4(vPick.rgb, 0.0) :
                                     texture2D(uSampler, vTexcoord)*vec4(light)*vec4(vColor, 1.0);
}
