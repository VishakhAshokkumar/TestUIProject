//
//  AnnotationModel.swift
//  TestUIProject
//
//  Created by Vishakh on 12/10/25.
//

import SwiftUI

// MARK: - Arrow Annotation
struct ArrowAnnotation: Identifiable, Equatable {
    let id = UUID()
    var startPoint: CGPoint // Normalized 0-1
    var endPoint: CGPoint   // Normalized 0-1
    var color: Color
    var lineWidth: CGFloat = 3
    
    static func == (lhs: ArrowAnnotation, rhs: ArrowAnnotation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Text Annotation
struct TextAnnotation: Identifiable, Equatable {
    let id = UUID()
    var text: String
    var position: CGPoint // Normalized 0-1
    var color: Color
    var fontSize: CGFloat = 24
    var rotation: Angle = .zero
    
    static func == (lhs: TextAnnotation, rhs: TextAnnotation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Shape Type
enum ShapeType: String, CaseIterable {
    case circle
    case rectangle
}

// MARK: - Shape Annotation
struct ShapeAnnotation: Identifiable, Equatable {
    let id = UUID()
    var type: ShapeType
    var origin: CGPoint   // Normalized 0-1
    var size: CGSize      // Normalized 0-1
    var color: Color
    var lineWidth: CGFloat = 3
    var isFilled: Bool = false
    
    static func == (lhs: ShapeAnnotation, rhs: ShapeAnnotation) -> Bool {
        lhs.id == rhs.id
    }
    
    var normalizedRect: CGRect {
        CGRect(origin: origin, size: size).standardized
    }
}

// MARK: - Magnifier Annotation
struct MagnifierAnnotation: Identifiable, Equatable {
    let id = UUID()
    var sourceCenter: CGPoint    // Where to magnify from (normalized 0-1)
    var displayCenter: CGPoint   // Where to display the magnifier (normalized 0-1)
    var radius: CGFloat          // Normalized radius
    var scale: CGFloat = 1.0     // Magnification level
    
    static func == (lhs: MagnifierAnnotation, rhs: MagnifierAnnotation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Arrow Annotation View
struct ArrowAnnotationView: View {
    let arrow: ArrowAnnotation
    let imageSize: CGSize
    let isSelected: Bool
    let onSelect: () -> Void
    let onUpdate: (ArrowAnnotation) -> Void
    
    @State private var isDraggingStart = false
    @State private var isDraggingEnd = false
    
    private var startPosition: CGPoint {
        CGPoint(
            x: arrow.startPoint.x * imageSize.width,
            y: arrow.startPoint.y * imageSize.height
        )
    }
    
    private var endPosition: CGPoint {
        CGPoint(
            x: arrow.endPoint.x * imageSize.width,
            y: arrow.endPoint.y * imageSize.height
        )
    }
    
    var body: some View {
        ZStack {
            // Arrow line with arrowhead
            ArrowShape(start: startPosition, end: endPosition)
                .stroke(arrow.color, lineWidth: arrow.lineWidth)
                .contentShape(ArrowHitTestShape(start: startPosition, end: endPosition))
                .onTapGesture {
                    onSelect()
                }
            
            // Arrowhead fill
            ArrowHeadShape(start: startPosition, end: endPosition)
                .fill(arrow.color)
                .allowsHitTesting(false)
            
            // Anchor points (visible when selected) with BLUE color
            if isSelected {
                // Start anchor - BLUE
                DraggableAnchor(
                    position: startPosition,
                    color: .blue,
                    onDrag: { newPosition in
                        var updated = arrow
                        updated.startPoint = CGPoint(
                            x: max(0, min(1, newPosition.x / imageSize.width)),
                            y: max(0, min(1, newPosition.y / imageSize.height))
                        )
                        onUpdate(updated)
                    }
                )
                
                // End anchor - BLUE
                DraggableAnchor(
                    position: endPosition,
                    color: .blue,
                    onDrag: { newPosition in
                        var updated = arrow
                        updated.endPoint = CGPoint(
                            x: max(0, min(1, newPosition.x / imageSize.width)),
                            y: max(0, min(1, newPosition.y / imageSize.height))
                        )
                        onUpdate(updated)
                    }
                )
                
                // Middle anchor for moving whole arrow - BLUE
                DraggableAnchor(
                    position: CGPoint(
                        x: (startPosition.x + endPosition.x) / 2,
                        y: (startPosition.y + endPosition.y) / 2
                    ),
                    color: .blue,
                    size: 12,
                    onDrag: { newPosition in
                        let midPoint = CGPoint(
                            x: (startPosition.x + endPosition.x) / 2,
                            y: (startPosition.y + endPosition.y) / 2
                        )
                        let delta = CGPoint(
                            x: newPosition.x - midPoint.x,
                            y: newPosition.y - midPoint.y
                        )
                        var updated = arrow
                        let newStart = CGPoint(
                            x: (startPosition.x + delta.x) / imageSize.width,
                            y: (startPosition.y + delta.y) / imageSize.height
                        )
                        let newEnd = CGPoint(
                            x: (endPosition.x + delta.x) / imageSize.width,
                            y: (endPosition.y + delta.y) / imageSize.height
                        )
                        updated.startPoint = CGPoint(
                            x: max(0, min(1, newStart.x)),
                            y: max(0, min(1, newStart.y))
                        )
                        updated.endPoint = CGPoint(
                            x: max(0, min(1, newEnd.x)),
                            y: max(0, min(1, newEnd.y))
                        )
                        onUpdate(updated)
                    }
                )
            }
        }
    }
}

// MARK: - Arrow Shape
struct ArrowShape: Shape {
    let start: CGPoint
    let end: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        return path
    }
}

// MARK: - Arrow Head Shape
struct ArrowHeadShape: Shape {
    let start: CGPoint
    let end: CGPoint
    
    func path(in rect: CGRect) -> Path {
        let angle = atan2(end.y - start.y, end.x - start.x)
        let arrowLength: CGFloat = 15
        let arrowAngle: CGFloat = .pi / 6
        
        let point1 = CGPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        let point2 = CGPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )
        
        var path = Path()
        path.move(to: end)
        path.addLine(to: point1)
        path.addLine(to: point2)
        path.closeSubpath()
        return path
    }
}

// MARK: - Arrow Hit Test Shape
struct ArrowHitTestShape: Shape {
    let start: CGPoint
    let end: CGPoint
    let hitWidth: CGFloat = 30
    
    func path(in rect: CGRect) -> Path {
        let angle = atan2(end.y - start.y, end.x - start.x)
        let perpAngle = angle + .pi / 2
        let offset = CGPoint(
            x: cos(perpAngle) * hitWidth / 2,
            y: sin(perpAngle) * hitWidth / 2
        )
        
        var path = Path()
        path.move(to: CGPoint(x: start.x + offset.x, y: start.y + offset.y))
        path.addLine(to: CGPoint(x: end.x + offset.x, y: end.y + offset.y))
        path.addLine(to: CGPoint(x: end.x - offset.x, y: end.y - offset.y))
        path.addLine(to: CGPoint(x: start.x - offset.x, y: start.y - offset.y))
        path.closeSubpath()
        return path
    }
}

// MARK: - Shape Annotation View
struct ShapeAnnotationView: View {
    let shape: ShapeAnnotation
    let imageSize: CGSize
    let isSelected: Bool
    let onSelect: () -> Void
    let onUpdate: (ShapeAnnotation) -> Void
    
    private var rect: CGRect {
        let normalized = shape.normalizedRect
        return CGRect(
            x: normalized.origin.x * imageSize.width,
            y: normalized.origin.y * imageSize.height,
            width: normalized.size.width * imageSize.width,
            height: normalized.size.height * imageSize.height
        )
    }
    
    var body: some View {
        ZStack {
            // Shape
            Group {
                switch shape.type {
                case .circle:
                    Ellipse()
                        .stroke(shape.color, lineWidth: shape.lineWidth)
                        .frame(width: abs(rect.width), height: abs(rect.height))
                        .position(x: rect.midX, y: rect.midY)
                case .rectangle:
                    Rectangle()
                        .stroke(shape.color, lineWidth: shape.lineWidth)
                        .frame(width: abs(rect.width), height: abs(rect.height))
                        .position(x: rect.midX, y: rect.midY)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }
            
            // Resize handles when selected - BLUE color
            if isSelected {
                // Corner handles
                ForEach(0..<4, id: \.self) { index in
                    let position = cornerPosition(index: index)
                    DraggableAnchor(
                        position: position,
                        color: .blue,
                        onDrag: { newPos in
                            handleCornerDrag(index: index, newPosition: newPos)
                        }
                    )
                }
                
                // Center handle for moving - BLUE
                DraggableAnchor(
                    position: CGPoint(x: rect.midX, y: rect.midY),
                    color: .blue,
                    size: 12,
                    onDrag: { newPos in
                        let delta = CGPoint(
                            x: (newPos.x - rect.midX) / imageSize.width,
                            y: (newPos.y - rect.midY) / imageSize.height
                        )
                        var updated = shape
                        updated.origin = CGPoint(
                            x: max(0, min(1, shape.origin.x + delta.x)),
                            y: max(0, min(1, shape.origin.y + delta.y))
                        )
                        onUpdate(updated)
                    }
                )
            }
        }
    }
    
    private func cornerPosition(index: Int) -> CGPoint {
        switch index {
        case 0: return CGPoint(x: rect.minX, y: rect.minY)
        case 1: return CGPoint(x: rect.maxX, y: rect.minY)
        case 2: return CGPoint(x: rect.maxX, y: rect.maxY)
        case 3: return CGPoint(x: rect.minX, y: rect.maxY)
        default: return .zero
        }
    }
    
    private func handleCornerDrag(index: Int, newPosition: CGPoint) {
        var updated = shape
        let normalizedNew = CGPoint(
            x: max(0, min(1, newPosition.x / imageSize.width)),
            y: max(0, min(1, newPosition.y / imageSize.height))
        )
        
        let currentRect = shape.normalizedRect
        
        switch index {
        case 0: // Top-left
            updated.origin = normalizedNew
            updated.size = CGSize(
                width: currentRect.maxX - normalizedNew.x,
                height: currentRect.maxY - normalizedNew.y
            )
        case 1: // Top-right
            updated.origin = CGPoint(x: currentRect.minX, y: normalizedNew.y)
            updated.size = CGSize(
                width: normalizedNew.x - currentRect.minX,
                height: currentRect.maxY - normalizedNew.y
            )
        case 2: // Bottom-right
            updated.size = CGSize(
                width: normalizedNew.x - currentRect.minX,
                height: normalizedNew.y - currentRect.minY
            )
        case 3: // Bottom-left
            updated.origin = CGPoint(x: normalizedNew.x, y: currentRect.minY)
            updated.size = CGSize(
                width: currentRect.maxX - normalizedNew.x,
                height: normalizedNew.y - currentRect.minY
            )
        default:
            break
        }
        
        onUpdate(updated)
    }
}

// MARK: - Text Annotation View
struct TextAnnotationView: View {
    let annotation: TextAnnotation
    let imageSize: CGSize
    let isSelected: Bool
    let onSelect: () -> Void
    let onTap: () -> Void
    let onUpdate: (TextAnnotation) -> Void
    
    @State private var dragOffset: CGSize = .zero
    
    private var position: CGPoint {
        CGPoint(
            x: annotation.position.x * imageSize.width,
            y: annotation.position.y * imageSize.height
        )
    }
    
    var body: some View {
        Text(annotation.text)
            .font(.system(size: annotation.fontSize, weight: .bold))
            .foregroundColor(annotation.color)
            .padding(8)
            .background(
                isSelected ?
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.blue.opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [5]))
                : nil
            )
            .position(
                x: position.x + dragOffset.width,
                y: position.y + dragOffset.height
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        var updated = annotation
                        let newX = (position.x + value.translation.width) / imageSize.width
                        let newY = (position.y + value.translation.height) / imageSize.height
                        updated.position = CGPoint(
                            x: max(0, min(1, newX)),
                            y: max(0, min(1, newY))
                        )
                        onUpdate(updated)
                        dragOffset = .zero
                    }
            )
            .onTapGesture(count: 2) {
                onTap()
            }
            .onTapGesture {
                onSelect()
            }
    }
}

// MARK: - Magnifier Annotation View
struct MagnifierAnnotationView: View {
    let magnifier: MagnifierAnnotation
    let originalImage: UIImage
    let imageSize: CGSize
    let isSelected: Bool
    let onSelect: () -> Void
    let onUpdate: (MagnifierAnnotation) -> Void
    
    private var sourcePosition: CGPoint {
        CGPoint(
            x: magnifier.sourceCenter.x * imageSize.width,
            y: magnifier.sourceCenter.y * imageSize.height
        )
    }
    
    private var displayPosition: CGPoint {
        CGPoint(
            x: magnifier.displayCenter.x * imageSize.width,
            y: magnifier.displayCenter.y * imageSize.height
        )
    }
    
    private var radius: CGFloat {
        magnifier.radius * imageSize.width
    }
    
    var body: some View {
        ZStack {
            // Magnifier circle with content
            ZStack {
                // Magnified content
                MagnifierCircleView(
                    image: originalImage,
                    sourceCenter: magnifier.sourceCenter,
                    radius: magnifier.radius,
                    scale: magnifier.scale,
                    imageSize: imageSize
                )
                .frame(width: radius * 2, height: radius * 2)
                .clipShape(Circle())
                
                // Orange border
                Circle()
                    .stroke(Color.orange, lineWidth: 4)
                    .frame(width: radius * 2, height: radius * 2)
            }
            .shadow(color: .black.opacity(0.3), radius: 4)
            .position(displayPosition)
            .onTapGesture {
                onSelect()
            }
            
            // Resize handle (bottom-right of circle) when selected
            if isSelected {
                ResizeHandle(
                    position: CGPoint(
                        x: displayPosition.x + radius * cos(.pi / 4),
                        y: displayPosition.y + radius * sin(.pi / 4)
                    ),
                    onDrag: { newPos in
                        // Calculate new radius from center to drag position
                        let dx = newPos.x - displayPosition.x
                        let dy = newPos.y - displayPosition.y
                        let distance = sqrt(dx * dx + dy * dy)
                        var updated = magnifier
                        updated.radius = max(0.05, min(0.3, distance / imageSize.width))
                        onUpdate(updated)
                    }
                )
                
                // Magnification slider below the circle
                MagnificationSlider(
                    position: CGPoint(
                        x: displayPosition.x,
                        y: displayPosition.y + radius + 40
                    ),
                    scale: magnifier.scale,
                    onScaleChange: { newScale in
                        var updated = magnifier
                        updated.scale = newScale
                        onUpdate(updated)
                    }
                )
                
                // Move handle for repositioning the entire magnifier
                MoveHandle(
                    position: displayPosition,
                    onDrag: { newPos in
                        var updated = magnifier
                        // Calculate the offset from current position
                        let dx = (newPos.x - displayPosition.x) / imageSize.width
                        let dy = (newPos.y - displayPosition.y) / imageSize.height
                        
                        // Update both display and source positions to move together
                        updated.displayCenter = CGPoint(
                            x: max(0, min(1, magnifier.displayCenter.x + dx)),
                            y: max(0, min(1, magnifier.displayCenter.y + dy))
                        )
                        updated.sourceCenter = CGPoint(
                            x: max(0, min(1, magnifier.sourceCenter.x + dx)),
                            y: max(0, min(1, magnifier.sourceCenter.y + dy))
                        )
                        onUpdate(updated)
                    }
                )
            }
        }
    }
}

// MARK: - Resize Handle (iOS style)
struct ResizeHandle: View {
    let position: CGPoint
    let onDrag: (CGPoint) -> Void
    
    @State private var isDragging = false
    
    var body: some View {
        ZStack {
            // White circle background
            Circle()
                .fill(Color.white)
                .frame(width: 30, height: 30)
                .shadow(color: .black.opacity(0.2), radius: 2)
            
            // Blue icon
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.blue)
        }
        .scaleEffect(isDragging ? 1.2 : 1.0)
        .position(position)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isDragging = true
                    onDrag(value.location)
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isDragging)
    }
}

// MARK: - Move Handle (for dragging entire magnifier)
struct MoveHandle: View {
    let position: CGPoint
    let onDrag: (CGPoint) -> Void
    
    @State private var isDragging = false
    
    var body: some View {
        Circle()
            .fill(Color.clear)
            .frame(width: 60, height: 60)
            .contentShape(Circle())
            .position(position)
            .gesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        isDragging = true
                        onDrag(value.location)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
    }
}

// MARK: - Magnification Slider (iOS style)
struct MagnificationSlider: View {
    let position: CGPoint
    let scale: CGFloat
    let onScaleChange: (CGFloat) -> Void
    
    @State private var isDragging = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Slider track
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                    
                    // Active track
                    Capsule()
                        .fill(Color.white)
                        .frame(width: sliderPosition(in: geometry.size.width), height: 4)
                    
                    // Slider thumb
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .shadow(color: .black.opacity(0.2), radius: 2)
                        .position(
                            x: sliderPosition(in: geometry.size.width),
                            y: geometry.size.height / 2
                        )
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    isDragging = true
                                    let newPosition = max(0, min(value.location.x, geometry.size.width))
                                    let percentage = newPosition / geometry.size.width
                                    let newScale = 1.0 + (percentage * 3.0) // 1x to 4x
                                    onScaleChange(newScale)
                                }
                                .onEnded { _ in
                                    isDragging = false
                                }
                        )
                }
            }
            .frame(width: 200, height: 28)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.6))
        )
        .position(position)
    }
    
    private func sliderPosition(in width: CGFloat) -> CGFloat {
        let percentage = (scale - 1.0) / 3.0 // 1x to 4x maps to 0 to 1
        return max(0, min(width, percentage * width))
    }
}

// MARK: - Magnifier Circle View (UIKit based for performance)
struct MagnifierCircleView: UIViewRepresentable {
    let image: UIImage
    let sourceCenter: CGPoint
    let radius: CGFloat
    let scale: CGFloat
    let imageSize: CGSize
    
    func makeUIView(context: Context) -> MagnifierUIView {
        let view = MagnifierUIView()
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: MagnifierUIView, context: Context) {
        uiView.image = image
        uiView.sourceCenter = sourceCenter
        uiView.radius = radius
        uiView.scale = scale
        uiView.imageSize = imageSize
        uiView.setNeedsDisplay()
    }
}

class MagnifierUIView: UIView {
    var image: UIImage?
    var sourceCenter: CGPoint = .zero
    var radius: CGFloat = 0.1
    var scale: CGFloat = 2.0
    var imageSize: CGSize = .zero
    
    override func draw(_ rect: CGRect) {
        guard let image = image,
              let cgImage = image.cgImage,
              let context = UIGraphicsGetCurrentContext() else { return }
        
        // Calculate source rect in image coordinates
        let imageSourceCenter = CGPoint(
            x: sourceCenter.x * image.size.width,
            y: sourceCenter.y * image.size.height
        )
        let imageRadius = (radius * imageSize.width) / scale
        
        let sourceRect = CGRect(
            x: imageSourceCenter.x - imageRadius,
            y: imageSourceCenter.y - imageRadius,
            width: imageRadius * 2,
            height: imageRadius * 2
        )
        
        // Crop and draw
        if let croppedImage = cgImage.cropping(to: sourceRect) {
            // Flip context for correct image orientation
            context.translateBy(x: 0, y: rect.height)
            context.scaleBy(x: 1, y: -1)
            context.draw(croppedImage, in: rect)
        }
    }
}

// MARK: - Draggable Anchor
struct DraggableAnchor: View {
    let position: CGPoint
    let color: Color
    var size: CGFloat = 14
    let onDrag: (CGPoint) -> Void
    
    @State private var isDragging = false
    
    var body: some View {
        ZStack {
            // Outer white border
            Circle()
                .fill(Color.white)
                .frame(width: size + 3, height: size + 3)
                .shadow(color: .black.opacity(0.3), radius: 2)
            
            // Inner colored circle
            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
        .scaleEffect(isDragging ? 1.4 : 1.0)
        .position(position)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isDragging = true
                    onDrag(value.location)
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isDragging)
    }
}
