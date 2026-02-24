//
//  PencilkitTest.swift
//  TestUIProject
//
//  Created by Vishakh on 12/9/25.
//

import UIKit
import PencilKit
import SwiftUI

class ZuperImageEditorVC: UIViewController {
    
    // MARK: - Properties
    var fileURL: URL?
    var onDone: ((Data?) -> Void)?
    var animateDismiss: Bool = true
    
    private var canvasView: PKCanvasView!
    private var toolPicker: PKToolPicker?
    private var imageView: UIImageView!
    private var originalImage: UIImage?
    private var colorButton: UIButton!
    
    // Arrow drawing points
    private var arrowStartPoint: CGPoint = .zero
    private var arrowEndPoint: CGPoint = .zero
    private var arrowLayer: CAShapeLayer?
    
    // Magnifier
    private var magnifierView: MagnifierView?
    
    // Current drawing tool
    private var currentTool: DrawingTool = .pen
    private var currentColor: UIColor = .red
    private var currentLineWidth: CGFloat = 3.0
    
    enum DrawingTool: Int {
        case pen = 0
        case highlighter = 1
        case pencil = 2
        case arrow = 3
        case magnifier = 4
        case eraser = 5
    }
    
    // MARK: - Initialization
    init(fileURL: URL?) {
        self.fileURL = fileURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadImage()
        setupArrowDrawing()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        // Setup image view
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        // Setup canvas view
        canvasView = PKCanvasView()
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.delegate = self
        view.addSubview(canvasView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            
            canvasView.topAnchor.constraint(equalTo: imageView.topAnchor),
            canvasView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            canvasView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
        ])
        
        canvasView.drawingPolicy = .anyInput
        
        setupCustomToolbar()
        setupNavigationBar()
    }
    
    private func setupNavigationBar() {
        let cancelButton = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.leftBarButtonItem = cancelButton
        
        let doneButton = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(doneTapped)
        )
        navigationItem.rightBarButtonItem = doneButton
        
        navigationItem.title = "Edit Image"
    }
    
    private func setupCustomToolbar() {
        let toolbar = UIView()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        view.addSubview(toolbar)
        
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        // Tool buttons container
        let toolStackView = UIStackView()
        toolStackView.axis = .horizontal
        toolStackView.distribution = .fillEqually
        toolStackView.spacing = 12
        toolStackView.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(toolStackView)
        
        // Color section container
        let colorStackView = UIStackView()
        colorStackView.axis = .horizontal
        colorStackView.spacing = 8
        colorStackView.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(colorStackView)
        
        NSLayoutConstraint.activate([
            toolStackView.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor, constant: 16),
            toolStackView.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor, constant: -16),
            toolStackView.topAnchor.constraint(equalTo: toolbar.topAnchor, constant: 8),
            toolStackView.heightAnchor.constraint(equalToConstant: 50),
            
            colorStackView.centerXAnchor.constraint(equalTo: toolbar.centerXAnchor),
            colorStackView.bottomAnchor.constraint(equalTo: toolbar.bottomAnchor, constant: -8),
            colorStackView.heightAnchor.constraint(equalToConstant: 34)
        ])
        
        // Tool buttons
        let penButton = createToolButton(icon: "pencil", tool: .pen)
        let highlighterButton = createToolButton(icon: "highlighter", tool: .highlighter)
        let pencilButton = createToolButton(icon: "pencil.tip", tool: .pencil)
        let arrowButton = createToolButton(icon: "arrow.up.right", tool: .arrow)
        let magnifierButton = createToolButton(icon: "magnifyingglass", tool: .magnifier)
        let eraserButton = createToolButton(icon: "eraser.fill", tool: .eraser)
        
        [penButton, highlighterButton, pencilButton, arrowButton, magnifierButton, eraserButton].forEach {
            toolStackView.addArrangedSubview($0)
        }
        
        // Color palette - predefined colors
        let colors: [UIColor] = [
            .red, .systemOrange, .systemYellow, .systemGreen,
            .systemBlue, .systemPurple, .black, .white
        ]
        
        colors.forEach { color in
            let colorBtn = createQuickColorButton(color: color)
            colorStackView.addArrangedSubview(colorBtn)
        }
        
        // Color picker button (custom color)
        colorButton = createColorPickerButton()
        colorStackView.addArrangedSubview(colorButton)
    }
    
    private func createToolButton(icon: String, tool: DrawingTool) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: icon), for: .normal)
        button.tintColor = .white
        button.backgroundColor = tool == currentTool ? UIColor.white.withAlphaComponent(0.3) : .clear
        button.layer.cornerRadius = 8
        button.tag = tool.rawValue
        button.addTarget(self, action: #selector(toolButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    private func createQuickColorButton(color: UIColor) -> UIButton {
        let button = UIButton(type: .custom)
        button.backgroundColor = color
        button.layer.cornerRadius = 17
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        button.widthAnchor.constraint(equalToConstant: 34).isActive = true
        button.heightAnchor.constraint(equalToConstant: 34).isActive = true
        button.addTarget(self, action: #selector(quickColorTapped(_:)), for: .touchUpInside)
        return button
    }
    
    private func createColorPickerButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.backgroundColor = currentColor
        button.layer.cornerRadius = 17
        button.layer.borderWidth = 3
        button.layer.borderColor = UIColor.white.cgColor
        button.widthAnchor.constraint(equalToConstant: 34).isActive = true
        button.heightAnchor.constraint(equalToConstant: 34).isActive = true
        
        // Add gradient border to indicate it's special
        let gradientBorder = CAGradientLayer()
        gradientBorder.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
        gradientBorder.colors = [UIColor.systemPink.cgColor, UIColor.systemPurple.cgColor]
        gradientBorder.startPoint = CGPoint(x: 0, y: 0)
        gradientBorder.endPoint = CGPoint(x: 1, y: 1)
        
        let shape = CAShapeLayer()
        shape.lineWidth = 3
        shape.path = UIBezierPath(ovalIn: gradientBorder.bounds).cgPath
        shape.strokeColor = UIColor.black.cgColor
        shape.fillColor = UIColor.clear.cgColor
        gradientBorder.mask = shape
        
        button.layer.addSublayer(gradientBorder)
        button.addTarget(self, action: #selector(colorPickerButtonTapped), for: .touchUpInside)
        
        return button
    }
    
    @objc private func toolButtonTapped(_ sender: UIButton) {
        // Update all buttons' appearance
        if let stackView = sender.superview as? UIStackView {
            stackView.arrangedSubviews.forEach { view in
                if let button = view as? UIButton {
                    button.backgroundColor = .clear
                }
            }
        }
        sender.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        
        if let tool = DrawingTool(rawValue: sender.tag) {
            selectTool(tool)
        }
    }
    
    @objc private func quickColorTapped(_ sender: UIButton) {
        guard let color = sender.backgroundColor else { return }
        currentColor = color
        colorButton.backgroundColor = color
        
        // Update the current tool with new color
        selectTool(currentTool)
        
        // Visual feedback
        UIView.animate(withDuration: 0.2, animations: {
            sender.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                sender.transform = .identity
            }
        }
    }
    
    @objc private func colorPickerButtonTapped() {
        let colorPicker = UIColorPickerViewController()
        colorPicker.selectedColor = currentColor
        colorPicker.delegate = self
        present(colorPicker, animated: true)
    }
    
    @objc private func cancelTapped() {
        onDone?(nil)
    }
    
    @objc private func doneTapped() {
        let editedImage = captureEditedImage()
        onDone?(editedImage?.pngData())
    }
    
    // MARK: - Tool Selection
    private func selectTool(_ tool: DrawingTool) {
        currentTool = tool
        
        // Remove magnifier if switching from magnifier tool
        if tool != .magnifier {
            removeMagnifier()
            canvasView.isUserInteractionEnabled = true
        }
        
        switch tool {
        case .pen:
            let ink = PKInkingTool(.pen, color: currentColor, width: currentLineWidth)
            canvasView.tool = ink
            
        case .highlighter:
            let ink = PKInkingTool(.marker, color: currentColor.withAlphaComponent(0.5), width: currentLineWidth * 3)
            canvasView.tool = ink
            
        case .pencil:
            let ink = PKInkingTool(.pencil, color: currentColor, width: currentLineWidth)
            canvasView.tool = ink
            
        case .eraser:
            canvasView.tool = PKEraserTool(.bitmap)
            
        case .arrow:
            let ink = PKInkingTool(.pen, color: currentColor, width: currentLineWidth)
            canvasView.tool = ink
            
        case .magnifier:
            enableMagnifier()
        }
    }
    
    // MARK: - Helper Methods
    private func loadImage() {
        guard let fileURL = fileURL else { return }
        
        if let image = UIImage(contentsOfFile: fileURL.path) {
            originalImage = image
            imageView.image = image
        }
    }
    
    private func captureEditedImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: imageView.bounds.size)
        
        return renderer.image { context in
            imageView.image?.draw(in: imageView.bounds)
            
            let drawing = canvasView.drawing
            let image = drawing.image(from: canvasView.bounds, scale: UIScreen.main.scale)
            image.draw(in: canvasView.bounds)
        }
    }
    
    private func enableMagnifier() {
        canvasView.isUserInteractionEnabled = false
        
        let magnifier = MagnifierView(frame: CGRect(x: 0, y: 0, width: 150, height: 150))
        magnifier.center = view.center
        magnifier.contentView = view // Pass the view to magnify
        view.addSubview(magnifier)
        magnifierView = magnifier
        
        // Close button for magnifier
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.8)
        closeButton.layer.cornerRadius = 20
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        magnifier.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: magnifier.topAnchor, constant: -10),
            closeButton.trailingAnchor.constraint(equalTo: magnifier.trailingAnchor, constant: 10),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        closeButton.addTarget(self, action: #selector(closeMagnifierTapped), for: .touchUpInside)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleMagnifierPan(_:)))
        magnifier.addGestureRecognizer(panGesture)
    }
    
    @objc private func closeMagnifierTapped() {
        removeMagnifier()
        canvasView.isUserInteractionEnabled = true
        
        // Reset to pen tool
        if let toolStackView = view.subviews.compactMap({ $0.subviews.first as? UIStackView }).first {
            toolStackView.arrangedSubviews.forEach { view in
                if let button = view as? UIButton, button.tag == DrawingTool.pen.rawValue {
                    toolButtonTapped(button)
                }
            }
        }
    }
    
    private func removeMagnifier() {
        magnifierView?.removeFromSuperview()
        magnifierView = nil
    }
    
    @objc private func handleMagnifierPan(_ gesture: UIPanGestureRecognizer) {
        guard let magnifierView = gesture.view as? MagnifierView else { return }
        let translation = gesture.translation(in: view)
        magnifierView.center = CGPoint(
            x: magnifierView.center.x + translation.x,
            y: magnifierView.center.y + translation.y
        )
        gesture.setTranslation(.zero, in: view)
        
        // Update the magnifier display with the snapshot approach
        magnifierView.updateMagnifiedContent()  // Use this instead of setNeedsDisplay()
    }
}

// MARK: - PKCanvasViewDelegate
extension ZuperImageEditorVC: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        // Trigger magnifier update if active
        magnifierView?.updateMagnifiedContent()
    }
}

// MARK: - UIColorPickerViewControllerDelegate
extension ZuperImageEditorVC: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        currentColor = viewController.selectedColor
        colorButton.backgroundColor = currentColor
        selectTool(currentTool)
    }
}

// MARK: - Alternative Magnifier View (Snapshot-based)
class MagnifierView: UIView {
    private let magnification: CGFloat = 2.5
    private var contentImageView: UIImageView!
    weak var contentView: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .white
        layer.cornerRadius = bounds.width / 2
        layer.borderWidth = 4
        layer.borderColor = UIColor.systemBlue.cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
        layer.shadowOpacity = 0.5
        clipsToBounds = true
        isUserInteractionEnabled = true
        
        // Image view to display the magnified content
        contentImageView = UIImageView(frame: bounds)
        contentImageView.contentMode = .scaleAspectFill
        contentImageView.clipsToBounds = true
        addSubview(contentImageView)
        
        // Crosshair view
        addCrosshairView()
    }
    
    private func addCrosshairView() {
        let crosshairView = CrosshairView(frame: bounds)
        crosshairView.backgroundColor = .clear
        crosshairView.isUserInteractionEnabled = false
        addSubview(crosshairView)
    }
    
    func updateMagnifiedContent() {
        guard let contentView = contentView else { return }
        
        // Calculate the center point in the content view's coordinate system
        let magnifierCenterInSuperview = superview?.convert(center, to: contentView) ?? center
        
        // Calculate the rect to capture
        let captureWidth = bounds.width / magnification
        let captureHeight = bounds.height / magnification
        
        let captureRect = CGRect(
            x: magnifierCenterInSuperview.x - captureWidth / 2,
            y: magnifierCenterInSuperview.y - captureHeight / 2,
            width: captureWidth,
            height: captureHeight
        )
        
        // Ensure the capture rect is within bounds
        let clampedRect = captureRect.intersection(contentView.bounds)
        guard !clampedRect.isEmpty else { return }
        
        // Create a snapshot of the area
        let renderer = UIGraphicsImageRenderer(bounds: clampedRect)
        let snapshot = renderer.image { context in
            context.cgContext.translateBy(x: -clampedRect.origin.x, y: -clampedRect.origin.y)
            contentView.drawHierarchy(in: contentView.bounds, afterScreenUpdates: false)
        }
        
        // Display the magnified snapshot
        contentImageView.image = snapshot
    }
    
    override func setNeedsDisplay() {
        super.setNeedsDisplay()
        updateMagnifiedContent()
    }
}

// Helper view for crosshair
class CrosshairView: UIView {
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let centerPoint = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        let crosshairLength: CGFloat = 15
        
        // Shadow
        context.setShadow(offset: CGSize(width: 0, height: 1), blur: 2, color: UIColor.black.withAlphaComponent(0.5).cgColor)
        
        context.setStrokeColor(UIColor.systemBlue.cgColor)
        context.setLineWidth(2.5)
        context.setLineCap(.round)
        
        // Horizontal line
        context.move(to: CGPoint(x: centerPoint.x - crosshairLength, y: centerPoint.y))
        context.addLine(to: CGPoint(x: centerPoint.x + crosshairLength, y: centerPoint.y))
        
        // Vertical line
        context.move(to: CGPoint(x: centerPoint.x, y: centerPoint.y - crosshairLength))
        context.addLine(to: CGPoint(x: centerPoint.x, y: centerPoint.y + crosshairLength))
        
        context.strokePath()
        
        // Center dot
        context.setFillColor(UIColor.systemBlue.cgColor)
        context.fillEllipse(in: CGRect(x: centerPoint.x - 3, y: centerPoint.y - 3, width: 6, height: 6))
    }
}

// MARK: - Arrow Drawing Support
extension ZuperImageEditorVC {
    
    func setupArrowDrawing() {
        let arrowGesture = UIPanGestureRecognizer(target: self, action: #selector(handleArrowGesture(_:)))
        canvasView.addGestureRecognizer(arrowGesture)
    }
    
    @objc func handleArrowGesture(_ gesture: UIPanGestureRecognizer) {
        guard currentTool == .arrow else { return }
        
        let location = gesture.location(in: canvasView)
        
        switch gesture.state {
        case .began:
            arrowStartPoint = location
            arrowEndPoint = location
            
        case .changed:
            arrowEndPoint = location
            updateArrowPreview()
            
        case .ended:
            arrowEndPoint = location
            finalizeArrow()
            removeArrowPreview()
            
        case .cancelled:
            removeArrowPreview()
            
        default:
            break
        }
    }
    
    func updateArrowPreview() {
        removeArrowPreview()
        
        let arrowPath = createArrowPath(from: arrowStartPoint, to: arrowEndPoint)
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = arrowPath.cgPath
        shapeLayer.strokeColor = currentColor.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = currentLineWidth
        shapeLayer.lineCap = .round
        shapeLayer.lineJoin = .round
        
        canvasView.layer.addSublayer(shapeLayer)
        arrowLayer = shapeLayer
    }
    
    func removeArrowPreview() {
        arrowLayer?.removeFromSuperlayer()
        arrowLayer = nil
    }
    
    func finalizeArrow() {
        let arrowPath = createArrowPath(from: arrowStartPoint, to: arrowEndPoint)
        addPathToCanvas(arrowPath)
    }
    
    func createArrowPath(from start: CGPoint, to end: CGPoint) -> UIBezierPath {
        let path = UIBezierPath()
        
        path.move(to: start)
        path.addLine(to: end)
        
        let angle = atan2(end.y - start.y, end.x - start.x)
        let arrowLength: CGFloat = 20
        let arrowAngle: CGFloat = .pi / 6
        
        let arrowPoint1 = CGPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        
        let arrowPoint2 = CGPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )
        
        path.move(to: end)
        path.addLine(to: arrowPoint1)
        path.move(to: end)
        path.addLine(to: arrowPoint2)
        
        return path
    }
    
    func addPathToCanvas(_ path: UIBezierPath) {
        var points: [PKStrokePoint] = []
        
        path.cgPath.applyWithBlock { elementPointer in
            let element = elementPointer.pointee
            switch element.type {
            case .moveToPoint, .addLineToPoint:
                let point = element.points[0]
                let pkPoint = PKStrokePoint(
                    location: point,
                    timeOffset: TimeInterval(points.count) * 0.001,
                    size: CGSize(width: currentLineWidth, height: currentLineWidth),
                    opacity: 1.0,
                    force: 1.0,
                    azimuth: 0,
                    altitude: .pi / 2
                )
                points.append(pkPoint)
            default:
                break
            }
        }
        
        if points.count >= 2 {
            let strokePath = PKStrokePath(controlPoints: points, creationDate: Date())
            let ink = PKInk(.pen, color: currentColor)
            let stroke = PKStroke(ink: ink, path: strokePath)
            
            var drawing = canvasView.drawing
            drawing.strokes.append(stroke)
            canvasView.drawing = drawing
        }
    }
}

extension CGRect {
    var diagonal: CGFloat {
        return sqrt(width * width + height * height)
    }
}

// MARK: - SwiftUI Wrapper
struct ZuperImageEditorWrapper: UIViewControllerRepresentable {
    var fileURL: URL?
    let editedImageData: (Data?) -> Void
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIViewController {
        let zuperImageEditorVC = ZuperImageEditorVC(fileURL: fileURL)
        zuperImageEditorVC.animateDismiss = true
        zuperImageEditorVC.onDone = { editedImageData in
            self.editedImageData(editedImageData)
            isPresented = false
        }
        
        let navController = UINavigationController(rootViewController: zuperImageEditorVC)
        navController.modalPresentationStyle = .fullScreen
        
        return navController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
