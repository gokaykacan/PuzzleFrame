import Foundation
import UIKit

struct GameState: Codable {
    let gridSize: Int
    let imageKey: String
    let isUserImage: Bool
    let startTime: Date
    let moveCount: Int
    let piecePositions: [Int: CGPoint]
    let isCompleted: Bool
    let completionTime: TimeInterval?
    
    private enum CodingKeys: String, CodingKey {
        case gridSize, imageKey, isUserImage, startTime, moveCount, piecePositions, isCompleted, completionTime
    }
    
    init(gridSize: Int, imageKey: String, isUserImage: Bool, startTime: Date = Date(), moveCount: Int = 0, piecePositions: [Int: CGPoint] = [:], isCompleted: Bool = false, completionTime: TimeInterval? = nil) {
        self.gridSize = gridSize
        self.imageKey = imageKey
        self.isUserImage = isUserImage
        self.startTime = startTime
        self.moveCount = moveCount
        self.piecePositions = piecePositions
        self.isCompleted = isCompleted
        self.completionTime = completionTime
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gridSize = try container.decode(Int.self, forKey: .gridSize)
        imageKey = try container.decode(String.self, forKey: .imageKey)
        isUserImage = try container.decode(Bool.self, forKey: .isUserImage)
        startTime = try container.decode(Date.self, forKey: .startTime)
        moveCount = try container.decode(Int.self, forKey: .moveCount)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        completionTime = try container.decodeIfPresent(TimeInterval.self, forKey: .completionTime)
        
        let positionsData = try container.decode([String: [String: Double]].self, forKey: .piecePositions)
        var positions: [Int: CGPoint] = [:]
        for (key, value) in positionsData {
            if let index = Int(key), let x = value["x"], let y = value["y"] {
                positions[index] = CGPoint(x: x, y: y)
            }
        }
        piecePositions = positions
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(gridSize, forKey: .gridSize)
        try container.encode(imageKey, forKey: .imageKey)
        try container.encode(isUserImage, forKey: .isUserImage)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(moveCount, forKey: .moveCount)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encodeIfPresent(completionTime, forKey: .completionTime)
        
        var positionsData: [String: [String: Double]] = [:]
        for (index, point) in piecePositions {
            positionsData[String(index)] = ["x": point.x, "y": point.y]
        }
        try container.encode(positionsData, forKey: .piecePositions)
    }
}

class GameStateManager {
    static let shared = GameStateManager()
    private let userDefaults = UserDefaults.standard
    private let gameStateKey = "current_game_state"
    private let completedGamesKey = "completed_games"
    
    private init() {}
    
    func saveGameState(_ gameState: GameState) {
        do {
            let data = try JSONEncoder().encode(gameState)
            userDefaults.set(data, forKey: gameStateKey)
        } catch {
            print("Failed to save game state: \(error)")
        }
    }
    
    func loadGameState() -> GameState? {
        guard let data = userDefaults.data(forKey: gameStateKey) else { return nil }
        
        do {
            return try JSONDecoder().decode(GameState.self, from: data)
        } catch {
            print("Failed to load game state: \(error)")
            return nil
        }
    }
    
    func clearGameState() {
        userDefaults.removeObject(forKey: gameStateKey)
    }
    
    func saveCompletedGame(_ gameState: GameState) {
        guard gameState.isCompleted else { return }
        
        var completedGames = loadCompletedGames()
        completedGames.append(gameState)
        
        if completedGames.count > 5 {
            completedGames.removeFirst(completedGames.count - 5)
        }
        
        do {
            let data = try JSONEncoder().encode(completedGames)
            userDefaults.set(data, forKey: completedGamesKey)
        } catch {
            print("Failed to save completed games: \(error)")
        }
    }
    
    func loadCompletedGames() -> [GameState] {
        guard let data = userDefaults.data(forKey: completedGamesKey) else { return [] }
        
        do {
            return try JSONDecoder().decode([GameState].self, from: data)
        } catch {
            print("Failed to load completed games: \(error)")
            return []
        }
    }
    
    func getBestTime(for gridSize: Int) -> TimeInterval? {
        let completedGames = loadCompletedGames()
        let relevantGames = completedGames.filter { $0.gridSize == gridSize && $0.completionTime != nil }
        return relevantGames.compactMap { $0.completionTime }.min()
    }
    
    func getBestMoveCount(for gridSize: Int) -> Int? {
        let completedGames = loadCompletedGames()
        let relevantGames = completedGames.filter { $0.gridSize == gridSize && $0.isCompleted }
        return relevantGames.map { $0.moveCount }.min()
    }
    
    func resetHighScores() {
        userDefaults.removeObject(forKey: completedGamesKey)
    }
}