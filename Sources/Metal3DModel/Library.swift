//
//  Library.swift
//  Metal3DModelProject
//
//  Created by Yuki Kuwashima on 2025/02/17.
//

@preconcurrency import MetalKit

/**
 An enumeration encapsulating Metal-related objects and configurations for rendering.

 This library provides shared access to the Metal device, default library, command queue,
 render pipeline states, depth-stencil states, and vertex descriptors. It centralizes
 resource creation and configuration for use throughout the rendering system.
 */
enum Library {
    static let device = MTLCreateSystemDefaultDevice()!
    static let modelVertexDescriptor: MTLVertexDescriptor = {
        let vertexDescriptor = MTLVertexDescriptor()

        // Position attribute
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        // Normal attribute
        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].offset = 0
        vertexDescriptor.attributes[1].bufferIndex = 1

        // Tangent attribute
        vertexDescriptor.attributes[2].format = .float3
        vertexDescriptor.attributes[2].offset = 0
        vertexDescriptor.attributes[2].bufferIndex = 2

        // UV attribute
        vertexDescriptor.attributes[3].format = .float2
        vertexDescriptor.attributes[3].offset = 0
        vertexDescriptor.attributes[3].bufferIndex = 3

        // Layout for position buffer
        vertexDescriptor.layouts[0].stride = MemoryLayout<simd_float3>.stride
        vertexDescriptor.layouts[0].stepRate = 1
        vertexDescriptor.layouts[0].stepFunction = .perVertex

        // Layout for normal buffer
        vertexDescriptor.layouts[1].stride = MemoryLayout<simd_float3>.stride
        vertexDescriptor.layouts[1].stepRate = 1
        vertexDescriptor.layouts[1].stepFunction = .perVertex

        // Layout for tangent buffer
        vertexDescriptor.layouts[2].stride = MemoryLayout<simd_float3>.stride
        vertexDescriptor.layouts[2].stepRate = 1
        vertexDescriptor.layouts[2].stepFunction = .perVertex

        // Layout for UV buffer
        vertexDescriptor.layouts[3].stride = MemoryLayout<simd_float2>.stride
        vertexDescriptor.layouts[3].stepRate = 1
        vertexDescriptor.layouts[3].stepFunction = .perVertex

        return vertexDescriptor
    }()
}
