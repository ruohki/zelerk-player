import Foundation

struct Station: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var streamURL: URL
    var apiURL: URL?  // Optional AzuraCast API endpoint for now-playing

    init(id: UUID = UUID(), name: String, streamURL: URL, apiURL: URL? = nil) {
        self.id = id
        self.name = name
        self.streamURL = streamURL
        self.apiURL = apiURL
    }
}
