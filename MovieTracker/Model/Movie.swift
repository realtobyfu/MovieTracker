//
//  MovieDTO.swift
//  MovieTracker
//
//  Created by Tobias Fu on 1/11/26.
//


struct Response: Codable {
    var page: Int
    var results: [Movie]
    var totalPages: Int
    var totalResults: Int
}

struct Movie: Codable, Hashable, Identifiable {
    let id: Int
    let originalTitle : String
    let title: String
    let overview: String?
    let posterPath: String?
    let releaseDate: String?
    let voteAverage: Double?
    let durationInMinutes: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, originalTitle, title, overview, posterPath, releaseDate, voteAverage
        case durationInMinutes = "runtime"
    }
}

extension Movie {
    static var sample = Movie(id: 1242898, originalTitle: "Predator: Badlands", title: "Predator: Badlands", overview: "Cast out from his clan, a young Predator finds an unlikely ally in a damaged android and embarks on a treacherous journey in search of the ultimate adversary.", posterPath: "/pHpq9yNUIo6aDoCXEBzjSolywgz.jpg", releaseDate: "2025-11-05", voteAverage: 7.758, durationInMinutes: 130)
    
    static var sample2 = Movie(
        id: 999,
        originalTitle: "Test Movie 2",
        title: "Test Movie 2",
        overview: "A test movie",
        posterPath: nil,
        releaseDate: "2025-01-01",
        voteAverage: 8.0,
        durationInMinutes: 120
    )

}
