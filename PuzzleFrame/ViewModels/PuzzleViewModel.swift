import UIKit

protocol PuzzleViewModelDelegate: AnyObject {
    func didUpdateGameState()
    func didCompleteGame(time: TimeInterval, moves: Int)
    func didEncounterError(_ error: Error)
}

class PuzzleViewModel {
    
    weak var delegate: PuzzleViewModelDelegate?
    
    private var gameState: GameState?
    private var gameTimer: Timer?
    private var startTime: Date = Date()
    private var elapsedTime: TimeInterval = 0
    private var moveCount: Int = 0
    private var isPaused: Bool = false
    
    var currentTime: String {
        let totalTime = isPaused ? elapsedTime : elapsedTime + Date().timeIntervalSince(startTime)
        let minutes = Int(totalTime) / 60
        let seconds = Int(totalTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var currentMoves: Int {
        return moveCount
    }
    
    var isGamePaused: Bool {
        return isPaused
    }
    
    deinit {
        gameTimer?.invalidate()
        delegate = nil
    }
    
    func startNewGame(image: UIImage, imageKey: String, isUserImage: Bool, gridSize: Int) {
        let newGameState = GameState(
            gridSize: gridSize,
            imageKey: imageKey,
            isUserImage: isUserImage,
            startTime: Date(),
            moveCount: 0
        )
        
        self.gameState = newGameState
        self.startTime = Date()
        self.elapsedTime = 0
        self.moveCount = 0
        self.isPaused = false
        
        startTimer()
        saveGameState()
    }
    
    func resumeGame(_ gameState: GameState) {
        self.gameState = gameState
        self.elapsedTime = Date().timeIntervalSince(gameState.startTime)
        self.moveCount = gameState.moveCount
        self.isPaused = false
        self.startTime = Date()
        
        startTimer()
    }
    
    func pauseGame() {
        guard !isPaused else { return }
        
        isPaused = true
        elapsedTime += Date().timeIntervalSince(startTime)
        gameTimer?.invalidate()
        gameTimer = nil
        
        saveGameState()
    }
    
    func resumeGame() {
        guard isPaused else { return }
        
        isPaused = false
        startTime = Date()
        startTimer()
    }
    
    func incrementMoveCount() {
        moveCount += 1
        delegate?.didUpdateGameState()
        saveGameState()
    }
    
    func completeGame() {
        pauseGame()
        
        let completionTime = elapsedTime
        
        guard var gameState = gameState else { return }
        gameState = GameState(
            gridSize: gameState.gridSize,
            imageKey: gameState.imageKey,
            isUserImage: gameState.isUserImage,
            startTime: gameState.startTime,
            moveCount: moveCount,
            piecePositions: gameState.piecePositions,
            isCompleted: true,
            completionTime: completionTime
        )
        
        GameStateManager.shared.saveCompletedGame(gameState)
        GameStateManager.shared.clearGameState()
        
        delegate?.didCompleteGame(time: completionTime, moves: moveCount)
    }
    
    private func startTimer() {
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.delegate?.didUpdateGameState()
        }
    }
    
    private func saveGameState() {
        guard var gameState = gameState else { return }
        
        gameState = GameState(
            gridSize: gameState.gridSize,
            imageKey: gameState.imageKey,
            isUserImage: gameState.isUserImage,
            startTime: gameState.startTime,
            moveCount: moveCount,
            piecePositions: gameState.piecePositions,
            isCompleted: false,
            completionTime: nil
        )
        
        GameStateManager.shared.saveGameState(gameState)
    }
    
    func handleMemoryWarning() {
        // Handle memory warning
    }
}