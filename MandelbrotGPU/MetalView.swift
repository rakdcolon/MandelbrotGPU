//
//  MetalView.swift
//  MandelbrotGPU
//
//  Created by Rohan Karamel on 6/13/25.
//

import SwiftUI
import MetalKit

struct MetalView: NSViewRepresentable
{
    class Coordinator: NSObject, MTKViewDelegate
    {
        var parent: MetalView
        init(_ parent: MetalView) { self.parent = parent }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView)
        {
            // Placeholder: Clear to black
            guard let drawable = view.currentDrawable,
                  let commandBuffer = parent.commandQueue.makeCommandBuffer(),
                  let passDesc = view.currentRenderPassDescriptor else { return }

            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDesc)!
            encoder.endEncoding()
            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }

    let device = MTLCreateSystemDefaultDevice()!
    let commandQueue: MTLCommandQueue

    init() { self.commandQueue = device.makeCommandQueue()! }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> MTKView
    {
        let view = MTKView(frame: .zero, device: device)
        view.delegate = context.coordinator
        view.clearColor = MTLClearColorMake(0, 0, 0, 1) // black background
        view.enableSetNeedsDisplay = true
        view.isPaused = false
        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {}
}
