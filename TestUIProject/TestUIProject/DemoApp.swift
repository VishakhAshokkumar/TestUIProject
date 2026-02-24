//
//  DemoApp.swift
//  TestUIProject
//
//  Created by Vishakh on 12/10/25.
//

import SwiftUI
import PhotosUI


// MARK: - Demo Content View
struct DemoContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var editedImage: UIImage?
    @State private var showEditor = false
    @State private var showSaveAlert = false
    @State private var saveMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Image display area
                imageDisplayArea
                
                // Action buttons
                actionButtons
                
                Spacer()
            }
            .padding()
            .navigationTitle("Image Editor Demo")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Image(systemName: "photo.badge.plus")
                            .font(.title3)
                    }
                }
            }
            .onChange(of: selectedItem) { _, newValue in
                loadImage(from: newValue)
            }
            .fullScreenCover(isPresented: $showEditor) {
                if let image = selectedImage {
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
            .alert("Save Image", isPresented: $showSaveAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(saveMessage)
            }
        }
    }
    
    // MARK: - Image Display Area
    @ViewBuilder
    private var imageDisplayArea: some View {
        if let displayImage = editedImage ?? selectedImage {
            VStack(spacing: 16) {
                // Image preview
                Image(uiImage: displayImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 450)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                
                // Status badge
                if editedImage != nil {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Edited")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(20)
                }
            }
        } else {
            // Empty state
            emptyState
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Image Selected")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("Choose a photo from your library to start editing")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            PhotosPicker(selection: $selectedItem, matching: .images) {
                HStack {
                    Image(systemName: "photo.fill")
                    Text("Select from Gallery")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Action Buttons
    @ViewBuilder
    private var actionButtons: some View {
        if selectedImage != nil {
            VStack(spacing: 12) {
                // Primary actions row
                HStack(spacing: 16) {
                    // Edit button
                    Button(action: { showEditor = true }) {
                        HStack {
                            Image(systemName: "pencil.tip.crop.circle")
                            Text("Edit Image")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    // Save to gallery button (only if edited)
                    if editedImage != nil {
                        Button(action: saveToGallery) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                }
                
                // Secondary actions row
                HStack(spacing: 16) {
                    // Choose different image
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo.badge.arrow.down")
                            Text("Change Image")
                        }
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(10)
                    }
                    
                    // Reset to original
                    if editedImage != nil {
                        Button(action: {
                            editedImage = nil
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset")
                            }
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray5))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func loadImage(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    selectedImage = image
                    editedImage = nil // Reset edited when new image selected
                }
            }
        }
    }
    
    private func saveToGallery() {
        guard let imageToSave = editedImage else { return }
        
        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
        saveMessage = "Image saved to your photo library!"
        showSaveAlert = true
    }
}

// MARK: - Alternative Grid Gallery Picker View
struct GalleryGridView: View {
    @Binding var selectedImage: UIImage?
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var loadedImages: [UIImage] = []
    @State private var showEditor = false
    @State private var imageToEdit: UIImage?
    
    let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 4) {
                    // Add new photo button
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .images) {
                        ZStack {
                            Color(.systemGray5)
                            VStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.largeTitle)
                                Text("Add Photos")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                        }
                        .aspectRatio(1, contentMode: .fit)
                    }
                    
                    // Loaded images grid
                    ForEach(loadedImages.indices, id: \.self) { index in
                        Image(uiImage: loadedImages[index])
                            .resizable()
                            .scaledToFill()
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                            .onTapGesture {
                                imageToEdit = loadedImages[index]
                                showEditor = true
                            }
                    }
                }
                .padding(4)
            }
            .navigationTitle("Gallery")
            .onChange(of: selectedItems) { _, newItems in
                loadImages(from: newItems)
            }
            .fullScreenCover(isPresented: $showEditor) {
                if let image = imageToEdit {
                    ImageEditor(
                        image: image,
                        onSave: { edited in
                            if let index = loadedImages.firstIndex(where: { $0 === imageToEdit }) {
                                loadedImages[index] = edited
                            }
                            selectedImage = edited
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
    
    private func loadImages(from items: [PhotosPickerItem]) {
        Task {
            var images: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            await MainActor.run {
                loadedImages.append(contentsOf: images)
                selectedItems.removeAll()
            }
        }
    }
}

// MARK: - Quick Test View with Sample Images
struct QuickTestView: View {
    @State private var testImage: UIImage?
    @State private var editedImage: UIImage?
    @State private var showEditor = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let image = editedImage ?? testImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 400)
                        .cornerRadius(12)
                    
                    Button("Edit") {
                        showEditor = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                } else {
                    // Generate a test image
                    Button("Generate Test Image") {
                        testImage = generateTestImage()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("Quick Test")
            .fullScreenCover(isPresented: $showEditor) {
                if let image = testImage {
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
    
    // Generate a test image for simulator testing without needing gallery
    private func generateTestImage() -> UIImage {
        let size = CGSize(width: 800, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // Gradient background
            let colors = [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])!
            context.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
            
            // Add some shapes
            context.cgContext.setFillColor(UIColor.white.withAlphaComponent(0.3).cgColor)
            context.cgContext.fillEllipse(in: CGRect(x: 100, y: 100, width: 200, height: 200))
            context.cgContext.fillEllipse(in: CGRect(x: 500, y: 300, width: 150, height: 150))
            
            // Add text
            let text = "Test Image"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 48),
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attrs)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attrs)
            
            // Add sample elements to test magnifier on
            context.cgContext.setFillColor(UIColor.systemYellow.cgColor)
            context.cgContext.fill(CGRect(x: 50, y: 400, width: 100, height: 100))
            
            context.cgContext.setFillColor(UIColor.systemGreen.cgColor)
            context.cgContext.fillEllipse(in: CGRect(x: 650, y: 50, width: 100, height: 100))
            
            // Grid pattern for testing magnification
            context.cgContext.setStrokeColor(UIColor.white.withAlphaComponent(0.2).cgColor)
            context.cgContext.setLineWidth(1)
            for i in stride(from: 0, to: size.width, by: 50) {
                context.cgContext.move(to: CGPoint(x: i, y: 0))
                context.cgContext.addLine(to: CGPoint(x: i, y: size.height))
            }
            for i in stride(from: 0, to: size.height, by: 50) {
                context.cgContext.move(to: CGPoint(x: 0, y: i))
                context.cgContext.addLine(to: CGPoint(x: size.width, y: i))
            }
            context.cgContext.strokePath()
        }
    }
}

// MARK: - Tab-Based Demo App
struct TabDemoView: View {
    var body: some View {
        TabView {
            DemoContentView()
                .tabItem {
                    Label("Gallery", systemImage: "photo.on.rectangle")
                }
            
            QuickTestView()
                .tabItem {
                    Label("Quick Test", systemImage: "paintbrush")
                }
        }
    }
}

// MARK: - Preview
#Preview("Main Demo") {
    DemoContentView()
}

#Preview("Quick Test") {
    QuickTestView()
}

#Preview("Tab Demo") {
    TabDemoView()
}
