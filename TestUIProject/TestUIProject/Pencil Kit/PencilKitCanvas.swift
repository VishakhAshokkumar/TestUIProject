//
//  PencilKitCanvas.swift
//  TestUIProject
//
//  Created by Vishakh on 12/10/25.
//

import SwiftUI
import PencilKit

// MARK: - PencilKit Canvas for Drawing
struct PencilKitCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var tool: PKInkingTool.InkType
    var color: UIColor
    var lineWidth: CGFloat = 5.0
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.delegate = context.coordinator
        canvasView.drawing = drawing
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.tool = PKInkingTool(tool, color: color, width: lineWidth)
        canvasView.becomeFirstResponder()
        
        return canvasView
    }
    
    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        canvasView.tool = PKInkingTool(tool, color: color, width: lineWidth)
        
        // Only update drawing if it changed externally
        if canvasView.drawing != drawing {
            canvasView.drawing = drawing
        }
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PencilKitCanvas
        
        init(_ parent: PencilKitCanvas) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            DispatchQueue.main.async { [weak self] in
                self?.parent.drawing = canvasView.drawing
            }
        }
    }
}

// MARK: - Full-Featured PencilKit Canvas with Tool Picker
struct PencilKitCanvasWithToolPicker: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    @Binding var showToolPicker: Bool
    var backgroundColor: UIColor = .clear
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.delegate = context.coordinator
        canvasView.drawing = drawing
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = backgroundColor
        canvasView.isOpaque = backgroundColor != .clear
        
        // Setup tool picker
        let toolPicker = PKToolPicker()
        toolPicker.setVisible(showToolPicker, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        context.coordinator.toolPicker = toolPicker
        
        canvasView.becomeFirstResponder()
        
        return canvasView
    }
    
    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        context.coordinator.toolPicker?.setVisible(showToolPicker, forFirstResponder: canvasView)
        
        if showToolPicker {
            canvasView.becomeFirstResponder()
        }
        
        if canvasView.drawing != drawing {
            canvasView.drawing = drawing
        }
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PencilKitCanvasWithToolPicker
        var toolPicker: PKToolPicker?
        
        init(_ parent: PencilKitCanvasWithToolPicker) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }
    }
}

// MARK: - Custom Tool Picker View
struct CustomToolPicker: View {
    @Binding var selectedTool: PKInkingTool.InkType
    @Binding var selectedColor: Color
    @Binding var lineWidth: CGFloat
    
    let tools: [PKInkingTool.InkType] = [.pen, .pencil, .marker]
    
    var body: some View {
        VStack(spacing: 16) {
            // Tool selection
            HStack(spacing: 20) {
                ForEach(tools, id: \.rawValue) { tool in
                    Button(action: { selectedTool = tool }) {
                        VStack(spacing: 4) {
                            Image(systemName: iconForTool(tool))
                                .font(.title2)
                            Text(nameForTool(tool))
                                .font(.caption)
                        }
                        .foregroundColor(selectedTool == tool ? .blue : .gray)
                    }
                }
            }
            
            // Line width slider
            HStack {
                Text("Width")
                    .font(.caption)
                    .foregroundColor(.gray)
                Slider(value: $lineWidth, in: 1...20)
                Text("\(Int(lineWidth))")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(width: 30)
            }
            
            // Color picker
            ColorPicker("Color", selection: $selectedColor)
                .labelsHidden()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
    
    private func iconForTool(_ tool: PKInkingTool.InkType) -> String {
        switch tool {
        case .pen: return "pencil.tip"
        case .pencil: return "pencil"
        case .marker: return "highlighter"
        default: return "pencil"
        }
    }
    
    private func nameForTool(_ tool: PKInkingTool.InkType) -> String {
        switch tool {
        case .pen: return "Pen"
        case .pencil: return "Pencil"
        case .marker: return "Marker"
        default: return "Tool"
        }
    }
}

// MARK: - Eraser Tool
struct EraserCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var eraserType: PKEraserTool.EraserType = .bitmap
    var tool: PKInkingTool
    var eraserWidth: CGFloat = 20
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.delegate = context.coordinator
        canvasView.drawing = drawing
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.tool = PKEraserTool(eraserType, width: eraserWidth)
        
        return canvasView
    }
    
    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        canvasView.tool = PKEraserTool(eraserType, width: eraserWidth)
        
        if canvasView.drawing != drawing {
            canvasView.drawing = drawing
        }
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: EraserCanvas
        
        init(_ parent: EraserCanvas) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }
    }
}

// MARK: - Drawing Extension for Rendering
extension PKDrawing {
    /// Renders the drawing to an image of the specified size
    func rendered(to size: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage {
        let bounds = CGRect(origin: .zero, size: size)
        return image(from: bounds, scale: scale)
    }
    
    /// Appends another drawing to this one
    mutating func append(_ other: PKDrawing) {
        var strokes = self.strokes
        strokes.append(contentsOf: other.strokes)
        self = PKDrawing(strokes: strokes)
    }
}
