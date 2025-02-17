//
//  ContentView.swift
//  Demo
//
//  Created by Yuki Kuwashima on 2025/02/14.
//

import SwiftUI
import Metal3DModel

struct ContentView: View {
    var body: some View {
        Button("generate") {
            let model = try! SingleMeshModel3D(assetURL: Bundle.main.url(forResource: "icosphere", withExtension: "usdc")!)
            dump(model.mesh.vertices)
        }
    }
}
