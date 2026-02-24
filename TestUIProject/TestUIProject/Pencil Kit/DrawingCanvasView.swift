//
//  DrawingCanvasView.swift
//  TestUIProject
//
//  Created by Vishakh on 02/19/26.
//

import SwiftUI
import PencilKit

struct DrawingCanvasView: View {
    @State private var drawing = PKDrawing()
    @State private var showToolPicker = true

    var body: some View {
        NavigationStack {
            PencilKitCanvasWithToolPicker(
                drawing: $drawing,
                showToolPicker: $showToolPicker,
                backgroundColor: .white
            )
            .navigationTitle("Canvas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showToolPicker.toggle()
                    } label: {
                        Image(systemName: showToolPicker ? "pencil.tip.crop.circle.fill" : "pencil.tip.crop.circle")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        drawing = PKDrawing()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }
}

#Preview {
    DrawingCanvasView()
}
