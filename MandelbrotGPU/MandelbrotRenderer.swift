//
//  MandelbrotRenderer.swift
//  MandelbrotGPU
//
//  Created by Rohan Karamel on 6/13/25.
//

import Metal
import MetalKit

class MandelbrotRenderer: NSObject, MTKViewDelegate
{
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var computePipeline: MTLComputePipelineState?

    private var time: Float = 0

    init(view: MTKView)
    {
        self.device = view.device!
        self.commandQueue = device.makeCommandQueue()!

        super.init()
        view.delegate = self
        loadShader()
    }

    private func loadShader()
    {
        guard let library = device.makeDefaultLibrary(),
              let kernelFunction = library.makeFunction(name: "mandelbrotShader")
        else
        {
            fatalError("Could not load mandelbrotShader")
        }

        do
        {
            computePipeline = try device.makeComputePipelineState(function: kernelFunction)
        }
        catch
        {
            fatalError("Failed to create pipeline state: \(error)")
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView)
    {
        guard let drawable = view.currentDrawable,
              let computePipeline = computePipeline,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder()
        else
        {
            return
        }

        let texture = drawable.texture
        computeEncoder.setComputePipelineState(computePipeline)
        computeEncoder.setTexture(texture, index: 0)

        // Set up thread execution dimensions
        let w = computePipeline.threadExecutionWidth
        let h = computePipeline.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSize(width: w, height: h, depth: 1)
        let threadsPerGrid = MTLSize(width: texture.width, height: texture.height, depth: 1)

        computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        computeEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
