vec3 get_lava_fog(float dist, vec3 color) {
    const vec3 LAVA_FOG_COLOR = to_linear(vec3(0.85, 0.65, 0.45));  // softer orange pastel
    const vec3 PSNOW_FOG_COLOR = to_linear(vec3(0.7, 0.75, 0.85)); // lighter bluish pastel

    if (isEyeInWater == 1) {
        vec3 UnderwaterCol = to_linear(vec3(f_WATER_RED * 0.8, f_WATER_GREEN * 0.85, f_WATER_BLUE * 0.9))*(SKY_GROUND * 0.9 + SKY_TOP * 0.9);
        UnderwaterCol = mix_preserve_c1lum(UnderwaterCol, fogColor, f_BIOME_WATER_CONTRIBUTION * 0.8);
        dist = clamp(dist / 80, 0, 1);  // fog starts later for softer feel
        return mix(color, UnderwaterCol, dist);
    }
    else if (isEyeInWater == 2) {
        dist = clamp(dist / 3, 0, 1);  // softer fog blend over longer distance
        return mix(color, LAVA_FOG_COLOR, dist * 0.7);  // less intense
    }
    else if (isEyeInWater == 3) {
        dist = clamp(dist / 3, 0, 1);
        return mix(color, PSNOW_FOG_COLOR, dist * 0.7);
    }
    return color;
}

vec3 get_border_fog(float strength, vec3 color, vec3 SkyColor) {
    strength *= strength * 0.8;  // slightly less intense
    #ifndef DIMENSION_NETHER
    strength *= strength * 0.9;
    strength *= strength * 0.9;
    #endif
    strength = exp(-2.0 * strength);  // gentler exponential fade
    return mix(SkyColor, color, strength);
}

vec3 get_blindness_fog(float Dist, vec3 Color) {
    Dist = clamp(1.0 - exp(-2.0 * Dist / 12), 0, 1) * max(darknessFactor, blindness);
    return Color * (1 - Dist * 0.8);  // less harsh fade
}

vec3 get_atm_fog(float Dist, vec3 Color, vec3 WorldPos, vec3 FogColor) {
    Dist = min(Dist / 320, 1);  // fog starts further away
    Dist = 1.0 - exp(-2.0 * Dist);
    float Visibility = sunriseStrength * 0.4 + nightStrength * 0.8;  // softer effects
    Visibility = max(Visibility, rainStrength * 0.8) * isOutdoorsSmooth;
    Visibility *= ATM_FOG_STRENGTH * 0.7;

    Visibility *= 1 - fbm_fast(WorldPos.xz, 1) * 0.7;

    float HeightFalloff = WorldPos.y >= 50 ? smoothstep(55, 75, WorldPos.y) - smoothstep(75, 130, WorldPos.y) : 0;

    float Factor = Dist * HeightFalloff * Visibility;
    vec3 FinalC = mix(Color, FogColor, Factor * 0.8);
    return FinalC;
}

vec3 get_fog_main(vec3 PlayerPos, vec3 Color, float Depth, vec3 SkyColor) {
    float Dist = length(PlayerPos);

    if (Depth < 1) {
        #if defined DIMENSION_OVERWORLD && defined ATMOSPHERIC_FOG
        if(isEyeInWater == 0)
            Color.rgb = get_atm_fog(Dist, Color.rgb, PlayerPos + cameraPosition, SkyColor);
        #endif
        #if defined BORDER_FOG && !defined CUSTOM_SKYBOXES
            #ifdef DISTANT_HORIZONS
                Color.rgb = get_border_fog(Dist / dhRenderDistance, Color.rgb, SkyColor);
            #else
                Color.rgb = get_border_fog(Dist / far, Color.rgb, SkyColor);
            #endif
        #endif
    }
    Color.rgb = get_lava_fog(Dist, Color.rgb);
    Color.rgb = get_blindness_fog(Dist, Color.rgb);
    return Color;
}
