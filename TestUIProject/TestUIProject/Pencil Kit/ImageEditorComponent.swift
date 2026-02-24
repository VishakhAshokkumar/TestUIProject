//
//  ImageEditorComponent.swift
//  TestUIProject
//
//  Created by Vishakh on 12/10/25.
//

import SwiftUI
import PhotosUI

// MARK: - Image Editor Component
/// A SwiftUI view that provides a full-featured image editor
/// with drawing, arrows, text, shapes, and magnifier annotations.
///
/// Usage:
/// ```swift
/// ImageEditor(
///     image: myImage,
///     onSave: { editedImage in
///         // Handle the edited image
///     },
///     onCancel: {
///         // Handle cancellation
///     }
/// )
/// ```
public struct ImageEditor: View {
    private let image: UIImage
    private let onSave: (UIImage) -> Void
    private let onCancel: () -> Void
    
    /// Creates a new ImageEditor
    /// - Parameters:
    ///   - image: The source image to edit
    ///   - onSave: Callback with the edited image when user saves
    ///   - onCancel: Callback when user cancels editing
    public init(
        image: UIImage,
        onSave: @escaping (UIImage) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.image = image
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
    public var body: some View {
        ImageEditorView(
            inputImage: image,
            onSave: onSave,
            onCancel: onCancel
        )
    }
}

// MARK: - Image Editor Modifier
/// A view modifier that presents the image editor as a sheet
public struct ImageEditorModifier: ViewModifier {
    @Binding var isPresented: Bool
    let image: UIImage?
    let onSave: (UIImage) -> Void
    
    public func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                if let image = image {
                    ImageEditor(
                        image: image,
                        onSave: { editedImage in
                            onSave(editedImage)
                            isPresented = false
                        },
                        onCancel: {
                            isPresented = false
                        }
                    )
                }
            }
    }
}

extension View {
    /// Presents an image editor as a full-screen cover
    /// - Parameters:
    ///   - isPresented: Binding to control presentation
    ///   - image: The image to edit
    ///   - onSave: Callback with the edited image
    public func imageEditor(
        isPresented: Binding<Bool>,
        image: UIImage?,
        onSave: @escaping (UIImage) -> Void
    ) -> some View {
        modifier(ImageEditorModifier(
            isPresented: isPresented,
            image: image,
            onSave: onSave
        ))
    }
}

// MARK: - Image Picker with Editor
/// A view that combines PhotosPicker with the image editor
public struct ImagePickerWithEditor: View {
    @Binding var editedImage: UIImage?
    @State private var selectedItem: PhotosPickerItem?
    @State private var pickedImage: UIImage?
    @State private var showEditor = false
    
    public init(editedImage: Binding<UIImage?>) {
        self._editedImage = editedImage
    }
    
    public var body: some View {
        VStack {
            if let editedImage = editedImage {
                Image(uiImage: editedImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
                
                Button("Edit Again") {
                    pickedImage = editedImage
                    showEditor = true
                }
                .buttonStyle(.bordered)
            } else {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images
                ) {
                    Label("Select Image", systemImage: "photo")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .onChange(of: selectedItem) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    pickedImage = image
                    showEditor = true
                }
            }
        }
        .fullScreenCover(isPresented: $showEditor) {
            if let image = pickedImage {
                ImageEditor(
                    image: image,
                    onSave: { edited in
                        editedImage = edited
                        showEditor = false
                    },
                    onCancel: {
                        showEditor = false
                    }
                )
            }
        }
    }
}

// MARK: - Simplified Editor Configuration
public struct ImageEditorConfiguration {
    public var allowedTools: Set<EditorTool>
    public var defaultColor: Color
    public var showColorPicker: Bool
    public var maxUndoSteps: Int
    
    public static let `default` = ImageEditorConfiguration(
        allowedTools: Set(EditorTool.allCases),
        defaultColor: .orange,
        showColorPicker: true,
        maxUndoSteps: 20
    )
    
    public init(
        allowedTools: Set<EditorTool>,
        defaultColor: Color = .orange,
        showColorPicker: Bool = true,
        maxUndoSteps: Int = 20
    ) {
        self.allowedTools = allowedTools
        self.defaultColor = defaultColor
        self.showColorPicker = showColorPicker
        self.maxUndoSteps = maxUndoSteps
    }
}

// Make EditorTool CaseIterable for configuration
extension EditorTool: CaseIterable {
    public static var allCases: [EditorTool] {
        [.draw, .arrow, .text, .circle, .rectangle, .magnifier, .eraser]
    }
}

// MARK: - Utility Extensions
extension UIImage {
    /// Creates a thumbnail of the image
    func thumbnail(maxSize: CGFloat) -> UIImage? {
        let aspectRatio = size.width / size.height
        let targetSize: CGSize
        
        if aspectRatio > 1 {
            targetSize = CGSize(width: maxSize, height: maxSize / aspectRatio)
        } else {
            targetSize = CGSize(width: maxSize * aspectRatio, height: maxSize)
        }
        
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    /// Rotates the image by the specified angle
    func rotated(by angle: CGFloat) -> UIImage? {
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: angle))
            .integral.size
        
        let renderer = UIGraphicsImageRenderer(size: rotatedSize)
        return renderer.image { context in
            context.cgContext.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            context.cgContext.rotate(by: angle)
            draw(in: CGRect(
                x: -size.width / 2,
                y: -size.height / 2,
                width: size.width,
                height: size.height
            ))
        }
    }
    
    /// Crops the image to the specified rect
    func cropped(to rect: CGRect) -> UIImage? {
        guard let cgImage = cgImage?.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }
}

// MARK: - Color Extension for Codable
extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, opacity
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(Double.self, forKey: .red)
        let green = try container.decode(Double.self, forKey: .green)
        let blue = try container.decode(Double.self, forKey: .blue)
        let opacity = try container.decode(Double.self, forKey: .opacity)
        self.init(red: red, green: green, blue: blue, opacity: opacity)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let components = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        try container.encode(components[0], forKey: .red)
        try container.encode(components[1], forKey: .green)
        try container.encode(components[2], forKey: .blue)
        try container.encode(components.count > 3 ? components[3] : 1.0, forKey: .opacity)
    }
}
