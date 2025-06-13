// ShaderTypes.h
#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

struct MandelbrotUniforms {
    vector_float2 center;
    float scale;
    uint maxIterations;
};

#endif /* ShaderTypes_h */

