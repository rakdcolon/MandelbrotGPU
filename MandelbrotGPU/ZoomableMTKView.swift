import MetalKit

class ZoomableMTKView: MTKView {
    var onZoom: ((Float) -> Void)?
    var onPan: ((SIMD2<Float>) -> Void)?

    private var lastDragLocation: CGPoint?

    override func scrollWheel(with event: NSEvent) {
        let deltaY = Float(event.scrollingDeltaY)
        let zoomFactor: Float = 1.0 - deltaY * 0.01
        onZoom?(zoomFactor)
    }

    override func mouseDown(with event: NSEvent) {
        lastDragLocation = convert(event.locationInWindow, from: nil)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let lastLocation = lastDragLocation else { return }
        let newLocation = convert(event.locationInWindow, from: nil)

        let dx = Float(newLocation.x - lastLocation.x)
        let dy = Float(newLocation.y - lastLocation.y)

        // Normalize by screen size
        let width = Float(self.frame.width)
        let height = Float(self.frame.height)

        let panAmount = SIMD2<Float>(-dx / width, dy / height)
        onPan?(panAmount)

        lastDragLocation = newLocation
    }

    override func mouseUp(with event: NSEvent) {
        lastDragLocation = nil
    }
}

