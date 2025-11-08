void get_sky_color() {
    const vec3 SKY_TOP_NOON = to_linear(vec3(f_NOON_SKY_T_R * 0.85, f_NOON_SKY_T_G * 0.9, f_NOON_SKY_T_B * 1.1));
    const vec3 SKY_TOP_SUNRISE = to_linear(vec3(f_SUNRISE_SKY_T_R * 1.1, f_SUNRISE_SKY_T_G * 1.05, f_SUNRISE_SKY_T_B * 0.9));
    const vec3 SKY_TOP_SUNSET = to_linear(vec3(f_SUNSET_SKY_T_R * 1.05, f_SUNSET_SKY_T_G * 0.9, f_SUNSET_SKY_T_B * 1.1));
    const vec3 SKY_TOP_NIGHT = to_linear(vec3(f_NIGHT_SKY_T_R * 0.7, f_NIGHT_SKY_T_G * 0.8, f_NIGHT_SKY_T_B * 1.2));

    const vec3 SKY_GROUND_NOON = to_linear(vec3(f_NOON_SKY_G_R * 0.9, f_NOON_SKY_G_G * 0.95, f_NOON_SKY_G_B * 1.1));
    const vec3 SKY_GROUND_SUNRISE = to_linear(vec3(f_SUNRISE_SKY_G_R * 1.1, f_SUNRISE_SKY_G_G * 1.05, f_SUNRISE_SKY_G_B * 0.95));
    const vec3 SKY_GROUND_SUNSET = to_linear(vec3(f_SUNSET_SKY_G_R * 1.05, f_SUNSET_SKY_G_G * 0.95, f_SUNSET_SKY_G_B * 1.1));
    const vec3 SKY_GROUND_NIGHT = to_linear(vec3(f_NIGHT_SKY_G_R * 0.75, f_NIGHT_SKY_G_G * 0.85, f_NIGHT_SKY_G_B * 1.15));

    SKY_TOP = SKY_TOP_SUNRISE * sunriseStrength + SKY_TOP_NOON * dayStrength + SKY_TOP_SUNSET * sunsetStrength + SKY_TOP_NIGHT * nightStrength;
    SKY_GROUND = SKY_GROUND_SUNRISE * sunriseStrength + SKY_GROUND_NOON * dayStrength + SKY_GROUND_SUNSET * sunsetStrength + SKY_GROUND_NIGHT * nightStrength;

    SKY_TOP = apply_saturation(SKY_TOP, 1 - rainStrength * (RAIN_SKY_DESATURATION * 0.7)) * (1 - rainStrength * (RAIN_SKY_DARKENING * 0.6));
    SKY_GROUND = SKY_GROUND * (1 - rainStrength * 0.35);
}

void get_sun_color() {

    #ifdef DIMENSION_NETHER
    SUN_AMBIENT = to_linear(vec3(f_NETHER_AMBIENT_R * 0.8, f_NETHER_AMBIENT_G * 0.85, f_NETHER_AMBIENT_B * 0.9));
    SUN_DIRECT = vec3(0);
    return;
    #elif defined DIMENSION_END
    SUN_AMBIENT = to_linear(vec3(f_END_AMBIENT_R * 0.85, f_END_AMBIENT_G * 0.9, f_END_AMBIENT_B * 1.05));
    SUN_DIRECT = to_linear(vec3(f_END_DIRECT_R * 0.85, f_END_DIRECT_G * 0.9, f_END_DIRECT_B * 1.05));
    return;
    #endif

    SUN_AMBIENT = vec3(
        f_SUNRISE_AMBIENT * sunriseStrength * 1.1 +
        f_NOON_AMBIENT * dayStrength * 0.9 +
        f_SUNSET_AMBIENT * sunsetStrength * 1.05 +
        f_NIGHT_AMBIENT * nightStrength * 0.8
    );
    SUN_AMBIENT = to_linear(SUN_AMBIENT);

    float LHeight = sin(sunAngleAtHome * PI * 2);

    if (LHeight > 0) {
        const vec3 SUNRISE_SUN = to_linear(vec3(f_SUNRISE_RED * 1.1, f_SUNRISE_GREEN * 1.05, f_SUNRISE_BLUE * 0.9));
        const vec3 NOON_SUN = to_linear(vec3(f_NOON_RED * 0.95, f_NOON_GREEN * 0.9, f_NOON_BLUE * 1.05));
        const vec3 SUNSET_SUN = to_linear(vec3(f_SUNSET_RED * 1.05, f_SUNSET_GREEN * 0.9, f_SUNSET_BLUE * 1.1));

        SUN_DIRECT = SUNRISE_SUN * sunriseStrength + NOON_SUN * dayStrength + SUNSET_SUN * sunsetStrength;
    }
    else {
        SUN_DIRECT = to_linear(vec3(f_MOON_RED * 0.7, f_MOON_GREEN * 0.75, f_MOON_BLUE * 1.1));

        const float MPI_DIV2 = MOON_PHASE_INFLUENCE / 2;
        float MoonPhaseFactor = cos(float(worldDay % 8) / 8.0 * 2 * PI) * MPI_DIV2 + (1 - MPI_DIV2);
        SUN_DIRECT *= MoonPhaseFactor;
    }
    SUN_DIRECT *= smoothstep(0, 0.2, abs(LHeight)); 
    SUN_DIRECT = apply_saturation(SUN_DIRECT, 1 - rainStrength * 0.4) * (1 - rainStrength * 0.3);
}

void init_colors() {
    get_sky_color();
    get_sun_color();
}
