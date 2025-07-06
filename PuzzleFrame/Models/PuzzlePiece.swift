import UIKit

class PuzzlePiece: CALayer {
    
    var pieceIndex: Int = 0
    var correctPosition: CGPoint = .zero
    var currentGridPosition: CGPoint = .zero
    var isInCorrectPosition: Bool = false
    
    private var originalImage: UIImage?
    private var pieceImage: UIImage?
    private var cropPosition: CGPoint = .zero
    private var gridSize: Int = 4
    
    override init() {
        super.init()
        setupLayer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
        if let puzzlePiece = layer as? PuzzlePiece {
            self.pieceIndex = puzzlePiece.pieceIndex
            self.correctPosition = puzzlePiece.correctPosition
            self.currentGridPosition = puzzlePiece.currentGridPosition
            self.isInCorrectPosition = puzzlePiece.isInCorrectPosition
            self.originalImage = puzzlePiece.originalImage
            self.pieceImage = puzzlePiece.pieceImage
        }
    }
    
    private func setupLayer() {
        contentsGravity = .resizeAspectFill
        masksToBounds = true
        borderWidth = 1.0
        borderColor = UIColor.systemGray4.cgColor
        shadowOffset = CGSize(width: 0, height: 2)
        shadowRadius = 4.0
        shadowOpacity = 0.3
        shadowColor = UIColor.black.cgColor
    }
    
    deinit {
        originalImage = nil
        pieceImage = nil
    }
    
    func configure(with image: UIImage, index: Int, correctPosition: CGPoint, pieceSize: CGSize, gridSize: Int) {
        self.pieceIndex = index
        self.correctPosition = correctPosition
        self.gridSize = gridSize
        self.bounds = CGRect(origin: .zero, size: pieceSize)
        
        autoreleasepool {
            self.originalImage = image
            self.pieceImage = createPieceImage(from: image, size: pieceSize)
            self.contents = self.pieceImage?.cgImage
        }
    }
    
    func setCropPosition(_ position: CGPoint) {
        self.cropPosition = position
        if let originalImage = originalImage {
            autoreleasepool {
                self.pieceImage = createPieceImage(from: originalImage, size: bounds.size)
                self.contents = self.pieceImage?.cgImage
            }
        }
    }
    
    private func createPieceImage(from image: UIImage, size: CGSize) -> UIImage? {
        let imageSize = image.size
        
        // Calculate how much of the original image each piece should contain
        let pieceWidth = imageSize.width / CGFloat(gridSize)
        let pieceHeight = imageSize.height / CGFloat(gridSize)
        
        // Calculate the row and column of this piece
        let row = pieceIndex / gridSize
        let col = pieceIndex % gridSize
        
        // Calculate crop rectangle in original image coordinates
        let cropRect = CGRect(
            x: CGFloat(col) * pieceWidth,
            y: CGFloat(row) * pieceHeight,
            width: pieceWidth,
            height: pieceHeight
        )
        
        // Ensure crop rect is within image bounds
        let validCropRect = cropRect.intersection(CGRect(origin: .zero, size: imageSize))
        
        guard !validCropRect.isEmpty,
              let cgImage = image.cgImage?.cropping(to: validCropRect) else { 
            // Fallback: return a debug image
            return createDebugImage(size: size)
        }
        
        let croppedImage = UIImage(cgImage: cgImage)
        return resizeImage(croppedImage, to: size)
    }
    
    private func createDebugImage(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        // Create a colored rectangle based on piece index
        let colors: [UIColor] = [.red, .blue, .green, .yellow, .purple, .orange, .cyan, .magenta]
        let color = colors[pieceIndex % colors.count]
        color.setFill()
        
        let rect = CGRect(origin: .zero, size: size)
        UIRectFill(rect)
        
        // Add border
        UIColor.black.setStroke()
        let path = UIBezierPath(rect: rect.insetBy(dx: 1, dy: 1))
        path.lineWidth = 2
        path.stroke()
        
        // Add piece number
        let text = "\(pieceIndex)"
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: min(size.width, size.height) * 0.3)
        ]
        
        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        text.draw(in: textRect, withAttributes: attributes)
        
        let debugImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return debugImage
    }
    
    private func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    func updatePosition(_ newPosition: CGPoint) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        position = newPosition
        CATransaction.commit()
    }
    
    func animateToPosition(_ targetPosition: CGPoint, duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        
        let animation = CABasicAnimation(keyPath: "position")
        animation.fromValue = position
        animation.toValue = targetPosition
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        add(animation, forKey: "positionAnimation")
        position = targetPosition
        
        CATransaction.commit()
    }
    
    func highlightAsCorrect() {
        borderColor = UIColor.systemGreen.cgColor
        borderWidth = 2.0
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 1.05
        scaleAnimation.duration = 0.1
        scaleAnimation.autoreverses = true
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        add(scaleAnimation, forKey: "correctHighlight")
    }
    
    func removeHighlight() {
        borderColor = UIColor.systemGray4.cgColor
        borderWidth = 1.0
    }
    
    func checkIfInCorrectPosition(tolerance: CGFloat = 20.0) -> Bool {
        let distance = sqrt(pow(position.x - correctPosition.x, 2) + pow(position.y - correctPosition.y, 2))
        isInCorrectPosition = distance <= tolerance
        return isInCorrectPosition
    }
    
    func snapToCorrectPosition() {
        if checkIfInCorrectPosition() {
            animateToPosition(correctPosition, duration: 0.2) { [weak self] in
                self?.highlightAsCorrect()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.removeHighlight()
                }
            }
        }
    }
    
    func releaseResources() {
        originalImage = nil
        pieceImage = nil
        contents = nil
        removeAllAnimations()
    }
}