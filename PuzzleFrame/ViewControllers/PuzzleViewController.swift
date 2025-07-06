import UIKit

class PuzzleViewController: UIViewController, UIGestureRecognizerDelegate {
    
    private let viewModel = PuzzleViewModel()
    private var puzzlePieces: [PuzzlePiece] = []
    private var gridSize: Int = 4
    private var pieceSize: CGSize = .zero
    private var puzzleContainerView: UIView!
    
    var resumeGameState: GameState?
    
    // MARK: - UI Components
    private let timeLabel = UILabel()
    private let movesLabel = UILabel()
    private let pauseButton = UIButton(type: .system)
    private let menuButton = UIButton(type: .system)
    private let pieceSelectionScrollView = UIScrollView()
    private let pieceSelectionContainer = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupUI()
        setupConstraints()
        
        if let gameState = resumeGameState {
            resumeGame(gameState)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.pauseGame()
    }
    
    deinit {
        viewModel.delegate = nil
        releasePuzzlePieces()
    }
    
    private func setupViewModel() {
        viewModel.delegate = self
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.hidesBackButton = true
        
        // Time Label
        timeLabel.font = .systemFont(ofSize: 16, weight: .medium)
        timeLabel.textAlignment = .center
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timeLabel)
        
        // Moves Label
        movesLabel.font = .systemFont(ofSize: 16, weight: .medium)
        movesLabel.textAlignment = .center
        movesLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(movesLabel)
        
        // Pause Button
        pauseButton.setTitle("puzzle.pause".localized, for: .normal)
        pauseButton.addTarget(self, action: #selector(pauseButtonTapped), for: .touchUpInside)
        pauseButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pauseButton)
        
        // Menu Button
        menuButton.setTitle("puzzle.menu".localized, for: .normal)
        menuButton.addTarget(self, action: #selector(menuButtonTapped), for: .touchUpInside)
        menuButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(menuButton)
        
        // Puzzle Container - Daha büyük
        puzzleContainerView = UIView()
        puzzleContainerView.backgroundColor = .systemGray6
        puzzleContainerView.layer.cornerRadius = 12
        puzzleContainerView.layer.borderWidth = 2
        puzzleContainerView.layer.borderColor = UIColor.systemBlue.cgColor
        puzzleContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(puzzleContainerView)
        
        // Piece Selection Scroll View - Alt kısımda horizontal scroll
        pieceSelectionScrollView.backgroundColor = .systemGray5
        pieceSelectionScrollView.showsHorizontalScrollIndicator = true
        pieceSelectionScrollView.showsVerticalScrollIndicator = false
        pieceSelectionScrollView.canCancelContentTouches = false
        pieceSelectionScrollView.delaysContentTouches = false
        pieceSelectionScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pieceSelectionScrollView)
        
        // Piece Selection Container
        pieceSelectionContainer.translatesAutoresizingMaskIntoConstraints = false
        pieceSelectionScrollView.addSubview(pieceSelectionContainer)
    }
    
    private func setupConstraints() {
        // Dynamic height based on grid size for better piece visibility
        let pieceSelectionHeight: CGFloat = gridSize > 8 ? 140 : 120
        
        NSLayoutConstraint.activate([
            // Time Label
            timeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            timeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            // Moves Label
            movesLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            movesLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Pause Button
            pauseButton.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 10),
            pauseButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            
            // Menu Button
            menuButton.topAnchor.constraint(equalTo: movesLabel.bottomAnchor, constant: 10),
            menuButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Piece Selection Scroll View - Alt kısımda
            pieceSelectionScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pieceSelectionScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pieceSelectionScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            pieceSelectionScrollView.heightAnchor.constraint(equalToConstant: pieceSelectionHeight),
            
            // Puzzle Container - Daha büyük, piece selection'ın üstünde
            puzzleContainerView.topAnchor.constraint(equalTo: pauseButton.bottomAnchor, constant: 20),
            puzzleContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            puzzleContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            puzzleContainerView.bottomAnchor.constraint(equalTo: pieceSelectionScrollView.topAnchor, constant: -10),
            
            // Piece Selection Container
            pieceSelectionContainer.topAnchor.constraint(equalTo: pieceSelectionScrollView.topAnchor),
            pieceSelectionContainer.bottomAnchor.constraint(equalTo: pieceSelectionScrollView.bottomAnchor),
            pieceSelectionContainer.leadingAnchor.constraint(equalTo: pieceSelectionScrollView.leadingAnchor),
            pieceSelectionContainer.trailingAnchor.constraint(equalTo: pieceSelectionScrollView.trailingAnchor),
            pieceSelectionContainer.heightAnchor.constraint(equalTo: pieceSelectionScrollView.heightAnchor)
        ])
    }
    
    func setupNewGame(image: UIImage, imageKey: String, isUserImage: Bool, gridSize: Int) {
        self.gridSize = gridSize
        viewModel.startNewGame(image: image, imageKey: imageKey, isUserImage: isUserImage, gridSize: gridSize)
        createPuzzlePieces(from: image)
    }
    
    private func resumeGame(_ gameState: GameState) {
        self.gridSize = gameState.gridSize
        viewModel.resumeGame(gameState)
        
        // Load the image and create puzzle pieces
        if gameState.isUserImage {
            if let image = CacheManager.shared.loadUserImage(forKey: gameState.imageKey) {
                createPuzzlePieces(from: image)
            }
        } else {
            if let image = CacheManager.shared.loadGameImage(forKey: gameState.imageKey) ?? UIImage(named: gameState.imageKey) {
                createPuzzlePieces(from: image)
            }
        }
    }
    
    private func createPuzzlePieces(from image: UIImage) {
        releasePuzzlePieces()
        
        // Ensure the view has been laid out
        view.layoutIfNeeded()
        
        let containerSize = puzzleContainerView.bounds.size
        let selectionHeight = pieceSelectionScrollView.bounds.height
        
        if containerSize.width == 0 || containerSize.height == 0 || selectionHeight == 0 {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.view.layoutIfNeeded()
                if self.puzzleContainerView.bounds.width > 0 && self.pieceSelectionScrollView.bounds.height > 0 {
                    self.createPuzzlePieces(from: image)
                }
            }
            return
        }
        
        // Calculate piece size - different for puzzle and selection area
        let minDimension = min(containerSize.width, containerSize.height)
        let puzzlePieceSize = minDimension / CGFloat(gridSize)
        
        // For selection area, use a minimum size to keep pieces visible
        let minSelectionPieceSize: CGFloat = 60  // Minimum 60 points
        let maxSelectionPieceSize: CGFloat = 100 // Maximum 100 points
        
        let selectionPieceSize = min(maxSelectionPieceSize, max(minSelectionPieceSize, puzzlePieceSize))
        
        // Use selection piece size for better visibility
        pieceSize = CGSize(width: selectionPieceSize, height: selectionPieceSize)
        
        // Calculate total width for scroll view content
        let totalPieces = gridSize * gridSize
        let pieceSpacing: CGFloat = 10
        let totalWidth = CGFloat(totalPieces) * (pieceSize.width + pieceSpacing) + pieceSpacing
        
        // Set scroll view content size
        pieceSelectionScrollView.contentSize = CGSize(width: totalWidth, height: selectionHeight)
        pieceSelectionContainer.frame = CGRect(x: 0, y: 0, width: totalWidth, height: selectionHeight)
        
        // Create pieces and place them in selection area
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let piece = PuzzlePiece()
                let index = row * gridSize + col
                
                // Calculate correct position in puzzle container
                let correctPosition = CGPoint(
                    x: CGFloat(col) * pieceSize.width + pieceSize.width / 2,
                    y: CGFloat(row) * pieceSize.height + pieceSize.height / 2
                )
                
                piece.configure(with: image, index: index, correctPosition: correctPosition, pieceSize: pieceSize, gridSize: gridSize)
                
                // Place piece in selection area horizontally
                let selectionX = pieceSpacing + CGFloat(index) * (pieceSize.width + pieceSpacing)
                let selectionY = (selectionHeight - pieceSize.height) / 2
                
                let pieceView = UIView(frame: CGRect(x: selectionX, y: selectionY, width: pieceSize.width, height: pieceSize.height))
                pieceView.layer.addSublayer(piece)
                piece.position = CGPoint(x: pieceSize.width/2, y: pieceSize.height/2)
                
                // Add drag gesture
                let panGesture = UIPanGestureRecognizer(target: self, action: #selector(piecePanned(_:)))
                panGesture.delegate = self
                pieceView.addGestureRecognizer(panGesture)
                pieceSelectionContainer.addSubview(pieceView)
                
                // Store reference
                puzzlePieces.append(piece)
            }
        }
    }
    
    private func shufflePieces() {
        // Simple shuffle by swapping positions
        for _ in 0..<(gridSize * gridSize * 2) {
            let index1 = Int.random(in: 0..<puzzlePieces.count)
            let index2 = Int.random(in: 0..<puzzlePieces.count)
            
            let tempPosition = puzzlePieces[index1].position
            puzzlePieces[index1].updatePosition(puzzlePieces[index2].position)
            puzzlePieces[index2].updatePosition(tempPosition)
        }
    }
    
    @objc private func piecePanned(_ gesture: UIPanGestureRecognizer) {
        guard let pieceView = gesture.view,
              let piece = pieceView.layer.sublayers?.first as? PuzzlePiece else { return }
        
        switch gesture.state {
        case .began:
            // Bring piece to front and add to main view for dragging
            pieceView.superview?.bringSubviewToFront(pieceView)
            
        case .changed:
            let translation = gesture.translation(in: view)
            let newCenter = CGPoint(
                x: pieceView.center.x + translation.x,
                y: pieceView.center.y + translation.y
            )
            
            // Convert to main view coordinates if piece is in selection container
            if pieceView.superview == pieceSelectionContainer {
                let centerInMainView = view.convert(newCenter, from: pieceSelectionContainer)
                // Move piece to main view for better dragging
                let frameInMainView = view.convert(pieceView.frame, from: pieceSelectionContainer)
                pieceView.removeFromSuperview()
                view.addSubview(pieceView)
                pieceView.frame = frameInMainView
                pieceView.center = centerInMainView
            } else {
                pieceView.center = newCenter
            }
            
            gesture.setTranslation(.zero, in: view)
            
        case .ended:
            handlePieceDrop(pieceView: pieceView, piece: piece)
            
        default:
            break
        }
    }
    
    private func handlePieceDrop(pieceView: UIView, piece: PuzzlePiece) {
        // Piece center is now in main view coordinates
        let pieceCenter = pieceView.center
        let puzzleFrame = puzzleContainerView.frame
        let selectionFrame = pieceSelectionScrollView.frame
        
        // Check if piece is in puzzle area
        if puzzleFrame.contains(pieceCenter) {
            // Convert piece center to puzzle container coordinates for correct position checking
            let puzzleRelativeCenter = view.convert(pieceCenter, to: puzzleContainerView)
            let pieceCorrectCenter = piece.correctPosition
            let distance = sqrt(pow(puzzleRelativeCenter.x - pieceCorrectCenter.x, 2) + pow(puzzleRelativeCenter.y - pieceCorrectCenter.y, 2))
            let tolerance: CGFloat = 30.0
            
            // Move piece to puzzle container and resize if needed
            let puzzlePieceSize = min(puzzleContainerView.bounds.width, puzzleContainerView.bounds.height) / CGFloat(gridSize)
            
            pieceView.removeFromSuperview()
            puzzleContainerView.addSubview(pieceView)
            
            // Resize piece for puzzle area if it's different from selection size
            if abs(pieceView.bounds.width - puzzlePieceSize) > 1 {
                UIView.animate(withDuration: 0.2) {
                    pieceView.bounds = CGRect(origin: .zero, size: CGSize(width: puzzlePieceSize, height: puzzlePieceSize))
                    pieceView.center = puzzleRelativeCenter
                }
            } else {
                pieceView.center = puzzleRelativeCenter
            }
            
            if distance <= tolerance {
                // Snap to correct position in puzzle area
                UIView.animate(withDuration: 0.2) {
                    pieceView.center = pieceCorrectCenter
                }
                piece.isInCorrectPosition = true
                piece.highlightAsCorrect()
            } else {
                // Keep piece in puzzle area but not in correct position
                piece.isInCorrectPosition = false
            }
        } else if selectionFrame.contains(pieceCenter) {
            // Move piece back to selection area
            piece.isInCorrectPosition = false
            returnPieceToSelection(pieceView: pieceView, piece: piece)
        } else {
            // Piece is outside both areas - return to selection area
            piece.isInCorrectPosition = false
            returnPieceToSelection(pieceView: pieceView, piece: piece)
        }
        
        viewModel.incrementMoveCount()
        checkForCompletion()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    
    private func returnPieceToSelection(pieceView: UIView, piece: PuzzlePiece) {
        // Find available spot in selection area
        let pieceSpacing: CGFloat = 10
        let selectionHeight = pieceSelectionScrollView.bounds.height
        
        // Count existing pieces in selection area (excluding the current piece if it's already there)
        let existingPiecesInSelection = pieceSelectionContainer.subviews.filter { $0 != pieceView }.count
        let selectionX = pieceSpacing + CGFloat(existingPiecesInSelection) * (pieceSize.width + pieceSpacing)
        let selectionY = (selectionHeight - pieceSize.height) / 2
        
        // Move piece to selection container
        if pieceView.superview != pieceSelectionContainer {
            pieceView.removeFromSuperview()
            pieceSelectionContainer.addSubview(pieceView)
        }
        
        // Animate to selection position and resize to selection size
        UIView.animate(withDuration: 0.3) {
            pieceView.frame = CGRect(x: selectionX, y: selectionY, width: self.pieceSize.width, height: self.pieceSize.height)
        }
        
        // Update scroll view content size
        let totalWidth = selectionX + pieceSize.width + pieceSpacing
        pieceSelectionScrollView.contentSize = CGSize(width: max(totalWidth, pieceSelectionScrollView.bounds.width), height: selectionHeight)
        pieceSelectionContainer.frame = CGRect(x: 0, y: 0, width: max(totalWidth, pieceSelectionScrollView.bounds.width), height: selectionHeight)
    }
    
    private func checkForCompletion() {
        let allInCorrectPosition = puzzlePieces.allSatisfy { $0.isInCorrectPosition }
        
        if allInCorrectPosition {
            viewModel.completeGame()
        }
    }
    
    @objc private func pauseButtonTapped() {
        if viewModel.isGamePaused {
            viewModel.resumeGame()
            pauseButton.setTitle("puzzle.pause".localized, for: .normal)
        } else {
            viewModel.pauseGame()
            pauseButton.setTitle("puzzle.resume".localized, for: .normal)
        }
    }
    
    @objc private func menuButtonTapped() {
        let alert = UIAlertController(title: "puzzle.menu".localized, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "puzzle.new".localized, style: .default) { _ in
            self.navigationController?.popToRootViewController(animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "puzzle.menu".localized, style: .default) { _ in
            self.navigationController?.popToRootViewController(animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "puzzle.quit".localized, style: .destructive) { _ in
            self.showQuitConfirmation()
        })
        
        alert.addAction(UIAlertAction(title: "common.cancel".localized, style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showQuitConfirmation() {
        let alert = UIAlertController(
            title: "puzzle.quit.title".localized,
            message: "puzzle.quit.message".localized,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "puzzle.quit.confirm".localized, style: .destructive) { _ in
            // Clear current game state and return to main menu
            GameStateManager.shared.clearGameState()
            self.navigationController?.popToRootViewController(animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "common.cancel".localized, style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func releasePuzzlePieces() {
        for piece in puzzlePieces {
            piece.removeFromSuperlayer()
            piece.releaseResources()
        }
        puzzlePieces.removeAll()
    }
}

// MARK: - PuzzleViewModelDelegate
extension PuzzleViewController: PuzzleViewModelDelegate {
    func didUpdateGameState() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.timeLabel.text = String(format: "puzzle.time".localized, self.viewModel.currentTime)
            self.movesLabel.text = String(format: "puzzle.moves".localized, self.viewModel.currentMoves)
        }
    }
    
    func didCompleteGame(time: TimeInterval, moves: Int) {
        DispatchQueue.main.async { [weak self] in
            let completionVC = CompletionViewController()
            completionVC.configure(time: time, moves: moves, gridSize: self?.gridSize ?? 4)
            self?.navigationController?.pushViewController(completionVC, animated: true)
        }
    }
    
    func didEncounterError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.showErrorAlert(message: error.localizedDescription)
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension PuzzleViewController {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Our pan gesture should take priority over scroll view's pan gesture
        if otherGestureRecognizer.view == pieceSelectionScrollView {
            return true
        }
        return false
    }
}

// MARK: - Error Handling
extension PuzzleViewController {
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "error.title".localized, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "common.ok".localized, style: .default))
        present(alert, animated: true)
    }
}