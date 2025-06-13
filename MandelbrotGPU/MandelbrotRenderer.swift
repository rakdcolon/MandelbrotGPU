import Metal
import MetalKit

import simd

struct MandelbrotUniforms {
    var center: SIMD2<Float>
    var scale: Float
    var maxIterations: UInt32
}


class MandelbrotRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var computePipeline: MTLComputePipelineState!

    private var uniformsBuffer: MTLBuffer!
    
    static var shared: MandelbrotRenderer?

    // Interaction State
    var center = SIMD2<Float>(-0.5, 0.0)
    var scale: Float = 2.0
    var maxIterations: UInt32 = 100

    init(view: MTKView) {
        self.device = view.device!
        self.commandQueue = device.makeCommandQueue()!
        super.init()
        MandelbrotRenderer.shared = self
        view.delegate = self
        loadShader()
    }

    private func loadShader() {
        guard let library = device.makeDefaultLibrary(),
              let kernel = library.makeFunction(name: "mandelbrotShader") else {
            fatalError("Failed to load shader.")
        }

        computePipeline = try! device.makeComputePipelineState(function: kernel)
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else { return }

        let texture = drawable.texture
        encoder.setComputePipelineState(computePipeline)
        encoder.setTexture(texture, index: 0)

        // Set uniform buffer
        let uniforms = MandelbrotUniforms(center: center, scale: scale, maxIterations: maxIterations)
        uniformsBuffer = device.makeBuffer(bytes: [uniforms],
                                           length: MemoryLayout<MandelbrotUniforms>.stride,
                                           options: [])
        encoder.setBuffer(uniformsBuffer, offset: 0, index: 0)

        // Dispatch threads
        let w = computePipeline.threadExecutionWidth
        let h = computePipeline.maxTotalThreadsPerThreadgroup / w
        let threadsPerGroup = MTLSize(width: w, height: h, depth: 1)
        let threadsPerGrid = MTLSize(width: texture.width, height: texture.height, depth: 1)

        encoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

