import SwiftUI
import MetalKit

struct MetalView: NSViewRepresentable {
    let device = MTLCreateSystemDefaultDevice()!
    private let renderer = RendererHolder()

    func makeNSView(context: Context) -> MTKView {
        let view = ZoomableMTKView(frame: .zero, device: device)
        view.enableSetNeedsDisplay = false
        view.isPaused = false
        view.framebufferOnly = false
        view.colorPixelFormat = .bgra8Unorm

        let r = MandelbrotRenderer(view: view)
        renderer.renderer = r

        context.coordinator.renderer = r

        (view as ZoomableMTKView).onZoom = { factor in
            r.scale *= factor
        }

        (view as ZoomableMTKView).onPan = { panAmount in
            let view = view as ZoomableMTKView
            let aspect = Float(view.drawableSize.width / view.drawableSize.height)
            r.center.x += panAmount.x * r.scale * 2.0 * aspect
            r.center.y += panAmount.y * r.scale * 2.0
        }


        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class RendererHolder {
        var renderer: MandelbrotRenderer?
    }

    class Coordinator: NSObject {
        var renderer: MandelbrotRenderer?

        @objc func magnified(_ sender: NSMagnificationGestureRecognizer) {
            guard let r = renderer else { return }
            let zoomFactor: Float = 1 - Float(sender.magnification)
            r.scale *= zoomFactor
        }

        @objc func panned(_ sender: NSPanGestureRecognizer) {
            guard let r = renderer else { return }
            let translation = sender.translation(in: sender.view)
            let dx = Float(translation.x) / Float(sender.view?.frame.width ?? 1)
            let dy = Float(translation.y) / Float(sender.view?.frame.height ?? 1)

            r.center.x -= dx * r.scale * 2
            r.center.y += dy * r.scale * 2
            sender.setTranslation(.zero, in: sender.view)
        }
    }
}

