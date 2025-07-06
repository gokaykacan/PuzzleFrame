import UIKit

class SettingsViewController: UIViewController {
    
    private let viewModel = SettingsViewModel()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    
    private enum Section: Int, CaseIterable {
        case language
        case gameSettings
        case dataManagement
        case navigation
        case about
        
        var title: String {
            switch self {
            case .language:
                return "settings.language".localized
            case .gameSettings:
                return "Game Settings"
            case .dataManagement:
                return "Data Management"
            case .navigation:
                return "Navigation"
            case .about:
                return "About"
            }
        }
    }
    
    private enum LanguageRow: Int, CaseIterable {
        case language
    }
    
    private enum GameSettingsRow: Int, CaseIterable {
        case sound
        case haptic
        case timer
    }
    
    private enum DataManagementRow: Int, CaseIterable {
        case photoAccess
        case resetScores
        case cacheSize
        case clearCache
    }
    
    private enum NavigationRow: Int, CaseIterable {
        case mainMenu
    }
    
    private enum AboutRow: Int, CaseIterable {
        case version
        case memoryUsage
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupUI()
        setupNotifications()
    }
    
    deinit {
        viewModel.delegate = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupViewModel() {
        viewModel.delegate = self
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "settings.title".localized
        
        // Add back button - make it more prominent
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped)
        )
        navigationItem.leftBarButtonItem?.title = "common.back".localized
        
        // Also add a close button for safety
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "common.done".localized,
            style: .done,
            target: self,
            action: #selector(backTapped)
        )
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: "SwitchCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageChanged),
            name: .languageChanged,
            object: nil
        )
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func languageChanged() {
        DispatchQueue.main.async { [weak self] in
            self?.updateUIForLanguageChange()
        }
    }
    
    private func updateUIForLanguageChange() {
        title = "settings.title".localized
        navigationItem.leftBarButtonItem?.title = "common.back".localized
        navigationItem.rightBarButtonItem?.title = "common.done".localized
        tableView.reloadData()
    }
    
    private func showLanguageSelection() {
        let alert = UIAlertController(title: "settings.language".localized, message: nil, preferredStyle: .actionSheet)
        
        for language in viewModel.availableLanguages {
            let displayName = viewModel.getLanguageDisplayName(language)
            let isSelected = language == viewModel.currentLanguage
            let title = isSelected ? "✓ \(displayName)" : displayName
            
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.viewModel.setLanguage(language)
            })
        }
        
        alert.addAction(UIAlertAction(title: "common.cancel".localized, style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = tableView
            popover.sourceRect = tableView.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func showResetScoresConfirmation() {
        let alert = UIAlertController(
            title: "settings.reset.scores".localized,
            message: "Are you sure you want to reset all high scores?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { [weak self] _ in
            self?.viewModel.resetHighScores()
        })
        
        alert.addAction(UIAlertAction(title: "common.cancel".localized, style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showClearCacheConfirmation() {
        let alert = UIAlertController(
            title: "Clear Cache",
            message: "Are you sure you want to clear the image cache?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            self?.viewModel.clearCache()
        })
        
        alert.addAction(UIAlertAction(title: "common.cancel".localized, style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func handlePhotoAccessTap() {
        let status = viewModel.getPhotoAccessStatus()
        
        if status == "Denied" || status == "Restricted" {
            // Show settings alert
            PhotoKitManager.shared.showPermissionAlert(from: self)
        } else if status == "Not Requested" {
            // Request permission
            viewModel.requestPhotoAccess()
        } else {
            // Already granted, show info
            let alert = UIAlertController(
                title: "permission.photos.title".localized,
                message: "Photo access is already granted.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "common.ok".localized, style: .default))
            present(alert, animated: true)
        }
    }
    
    private func goToMainMenu() {
        navigationController?.popToRootViewController(animated: true)
    }
}

// MARK: - UITableViewDataSource
extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }
        
        switch sectionType {
        case .language:
            return LanguageRow.allCases.count
        case .gameSettings:
            return GameSettingsRow.allCases.count
        case .dataManagement:
            return DataManagementRow.allCases.count
        case .navigation:
            return NavigationRow.allCases.count
        case .about:
            return AboutRow.allCases.count
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(rawValue: section)?.title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sectionType = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        
        switch sectionType {
        case .language:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = "settings.language".localized
            cell.detailTextLabel?.text = viewModel.getLanguageDisplayName(viewModel.currentLanguage)
            cell.accessoryType = .disclosureIndicator
            return cell
            
        case .gameSettings:
            guard let rowType = GameSettingsRow(rawValue: indexPath.row) else { return UITableViewCell() }
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SwitchTableViewCell
            
            switch rowType {
            case .sound:
                cell.configure(title: "settings.sound".localized, isOn: viewModel.isSoundEnabled) { [weak self] isOn in
                    self?.viewModel.isSoundEnabled = isOn
                }
            case .haptic:
                cell.configure(title: "settings.haptic".localized, isOn: viewModel.isHapticEnabled) { [weak self] isOn in
                    self?.viewModel.isHapticEnabled = isOn
                }
            case .timer:
                cell.configure(title: "settings.timer".localized, isOn: viewModel.isTimerEnabled) { [weak self] isOn in
                    self?.viewModel.isTimerEnabled = isOn
                }
            }
            return cell
            
        case .dataManagement:
            guard let rowType = DataManagementRow(rawValue: indexPath.row) else { return UITableViewCell() }
            
            switch rowType {
            case .photoAccess:
                let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
                cell.textLabel?.text = "settings.photo.access".localized
                cell.detailTextLabel?.text = viewModel.getPhotoAccessStatus()
                cell.accessoryType = .disclosureIndicator
                return cell
            case .resetScores:
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = "settings.reset.scores".localized
                cell.textLabel?.textColor = .systemRed
                cell.accessoryType = .none
                return cell
            case .cacheSize:
                let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
                cell.textLabel?.text = "Cache Size"
                cell.detailTextLabel?.text = viewModel.getCacheSize()
                cell.accessoryType = .none
                cell.selectionStyle = .none
                return cell
            case .clearCache:
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = "Clear Cache"
                cell.textLabel?.textColor = .systemOrange
                cell.accessoryType = .none
                return cell
            }
            
        case .navigation:
            guard let rowType = NavigationRow(rawValue: indexPath.row) else { return UITableViewCell() }
            
            switch rowType {
            case .mainMenu:
                let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
                cell.textLabel?.text = "puzzle.menu".localized
                cell.textLabel?.textColor = .systemBlue
                cell.accessoryType = .disclosureIndicator
                return cell
            }
            
        case .about:
            guard let rowType = AboutRow(rawValue: indexPath.row) else { return UITableViewCell() }
            
            switch rowType {
            case .version:
                let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
                cell.textLabel?.text = "settings.version".localized
                cell.detailTextLabel?.text = viewModel.getAppVersion()
                cell.accessoryType = .none
                cell.selectionStyle = .none
                return cell
            case .memoryUsage:
                let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
                cell.textLabel?.text = "Memory Usage"
                cell.detailTextLabel?.text = viewModel.getMemoryUsage()
                cell.accessoryType = .none
                cell.selectionStyle = .none
                return cell
            }
        }
    }
}

// MARK: - UITableViewDelegate
extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let sectionType = Section(rawValue: indexPath.section) else { return }
        
        switch sectionType {
        case .language:
            showLanguageSelection()
            
        case .gameSettings:
            break
            
        case .dataManagement:
            guard let rowType = DataManagementRow(rawValue: indexPath.row) else { return }
            switch rowType {
            case .photoAccess:
                handlePhotoAccessTap()
            case .resetScores:
                showResetScoresConfirmation()
            case .cacheSize:
                break
            case .clearCache:
                showClearCacheConfirmation()
            }
            
        case .navigation:
            guard let rowType = NavigationRow(rawValue: indexPath.row) else { return }
            switch rowType {
            case .mainMenu:
                goToMainMenu()
            }
            
        case .about:
            break
        }
    }
}

// MARK: - SettingsViewModelDelegate
extension SettingsViewController: SettingsViewModelDelegate {
    func didUpdateLanguage() {
        DispatchQueue.main.async { [weak self] in
            self?.updateUIForLanguageChange()
        }
    }
    
    func didUpdateSettings() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    func didEncounterError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.showErrorAlert(message: error.localizedDescription)
        }
    }
}

// MARK: - SwitchTableViewCell
class SwitchTableViewCell: UITableViewCell {
    
    private let titleLabel = UILabel()
    private let switchControl = UISwitch()
    private var valueChangeHandler: ((Bool) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        switchControl.translatesAutoresizingMaskIntoConstraints = false
        switchControl.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(switchControl)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            switchControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            switchControl.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: switchControl.leadingAnchor, constant: -16)
        ])
    }
    
    func configure(title: String, isOn: Bool, valueChangeHandler: @escaping (Bool) -> Void) {
        titleLabel.text = title
        switchControl.isOn = isOn
        self.valueChangeHandler = valueChangeHandler
    }
    
    @objc private func switchValueChanged() {
        valueChangeHandler?(switchControl.isOn)
    }
}

// MARK: - Error Handling
extension SettingsViewController {
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "error.title".localized, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "common.ok".localized, style: .default))
        present(alert, animated: true)
    }
}