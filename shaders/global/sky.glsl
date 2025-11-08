float fogify(float x, float w) {
    return w / (x * x + w * 1.5);  // softer fog curve
}

vec3 round_sun(float Dist) {
    Dist = Dist * 0.5 + 0.5;
    const vec3 SUN_COLOR = vec3(3.5, 2.8, 1.4);  // lighter pastel sun
    const vec3 MOON_COLOR = vec3(1.3, 1.8, 2.9); // softer moon blue
    float What = sunriseStrength + sunsetStrength;
    vec3 Color = SUN_COLOR * (1 - smoothstep(0., 0.002, 1 - Dist)) * (dayStrength + What * 0.8);
    Color += MOON_COLOR * (smoothstep(0.999, 1., 1 - Dist)) * (nightStrength + What * 0.8);
    return Color;
}

vec3 get_sun_glare(float Dist) {
    const vec3 SUN_GLARE = to_linear(vec3(f_SUN_GLARE_R * 1.1, f_SUN_GLARE_G * 1.1, f_SUN_GLARE_B * 1.2));  // softer glare colors

    vec3 SunGlare = SUN_GLARE * (1 - rainStrength * RAIN_SKY_DARKENING * 0.6);
    float Visibility = sunsetStrength + sunriseStrength;

    return SunGlare * (Dist * 0.6 + 0.4) * Visibility;
}

vec3 get_clouds(vec3 ViewPosN, vec3 PlayerPos, vec3 PlayerPosN, vec3 SunGlare, vec3 SkyColor) {
    vec2 CloudPos = PlayerPos.xz / (PlayerPos.y + length(PlayerPos.xz) / 8);  // softer division

    const float ACTUAL_CLOUD_SPEED = CLOUD_SPEED / 120.;
    float Animation = float(frameTimeCounter) * ACTUAL_CLOUD_SPEED;
    CloudPos += cameraPosition.xz / 640;
    CloudPos = (CloudPos + Animation) * 28;  // slower, smoother clouds

    float Noise = fbm_clouds(CloudPos, CLOUD_QUALITY);
    float CloudAmount = CLOUD_AMOUNT / 120.0 + rainStrength / 12;
    Noise *= smoothstep(0, 0.35 - CLOUD_OPACITY, Noise - 0.5 + CloudAmount);
    Noise *= smoothstep(0.0, 0.3, PlayerPosN.y);

    const float DENSITY = 1.2;  // lighter cloud density
    float Transmittance = exp(-Noise * DENSITY);
    float Absorbtion = fbm_clouds(CloudPos + to_player_pos(sunOrMoonPosN).xz * 7, 2);
    Absorbtion = pow4(Absorbtion * 1.8);

    float LHeight = sin(sunAngleAtHome * PI * 2);
    vec3 CloudColorRaw = (SKY_GROUND * 1.7 + SunGlare);
    vec3 CloudColor = CloudColorRaw * 0.22 / PI;

    float VdotL = dot(ViewPosN, sunOrMoonPosN);
    float MiePhase = max(xlf_phase(VdotL, 0.75) * 1.3, 1 / PI);
    CloudColor += SUN_DIRECT * MiePhase * exp(-Absorbtion * DENSITY);

    return SkyColor * Transmittance + CloudColor * Noise * DENSITY;
}

vec3 get_sky(vec3 ViewPosN, vec3 SunGlare) {
    float upDot = dot(ViewPosN, gbufferModelView[1].xyz) + 0.15;  // softer bias

    vec3 MixedColor = mix(SKY_TOP, SKY_GROUND + SunGlare, fogify(max(upDot, 0.0), 0.04));  // softer fogify weight
    return MixedColor;
}

float get_stars(vec3 PlayerPos) {
    vec3 StarCoord = PlayerPos / (PlayerPos.y + length(PlayerPos.xz) * 1.2);  // softer division
    StarCoord.x += frameTimeCounter * 0.0008;
    const float ACTUAL_STAR_SIZE = STAR_SIZE * 480;
    StarCoord = floor(StarCoord * ACTUAL_STAR_SIZE) / ACTUAL_STAR_SIZE;

    float Visibility = smoothstep(0, 0.12, StarCoord.y); // gentler fade near horizon
    #ifdef DIMENSION_OVERWORLD
    Visibility *= nightStrength * 0.9;
    #endif
    return max(0, random(StarCoord.xz) - 0.995) * 40 * Visibility;
}

vec3 get_aurora(vec3 PlayerPosN, float Dither) {
    float AuroraStrength = AURORA_STRENGTH * nightStrength * 0.8;
    #ifndef AURORA_EVERYWHERE
        AuroraStrength *= precipitationSmooth - 1;
    #endif
    if(precipitationSmooth <= 0.01) return vec3(0);

    const vec3 COLOR_TOP = pow(vec3(38, 255, 238) / 255.0, vec3(2.2));   // softer cyan
    const vec3 COLOR_BOTTOM = pow(vec3(152, 255, 58) / 255.0, vec3(2.2)); // gentler green

    const float PLANE_TOP = 11.0 + AURORA_HEIGHT;
    const float PLANE_BOTTOM = 11.0;

    vec3 StartPos = PLANE_BOTTOM / PlayerPosN.y * PlayerPosN; 
    vec3 EndPos = PLANE_TOP / PlayerPosN.y * PlayerPosN;

    const int SAMPLE_COUNT = 2;

    vec3 Step = (EndPos - StartPos) / SAMPLE_COUNT;
    vec3 Pos = Step * Dither + StartPos;

    vec2 Wind = frameTimeCounter * vec2(0.22, 0.3);

    vec3 AuroraColor = vec3(0);
    for(int i = 1; i <= SAMPLE_COUNT; i++) {
        float Noise = texture2D(noisetex, (Pos.xz - Wind) / vec2(90, 180)).r;

        Noise = pow2(pow4(Noise));
        Noise *= smoothstep(0.0, 0.3, PlayerPosN.y);
        AuroraColor += Noise * mix(COLOR_BOTTOM, COLOR_TOP, smoothstep(0, 1, Dither));

        Pos += Step;
    }

    return AuroraColor * AuroraStrength / SAMPLE_COUNT;
}

vec3 get_end_sky(vec3 pos, vec3 PlayerPos) {
    const vec3 SkyT = to_linear(vec3(f_END_SKY_T_R * 0.85, f_END_SKY_T_G * 0.9, f_END_SKY_T_B * 1.05));
    const vec3 SkyG1 = to_linear(vec3(f_END_AURORA1_R * 1.1, f_END_AURORA1_G * 1.05, f_END_AURORA1_B * 0.95));
    const vec3 SkyG2 = to_linear(vec3(f_END_AURORA2_R * 1.05, f_END_AURORA2_G * 0.9, f_END_AURORA2_B * 1.1));
    float upDot = dot(pos, gbufferModelView[1].xyz);
    vec2 RotPos1 = rotate(PlayerPos.xz, frameTimeCounter * 0.015);
    vec2 RotPos2 = rotate(PlayerPos.xz, -frameTimeCounter * 0.005);
    float Noise1 = fbm_fast(RotPos1 * 140, 2) * (1 - abs(upDot));
    float Noise2 = fbm_fast(RotPos2 * 260, 2) * (1 - abs(upDot));
    float Noise = (Noise1 + Noise2);
    vec3 SkyG = SkyG1 * Noise1 + SkyG2 * Noise2;
    vec3 Final = SkyT + SkyG * (fogify(upDot + 0.3, 0.06));
    Final *= max(1 - fogify(max(upDot + 0.35, 0), 0.025), 0.02);
    return Final;
}

vec3 get_sky_main(vec3 ViewPosN, vec3 PlayerPosN, vec3 SunGlare) {
    #ifdef DIMENSION_OVERWORLD
        vec3 SkyColor = get_sky(ViewPosN, SunGlare);
    #elif defined DIMENSION_END
        vec3 SkyColor = get_end_sky(ViewPosN, PlayerPosN);
    #else
        vec3 fogColorL = to_linear(fogColor.rgb);
        vec3 SkyColor = mix(fogColorL, normalize(fogColorL), 0.5) / 2.5;
    #endif

    return SkyColor;
}
