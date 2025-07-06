import UIKit

class MainViewController: UIViewController {
    
    private let viewModel = MainViewModel()
    private var selectedGridSize: Int = 4
    
    // MARK: - UI Components
    private let titleLabel = UILabel()
    private let difficultySegmentedControl = UISegmentedControl()
    private let selectImageButton = UIButton(type: .system)
    private let resumeGameButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system)
    private let bestTimeLabel = UILabel()
    private let bestMovesLabel = UILabel()
    
    private var difficultyOptions: [(title: String, gridSize: Int)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupUI()
        setupConstraints()
        setupMemoryWarningHandler()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshUI()
    }
    
    deinit {
        viewModel.delegate = nil
        MemoryManager.shared.removeAllMemoryWarningHandlers()
    }
    
    private func setupViewModel() {
        viewModel.delegate = self
        difficultyOptions = viewModel.getDifficultyOptions()
        selectedGridSize = difficultyOptions.first?.gridSize ?? 4
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Title Label
        titleLabel.text = "main.title".localized
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Difficulty Segmented Control
        difficultySegmentedControl.removeAllSegments()
        for (index, option) in difficultyOptions.enumerated() {
            difficultySegmentedControl.insertSegment(withTitle: option.title, at: index, animated: false)
        }
        difficultySegmentedControl.selectedSegmentIndex = 0
        difficultySegmentedControl.addTarget(self, action: #selector(difficultyChanged), for: .valueChanged)
        difficultySegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(difficultySegmentedControl)
        
        // Select Image Button
        selectImageButton.setTitle("main.select.image".localized, for: .normal)
        selectImageButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        selectImageButton.backgroundColor = .systemBlue
        selectImageButton.setTitleColor(.white, for: .normal)
        selectImageButton.layer.cornerRadius = 12
        selectImageButton.addTarget(self, action: #selector(selectImageTapped), for: .touchUpInside)
        selectImageButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(selectImageButton)
        
        // Resume Game Button
        resumeGameButton.setTitle("Continue Game", for: .normal)
        resumeGameButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        resumeGameButton.backgroundColor = .systemGreen
        resumeGameButton.setTitleColor(.white, for: .normal)
        resumeGameButton.layer.cornerRadius = 12
        resumeGameButton.addTarget(self, action: #selector(resumeGameTapped), for: .touchUpInside)
        resumeGameButton.translatesAutoresizingMaskIntoConstraints = false
        resumeGameButton.isHidden = true
        view.addSubview(resumeGameButton)
        
        // Settings Button
        settingsButton.setTitle("main.settings".localized, for: .normal)
        settingsButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        settingsButton.backgroundColor = .systemGray
        settingsButton.setTitleColor(.white, for: .normal)
        settingsButton.layer.cornerRadius = 12
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(settingsButton)
        
        // Best Time Label
        bestTimeLabel.font = .systemFont(ofSize: 14, weight: .regular)
        bestTimeLabel.textColor = .secondaryLabel
        bestTimeLabel.textAlignment = .center
        bestTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bestTimeLabel)
        
        // Best Moves Label
        bestMovesLabel.font = .systemFont(ofSize: 14, weight: .regular)
        bestMovesLabel.textColor = .secondaryLabel
        bestMovesLabel.textAlignment = .center
        bestMovesLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bestMovesLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Difficulty Segmented Control
            difficultySegmentedControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            difficultySegmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            difficultySegmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            difficultySegmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            // Best Time Label
            bestTimeLabel.topAnchor.constraint(equalTo: difficultySegmentedControl.bottomAnchor, constant: 20),
            bestTimeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bestTimeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Best Moves Label
            bestMovesLabel.topAnchor.constraint(equalTo: bestTimeLabel.bottomAnchor, constant: 5),
            bestMovesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            bestMovesLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Select Image Button
            selectImageButton.topAnchor.constraint(equalTo: bestMovesLabel.bottomAnchor, constant: 60),
            selectImageButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            selectImageButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            selectImageButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Resume Game Button
            resumeGameButton.topAnchor.constraint(equalTo: selectImageButton.bottomAnchor, constant: 20),
            resumeGameButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resumeGameButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            resumeGameButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Settings Button
            settingsButton.topAnchor.constraint(equalTo: resumeGameButton.bottomAnchor, constant: 20),
            settingsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            settingsButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupMemoryWarningHandler() {
        MemoryManager.shared.addMemoryWarningHandler { [weak self] in
            self?.handleMemoryWarning()
        }
    }
    
    private func refreshUI() {
        updateBestScoreLabels()
        updateResumeGameButton()
    }
    
    private func updateBestScoreLabels() {
        if let bestTime = viewModel.getBestTime(for: selectedGridSize) {
            bestTimeLabel.text = "Best Time: \(bestTime)"
        } else {
            bestTimeLabel.text = "Best Time: --:--"
        }
        
        if let bestMoves = viewModel.getBestMoveCount(for: selectedGridSize) {
            bestMovesLabel.text = "Best Moves: \(bestMoves)"
        } else {
            bestMovesLabel.text = "Best Moves: --"
        }
    }
    
    private func updateResumeGameButton() {
        if viewModel.hasCurrentGame {
            resumeGameButton.isHidden = false
            if let gameInfo = viewModel.currentGameInfo {
                resumeGameButton.setTitle("Continue Game (\(gameInfo))", for: .normal)
            }
        } else {
            resumeGameButton.isHidden = true
        }
    }
    
    @objc private func difficultyChanged() {
        let index = difficultySegmentedControl.selectedSegmentIndex
        if index < difficultyOptions.count {
            selectedGridSize = difficultyOptions[index].gridSize
            updateBestScoreLabels()
        }
    }
    
    @objc private func selectImageTapped() {
        let imageSelectionVC = ImageSelectionViewController()
        imageSelectionVC.gridSize = selectedGridSize
        navigationController?.pushViewController(imageSelectionVC, animated: true)
    }
    
    @objc private func resumeGameTapped() {
        guard let gameState = viewModel.resumeCurrentGame() else { return }
        
        let puzzleVC = PuzzleViewController()
        puzzleVC.resumeGameState = gameState
        navigationController?.pushViewController(puzzleVC, animated: true)
    }
    
    @objc private func settingsTapped() {
        let settingsVC = SettingsViewController()
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    private func handleMemoryWarning() {
        viewModel.handleMemoryWarning()
    }
}

// MARK: - MainViewModelDelegate
extension MainViewController: MainViewModelDelegate {
    func didUpdateUI() {
        DispatchQueue.main.async { [weak self] in
            self?.refreshUI()
        }
    }
    
    func didEncounterError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.showErrorAlert(message: error.localizedDescription)
        }
    }
}

// MARK: - Error Handling
extension MainViewController {
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "error.title".localized, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "common.ok".localized, style: .default))
        present(alert, animated: true)
    }
}