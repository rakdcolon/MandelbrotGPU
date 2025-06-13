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
    private var outputTexture: MTLTexture!

    private let targetSize = MTLSize(width: 15360, height: 8640, depth: 1)
    static var shared: MandelbrotRenderer?

    // Interaction State
    var center = SIMD2<Float>(-0.5, 0.0)
    var scale: Float = 2.0
    var maxIterations: UInt32 = 100

    var targetScale: Float = 1.5
    var zoomAnimationSpeed: Float = 0.1
    var targetCenter: SIMD2<Float> = SIMD2<Float>(-0.5, 0.0)

    init(view: MTKView) {
        self.device = view.device!
        self.commandQueue = device.makeCommandQueue()!
        self.targetScale = self.scale
        self.targetCenter = self.center
        super.init()
        MandelbrotRenderer.shared = self
        view.delegate = self
        createOutputTexture()
        loadShader()
    }

    private func createOutputTexture() {
        let desc = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: targetSize.width,
            height: targetSize.height,
            mipmapped: false
        )
        desc.usage = [.shaderWrite, .shaderRead]
        outputTexture = device.makeTexture(descriptor: desc)
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

        // Smooth zoom interpolation
        let lerpAmount = zoomAnimationSpeed
        scale += (targetScale - scale) * lerpAmount
        center += (targetCenter - center) * lerpAmount

        // Encode Mandelbrot uniforms
        let uniforms = MandelbrotUniforms(center: center, scale: scale, maxIterations: maxIterations)
        uniformsBuffer = device.makeBuffer(bytes: [uniforms],
                                           length: MemoryLayout<MandelbrotUniforms>.stride,
                                           options: [])
        encoder.setComputePipelineState(computePipeline)
        encoder.setTexture(outputTexture, index: 0)
        encoder.setBuffer(uniformsBuffer, offset: 0, index: 0)

        let w = computePipeline.threadExecutionWidth
        let h = computePipeline.maxTotalThreadsPerThreadgroup / w
        let threadsPerGroup = MTLSize(width: w, height: h, depth: 1)
        let threadsPerGrid = MTLSize(width: outputTexture.width, height: outputTexture.height, depth: 1)

        encoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
        encoder.endEncoding()

        // Copy centered portion of high-res texture to screen
        if let blit = commandBuffer.makeBlitCommandEncoder() {
            let outWidth = outputTexture.width
            let outHeight = outputTexture.height
            let drawWidth = drawable.texture.width
            let drawHeight = drawable.texture.height

            let offsetX = max((outWidth - drawWidth) / 2, 0)
            let offsetY = max((outHeight - drawHeight) / 2, 0)
            let copyWidth = min(outWidth, drawWidth)
            let copyHeight = min(outHeight, drawHeight)

            blit.copy(from: outputTexture,
                      sourceSlice: 0, sourceLevel: 0,
                      sourceOrigin: MTLOrigin(x: offsetX, y: offsetY, z: 0),
                      sourceSize: MTLSize(width: copyWidth, height: copyHeight, depth: 1),
                      to: drawable.texture,
                      destinationSlice: 0, destinationLevel: 0,
                      destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
            blit.endEncoding()
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func exportCurrentImage(to url: URL) {
        let width = outputTexture.width
        let height = outputTexture.height

        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let dataSize = height * bytesPerRow

        let region = MTLRegionMake2D(0, 0, width, height)
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: dataSize, alignment: bytesPerPixel)
        defer { buffer.deallocate() }

        outputTexture.getBytes(buffer,
                               bytesPerRow: bytesPerRow,
                               from: region,
                               mipmapLevel: 0)

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(data: buffer,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
              let cgImage = context.makeImage() else {
            print("Failed to create CGImage.")
            return
        }

        let nsImageRep = NSBitmapImageRep(cgImage: cgImage)
        guard let pngData = nsImageRep.representation(using: .png, properties: [:]) else {
            print("Failed to create PNG data.")
            return
        }

        do {
            try pngData.write(to: url)
            print("✅ Image exported to \(url.path)")
        } catch {
            print("❌ Failed to write image: \(error)")
        }
    }

}

