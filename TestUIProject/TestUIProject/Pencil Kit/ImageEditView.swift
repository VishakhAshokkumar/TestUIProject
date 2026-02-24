//
//  ImageEditorView.swift
//  TestUIProject
//
//  Created by Vishakh on 12/10/25.
//

import SwiftUI
import PencilKit
import PhotosUI
internal import Combine

// MARK: - Main Image Editor View
struct ImageEditorView: View {
    let inputImage: UIImage
    let onSave: (UIImage) -> Void
    let onCancel: () -> Void
    
    @StateObject private var editorState = ImageEditorState()
    @State private var showColorPicker = false
    @State private var showTextEditor = false
    @State private var editingTextAnnotation: TextAnnotation?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top toolbar
                    topToolbar
                    
                    // Canvas area
                    canvasArea(geometry: geometry)
                    
                    // Bottom toolbar
                    bottomToolbar
                }
            }
        }
        .onAppear {
            editorState.originalImage = inputImage
        }
        .sheet(isPresented: $showTextEditor, onDismiss: {
            editingTextAnnotation = nil
        }) {
            TextEditorSheet(
                annotation: editingTextAnnotation,
                color: editorState.selectedColor,
                onSave: { text, fontSize in
                    print("=== TEXT SAVE CALLBACK ===")
                    print("Text: \(text)")
                    print("Font size: \(fontSize)")
                    print("Color: \(editorState.selectedColor)")
                    print("Editing existing: \(editingTextAnnotation != nil)")
                    
                    if let editing = editingTextAnnotation {
                        // Editing existing text
                        if let index = editorState.textAnnotations.firstIndex(where: { $0.id == editing.id }) {
                            editorState.textAnnotations[index].text = text
                            editorState.textAnnotations[index].fontSize = fontSize
                            print("Updated text at index \(index)")
                        }
                    } else {
                        // Creating new text
                        let newText = TextAnnotation(
                            text: text,
                            position: CGPoint(x: 0.5, y: 0.5),
                            color: editorState.selectedColor,
                            fontSize: fontSize
                        )
                        editorState.textAnnotations.append(newText)
                        editorState.selectedAnnotationId = newText.id
                        print("Created new text annotation")
                        print("Total text annotations: \(editorState.textAnnotations.count)")
                        print("Text position: (0.5, 0.5)")
                        print("Text ID: \(newText.id)")
                    }
                    showTextEditor = false
                },
                onCancel: {
                    print("Text editor cancelled")
                    showTextEditor = false
                }
            )
        }
    }
    
    // MARK: - Top Toolbar
    private var topToolbar: some View {
        HStack {
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // Undo/Redo
            HStack(spacing: 16) {
                Button(action: { editorState.undo() }) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.title3)
                        .foregroundColor(editorState.canUndo ? .white : .gray)
                }
                .disabled(!editorState.canUndo)
                
                Button(action: { editorState.redo() }) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.title3)
                        .foregroundColor(editorState.canRedo ? .white : .gray)
                }
                .disabled(!editorState.canRedo)
            }
            
            Spacer()
            
            Button(action: {
                let finalImage = editorState.renderFinalImage()
                onSave(finalImage)
            }) {
                Text("Save")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.8))
    }
    
    // MARK: - Canvas Area
    private func canvasArea(geometry: GeometryProxy) -> some View {
        let imageSize = calculateImageSize(for: inputImage, in: geometry)
        let _ = { editorState.imageDisplaySize = imageSize }()

        return ZStack {
            // Base image
            Image(uiImage: inputImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: imageSize.width, height: imageSize.height)
            
            // Annotations layer
            AnnotationsLayer(
                editorState: editorState,
                imageSize: imageSize,
                onTextTap: { annotation in
                    editingTextAnnotation = annotation
                    showTextEditor = true
                }
            )
            .frame(width: imageSize.width, height: imageSize.height)
            
            // PencilKit canvas for drawing
            if editorState.currentTool == .draw {
                PencilKitCanvas(
                    drawing: $editorState.drawing,
                    tool: editorState.drawingTool,
                    color: UIColor(editorState.selectedColor)
                )
                .frame(width: imageSize.width, height: imageSize.height)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Color.black
                .contentShape(Rectangle())
                .onTapGesture {
                    // Deselect annotation when tapping on background
                    editorState.selectedAnnotationId = nil
                }
        )
        .clipped()
        .gesture(
            // Canvas creation gesture for drawing tools
            (editorState.currentTool == .arrow ||
             editorState.currentTool == .circle ||
             editorState.currentTool == .rectangle ||
             editorState.currentTool == .magnifier) ?
            canvasGesture(imageSize: imageSize) : nil
        )
    }

    
    // MARK: - Canvas Gesture
    private func canvasGesture(imageSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                let location = value.location
                editorState.handleDrag(at: location, imageSize: imageSize, phase: .changed)
            }
            .onEnded { value in
                let location = value.location
                editorState.handleDrag(at: location, imageSize: imageSize, phase: .ended)
            }
    }
    
    // MARK: - Bottom Toolbar
    private var bottomToolbar: some View {
        VStack(spacing: 12) {
            // Color picker row
            HStack(spacing: 12) {
                // Preset colors
                ForEach(presetColors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(editorState.selectedColor == color ? Color.white : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture {
                            editorState.selectedColor = color
                        }
                }
                
                // Custom color picker
                ColorPicker("", selection: $editorState.selectedColor)
                    .labelsHidden()
                    .frame(width: 32, height: 32)
            }
            .padding(.horizontal, 16)
            
            // Tools row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ToolButton(
                        icon: "pencil.tip",
                        label: "Draw",
                        isSelected: editorState.currentTool == .draw,
                        action: { editorState.currentTool = .draw }
                    )
                    
                    ToolButton(
                        icon: "arrow.up.right",
                        label: "Arrow",
                        isSelected: editorState.currentTool == .arrow,
                        action: { editorState.currentTool = .arrow }
                    )
                    
                    ToolButton(
                        icon: "textformat",
                        label: "Text",
                        isSelected: editorState.currentTool == .text,
                        action: {
                            print("Text button tapped")
                            editorState.currentTool = .text
                            editingTextAnnotation = nil
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                showTextEditor = true
                                print("showTextEditor set to: \(showTextEditor)")
                            }
                        }
                    )
                    
                    ToolButton(
                        icon: "circle",
                        label: "Circle",
                        isSelected: editorState.currentTool == .circle,
                        action: { editorState.currentTool = .circle }
                    )
                    
                    ToolButton(
                        icon: "rectangle",
                        label: "Rect",
                        isSelected: editorState.currentTool == .rectangle,
                        action: { editorState.currentTool = .rectangle }
                    )
                    
                    ToolButton(
                        icon: "magnifyingglass.circle",
                        label: "Magnify",
                        isSelected: editorState.currentTool == .magnifier,
                        action: { editorState.currentTool = .magnifier }
                    )
                    
                    ToolButton(
                        icon: "eraser",
                        label: "Eraser",
                        isSelected: editorState.currentTool == .eraser,
                        action: { editorState.currentTool = .eraser }
                    )
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.9))
    }
    
    // MARK: - Helpers
    private var presetColors: [Color] {
        [.red, .orange, .yellow, .green, .blue, .purple, .white, .black]
    }
    
    private func calculateImageSize(for image: UIImage, in geometry: GeometryProxy) -> CGSize {
        let availableWidth = geometry.size.width
        let availableHeight = geometry.size.height - 200 // Account for toolbars
        let imageAspect = image.size.width / image.size.height
        let availableAspect = availableWidth / availableHeight
        
        if imageAspect > availableAspect {
            let width = availableWidth
            let height = width / imageAspect
            return CGSize(width: width, height: height)
        } else {
            let height = availableHeight
            let width = height * imageAspect
            return CGSize(width: width, height: height)
        }
    }
}

// MARK: - Tool Button
struct ToolButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .orange : .white)
            .frame(width: 50)
        }
    }
}

// MARK: - Editor State
class ImageEditorState: ObservableObject {
    @Published var originalImage: UIImage?
    @Published var currentTool: EditorTool = .draw
    @Published var selectedColor: Color = .orange
    @Published var drawing: PKDrawing = PKDrawing()
    @Published var drawingTool: PKInkingTool.InkType = .pen
    
    // Annotations
    @Published var arrowAnnotations: [ArrowAnnotation] = []
    @Published var textAnnotations: [TextAnnotation] = []
    @Published var shapeAnnotations: [ShapeAnnotation] = []
    @Published var magnifierAnnotations: [MagnifierAnnotation] = []
    
    // Drag state
    @Published var currentArrowDrag: ArrowAnnotation?
    @Published var currentShapeDrag: ShapeAnnotation?
    @Published var currentMagnifierDrag: MagnifierAnnotation?
    @Published var draggingAnchor: AnchorType?
    @Published var selectedAnnotationId: UUID?

    // Display size tracking (for matching on-screen zoom in export)
    var imageDisplaySize: CGSize = .zero

    // Undo/Redo
    private var undoStack: [EditorAction] = []
    private var redoStack: [EditorAction] = []
    
    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    
    func undo() {
        guard let action = undoStack.popLast() else { return }
        redoStack.append(action.inverse(state: self))
        action.undo(state: self)
    }
    
    func redo() {
        guard let action = redoStack.popLast() else { return }
        undoStack.append(action.inverse(state: self))
        action.redo(state: self)
    }
    
    private func recordAction(_ action: EditorAction) {
        undoStack.append(action)
        redoStack.removeAll()
    }
    
    func handleDrag(at location: CGPoint, imageSize: CGSize, phase: DragPhase) {
        // Deselect any selected annotation when starting to create a new one
        if phase == .changed && selectedAnnotationId != nil {
            if currentArrowDrag == nil && currentShapeDrag == nil && currentMagnifierDrag == nil {
                selectedAnnotationId = nil
            }
        }
        
        switch currentTool {
        case .arrow:
            handleArrowDrag(at: location, imageSize: imageSize, phase: phase)
        case .circle, .rectangle:
            handleShapeDrag(at: location, imageSize: imageSize, phase: phase)
        case .magnifier:
            handleMagnifierDrag(at: location, imageSize: imageSize, phase: phase)
        case .eraser:
            handleEraserTap(at: location)
        default:
            break
        }
    }
    
    private func handleArrowDrag(at location: CGPoint, imageSize: CGSize, phase: DragPhase) {
        let normalizedLocation = CGPoint(
            x: location.x / imageSize.width,
            y: location.y / imageSize.height
        )
        
        switch phase {
        case .changed:
            if currentArrowDrag == nil {
                currentArrowDrag = ArrowAnnotation(
                    startPoint: normalizedLocation,
                    endPoint: normalizedLocation,
                    color: selectedColor
                )
            } else {
                currentArrowDrag?.endPoint = normalizedLocation
            }
        case .ended:
            if var arrow = currentArrowDrag {
                arrow.endPoint = normalizedLocation
                arrowAnnotations.append(arrow)
                recordAction(.addArrow(arrow))
                
                // Auto-select the newly created arrow
                selectedAnnotationId = arrow.id
                
                currentArrowDrag = nil
            }
        }
    }
    
    private func handleShapeDrag(at location: CGPoint, imageSize: CGSize, phase: DragPhase) {
        let normalizedLocation = CGPoint(
            x: location.x / imageSize.width,
            y: location.y / imageSize.height
        )
        
        let shapeType: ShapeType = currentTool == .circle ? .circle : .rectangle
        
        switch phase {
        case .changed:
            if currentShapeDrag == nil {
                currentShapeDrag = ShapeAnnotation(
                    type: shapeType,
                    origin: normalizedLocation,
                    size: .zero,
                    color: selectedColor
                )
            } else {
                let origin = currentShapeDrag!.origin
                currentShapeDrag?.size = CGSize(
                    width: normalizedLocation.x - origin.x,
                    height: normalizedLocation.y - origin.y
                )
            }
        case .ended:
            if let shape = currentShapeDrag {
                shapeAnnotations.append(shape)
                recordAction(.addShape(shape))
                
                // Auto-select the newly created shape
                selectedAnnotationId = shape.id
                
                currentShapeDrag = nil
            }
        }
    }
    
    private func handleMagnifierDrag(at location: CGPoint, imageSize: CGSize, phase: DragPhase) {
        // Don't create a new magnifier while one is selected — user must tap background to deselect first
        if selectedAnnotationId != nil { return }

        let normalizedLocation = CGPoint(
            x: location.x / imageSize.width,
            y: location.y / imageSize.height
        )
        
        switch phase {
        case .changed:
            if currentMagnifierDrag == nil {
                // Create magnifier at tap location
                currentMagnifierDrag = MagnifierAnnotation(
                    sourceCenter: normalizedLocation,
                    displayCenter: normalizedLocation,
                    radius: 0.1,
                    scale: 2.0
                )
            }
        case .ended:
            if let magnifier = currentMagnifierDrag {
                magnifierAnnotations.append(magnifier)
                recordAction(.addMagnifier(magnifier))
                
                // Auto-select the newly created magnifier
                selectedAnnotationId = magnifier.id
                
                currentMagnifierDrag = nil
            }
        }
    }
    
    private func handleEraserTap(at location: CGPoint) {
        // Remove annotation at tap location
        // Implementation depends on hit testing
    }
    
    func renderFinalImage() -> UIImage {
        guard let originalImage = originalImage else { return UIImage() }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: originalImage.size, format: format)
        return renderer.image { context in
            // Draw original image
            originalImage.draw(at: .zero)
            
            let scale = originalImage.size.width
            let cgContext = context.cgContext
            
            // Draw shapes
            for shape in shapeAnnotations {
                renderShape(shape, in: cgContext, scale: originalImage.size)
            }
            
            // Draw arrows
            for arrow in arrowAnnotations {
                renderArrow(arrow, in: cgContext, scale: originalImage.size)
            }
            
            // Draw magnifiers
            for magnifier in magnifierAnnotations {
                renderHighQualityMagnifier(magnifier, originalImage: originalImage, imageDisplaySize: imageDisplaySize, in: cgContext)
            }
            
            // Draw PencilKit content
            let drawingImage = drawing.image(from: CGRect(origin: .zero, size: originalImage.size), scale: 1.0)
            drawingImage.draw(at: .zero)
            
            // Draw text
            for text in textAnnotations {
                renderText(text, in: cgContext, scale: originalImage.size)
            }
        }
    }
    
    private func renderShape(_ shape: ShapeAnnotation, in context: CGContext, scale: CGSize) {
        let rect = CGRect(
            x: shape.origin.x * scale.width,
            y: shape.origin.y * scale.height,
            width: shape.size.width * scale.width,
            height: shape.size.height * scale.height
        ).standardized
        
        // Scale line width based on image size (0.5% of smaller dimension)
        let minDimension = min(scale.width, scale.height)
        let scaledLineWidth = minDimension * 0.005
        
        context.setStrokeColor(UIColor(shape.color).cgColor)
        context.setLineWidth(scaledLineWidth)
        
        switch shape.type {
        case .circle:
            context.strokeEllipse(in: rect)
        case .rectangle:
            context.stroke(rect)
        }
    }
    
    private func renderArrow(_ arrow: ArrowAnnotation, in context: CGContext, scale: CGSize) {
        let start = CGPoint(
            x: arrow.startPoint.x * scale.width,
            y: arrow.startPoint.y * scale.height
        )
        let end = CGPoint(
            x: arrow.endPoint.x * scale.width,
            y: arrow.endPoint.y * scale.height
        )
        
        // Scale line width based on image size (0.5% of smaller dimension)
        let minDimension = min(scale.width, scale.height)
        let scaledLineWidth = minDimension * 0.005 // 0.5% of smaller dimension
        
        // Scale arrowhead based on image size (2.5% of smaller dimension)
        let arrowLength = minDimension * 0.025
        let arrowAngle: CGFloat = .pi / 6
        
        context.setStrokeColor(UIColor(arrow.color).cgColor)
        context.setFillColor(UIColor(arrow.color).cgColor)
        context.setLineWidth(scaledLineWidth)
        
        // Draw line
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()
        
        // Draw arrowhead
        let angle = atan2(end.y - start.y, end.x - start.x)
        
        let point1 = CGPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        let point2 = CGPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )
        
        context.move(to: end)
        context.addLine(to: point1)
        context.addLine(to: point2)
        context.closePath()
        context.fillPath()
    }
    
    private func renderText(_ text: TextAnnotation, in context: CGContext, scale: CGSize) {
        let position = CGPoint(
            x: text.position.x * scale.width,
            y: text.position.y * scale.height
        )
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: text.fontSize * (scale.width / 400)),
            .foregroundColor: UIColor(text.color)
        ]
        
        let attributedString = NSAttributedString(string: text.text, attributes: attributes)
        attributedString.draw(at: position)
    }
}

// MARK: - Drag Phase
enum DragPhase {
    case changed, ended
}

// MARK: - Editor Tool
public enum EditorTool {
    case draw, arrow, text, circle, rectangle, magnifier, eraser
}

// MARK: - Anchor Type
enum AnchorType {
    case start, end, center
}

// MARK: - Annotations Layer
struct AnnotationsLayer: View {
    @ObservedObject var editorState: ImageEditorState
    let imageSize: CGSize
    let onTextTap: (TextAnnotation) -> Void
    
    var body: some View {
        ZStack {
            // Shapes
            ForEach(editorState.shapeAnnotations) { shape in
                ShapeAnnotationView(
                    shape: shape,
                    imageSize: imageSize,
                    isSelected: editorState.selectedAnnotationId == shape.id,
                    onSelect: { editorState.selectedAnnotationId = shape.id },
                    onUpdate: { updated in
                        if let index = editorState.shapeAnnotations.firstIndex(where: { $0.id == shape.id }) {
                            editorState.shapeAnnotations[index] = updated
                        }
                    }
                )
            }
            
            // Current shape being drawn
            if let shape = editorState.currentShapeDrag {
                ShapeAnnotationView(
                    shape: shape,
                    imageSize: imageSize,
                    isSelected: false,
                    onSelect: {},
                    onUpdate: { _ in }
                )
            }
            
            // Arrows
            ForEach(editorState.arrowAnnotations) { arrow in
                ArrowAnnotationView(
                    arrow: arrow,
                    imageSize: imageSize,
                    isSelected: editorState.selectedAnnotationId == arrow.id,
                    onSelect: { editorState.selectedAnnotationId = arrow.id },
                    onUpdate: { updated in
                        if let index = editorState.arrowAnnotations.firstIndex(where: { $0.id == arrow.id }) {
                            editorState.arrowAnnotations[index] = updated
                        }
                    }
                )
            }
            
            // Current arrow being drawn
            if let arrow = editorState.currentArrowDrag {
                ArrowAnnotationView(
                    arrow: arrow,
                    imageSize: imageSize,
                    isSelected: false,
                    onSelect: {},
                    onUpdate: { _ in }
                )
            }
            
            // Magnifiers
            ForEach(editorState.magnifierAnnotations) { magnifier in
                MagnifierAnnotationView(
                    magnifier: magnifier,
                    originalImage: editorState.originalImage ?? UIImage(),
                    imageSize: imageSize,
                    isSelected: editorState.selectedAnnotationId == magnifier.id,
                    onSelect: { editorState.selectedAnnotationId = magnifier.id },
                    onUpdate: { updated in
                        if let index = editorState.magnifierAnnotations.firstIndex(where: { $0.id == magnifier.id }) {
                            editorState.magnifierAnnotations[index] = updated
                        }
                    }
                )
            }
            
            // Current magnifier being drawn
            if let magnifier = editorState.currentMagnifierDrag {
                MagnifierAnnotationView(
                    magnifier: magnifier,
                    originalImage: editorState.originalImage ?? UIImage(),
                    imageSize: imageSize,
                    isSelected: false,
                    onSelect: {},
                    onUpdate: { _ in }
                )
            }
            
            // Text annotations
            ForEach(editorState.textAnnotations) { text in
                TextAnnotationView(
                    annotation: text,
                    imageSize: imageSize,
                    isSelected: editorState.selectedAnnotationId == text.id,
                    onSelect: { editorState.selectedAnnotationId = text.id },
                    onTap: { onTextTap(text) },
                    onUpdate: { updated in
                        if let index = editorState.textAnnotations.firstIndex(where: { $0.id == text.id }) {
                            editorState.textAnnotations[index] = updated
                        }
                    }
                )
                .onAppear {
                    print("Rendering text annotation: '\(text.text)' at position (\(text.position.x), \(text.position.y))")
                }
            }
        }
    }
}

// MARK: - Editor Actions for Undo/Redo
enum EditorAction {
    case addArrow(ArrowAnnotation)
    case removeArrow(ArrowAnnotation)
    case addShape(ShapeAnnotation)
    case removeShape(ShapeAnnotation)
    case addText(TextAnnotation)
    case removeText(TextAnnotation)
    case addMagnifier(MagnifierAnnotation)
    case removeMagnifier(MagnifierAnnotation)
    
    func undo(state: ImageEditorState) {
        switch self {
        case .addArrow(let arrow):
            state.arrowAnnotations.removeAll { $0.id == arrow.id }
        case .removeArrow(let arrow):
            state.arrowAnnotations.append(arrow)
        case .addShape(let shape):
            state.shapeAnnotations.removeAll { $0.id == shape.id }
        case .removeShape(let shape):
            state.shapeAnnotations.append(shape)
        case .addText(let text):
            state.textAnnotations.removeAll { $0.id == text.id }
        case .removeText(let text):
            state.textAnnotations.append(text)
        case .addMagnifier(let magnifier):
            state.magnifierAnnotations.removeAll { $0.id == magnifier.id }
        case .removeMagnifier(let magnifier):
            state.magnifierAnnotations.append(magnifier)
        }
    }
    
    func redo(state: ImageEditorState) {
        switch self {
        case .addArrow(let arrow):
            state.arrowAnnotations.append(arrow)
        case .removeArrow(let arrow):
            state.arrowAnnotations.removeAll { $0.id == arrow.id }
        case .addShape(let shape):
            state.shapeAnnotations.append(shape)
        case .removeShape(let shape):
            state.shapeAnnotations.removeAll { $0.id == shape.id }
        case .addText(let text):
            state.textAnnotations.append(text)
        case .removeText(let text):
            state.textAnnotations.removeAll { $0.id == text.id }
        case .addMagnifier(let magnifier):
            state.magnifierAnnotations.append(magnifier)
        case .removeMagnifier(let magnifier):
            state.magnifierAnnotations.removeAll { $0.id == magnifier.id }
        }
    }
    
    func inverse(state: ImageEditorState) -> EditorAction {
        switch self {
        case .addArrow(let arrow): return .removeArrow(arrow)
        case .removeArrow(let arrow): return .addArrow(arrow)
        case .addShape(let shape): return .removeShape(shape)
        case .removeShape(let shape): return .addShape(shape)
        case .addText(let text): return .removeText(text)
        case .removeText(let text): return .addText(text)
        case .addMagnifier(let magnifier): return .removeMagnifier(magnifier)
        case .removeMagnifier(let magnifier): return .addMagnifier(magnifier)
        }
    }
}
