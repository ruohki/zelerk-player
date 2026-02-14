import AppKit

class MenuBuilder {
    private let stationManager: StationManager
    private let streamPlayer: StreamPlayer
    private let onStationSelected: (Station) -> Void
    private let onShowConfiguration: () -> Void
    private let onTogglePlayPause: () -> Void
    private let onStop: () -> Void
    private let onVolumeChanged: (Float) -> Void
    var onToggleSongDisplay: (Bool) -> Void

    private var volumeSlider: NSSlider?

    init(
        stationManager: StationManager,
        streamPlayer: StreamPlayer,
        onStationSelected: @escaping (Station) -> Void,
        onShowConfiguration: @escaping () -> Void,
        onTogglePlayPause: @escaping () -> Void,
        onStop: @escaping () -> Void,
        onVolumeChanged: @escaping (Float) -> Void,
        onToggleSongDisplay: @escaping (Bool) -> Void
    ) {
        self.stationManager = stationManager
        self.streamPlayer = streamPlayer
        self.onStationSelected = onStationSelected
        self.onShowConfiguration = onShowConfiguration
        self.onTogglePlayPause = onTogglePlayPause
        self.onStop = onStop
        self.onVolumeChanged = onVolumeChanged
        self.onToggleSongDisplay = onToggleSongDisplay
    }

    func buildMenu(currentNowPlaying: NowPlaying?, showSongInMenuBar: Bool = true, currentStationID: UUID? = nil) -> NSMenu {
        let menu = NSMenu()

        // Now Playing section
        if let nowPlaying = currentNowPlaying, streamPlayer.isPlaying || streamPlayer.state == .paused {
            let nowPlayingItem = NSMenuItem(title: nowPlaying.displayText, action: nil, keyEquivalent: "")
            nowPlayingItem.isEnabled = false
            if let font = NSFont.systemFont(ofSize: 12, weight: .medium) as NSFont? {
                nowPlayingItem.attributedTitle = NSAttributedString(
                    string: nowPlaying.displayText,
                    attributes: [.font: font]
                )
            }
            menu.addItem(nowPlayingItem)
            menu.addItem(NSMenuItem.separator())
        }

        // Playback controls
        addPlaybackControls(to: menu)
        menu.addItem(NSMenuItem.separator())

        // Volume slider
        addVolumeControl(to: menu)
        menu.addItem(NSMenuItem.separator())

        // Stations
        addStationsSection(to: menu, currentStationID: currentStationID)
        menu.addItem(NSMenuItem.separator())

        // Settings
        let settingsItem = NSMenuItem(title: "Stations…", action: #selector(MenuActionHandler.showConfiguration), keyEquivalent: ",")
        settingsItem.target = MenuActionHandler.shared
        MenuActionHandler.shared.onShowConfiguration = onShowConfiguration
        menu.addItem(settingsItem)

        // Show Song in Menu Bar toggle
        let songDisplayItem = NSMenuItem(title: "Show Song in Menu Bar", action: #selector(MenuActionHandler.toggleSongDisplay(_:)), keyEquivalent: "")
        songDisplayItem.target = MenuActionHandler.shared
        songDisplayItem.state = showSongInMenuBar ? .on : .off
        MenuActionHandler.shared.onToggleSongDisplay = onToggleSongDisplay
        menu.addItem(songDisplayItem)

        // Start at Login (only on macOS 13+)
        if LoginItemManager.isSupported {
            let loginItem = NSMenuItem(title: "Start at Login", action: #selector(MenuActionHandler.toggleLoginItem), keyEquivalent: "")
            loginItem.target = MenuActionHandler.shared
            loginItem.state = LoginItemManager.isEnabled ? .on : .off
            menu.addItem(loginItem)
        }

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit zelerK", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        return menu
    }

    private func addPlaybackControls(to menu: NSMenu) {
        let playPauseTitle: String
        let playPauseEnabled: Bool

        switch streamPlayer.state {
        case .playing:
            playPauseTitle = "Pause"
            playPauseEnabled = true
        case .paused:
            playPauseTitle = "Resume"
            playPauseEnabled = true
        case .loading:
            playPauseTitle = "Loading…"
            playPauseEnabled = false
        case .stopped:
            playPauseTitle = "Play"
            playPauseEnabled = false
        case .error(let message):
            let errorItem = NSMenuItem(title: "Error: \(message)", action: nil, keyEquivalent: "")
            errorItem.isEnabled = false
            menu.addItem(errorItem)
            playPauseTitle = "Play"
            playPauseEnabled = false
        }

        let playPauseItem = NSMenuItem(title: playPauseTitle, action: #selector(MenuActionHandler.togglePlayPause), keyEquivalent: "p")
        playPauseItem.target = MenuActionHandler.shared
        playPauseItem.isEnabled = playPauseEnabled
        MenuActionHandler.shared.onTogglePlayPause = onTogglePlayPause
        menu.addItem(playPauseItem)

        let stopItem = NSMenuItem(title: "Stop", action: #selector(MenuActionHandler.stop), keyEquivalent: "s")
        stopItem.target = MenuActionHandler.shared
        stopItem.isEnabled = streamPlayer.state != .stopped
        MenuActionHandler.shared.onStop = onStop
        menu.addItem(stopItem)
    }

    private func addVolumeControl(to menu: NSMenu) {
        let volumeItem = NSMenuItem()
        let volumeView = NSView(frame: NSRect(x: 0, y: 0, width: 250, height: 24))
        volumeView.autoresizingMask = [.width]

        let slider = NSSlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minValue = 0
        slider.maxValue = 1
        slider.doubleValue = Double(streamPlayer.volume)
        slider.target = MenuActionHandler.shared
        slider.action = #selector(MenuActionHandler.volumeChanged(_:))
        MenuActionHandler.shared.onVolumeChanged = onVolumeChanged

        volumeView.addSubview(slider)

        NSLayoutConstraint.activate([
            slider.leadingAnchor.constraint(equalTo: volumeView.leadingAnchor, constant: 20),
            slider.trailingAnchor.constraint(equalTo: volumeView.trailingAnchor, constant: -20),
            slider.centerYAnchor.constraint(equalTo: volumeView.centerYAnchor)
        ])

        volumeItem.view = volumeView

        let volumeLabelItem = NSMenuItem(title: "Volume", action: nil, keyEquivalent: "")
        volumeLabelItem.isEnabled = false
        menu.addItem(volumeLabelItem)
        menu.addItem(volumeItem)
    }

    private func addStationsSection(to menu: NSMenu, currentStationID: UUID? = nil) {
        let stationsHeader = NSMenuItem(title: "Stations", action: nil, keyEquivalent: "")
        stationsHeader.isEnabled = false
        menu.addItem(stationsHeader)

        if stationManager.stations.isEmpty {
            let noStationsItem = NSMenuItem(title: "No stations configured", action: nil, keyEquivalent: "")
            noStationsItem.isEnabled = false
            menu.addItem(noStationsItem)
        } else {
            for (index, station) in stationManager.stations.enumerated() {
                let stationItem = NSMenuItem(title: station.name, action: #selector(MenuActionHandler.selectStation(_:)), keyEquivalent: index < 9 ? "\(index + 1)" : "")
                stationItem.tag = index
                stationItem.target = MenuActionHandler.shared
                if station.id == currentStationID {
                    stationItem.state = .on
                }
                menu.addItem(stationItem)
            }
            MenuActionHandler.shared.stations = stationManager.stations
            MenuActionHandler.shared.onStationSelected = onStationSelected
        }
    }
}

// Singleton action handler for menu items
class MenuActionHandler: NSObject {
    static let shared = MenuActionHandler()

    var onShowConfiguration: (() -> Void)?
    var onTogglePlayPause: (() -> Void)?
    var onStop: (() -> Void)?
    var onVolumeChanged: ((Float) -> Void)?
    var onStationSelected: ((Station) -> Void)?
    var onToggleSongDisplay: ((Bool) -> Void)?
    var stations: [Station] = []

    private override init() {
        super.init()
    }

    @objc func showConfiguration() {
        onShowConfiguration?()
    }

    @objc func togglePlayPause() {
        onTogglePlayPause?()
    }

    @objc func stop() {
        onStop?()
    }

    @objc func volumeChanged(_ sender: NSSlider) {
        onVolumeChanged?(Float(sender.doubleValue))
    }

    @objc func selectStation(_ sender: NSMenuItem) {
        let index = sender.tag
        guard index >= 0 && index < stations.count else { return }
        onStationSelected?(stations[index])
    }

    @objc func toggleSongDisplay(_ sender: NSMenuItem) {
        let newState = sender.state != .on
        sender.state = newState ? .on : .off
        onToggleSongDisplay?(newState)
    }

    @objc func toggleLoginItem(_ sender: NSMenuItem) {
        LoginItemManager.isEnabled.toggle()
        sender.state = LoginItemManager.isEnabled ? .on : .off
    }
}
