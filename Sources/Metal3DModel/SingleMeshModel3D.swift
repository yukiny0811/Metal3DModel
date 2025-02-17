//
//  SingleMeshModel3D.swift
//  Metal3DModel
//
//  Created by Yuki Kuwashima on 2025/02/17.
//

import MetalKit
import MetalVertexHelper

public class SingleMeshModel3D {

    @VertexObject
    public struct Vertex {
        public var position: simd_float3
        public var normal: simd_float3
        public var uv: simd_float2
        public init(position: simd_float3, normal: simd_float3, uv: simd_float2) {
            self.position = position
            self.normal = normal
            self.uv = uv
        }
    }

    public class Material {
        public var albedo: MTLTexture?
        public init(
            albedo: MTLTexture?
        ) {
            self.albedo = albedo
        }
    }

    public class Mesh {
        public var vertices: [Vertex]
        public var material: Material
        public init(vertices: [Vertex], material: Material) {
            self.vertices = vertices
            self.material = material
        }
    }

    public var mesh: Mesh

    public init(
        assetURL: URL,
        bundle: Bundle = .main
    ) throws {
        let modelVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(Library.modelVertexDescriptor)

        if let attr = modelVertexDescriptor.attributes[0] as? MDLVertexAttribute {
            attr.name = MDLVertexAttributePosition
            modelVertexDescriptor.attributes[0] = attr
        }
        if let attr = modelVertexDescriptor.attributes[1] as? MDLVertexAttribute {
            attr.name = MDLVertexAttributeNormal
            modelVertexDescriptor.attributes[1] = attr
        }
        if let attr = modelVertexDescriptor.attributes[2] as? MDLVertexAttribute {
            attr.name = MDLVertexAttributeTangent
            modelVertexDescriptor.attributes[2] = attr
        }
        if let attr = modelVertexDescriptor.attributes[3] as? MDLVertexAttribute {
            attr.name = MDLVertexAttributeTextureCoordinate
            modelVertexDescriptor.attributes[3] = attr
        }

        let bufferAllocator = MTKMeshBufferAllocator(device: Library.device)
        let asset = MDLAsset(url: assetURL, vertexDescriptor: modelVertexDescriptor, bufferAllocator: bufferAllocator)
        asset.loadTextures()

        for sourceMesh in asset.childObjects(of: MDLMesh.self) as! [MDLMesh] {
            sourceMesh.addTangentBasis(
                forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                normalAttributeNamed: MDLVertexAttributeNormal,
                tangentAttributeNamed: MDLVertexAttributeTangent
            )
            sourceMesh.vertexDescriptor = modelVertexDescriptor

            let material: Material = {
                for submesh in sourceMesh.submeshes as! [MDLSubmesh] {
                    if let mdlMaterial = submesh.material {
                        let albedoTexture: MTLTexture? = Self.loadTexture(of: .baseColor, from: mdlMaterial, bundle: bundle)
                        return Material(
                            albedo: albedoTexture
                        )
                    } else {
                        return Material(albedo: nil)
                    }
                }
                return Material(albedo: nil)
            }()

            let mtkMesh = try MTKMesh(mesh: sourceMesh, device: Library.device)

            let positions = Self.makeTriangleList(of: mtkMesh.vertexBuffers[0].buffer, submeshes: mtkMesh.submeshes, elementType: simd_float3.self)
            let normals = Self.makeTriangleList(of: mtkMesh.vertexBuffers[1].buffer, submeshes: mtkMesh.submeshes, elementType: simd_float3.self)
            let uvs = Self.makeTriangleList(of: mtkMesh.vertexBuffers[3].buffer, submeshes: mtkMesh.submeshes, elementType: simd_float2.self)

            var temporalVertices: [Vertex] = []
            for i in stride(from: 0, to: positions.count, by: 1) {
                let vertex = Vertex(position: positions[i], normal: normals[i], uv: uvs[i])
                temporalVertices.append(vertex)
            }
            self.mesh = Mesh(vertices: temporalVertices, material: material)
            return
        }

        self.mesh = Mesh(vertices: [], material: Material(albedo: nil))
    }

    private static func loadTexture(of semantic: MDLMaterialSemantic, from material: MDLMaterial, bundle: Bundle) -> MTLTexture? {
        let textureLoader = MTKTextureLoader(device: Library.device)
        let property = material.property(with: semantic)!
        switch property.type {
        case .string:
            let tex = try? textureLoader.newTexture(name: property.stringValue ?? "", scaleFactor: 1, bundle: bundle)
            tex?.label = property.name
            return tex
        default:
            return nil
        }
    }

    private static func makeTriangleList<Element>(of buffer: MTLBuffer, submeshes: [MTKSubmesh], elementType: Element.Type) -> [Element] {
        var triangleList = [Element]()
        // バッファ内の頂点数を計算するよ✨
        let vertexCount = buffer.length / MemoryLayout<Element>.stride
        // 頂点データのポインタを取得✨
        let verticesPointer = buffer.contents().bindMemory(to: Element.self, capacity: vertexCount)

        // 各サブメッシュごとに処理するよ😄
        for submesh in submeshes {
            // 三角形以外はスキップしちゃうよ🚫
            guard submesh.primitiveType == .triangle else {
                print("非三角形primitiveです: \(submesh.primitiveType)")
                continue
            }

            let indexBuffer = submesh.indexBuffer
            let indexCount = submesh.indexCount

            // インデックスの型に合わせて処理するよ🧐
            switch submesh.indexType {
            case .uint16:
                let indexPointer = indexBuffer.buffer.contents().bindMemory(to: UInt16.self, capacity: indexCount)
                // 3つずつ読み込んで三角形を生成するよ✨
                for i in stride(from: 0, to: indexCount, by: 3) {
                    let i0 = Int(indexPointer[i])
                    let i1 = Int(indexPointer[i + 1])
                    let i2 = Int(indexPointer[i + 2])
                    triangleList.append(verticesPointer[i0])
                    triangleList.append(verticesPointer[i1])
                    triangleList.append(verticesPointer[i2])
                }
            case .uint32:
                let indexPointer = indexBuffer.buffer.contents().bindMemory(to: UInt32.self, capacity: indexCount)
                // 同じく3つずつ読み込むよ🚀
                for i in stride(from: 0, to: indexCount, by: 3) {
                    let i0 = Int(indexPointer[i])
                    let i1 = Int(indexPointer[i + 1])
                    let i2 = Int(indexPointer[i + 2])
                    triangleList.append(verticesPointer[i0])
                    triangleList.append(verticesPointer[i1])
                    triangleList.append(verticesPointer[i2])
                }
            @unknown default:
                print("未知のindexTypeです: \(submesh.indexType)")
            }
        }

        return triangleList
    }
}
