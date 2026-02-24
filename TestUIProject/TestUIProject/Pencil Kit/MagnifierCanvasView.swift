//
//  MagnifierCanvasView.swift
//  TestUIProject
//
//  Created by Vishakh on 02/19/26.
//

import SwiftUI
import PencilKit

// MARK: - Main View
struct MagnifierCanvasView: View {
    @State private var drawing = PKDrawing()
    @State private var showToolPicker = true
    @State private var magnifierEnabled = false
    @State private var magnifierPosition = CGPoint(x: 200, y: 300)
    @State private var canvasSnapshot: UIImage?
    @State private var magnifierScale: CGFloat = 2.5

    private let magnifierSize: CGFloat = 160

    var body: some View {
        NavigationStack {
            ZStack {
                // PencilKit canvas
                SnapshotCanvasView(
                    drawing: $drawing,
                    showToolPicker: $showToolPicker,
                    onDrawingChanged: { snapshot in
                        canvasSnapshot = snapshot
                    }
                )
                .ignoresSafeArea(edges: .bottom)

                // Magnifier loupe overlay
                if magnifierEnabled {
                    MagnifierLoupe(
                        position: $magnifierPosition,
                        snapshot: canvasSnapshot,
                        scale: magnifierScale,
                        size: magnifierSize
                    )
                }
            }
            .navigationTitle("Magnifier Canvas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        magnifierEnabled.toggle()
                    } label: {
                        Image(systemName: magnifierEnabled ? "magnifyingglass.circle.fill" : "magnifyingglass.circle")
                            .foregroundStyle(magnifierEnabled ? .orange : .blue)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        if magnifierEnabled {
                            Menu {
                                Button("2x") { magnifierScale = 2.0 }
                                Button("2.5x") { magnifierScale = 2.5 }
                                Button("3x") { magnifierScale = 3.0 }
                                Button("4x") { magnifierScale = 4.0 }
                            } label: {
                                Text("\(magnifierScale, specifier: "%.1f")x")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.orange.opacity(0.15))
                                    .cornerRadius(6)
                            }
                        }

                        Button {
                            drawing = PKDrawing()
                            canvasSnapshot = nil
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Snapshot Canvas (PKCanvasView with snapshot support)
struct SnapshotCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    @Binding var showToolPicker: Bool
    var onDrawingChanged: (UIImage?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawing = drawing
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .white

        let toolPicker = PKToolPicker()
        toolPicker.setVisible(showToolPicker, forFirstResponder: canvas)
        toolPicker.addObserver(canvas)
        context.coordinator.toolPicker = toolPicker

        canvas.becomeFirstResponder()
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        context.coordinator.toolPicker?.setVisible(showToolPicker, forFirstResponder: canvas)

        if showToolPicker {
            canvas.becomeFirstResponder()
        }

        if canvas.drawing != drawing {
            canvas.drawing = drawing
        }
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: SnapshotCanvasView
        var toolPicker: PKToolPicker?

        init(_ parent: SnapshotCanvasView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing

            // Take a snapshot for the magnifier
            let renderer = UIGraphicsImageRenderer(bounds: canvasView.bounds)
            let snapshot = renderer.image { _ in
                canvasView.drawHierarchy(in: canvasView.bounds, afterScreenUpdates: false)
            }
            parent.onDrawingChanged(snapshot)
        }
    }
}

// MARK: - Magnifier Loupe
struct MagnifierLoupe: View {
    @Binding var position: CGPoint
    let snapshot: UIImage?
    let scale: CGFloat
    let size: CGFloat

    @State private var isDragging = false

    var body: some View {
        ZStack {
            // Crosshair at source point
            LoupeCrosshair()
                .frame(width: 24, height: 24)
                .position(position)
                .allowsHitTesting(false)

            // The loupe displayed above the touch point
            loupeView
                .position(
                    x: position.x,
                    y: position.y - size / 2 - 40
                )
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isDragging = true
                    position = value.location
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
    }

    private var loupeView: some View {
        ZStack {
            // Magnified content
            if let snapshot = snapshot {
                MagnifiedSnapshotView(
                    image: snapshot,
                    center: position,
                    zoomScale: scale,
                    displaySize: size
                )
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.white)
                    .frame(width: size, height: size)
            }

            // Crosshair inside loupe
            LoupeCrosshair()
                .frame(width: 20, height: 20)

            // Border ring
            Circle()
                .stroke(Color.orange, lineWidth: 4)
                .frame(width: size, height: size)

            // Outer glow
            Circle()
                .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                .frame(width: size + 6, height: size + 6)
        }
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isDragging)
    }
}

// MARK: - Magnified Snapshot View
struct MagnifiedSnapshotView: View {
    let image: UIImage
    let center: CGPoint
    let zoomScale: CGFloat
    let displaySize: CGFloat

    var body: some View {
        GeometryReader { _ in
            if let cropped = cropAndScale() {
                Image(uiImage: cropped)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: displaySize, height: displaySize)
            }
        }
    }

    private func cropAndScale() -> UIImage? {
        let imgScale = image.scale
        // Source region radius in points
        let regionRadius = (displaySize / 2) / zoomScale

        // Crop rect in pixel coordinates
        let cropRect = CGRect(
            x: (center.x - regionRadius) * imgScale,
            y: (center.y - regionRadius) * imgScale,
            width: regionRadius * 2 * imgScale,
            height: regionRadius * 2 * imgScale
        )

        let imageBounds = CGRect(
            x: 0, y: 0,
            width: image.size.width * imgScale,
            height: image.size.height * imgScale
        )

        let clampedRect = cropRect.intersection(imageBounds)
        guard !clampedRect.isEmpty,
              let cgImage = image.cgImage,
              let cropped = cgImage.cropping(to: clampedRect) else {
            return nil
        }

        return UIImage(cgImage: cropped, scale: imgScale, orientation: image.imageOrientation)
    }
}

// MARK: - Loupe Crosshair
struct LoupeCrosshair: View {
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let length = min(size.width, size.height) / 2

            // Horizontal line
            var hPath = Path()
            hPath.move(to: CGPoint(x: center.x - length, y: center.y))
            hPath.addLine(to: CGPoint(x: center.x + length, y: center.y))

            // Vertical line
            var vPath = Path()
            vPath.move(to: CGPoint(x: center.x, y: center.y - length))
            vPath.addLine(to: CGPoint(x: center.x, y: center.y + length))

            context.stroke(hPath, with: .color(.orange.opacity(0.8)), lineWidth: 1)
            context.stroke(vPath, with: .color(.orange.opacity(0.8)), lineWidth: 1)
        }
    }
}

// MARK: - Preview
#Preview {
    MagnifierCanvasView()
}
