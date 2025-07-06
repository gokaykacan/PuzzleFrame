import UIKit

protocol MainViewModelDelegate: AnyObject {
    func didUpdateUI()
    func didEncounterError(_ error: Error)
}

class MainViewModel {
    
    weak var delegate: MainViewModelDelegate?
    
    private let gameStateManager = GameStateManager.shared
    
    var hasCurrentGame: Bool {
        return gameStateManager.loadGameState() != nil
    }
    
    var currentGameInfo: String? {
        guard let gameState = gameStateManager.loadGameState() else { return nil }
        let elapsed = Date().timeIntervalSince(gameState.startTime)
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return String(format: "%d×%d - %02d:%02d", gameState.gridSize, gameState.gridSize, minutes, seconds)
    }
    
    deinit {
        delegate = nil
    }
    
    func getDifficultyOptions() -> [(title: String, gridSize: Int)] {
        return [
            ("main.difficulty.easy".localized, 4),
            ("main.difficulty.medium".localized, 8),
            ("main.difficulty.hard".localized, 16),
            ("main.difficulty.expert".localized, 32),
            ("main.difficulty.master".localized, 64)
        ]
    }
    
    func resumeCurrentGame() -> GameState? {
        return gameStateManager.loadGameState()
    }
    
    func clearCurrentGame() {
        gameStateManager.clearGameState()
        delegate?.didUpdateUI()
    }
    
    func getBestTime(for gridSize: Int) -> String? {
        guard let bestTime = gameStateManager.getBestTime(for: gridSize) else { return nil }
        let minutes = Int(bestTime) / 60
        let seconds = Int(bestTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func getBestMoveCount(for gridSize: Int) -> String? {
        guard let bestMoves = gameStateManager.getBestMoveCount(for: gridSize) else { return nil }
        return "\(bestMoves)"
    }
    
    func handleMemoryWarning() {
        MemoryManager.shared.removeAllMemoryWarningHandlers()
    }
}