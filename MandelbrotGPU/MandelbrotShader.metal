#include <metal_stdlib>
using namespace metal;

kernel void mandelbrotShader(
    texture2d<float, access::write> outTexture [[texture(0)]],
    uint2 gid [[thread_position_in_grid]]
)
{
    // Guard against out-of-bounds (needed for non-divisible threadgroups)
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;

    // Convert pixel coordinate to complex plane coordinate
    float2 center = float2(-0.5, 0.0); // center of the Mandelbrot set
    float scale = 2.0; // zoom scale (smaller = zoom in)
    float aspect = float(outTexture.get_width()) / outTexture.get_height();

    // Map screen (gid) to complex plane
    float2 c;
    c.x = (float(gid.x) / outTexture.get_width() - 0.5) * scale * aspect + center.x;
    c.y = (float(gid.y) / outTexture.get_height() - 0.5) * scale + center.y;

    // Mandelbrot iteration
    float2 z = float2(0.0, 0.0);
    int maxIter = 100;
    int i = 0;

    while (i < maxIter && dot(z, z) < 4.0) {
        z = float2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        i++;
    }

    // Convert iteration count to color
    float brightness = float(i) / maxIter;

    // Grayscale output for now (you’ll improve this in next step!)
    float4 color = float4(brightness, brightness, brightness, 1.0);
    outTexture.write(color, gid);
}

