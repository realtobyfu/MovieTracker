///
///  MovieService.swift
///  MovieTracker
///
///  Created by Tobias Fu on 1/10/26.
///

import Foundation

struct MovieService {
    func performRequest(mode: Mode, page: Int) async throws -> Response {
        var comps: URLComponents?
        switch mode {
        case .search(let searchText):
            comps = URLComponents(string: "https://api.themoviedb.org/3/search/movie")!
            comps?.queryItems = [
                URLQueryItem(name: "query", value: searchText),
                URLQueryItem(name: "include_adult", value: "false"),
                URLQueryItem(name: "language", value: "en-US"),
                URLQueryItem(name: "page", value: String(page))
            ]
        case .discover:
            comps = URLComponents(string: "https://api.themoviedb.org/3/discover/movie")
            comps?.queryItems = [
                URLQueryItem(name: "include_adult", value: "false"),
                URLQueryItem(name: "language", value: "en-US"),
                URLQueryItem(name: "page", value: String(page))
            ]
        }
        
        guard let url = comps?.url else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
            "accept": "application/json",
            "Authorization": "Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJjMWU0YjMyYWIzN2U1MDg2ZmU1YzA5NTIxYzBlNjdhNyIsInN1YiI6IjU2NTYzOTFlOTI1MTQxMDllODAwMDMyZSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.CnjFlQK6eKafVglC_aN3jx98dn9TD_SulgMz86RGohw"
        ]
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        decoder.dateDecodingStrategy = .formatted(formatter)
        
        return try decoder.decode(Response.self, from: data)
    }
    
}
