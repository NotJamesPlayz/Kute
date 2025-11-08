varying vec2 LightmapCoords;
varying vec2 texcoord;
varying vec4 glcolor;
attribute vec4 mc_Entity;
attribute vec2 mc_midTexCoord;
flat varying float material;
varying vec3 MixedLights;
flat varying vec3 Normal;

vec3 ViewPos;
#include "/global/light_colors.vsh"

void init_generic() {
    init_colors();

    gl_Position = ftransform();
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    LightmapCoords = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    LightmapCoords = max(LightmapCoords * 1.05 - 0.05, 0);  // softer offset

    material = mc_Entity.x;

    ViewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;

    Normal = normalize(gl_NormalMatrix * gl_Normal);
    vec3 NormalA;
    if (material == 10001 || material == 10004 || material == 10005 || material == 10006) {
        NormalA = gbufferModelView[1].xyz;
        if (gl_MultiTexCoord0.t > mc_midTexCoord.t && (material == 10004 || material == 10005)) NormalA *= 0.6;  // less darkening for grass
    }
    else {
        NormalA = Normal;
    }
    glcolor = gl_Color;

    #ifdef HANDHELD_LIGHTS
    float Dist = length(ViewPos);

    float HandheldLight = heldBlockLightValue * 0.8;  // soften handheld light a bit
    LightmapCoords.x = max(LightmapCoords.x, pow(max((HandheldLight - Dist) / 15.0, 0), 3.5 - HANDHELD_FALLOFF_CURVE));  // gentler falloff
    #endif

    #ifdef LM_FLICKER
    LightmapCoords.x *= (1 - LM_FLICKER_STRENGTH * 0.6) + texture2D(noisetex, vec2(frameTimeCounter / 8, 0)).r * LM_FLICKER_STRENGTH * 0.6;  // less flicker intensity
    #endif

    const vec3 TorchColor = to_linear(vec3(f_LM_RED * 1.1, f_LM_GREEN * 1.1, f_LM_BLUE * 1.2));  // softer pastel torch color
    float MinLight = clamp(MIN_LIGHT_AMOUNT + screenBrightness * 0.08 - 0.08, 0, 0.4);
    MinLight = to_linear(MinLight);
    MinLight += nightVision / 4;

    #ifndef DIMENSION_OVERWORLD
    LightmapCoords.y = 1;
    #else
    float NdotU = clamp(dot(gbufferModelView[1].xyz, Normal), -1, 1);
    SUN_AMBIENT = mix(SUN_AMBIENT, mix(SKY_GROUND, SKY_TOP, NdotU * 0.3 + 0.3), 0.6);  // softer blending
    #endif

    #ifndef DIMENSION_NETHER
        #ifdef DIMENSION_END
            float NdotL = max(dot(NormalA, gbufferModelView[1].xyz), 0);
        #else
            float NdotL = max(dot(NormalA, sunOrMoonPosN), 0);
        #endif

        float FakeShadowFactor = smoothstep(0.9, 0.98, LightmapCoords.y);  // narrower cutoff for softer shadow

        SUN_AMBIENT += SUN_DIRECT * NdotL * FakeShadowFactor * 0.8;  // soften direct sun contribution
    #endif

    LightmapCoords.x = pow(LightmapCoords.x, 3.5 - LM_FALLOFF_CURVE);  // gentler falloff

    LightmapCoords.x = mix(LightmapCoords.x, LightmapCoords.x, LightmapCoords.y);
    MixedLights = TorchColor * LightmapCoords.x + mix(vec3(MinLight), SUN_AMBIENT, LightmapCoords.y);
    MixedLights *= 1 - darknessLightFactor * 0.7;  // soften darkness effect
}
