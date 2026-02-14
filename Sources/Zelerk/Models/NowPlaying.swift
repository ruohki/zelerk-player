import Foundation

struct NowPlaying {
    var stationName: String
    var artist: String?
    var title: String?
    var album: String?
    var artworkURL: URL?

    var displayText: String {
        if let artist = artist, let title = title {
            return "\(artist) - \(title)"
        } else if let title = title {
            return title
        } else if let artist = artist {
            return artist
        } else {
            return stationName
        }
    }

    init(stationName: String = "", artist: String? = nil, title: String? = nil, album: String? = nil, artworkURL: URL? = nil) {
        self.stationName = stationName
        self.artist = artist
        self.title = title
        self.album = album
        self.artworkURL = artworkURL
    }
}

// AzuraCast API Response structures
struct AzuraCastNowPlayingResponse: Codable {
    let station: AzuraCastStation?
    let nowPlaying: AzuraCastNowPlaying?

    enum CodingKeys: String, CodingKey {
        case station
        case nowPlaying = "now_playing"
    }
}

struct AzuraCastStation: Codable {
    let name: String
}

struct AzuraCastNowPlaying: Codable {
    let song: AzuraCastSong?
}

struct AzuraCastSong: Codable {
    let title: String?
    let artist: String?
    let album: String?
    let art: String?
}
