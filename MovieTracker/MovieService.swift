////
////  MovieService.swift
////  MovieTracker
////
////  Created by Tobias Fu on 1/10/26.
////
//
//import Foundation
//
//enum NetworkError: Error {
//    case invalidURL(url: String)
//    case invalidResponse
//    case decodingError(Error)
//}
//
//
//enum MovieEndpoint {
//    case discover
//    case search
//    case detail(Int)
//    
//    var path: String {
//        switch self {
//        case .discover:
//            return "/discover/movie"
//        case .search:
//            return "/search/movie"
//        case .detail(let id):
//            return "/movie/\(id)"
//        }
//    }
//    
//    func baseQueryItems() -> [URLQueryItem] {
//        let commonItems = [
//            URLQueryItem(name: "include_adult", value: "false"),
//            URLQueryItem(name: "language", value: "en-US")
//        ]
//        
//        switch self {
//        case .discover:
//            return commonItems + [
//                URLQueryItem(name: "include_video", value: "false"),
//                URLQueryItem(name: "sort_by", value: "popularity.desc")
//            ]
//        case .search, .detail:
//            return commonItems
//        }
//        
//    }
//}
//
//struct MovieService {
//    private let session: URLSession
//    private let bearerToken: String
//    private let baseURL: String
//    private let decoder: JSONDecoder
//    
//    init(session: URLSession, bearerToken: String, baseURL: String, decoder: JSONDecoder) {
//        self.session = session
//        self.bearerToken = bearerToken
//        self.baseURL = baseURL
//        self.decoder = decoder
//    }
//    
//    private func performRequest<T: Codable>(
//        endpoint: MovieEndpoint,
//        additionalQueryItems: [URLQueryItem] = [],
//        responseType: T.Type
//    ) async throws -> T {
//        guard let url = URL(string: baseURL + endpoint.path) else {
//            throw URLError(.badURL)
//        }
//        
//        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
//            throw URLError(.badURL)
//        }
//        
//        let queryItems = endpoint.baseQueryItems() + additionalQueryItems
//        components.queryItems = components.queryItems.map { $0 + queryItems } ?? queryItems
//        
//        var request = URLRequest(url: components.url!)
//        request.httpMethod = "GET"
//        request.timeoutInterval = 10
//        request.allHTTPHeaderFields = [
//            "accept":  "application/json",
//            "Authorization": "Bearer \(bearerToken)"
//        ]
//        
//        let (data, response) = try await session.data(for: request)
//    }
//        
//    
//    
//    func fetchMovies(endpoint: MovieEndpoint, page: Int = 1, query: String? = nil) async throws -> [Movie] 
//}
