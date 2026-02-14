import AppKit

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem
    private var menu: NSMenu?
    private var menuBuilder: MenuBuilder
    private let stationManager: StationManager
    private let streamPlayer: StreamPlayer
    private let onShowConfiguration: () -> Void
    private let onStationSelected: (Station) -> Void

    private var currentNowPlaying: NowPlaying?
    private var currentStationID: UUID?
    private var scrollingTextView: ScrollingTextView?
    private var showSongInMenuBar: Bool = UserDefaults.standard.object(forKey: "zelerk.showSongInMenuBar") as? Bool ?? true

    init(stationManager: StationManager, streamPlayer: StreamPlayer, onShowConfiguration: @escaping () -> Void, onStationSelected: @escaping (Station) -> Void) {
        self.stationManager = stationManager
        self.streamPlayer = streamPlayer
        self.onShowConfiguration = onShowConfiguration
        self.onStationSelected = onStationSelected

        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Initialize menu builder
        menuBuilder = MenuBuilder(
            stationManager: stationManager,
            streamPlayer: streamPlayer,
            onStationSelected: onStationSelected,
            onShowConfiguration: onShowConfiguration,
            onTogglePlayPause: { [streamPlayer] in
                streamPlayer.togglePlayPause()
            },
            onStop: { [streamPlayer] in
                streamPlayer.stop()
            },
            onVolumeChanged: { [streamPlayer] volume in
                streamPlayer.volume = volume
            },
            onToggleSongDisplay: { _ in }
        )

        super.init()

        menuBuilder.onToggleSongDisplay = { [weak self] show in
            self?.setShowSongInMenuBar(show)
        }

        setupStatusItem()
        rebuildMenu()

        // Observe player state changes
        streamPlayer.onStateChange = { [weak self] state in
            if state == .stopped {
                self?.currentStationID = nil
            }
            self?.rebuildMenu()
            self?.updateStatusItemAppearance()
        }
    }

    private func setupStatusItem() {
        if let button = statusItem.button {
            // Use SF Symbol for menu bar icon (play icon since we start stopped)
            if let image = NSImage(systemSymbolName: "play.fill", accessibilityDescription: "Play") {
                image.size = NSSize(width: 16, height: 16)
                image.isTemplate = true
                button.image = image
            }
            button.imagePosition = .imageLeft

            // Handle clicks - left click for play/pause, right click for menu
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            // Right click - show menu
            showMenu()
        } else {
            // Left click - toggle play/pause or play first station
            handleLeftClick()
        }
    }

    private func handleLeftClick() {
        switch streamPlayer.state {
        case .playing:
            streamPlayer.pause()
        case .paused:
            streamPlayer.resume()
        case .stopped:
            // Play first station if available
            if let firstStation = stationManager.stations.first {
                onStationSelected(firstStation)
            } else {
                // No stations, show menu so user can configure
                showMenu()
            }
        case .loading:
            // Do nothing while loading
            break
        case .error:
            // On error, show menu
            showMenu()
        }
    }

    private func showMenu() {
        guard let button = statusItem.button else { return }
        menu = menuBuilder.buildMenu(currentNowPlaying: currentNowPlaying, showSongInMenuBar: showSongInMenuBar, currentStationID: currentStationID)
        statusItem.menu = menu
        button.performClick(nil)
        // Clear menu after showing so left-click works again
        DispatchQueue.main.async { [weak self] in
            self?.statusItem.menu = nil
        }
    }

    func rebuildMenu() {
        menu = menuBuilder.buildMenu(currentNowPlaying: currentNowPlaying, showSongInMenuBar: showSongInMenuBar, currentStationID: currentStationID)
    }

    func updateNowPlaying(_ nowPlaying: NowPlaying) {
        currentNowPlaying = nowPlaying
        let displayText = nowPlaying.displayText
        print("[StatusBar] Updating now playing: \(displayText)")

        if showSongInMenuBar {
            updateStatusItemText(displayText)
        }

        rebuildMenu()
    }

    private func updateStatusItemText(_ text: String) {
        guard let button = statusItem.button else { return }

        if showSongInMenuBar && !text.isEmpty {
            // Truncate long titles
            let maxLength = 40
            let displayText = text.count > maxLength ? String(text.prefix(maxLength - 1)) + "…" : text
            button.title = " \(displayText)"
        } else {
            button.title = ""
        }
    }

    private func updateStatusItemAppearance() {
        guard let button = statusItem.button else { return }

        let symbolName: String
        let description: String
        switch streamPlayer.state {
        case .playing:
            symbolName = "pause.fill"
            description = "Pause"
        case .loading:
            symbolName = "ellipsis"
            description = "Loading"
        case .paused:
            symbolName = "play.fill"
            description = "Play"
        case .stopped:
            symbolName = "play.fill"
            description = "Play"
        case .error:
            symbolName = "exclamationmark.triangle"
            description = "Error"
        }

        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: description) {
            image.size = NSSize(width: 16, height: 16)
            image.isTemplate = true
            button.image = image
        }
    }

    func setCurrentStation(_ station: Station) {
        currentStationID = station.id
        rebuildMenu()
    }

    func setShowSongInMenuBar(_ show: Bool) {
        showSongInMenuBar = show
        UserDefaults.standard.set(show, forKey: "zelerk.showSongInMenuBar")
        if !show {
            statusItem.button?.title = ""
        } else if let nowPlaying = currentNowPlaying {
            updateStatusItemText(nowPlaying.displayText)
        }
    }
}
