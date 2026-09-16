#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

// Bloom for the beam layer: a small Gaussian blur of the layer added back on
// top of it, so bright beams bleed light into the surrounding board.
[[ stitchable ]] half4 rtxBloom(float2 position, SwiftUI::Layer layer, float radius, float intensity) {
    half4 base = layer.sample(position);
    const int taps = 4;
    half4 acc = half4(0);
    float total = 0;
    float sigma2 = radius * radius * 0.5;
    for (int i = -taps; i <= taps; i++) {
        for (int j = -taps; j <= taps; j++) {
            float2 offset = float2(i, j) * (radius / taps);
            float w = exp(-dot(offset, offset) / sigma2);
            acc += layer.sample(position + offset) * w;
            total += w;
        }
    }
    half4 blur = acc / total;
    half4 result = base + blur * intensity;
    return min(result, half4(1.0));
}
