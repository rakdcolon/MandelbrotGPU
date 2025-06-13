import SwiftUI

struct ContentView: View {
    @State private var iterations: UInt32 = 100

    var body: some View {
        VStack {
            MetalView().frame(minWidth: 1200, minHeight: 800)

            Slider(value: Binding(get: {
                Double(iterations)
            }, set: { newVal in
                iterations = UInt32(newVal)
                MandelbrotRenderer.shared?.maxIterations = iterations
            }), in: 50...1000, step: 10)
            .padding()
        }
    }
}

