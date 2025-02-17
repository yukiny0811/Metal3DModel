//
//  Model3D.swift
//  Metal3DModel
//
//  Created by Yuki Kuwashima on 2025/02/07.
//

import MetalKit

public class Model3D {

    public class Material {
        public var albedo: MTLTexture?
        public init(
            albedo: MTLTexture?
        ) {
            self.albedo = albedo
        }
    }

    public class Mesh {
        public var mesh: MTKMesh
        public var materials: [Material]
        public init(mesh: MTKMesh, materials: [Material]) {
            self.mesh = mesh
            self.materials = materials
        }
    }

    public var meshes: [Mesh]

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

        var temporaryMeshes: [Mesh] = []
        for sourceMesh in asset.childObjects(of: MDLMesh.self) as! [MDLMesh] {
            sourceMesh.addTangentBasis(
                forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                normalAttributeNamed: MDLVertexAttributeNormal,
                tangentAttributeNamed: MDLVertexAttributeTangent
            )
            sourceMesh.vertexDescriptor = modelVertexDescriptor

            var materials: [Material] = []
            for submesh in sourceMesh.submeshes as! [MDLSubmesh] {
                if let mdlMaterial = submesh.material {
                    let albedoTexture: MTLTexture? = Self.loadTexture(of: .baseColor, from: mdlMaterial, bundle: bundle)
                    let material = Material(
                        albedo: albedoTexture
                    )
                    materials.append(material)
                } else {
                    materials.append(Material(albedo: nil))
                }
            }

            let mtkMesh = try MTKMesh(mesh: sourceMesh, device: Library.device)
            temporaryMeshes.append(Mesh(mesh: mtkMesh, materials: materials))
        }
        self.meshes = temporaryMeshes
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

    public func render(
        encoder: MTLRenderCommandEncoder
    ) {
        encoder.setCullMode(.none)
        for mesh in self.meshes {
            for b in 0..<mesh.mesh.vertexBuffers.count {
                switch b {
                case 0:
                    encoder.setVertexBuffer(mesh.mesh.vertexBuffers[b].buffer, offset: 0, index: 0)
                case 1:
                    encoder.setVertexBuffer(mesh.mesh.vertexBuffers[b].buffer, offset: 0, index: 1)
                case 2:
                    encoder.setVertexBuffer(mesh.mesh.vertexBuffers[b].buffer, offset: 0, index: 2)
                case 3:
                    encoder.setVertexBuffer(mesh.mesh.vertexBuffers[b].buffer, offset: 0, index: 3)
                default:
                    break
                }
            }
            for (i, submesh) in mesh.mesh.submeshes.enumerated() {
                encoder.setFragmentTexture(mesh.materials[i].albedo, index: 0)
                encoder.drawIndexedPrimitives(
                    type: submesh.primitiveType,
                    indexCount: submesh.indexCount,
                    indexType: submesh.indexType,
                    indexBuffer: submesh.indexBuffer.buffer,
                    indexBufferOffset: submesh.indexBuffer.offset
                )
            }
        }
    }
}

