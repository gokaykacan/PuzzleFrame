import UIKit

class CompletionViewController: UIViewController {
    
    private var completionTime: TimeInterval = 0
    private var moveCount: Int = 0
    private var gridSize: Int = 4
    
    // MARK: - UI Components
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let timeLabel = UILabel()
    private let movesLabel = UILabel()
    private let newPuzzleButton = UIButton(type: .system)
    private let changeDifficultyButton = UIButton(type: .system)
    private let mainMenuButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        addCelebrationAnimation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    func configure(time: TimeInterval, moves: Int, gridSize: Int) {
        self.completionTime = time
        self.moveCount = moves
        self.gridSize = gridSize
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Title Label
        titleLabel.text = "completion.title".localized
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .systemGreen
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Message Label
        messageLabel.text = "completion.message".localized
        messageLabel.font = .systemFont(ofSize: 18, weight: .medium)
        messageLabel.textAlignment = .center
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(messageLabel)
        
        // Time Label
        let minutes = Int(completionTime) / 60
        let seconds = Int(completionTime) % 60
        let timeString = String(format: "%02d:%02d", minutes, seconds)
        timeLabel.text = String(format: "completion.time".localized, timeString)
        timeLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        timeLabel.textAlignment = .center
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timeLabel)
        
        // Moves Label
        movesLabel.text = String(format: "completion.moves".localized, moveCount)
        movesLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        movesLabel.textAlignment = .center
        movesLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(movesLabel)
        
        // Share Button
        shareButton.setTitle("completion.share".localized, for: .normal)
        shareButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        shareButton.backgroundColor = .systemBlue
        shareButton.setTitleColor(.white, for: .normal)
        shareButton.layer.cornerRadius = 12
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        shareButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shareButton)
        
        // New Puzzle Button
        newPuzzleButton.setTitle("completion.new.puzzle".localized, for: .normal)
        newPuzzleButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        newPuzzleButton.backgroundColor = .systemGreen
        newPuzzleButton.setTitleColor(.white, for: .normal)
        newPuzzleButton.layer.cornerRadius = 12
        newPuzzleButton.addTarget(self, action: #selector(newPuzzleButtonTapped), for: .touchUpInside)
        newPuzzleButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(newPuzzleButton)
        
        // Change Difficulty Button
        changeDifficultyButton.setTitle("completion.change.difficulty".localized, for: .normal)
        changeDifficultyButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        changeDifficultyButton.backgroundColor = .systemOrange
        changeDifficultyButton.setTitleColor(.white, for: .normal)
        changeDifficultyButton.layer.cornerRadius = 12
        changeDifficultyButton.addTarget(self, action: #selector(changeDifficultyButtonTapped), for: .touchUpInside)
        changeDifficultyButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(changeDifficultyButton)
        
        // Main Menu Button
        mainMenuButton.setTitle("completion.main.menu".localized, for: .normal)
        mainMenuButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        mainMenuButton.backgroundColor = .systemGray
        mainMenuButton.setTitleColor(.white, for: .normal)
        mainMenuButton.layer.cornerRadius = 12
        mainMenuButton.addTarget(self, action: #selector(mainMenuButtonTapped), for: .touchUpInside)
        mainMenuButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mainMenuButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Message Label
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Time Label
            timeLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 40),
            timeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            timeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Moves Label
            movesLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 10),
            movesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            movesLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Share Button
            shareButton.topAnchor.constraint(equalTo: movesLabel.bottomAnchor, constant: 60),
            shareButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            shareButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            shareButton.heightAnchor.constraint(equalToConstant: 50),
            
            // New Puzzle Button
            newPuzzleButton.topAnchor.constraint(equalTo: shareButton.bottomAnchor, constant: 20),
            newPuzzleButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            newPuzzleButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            newPuzzleButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Change Difficulty Button
            changeDifficultyButton.topAnchor.constraint(equalTo: newPuzzleButton.bottomAnchor, constant: 20),
            changeDifficultyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            changeDifficultyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            changeDifficultyButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Main Menu Button
            mainMenuButton.topAnchor.constraint(equalTo: changeDifficultyButton.bottomAnchor, constant: 15),
            mainMenuButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainMenuButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            mainMenuButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func addCelebrationAnimation() {
        // Simple scale animation for celebration
        titleLabel.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        UIView.animate(withDuration: 0.8, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
            self.titleLabel.transform = CGAffineTransform.identity
        }, completion: nil)
        
        // Haptic feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    @objc private func shareButtonTapped() {
        let minutes = Int(completionTime) / 60
        let seconds = Int(completionTime) % 60
        let timeString = String(format: "%02d:%02d", minutes, seconds)
        
        let shareText = "I just completed a \(gridSize)×\(gridSize) puzzle in PuzzleFrame!\n⏱️ Time: \(timeString)\n🔄 Moves: \(moveCount)\n\nTry PuzzleFrame yourself! 🧩"
        
        let activityViewController = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = shareButton
            popover.sourceRect = shareButton.bounds
        }
        
        present(activityViewController, animated: true)
    }
    
    @objc private func newPuzzleButtonTapped() {
        // Go back to image selection with same difficulty
        if let navController = navigationController {
            for viewController in navController.viewControllers {
                if let imageSelectionVC = viewController as? ImageSelectionViewController {
                    imageSelectionVC.gridSize = gridSize
                    navController.popToViewController(imageSelectionVC, animated: true)
                    return
                }
            }
        }
        
        // Fallback: create new image selection
        let imageSelectionVC = ImageSelectionViewController()
        imageSelectionVC.gridSize = gridSize
        navigationController?.setViewControllers([MainViewController(), imageSelectionVC], animated: true)
    }
    
    @objc private func changeDifficultyButtonTapped() {
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc private func mainMenuButtonTapped() {
        navigationController?.popToRootViewController(animated: true)
    }
}