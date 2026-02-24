//
//  MagnifierView.swift
//  TestUIProject
//
//  Created by Vishakh on 12/10/25.
//

import SwiftUI

// MARK: - Enhanced Magnifier Annotation View
/// A magnifier view that shows a zoomed portion of the image with a pointer
/// connecting to the source area - similar to the iOS screenshot editor
struct EnhancedMagnifierView: View {
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
        Canvas { context, size in
            // Draw connecting line with gradient
            let linePath = Path { path in
                path.move(to: sourcePosition)
                path.addLine(to: displayPosition)
            }
            
            context.stroke(
                linePath,
                with: .color(.orange),
                lineWidth: 2
            )
            
            // Draw source indicator (small circle at magnify point)
            let sourceIndicatorPath = Circle()
                .path(in: CGRect(
                    x: sourcePosition.x - 8,
                    y: sourcePosition.y - 8,
                    width: 16,
                    height: 16
                ))
            
            context.fill(sourceIndicatorPath, with: .color(.orange))
            context.stroke(sourceIndicatorPath, with: .color(.white), lineWidth: 2)
            
            // Draw magnifier circle border
            let magnifierPath = Circle()
                .path(in: CGRect(
                    x: displayPosition.x - radius,
                    y: displayPosition.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
            
            context.stroke(magnifierPath, with: .color(.orange), lineWidth: 4)
        }
        
        // Magnified content overlay
        MagnifiedContentView(
            image: originalImage,
            sourceCenter: magnifier.sourceCenter,
            scale: magnifier.scale,
            size: radius * 2
        )
        .frame(width: radius * 2, height: radius * 2)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color.orange, lineWidth: 4)
        )
        .shadow(color: .black.opacity(0.3), radius: 4)
        .position(displayPosition)
        
        // Interactive anchors when selected
        if isSelected {
            // Source anchor (where to magnify from)
            MagnifierAnchor(
                position: sourcePosition,
                type: .source,
                onDrag: { newPos in
                    var updated = magnifier
                    updated.sourceCenter = CGPoint(
                        x: newPos.x / imageSize.width,
                        y: newPos.y / imageSize.height
                    )
                    onUpdate(updated)
                }
            )
            
            // Display anchor (where the magnifier circle appears)
            MagnifierAnchor(
                position: displayPosition,
                type: .display,
                onDrag: { newPos in
                    var updated = magnifier
                    updated.displayCenter = CGPoint(
                        x: newPos.x / imageSize.width,
                        y: newPos.y / imageSize.height
                    )
                    onUpdate(updated)
                }
            )
            
            // Resize anchor (on the edge of magnifier)
            MagnifierAnchor(
                position: CGPoint(x: displayPosition.x + radius, y: displayPosition.y),
                type: .resize,
                onDrag: { newPos in
                    var updated = magnifier
                    let newRadius = abs(newPos.x - displayPosition.x) / imageSize.width
                    updated.radius = max(0.05, min(0.25, newRadius))
                    onUpdate(updated)
                }
            )
            
            // Scale control (to adjust magnification level)
            ScaleControlView(
                position: CGPoint(x: displayPosition.x, y: displayPosition.y + radius + 20),
                scale: magnifier.scale,
                onScaleChange: { newScale in
                    var updated = magnifier
                    updated.scale = newScale
                    onUpdate(updated)
                }
            )
        }
    }
}

// MARK: - Magnified Content View
struct MagnifiedContentView: View {
    let image: UIImage
    let sourceCenter: CGPoint
    let scale: CGFloat
    let size: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            if let magnifiedImage = createMagnifiedImage() {
                Image(uiImage: magnifiedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
    
    private func createMagnifiedImage() -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        // Calculate the source rect in image coordinates
        let imageSourceCenter = CGPoint(
            x: sourceCenter.x * image.size.width,
            y: sourceCenter.y * image.size.height
        )
        
        let captureRadius = (size / 2) / scale
        
        let sourceRect = CGRect(
            x: imageSourceCenter.x - captureRadius,
            y: imageSourceCenter.y - captureRadius,
            width: captureRadius * 2,
            height: captureRadius * 2
        ).intersection(CGRect(origin: .zero, size: image.size))
        
        guard !sourceRect.isEmpty,
              let croppedImage = cgImage.cropping(to: sourceRect) else {
            return nil
        }
        
        return UIImage(cgImage: croppedImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

// MARK: - Magnifier Anchor Types
enum MagnifierAnchorType {
    case source
    case display
    case resize
}

// MARK: - Magnifier Anchor View
struct MagnifierAnchor: View {
    let position: CGPoint
    let type: MagnifierAnchorType
    let onDrag: (CGPoint) -> Void
    
    @State private var isDragging = false
    
    private var anchorColor: Color {
        switch type {
        case .source: return .orange
        case .display: return .blue
        case .resize: return .green
        }
    }
    
    private var anchorSize: CGFloat {
        switch type {
        case .source: return 16
        case .display: return 20
        case .resize: return 14
        }
    }
    
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(anchorColor, lineWidth: 2)
                .frame(width: anchorSize + 8, height: anchorSize + 8)
            
            // Inner fill
            Circle()
                .fill(anchorColor)
                .frame(width: anchorSize, height: anchorSize)
            
            // Icon based on type
            Image(systemName: iconForType)
                .font(.system(size: anchorSize * 0.5, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(isDragging ? 1.3 : 1.0)
        .position(position)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    onDrag(value.location)
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
        .animation(.spring(response: 0.3), value: isDragging)
    }
    
    private var iconForType: String {
        switch type {
        case .source: return "viewfinder"
        case .display: return "arrow.up.and.down.and.arrow.left.and.right"
        case .resize: return "arrow.left.and.right"
        }
    }
}

// MARK: - Scale Control View
struct ScaleControlView: View {
    let position: CGPoint
    let scale: CGFloat
    let onScaleChange: (CGFloat) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Button(action: { onScaleChange(max(1.5, scale - 0.5)) }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.orange)
            }
            
            Text("\(scale, specifier: "%.1f")x")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange)
                .cornerRadius(4)
            
            Button(action: { onScaleChange(min(4.0, scale + 0.5)) }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.orange)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
        .position(position)
    }
}

// MARK: - Magnifier Creation Helper
extension ImageEditorState {
    /// Creates a magnifier at the specified location
    func createMagnifier(at normalizedLocation: CGPoint) -> MagnifierAnnotation {
        // Position the display circle above and to the right of the source
        let displayOffset: CGFloat = 0.15
        
        return MagnifierAnnotation(
            sourceCenter: normalizedLocation,
            displayCenter: CGPoint(
                x: min(0.8, normalizedLocation.x + displayOffset),
                y: max(0.2, normalizedLocation.y - displayOffset)
            ),
            radius: 0.12,
            scale: 2.0
        )
    }
}

// MARK: - High Quality Magnifier Renderer
extension ImageEditorState {
    /// Renders a magnifier annotation at full resolution
    func renderHighQualityMagnifier(
        _ magnifier: MagnifierAnnotation,
        originalImage: UIImage,
        imageDisplaySize: CGSize,
        in context: CGContext
    ) {
        let imageSize = originalImage.size
        
        // Calculate positions in image coordinates
        let displayCenter = CGPoint(
            x: magnifier.displayCenter.x * imageSize.width,
            y: magnifier.displayCenter.y * imageSize.height
        )
        let sourceCenter = CGPoint(
            x: magnifier.sourceCenter.x * imageSize.width,
            y: magnifier.sourceCenter.y * imageSize.height
        )
        let radius = magnifier.radius * imageSize.width
        
        // Draw connecting line
        context.setStrokeColor(UIColor.orange.cgColor)
        context.setLineWidth(3)
        context.move(to: sourceCenter)
        context.addLine(to: displayCenter)
        context.strokePath()
        
        // Draw source indicator dot
        context.setFillColor(UIColor.orange.cgColor)
        let sourceIndicatorRect = CGRect(
            x: sourceCenter.x - 6,
            y: sourceCenter.y - 6,
            width: 12,
            height: 12
        )
        context.fillEllipse(in: sourceIndicatorRect)
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(2)
        context.strokeEllipse(in: sourceIndicatorRect)
        
        // Create circular clip path
        let circlePath = UIBezierPath(
            arcCenter: displayCenter,
            radius: radius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        )

        context.saveGState()
        context.addPath(circlePath.cgPath)
        context.clip()

        // Use the on-screen display width for capture — matches what the user sees
        let captureRadius = (magnifier.radius * imageDisplaySize.width) / magnifier.scale
        let sourceRect = CGRect(
            x: sourceCenter.x - captureRadius,
            y: sourceCenter.y - captureRadius,
            width: captureRadius * 2,
            height: captureRadius * 2
        )

        // Clamp to image bounds
        let clampedRect = sourceRect.intersection(CGRect(origin: .zero, size: imageSize))
        if !clampedRect.isEmpty {
            // Crop using a separate UIKit renderer — handles orientation correctly
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let cropRenderer = UIGraphicsImageRenderer(size: clampedRect.size, format: format)
            let croppedImage = cropRenderer.image { _ in
                originalImage.draw(at: CGPoint(x: -clampedRect.origin.x, y: -clampedRect.origin.y))
            }

            // Draw cropped image stretched into the display circle = magnification
            let drawRect = CGRect(
                x: displayCenter.x - radius,
                y: displayCenter.y - radius,
                width: radius * 2,
                height: radius * 2
            )
            croppedImage.draw(in: drawRect)
        }

        context.restoreGState()
        
        // Draw magnifier border
        context.setStrokeColor(UIColor.orange.cgColor)
        context.setLineWidth(5)
        context.addPath(circlePath.cgPath)
        context.strokePath()
        
        // Add subtle shadow effect (inner glow simulation)
        context.setStrokeColor(UIColor.orange.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(8)
        let outerCircle = UIBezierPath(
            arcCenter: displayCenter,
            radius: radius + 2,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        )
        context.addPath(outerCircle.cgPath)
        context.strokePath()
    }
}

// MARK: - Preview
#Preview {
    if let testImage = UIImage(systemName: "photo.fill")?.withTintColor(.blue) {
        EnhancedMagnifierView(
            magnifier: MagnifierAnnotation(
                sourceCenter: CGPoint(x: 0.3, y: 0.7),
                displayCenter: CGPoint(x: 0.6, y: 0.3),
                radius: 0.15,
                scale: 2.0
            ),
            originalImage: testImage,
            imageSize: CGSize(width: 400, height: 600),
            isSelected: true,
            onSelect: {},
            onUpdate: { _ in }
        )
        .frame(width: 400, height: 600)
        .background(Color.gray.opacity(0.3))
    }
}
