import AppKit
import AVFoundation

class ZelerkAppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var stationManager: StationManager!
    private var streamPlayer: StreamPlayer!
    private var nowPlayingService: NowPlayingService!
    private var configurationWindow: ConfigurationWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize services
        stationManager = StationManager()
        streamPlayer = StreamPlayer()
        nowPlayingService = NowPlayingService()

        // Set up now playing updates
        nowPlayingService.onUpdate = { [weak self] nowPlaying in
            DispatchQueue.main.async {
                self?.statusBarController?.updateNowPlaying(nowPlaying)
            }
        }

        // Initialize status bar
        statusBarController = StatusBarController(
            stationManager: stationManager,
            streamPlayer: streamPlayer,
            onShowConfiguration: { [weak self] in
                self?.showConfigurationWindow()
            },
            onStationSelected: { [weak self] station in
                self?.playStation(station)
            }
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        streamPlayer.stop()
        nowPlayingService.stopPolling()
    }

    private func showConfigurationWindow() {
        if configurationWindow == nil {
            configurationWindow = ConfigurationWindow(stationManager: stationManager)
            configurationWindow?.onStationsChanged = { [weak self] in
                self?.statusBarController?.rebuildMenu()
            }
        }
        configurationWindow?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func playStation(_ station: Station) {
        streamPlayer.play(url: station.streamURL)
        statusBarController?.setCurrentStation(station)

        // Start polling for now playing if API URL is configured
        if let apiURL = station.apiURL {
            nowPlayingService.startPolling(apiURL: apiURL)
        } else {
            nowPlayingService.stopPolling()
            statusBarController?.updateNowPlaying(NowPlaying(stationName: station.name))
        }
    }
}
