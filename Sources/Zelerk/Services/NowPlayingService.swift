import Foundation

class NowPlayingService {
    private var timer: Timer?
    private var currentAPIURL: URL?
    private let pollingInterval: TimeInterval = 10.0  // Poll every 10 seconds

    var onUpdate: ((NowPlaying) -> Void)?
    var onError: ((Error) -> Void)?

    private var lastDisplayText: String?
    private var isFirstFetch: Bool = true

    func startPolling(apiURL: URL) {
        stopPolling()
        currentAPIURL = apiURL
        isFirstFetch = true

        // Fetch immediately
        fetchNowPlaying()

        // Set up timer for periodic polling
        timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            self?.fetchNowPlaying()
        }
        // Add to common run loop modes so it fires even during menu tracking
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
        currentAPIURL = nil
        lastDisplayText = nil
        isFirstFetch = true
    }

    private func fetchNowPlaying() {
        guard let apiURL = currentAPIURL else { return }

        let task = URLSession.shared.dataTask(with: apiURL) { [weak self] data, response, error in
            if let error = error {
                print("[NowPlaying] Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.onError?(error)
                }
                return
            }

            guard let data = data else {
                print("[NowPlaying] No data received")
                return
            }

            do {
                let apiResponse = try JSONDecoder().decode(AzuraCastNowPlayingResponse.self, from: data)
                let nowPlaying = NowPlaying(
                    stationName: apiResponse.station?.name ?? "",
                    artist: apiResponse.nowPlaying?.song?.artist,
                    title: apiResponse.nowPlaying?.song?.title,
                    album: apiResponse.nowPlaying?.song?.album,
                    artworkURL: apiResponse.nowPlaying?.song?.art.flatMap { URL(string: $0) }
                )

                DispatchQueue.main.async {
                    guard let self = self else { return }

                    let displayText = nowPlaying.displayText

                    // Update if first fetch or if content changed
                    if self.isFirstFetch || self.lastDisplayText != displayText {
                        self.isFirstFetch = false
                        self.lastDisplayText = displayText
                        print("[NowPlaying] Updated: \(displayText)")
                        self.onUpdate?(nowPlaying)
                    }
                }
            } catch {
                print("[NowPlaying] Parse error: \(error)")
                // Try to print raw JSON for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("[NowPlaying] Raw response: \(jsonString.prefix(500))")
                }
                DispatchQueue.main.async {
                    self?.onError?(error)
                }
            }
        }
        task.resume()
    }
}
