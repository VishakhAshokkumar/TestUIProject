//
//  TextEditorSheet.swift
//  TestUIProject
//
//  Created by Vishakh on 12/10/25.
//

import SwiftUI

// MARK: - Text Editor Sheet
struct TextEditorSheet: View {
    let annotation: TextAnnotation?
    let color: Color
    let onSave: (String, CGFloat) -> Void
    let onCancel: () -> Void
    
    @State private var text: String = ""
    @State private var fontSize: CGFloat = 24
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    
    init(annotation: TextAnnotation?, color: Color, onSave: @escaping (String, CGFloat) -> Void, onCancel: @escaping () -> Void) {
        self.annotation = annotation
        self.color = color
        self.onSave = onSave
        self.onCancel = onCancel
        _text = State(initialValue: annotation?.text ?? "")
        _fontSize = State(initialValue: annotation?.fontSize ?? 24)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Preview
                ZStack {
                    Color(.systemGray6)
                        .cornerRadius(12)
                    
                    Text(text.isEmpty ? "Preview" : text)
                        .font(.system(size: fontSize, weight: .bold))
                        .foregroundColor(text.isEmpty ? .gray : color)
                        .padding()
                }
                .frame(height: 120)
                .padding(.horizontal)
                
                // Text input
                TextField("Enter text", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 18))
                    .padding(.horizontal)
                    .focused($isTextFieldFocused)
                
                // Font size slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Font Size")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(fontSize)) pt")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("A")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Slider(value: $fontSize, in: 12...72, step: 1)
                        
                        Text("A")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Quick size buttons
                HStack(spacing: 12) {
                    ForEach([16, 24, 36, 48], id: \.self) { size in
                        Button(action: { fontSize = CGFloat(size) }) {
                            Text("\(size)")
                                .font(.caption)
                                .fontWeight(fontSize == CGFloat(size) ? .bold : .regular)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    fontSize == CGFloat(size) ?
                                    color.opacity(0.2) :
                                    Color(.systemGray5)
                                )
                                .foregroundColor(fontSize == CGFloat(size) ? color : .primary)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle(annotation == nil ? "Add Text" : "Edit Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onSave(text, fontSize)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(text.isEmpty)
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Font Style Picker
struct FontStylePicker: View {
    @Binding var selectedStyle: FontStyle
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Style")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                ForEach(FontStyle.allCases, id: \.self) { style in
                    Button(action: { selectedStyle = style }) {
                        Text("Aa")
                            .font(fontForStyle(style))
                            .foregroundColor(selectedStyle == style ? color : .primary)
                            .frame(width: 50, height: 40)
                            .background(
                                selectedStyle == style ?
                                color.opacity(0.2) :
                                Color(.systemGray5)
                            )
                            .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private func fontForStyle(_ style: FontStyle) -> Font {
        switch style {
        case .regular:
            return .system(size: 16, weight: .regular)
        case .bold:
            return .system(size: 16, weight: .bold)
        case .italic:
            return .system(size: 16, weight: .regular, design: .serif).italic()
        case .boldItalic:
            return .system(size: 16, weight: .bold, design: .serif).italic()
        }
    }
}

enum FontStyle: String, CaseIterable {
    case regular
    case bold
    case italic
    case boldItalic
}

// MARK: - Color Selection Row
struct ColorSelectionRow: View {
    @Binding var selectedColor: Color
    let presetColors: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                ForEach(presetColors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture {
                            selectedColor = color
                        }
                }
                
                ColorPicker("", selection: $selectedColor)
                    .labelsHidden()
            }
        }
    }
}

// MARK: - Multiline Text Editor
struct MultilineTextEditor: View {
    @Binding var text: String
    let placeholder: String
    let color: Color
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
            }
            
            TextEditor(text: $text)
                .frame(minHeight: 100)
                .padding(4)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

// MARK: - Preview
#Preview {
    TextEditorSheet(
        annotation: nil,
        color: .orange,
        onSave: { _, _ in },
        onCancel: {}
    )
}
