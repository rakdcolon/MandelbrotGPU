//
//  MandelbrotShader.metal
//  MandelbrotGPU
//
//  Created by Rohan Karamel on 6/13/25.
//

#include <metal_stdlib>
using namespace metal;

kernel void mandelbrotShader(
        texture2d<float,
        access::write> outTexture [[texture(0)]],
        uint2 gid [[thread_position_in_grid]]
    )
{
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;

    float2 c;
    float scale = 2.0;
    float2 center = float2(-0.5, 0.0);

    // Map pixel to complex plane
    c.x = ((float)gid.x / outTexture.get_width() - 0.5f) * scale * 2.0 + center.x;
    c.y = ((float)gid.y / outTexture.get_height() - 0.5f) * scale + center.y;

    float2 z = float2(0.0, 0.0);
    int maxIter = 100;
    int i = 0;
    while (i < maxIter && dot(z, z) < 4.0)
    {
        z = float2(z.x * z.x - z.y * z.y, 2.0 * z.x * z.y) + c;
        i++;
    }

    float brightness = float(i) / maxIter;
    outTexture.write(float4(brightness, brightness, brightness, 1.0), gid);
}
