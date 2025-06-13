#include <metal_stdlib>
using namespace metal;
#include "ShaderTypes.h"

float3 hsv2rgb(float h, float s, float v) {
    float4 K = float4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    float3 p = abs(fract(float3(h) + K.xyz) * 6.0 - K.www);
    return v * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), s);
}

kernel void mandelbrotShader(
    texture2d<float, access::write> outTexture [[texture(0)]],
    constant MandelbrotUniforms& uniforms [[buffer(0)]],
    uint2 gid [[thread_position_in_grid]]
)
{
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;

    float aspect = float(outTexture.get_width()) / outTexture.get_height();

    // Map pixel to complex plane
    float2 c;
    c.x = (float(gid.x) / outTexture.get_width() - 0.5) * uniforms.scale * aspect + uniforms.center.x;
    c.y = (float(gid.y) / outTexture.get_height() - 0.5) * uniforms.scale + uniforms.center.y;

    float2 z = float2(0.0, 0.0);
    uint i = 0;

    while (i < uniforms.maxIterations && dot(z, z) < 4.0) {
        z = float2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        i++;
    }

    float brightness = float(i) / uniforms.maxIterations;

    // Apply log-smoothing for anti-banding
    if (i < uniforms.maxIterations) {
        float smooth = brightness + 1.0 - log2(log2(dot(z, z))) / log2(2.0);
        brightness = clamp(smooth, 0.0, 1.0);
    } else {
        brightness = 0.0;
    }

    // Map brightness non-linearly to hue to cycle more colors
    float hue = fmod(brightness * 5.0, 1.0);  // Cycles hue multiple times
    float saturation = 0.8 + 0.2 * brightness; // Slight variation in saturation
    float value = pow(brightness, 0.7);        // Gamma correction

    float3 rgb = hsv2rgb(hue, saturation, value);
    outTexture.write(float4(rgb, 1.0), gid);
}

