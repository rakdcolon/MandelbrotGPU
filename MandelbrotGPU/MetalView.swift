import SwiftUI
import MetalKit

struct MetalView: NSViewRepresentable {
    let device = MTLCreateSystemDefaultDevice()!

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: device)
        view.enableSetNeedsDisplay = false
        view.isPaused = false
        view.framebufferOnly = false
        view.colorPixelFormat = .bgra8Unorm

        // Persist renderer in Coordinator
        context.coordinator.renderer = MandelbrotRenderer(view: view)
        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {}

    class Coordinator: NSObject {
        var renderer: MandelbrotRenderer?
    }
}
