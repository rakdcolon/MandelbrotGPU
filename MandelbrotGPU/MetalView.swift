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

        (view as ZoomableMTKView).onZoom = { zoomFactor, mousePos in
            guard let r = renderer.renderer else { return }

            let viewSize = view.bounds.size
            let aspect = Float(view.drawableSize.width / view.drawableSize.height)

            let px = Float(mousePos.x / viewSize.width - 0.5)
            let py = Float(0.5 - mousePos.y / viewSize.height)

            let pointBefore = SIMD2<Float>(
                px * r.scale * 2.0 * aspect + r.center.x,
                py * r.scale * 2.0 + r.center.y
            )

            r.targetScale *= zoomFactor

            let pointAfter = SIMD2<Float>(
                px * r.targetScale * 2.0 * aspect + r.center.x,
                py * r.targetScale * 2.0 + r.center.y
            )

            let horizontalSensitivity: Float = 0.25  // <— reduce to dampen horizontal effect
            let verticalSensitivity: Float = 0.25

            let delta = pointBefore - pointAfter
            let dampenedDelta = SIMD2<Float>(delta.x * horizontalSensitivity, delta.y * verticalSensitivity)

            r.targetCenter += dampenedDelta
        }

        (view as ZoomableMTKView).onPan = { panAmount in
            guard let r = renderer.renderer else { return }
            let aspect = Float(view.drawableSize.width / view.drawableSize.height)
            
            r.targetCenter.x += panAmount.x * r.scale * 2.0 * aspect
            r.targetCenter.y += panAmount.y * r.scale * 2.0
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

