import AVFoundation
import Foundation

enum PlayerState: Equatable {
    case stopped
    case playing
    case paused
    case loading
    case error(String)
}

class StreamPlayer: NSObject {
    private static let volumeKey = "zelerk.volume"

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var statusObservation: NSKeyValueObservation?
    private var timeControlObservation: NSKeyValueObservation?

    private(set) var state: PlayerState = .stopped {
        didSet {
            onStateChange?(state)
        }
    }

    var onStateChange: ((PlayerState) -> Void)?

    private var _volume: Float

    var volume: Float {
        get { _volume }
        set {
            _volume = newValue
            player?.volume = newValue
            UserDefaults.standard.set(newValue, forKey: Self.volumeKey)
        }
    }

    var isPlaying: Bool {
        if case .playing = state { return true }
        return false
    }

    override init() {
        // Load saved volume or default to 1.0
        let savedVolume = UserDefaults.standard.object(forKey: Self.volumeKey) as? Float
        _volume = savedVolume ?? 1.0
        super.init()
    }

    func play(url: URL) {
        stop()

        state = .loading

        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.volume = _volume

        // Observe player item status
        statusObservation = playerItem?.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    self?.player?.play()
                    self?.state = .playing
                case .failed:
                    let errorMessage = item.error?.localizedDescription ?? "Unknown error"
                    self?.state = .error(errorMessage)
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }

        // Observe time control status for play/pause state
        timeControlObservation = player?.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch player.timeControlStatus {
                case .playing:
                    self.state = .playing
                case .paused:
                    // Only set to paused if we're not stopped or loading
                    if case .playing = self.state {
                        self.state = .paused
                    }
                case .waitingToPlayAtSpecifiedRate:
                    self.state = .loading
                @unknown default:
                    break
                }
            }
        }
    }

    func pause() {
        player?.pause()
        state = .paused
    }

    func resume() {
        player?.play()
        state = .playing
    }

    func togglePlayPause() {
        switch state {
        case .playing:
            pause()
        case .paused:
            resume()
        default:
            break
        }
    }

    func stop() {
        statusObservation?.invalidate()
        timeControlObservation?.invalidate()
        statusObservation = nil
        timeControlObservation = nil

        player?.pause()
        player = nil
        playerItem = nil

        state = .stopped
    }
}
