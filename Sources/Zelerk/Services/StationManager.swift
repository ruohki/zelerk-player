import Foundation

class StationManager {
    private let userDefaultsKey = "zelerk.stations"

    private(set) var stations: [Station] = []

    var onStationsChanged: (() -> Void)?

    init() {
        loadStations()
    }

    // MARK: - CRUD Operations

    func addStation(_ station: Station) {
        stations.append(station)
        saveStations()
        onStationsChanged?()
    }

    func updateStation(_ station: Station) {
        if let index = stations.firstIndex(where: { $0.id == station.id }) {
            stations[index] = station
            saveStations()
            onStationsChanged?()
        }
    }

    func deleteStation(_ station: Station) {
        stations.removeAll { $0.id == station.id }
        saveStations()
        onStationsChanged?()
    }

    func deleteStation(at index: Int) {
        guard index >= 0 && index < stations.count else { return }
        stations.remove(at: index)
        saveStations()
        onStationsChanged?()
    }

    func moveStation(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex >= 0 && sourceIndex < stations.count else { return }
        guard destinationIndex >= 0 && destinationIndex <= stations.count else { return }

        let station = stations.remove(at: sourceIndex)
        let adjustedDestination = destinationIndex > sourceIndex ? destinationIndex - 1 : destinationIndex
        stations.insert(station, at: min(adjustedDestination, stations.count))
        saveStations()
        onStationsChanged?()
    }

    // MARK: - Persistence

    private func loadStations() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            // First launch - populate with default stations
            stations = Self.defaultStations
            saveStations()
            return
        }

        do {
            stations = try JSONDecoder().decode([Station].self, from: data)
        } catch {
            print("Failed to load stations: \(error)")
            stations = Self.defaultStations
            saveStations()
        }
    }

    // MARK: - Default Stations

    private static let defaultStations: [Station] = [
        Station(
            name: "Chiptune.FM - 24/7 Random Chiptune Radio",
            streamURL: URL(string: "https://radio.zelerk.com/hls/chiptune/live.m3u8")!,
            apiURL: URL(string: "https://radio.zelerk.com/api/nowplaying/3")
        ),
        Station(
            name: "Vapor.FM - 24/7 Random Vaporfunk Radio",
            streamURL: URL(string: "https://radio.zelerk.com/hls/vapor/live.m3u8")!,
            apiURL: URL(string: "https://radio.zelerk.com/api/nowplaying/5")
        ),
        Station(
            name: "Keygen.FM - 24/7 Random Keygen Radio",
            streamURL: URL(string: "https://radio.zelerk.com/listen/keygen/stream.mp3")!,
            apiURL: URL(string: "https://radio.zelerk.com/api/nowplaying/6")
        )
    ]

    private func saveStations() {
        do {
            let data = try JSONEncoder().encode(stations)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to save stations: \(error)")
        }
    }

    // MARK: - Import/Export

    func exportStations() -> Data? {
        try? JSONEncoder().encode(stations)
    }

    func importStations(from data: Data) throws {
        let importedStations = try JSONDecoder().decode([Station].self, from: data)
        stations.append(contentsOf: importedStations)
        saveStations()
        onStationsChanged?()
    }
}
