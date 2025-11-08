vec3 CAS(sampler2D Sampler) {
    ivec2 Coords = ivec2(gl_FragCoord.xy);
    vec3 e = texelFetch2D(Sampler, Coords, 0).rgb;
    vec3 a = texelFetch2D(Sampler, Coords + ivec2(-1,-1), 0).rgb;
    vec3 b = texelFetch2D(Sampler, Coords + ivec2( 0,-1), 0).rgb;
    vec3 c = texelFetch2D(Sampler, Coords + ivec2( 1,-1), 0).rgb;
    vec3 d = texelFetch2D(Sampler, Coords + ivec2(-1, 0), 0).rgb;
    vec3 f = texelFetch2D(Sampler, Coords + ivec2( 1, 0), 0).rgb;
    vec3 g = texelFetch2D(Sampler, Coords + ivec2(-1, 1), 0).rgb;
    vec3 h = texelFetch2D(Sampler, Coords + ivec2( 0, 1), 0).rgb;
    vec3 i = texelFetch2D(Sampler, Coords + ivec2( 1, 1), 0).rgb;

    vec3 mnRGB  = min(min(min(d,e),min(f,b)),h);
    vec3 mnRGB2 = min(min(min(mnRGB,a),min(g,c)),i);
    mnRGB += mnRGB2;

    vec3 mxRGB  = max(max(max(d,e),max(f,b)),h);
    vec3 mxRGB2 = max(max(max(mxRGB,a),max(g,c)),i);
    mxRGB += mxRGB2;

    vec3 rcpMxRGB = vec3(1)/mxRGB;
    vec3 ampRGB = clamp((min(mnRGB, 2.0 - mxRGB) * rcpMxRGB), 0, 1);

    // soften sharpening a little for pastel smoothness~
    ampRGB = inversesqrt(ampRGB) * 1.1;
    float peak = 9.5 - 2.5 * SHARPENING;  // lowered a bit so sharpening is gentle

    vec3 wRGB = -vec3(1)/(ampRGB * peak);
    vec3 rcpWeightRGB = vec3(1)/(1.0 + 4.0 * wRGB);

    vec3 window = (b + d) + (f + h);
    vec3 outColor = clamp((window * wRGB + e) * rcpWeightRGB, 0, 1);

    return outColor;
}
