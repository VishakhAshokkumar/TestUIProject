//
//  ImageEditorView.swift
//  TestUIProject
//
//  Created by Vishakh on 12/9/25.
//

import SwiftUI

struct ImageEditorTestView: View {
    @State private var showImageEditor = false
    @State private var testImageURL: URL?
    @State private var editedImageData: Data?
    @State private var showImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Display area
                if let imageData = editedImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .border(Color.gray, width: 1)
                } else if let testImageURL = testImageURL,
                          let uiImage = UIImage(contentsOfFile: testImageURL.path) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .border(Color.gray, width: 1)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 300)
                        .overlay(
                            Text("No image selected")
                                .foregroundColor(.gray)
                        )
                }
                
                // Buttons
                VStack(spacing: 12) {
                    Button("Select Image from Photos") {
                        showImagePicker = true
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Use Sample Image") {
                        createSampleImage()
                    }
                    .buttonStyle(.bordered)
                    
                    if testImageURL != nil {
                        Button("Edit Image") {
                            showImageEditor = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                    
                    if editedImageData != nil {
                        Button("Clear Edited Image") {
                            editedImageData = nil
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Image Editor Test")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(imageURL: $testImageURL)
            }
            .fullScreenCover(isPresented: $showImageEditor) {
                ZuperImageEditorWrapper(
                    fileURL: testImageURL,
                    editedImageData: { data in
                        if let data = data {
                            editedImageData = data
                            print("✅ Image edited successfully, size: \(data.count) bytes")
                        } else {
                            print("❌ Edit cancelled")
                        }
                    },
                    isPresented: $showImageEditor
                )
            }
        }
    }
    
    private func createSampleImage() {
        // Create a sample image with some content
        let size = CGSize(width: 800, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Background
            UIColor.systemBlue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Some shapes
            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 200, y: 150, width: 400, height: 300))
            
            // Text
            let text = "Test Image for Editing"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 40, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            let attributedString = NSAttributedString(string: text, attributes: attributes)
            attributedString.draw(at: CGPoint(x: 150, y: 270))
        }
        
        // Save to temporary file
        if let imageData = image.pngData() {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("sample_image_\(UUID().uuidString).png")
            
            do {
                try imageData.write(to: tempURL)
                testImageURL = tempURL
                print("✅ Sample image created at: \(tempURL.path)")
            } catch {
                print("❌ Error saving sample image: \(error)")
            }
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageURL: URL?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                // Save to temporary file
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    let tempURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent("picked_image_\(UUID().uuidString).jpg")
                    
                    do {
                        try imageData.write(to: tempURL)
                        parent.imageURL = tempURL
                        print("✅ Image saved to: \(tempURL.path)")
                    } catch {
                        print("❌ Error saving image: \(error)")
                    }
                }
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview
#Preview {
    ImageEditorTestView()
}
