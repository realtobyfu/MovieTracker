///
///  MovieService.swift
///  MovieTracker
///
///  Created by Tobias Fu on 1/10/26.
///

import Foundation

enum Endpoint {
    case discover
    case search(query: String)
    case favorites
    case toggleFavorite
    
    var path: String {
        switch self {
        case .discover: return "/discover/movie"
        case .search: return "/search/movie"
        case .favorites: return "/account/22166677/favorite/movies"
        case .toggleFavorite: return "/account/22166677/favorite"
        }
    }
    
    var baseQueryItems: [URLQueryItem] {
        let common = [
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "language", value: "en-US")
        ]
        switch self {
        case .favorites:
            return common + [URLQueryItem(name: "sort_by", value: "created_at.asc")]
        case .search(let query):
            return common + [URLQueryItem(name: "query", value: query)]

        default:
            return common
        }
    }
}

// MARK: - Request Body
struct FavoriteRequest: Encodable {
    let mediaType: String
    let mediaId: Int
    let favorite: Bool
}

// MARK: - Protocol

protocol MovieServiceProtocol {
    func fetchMovies(endpoint: Endpoint, page: Int) async throws -> Response
    func fetchFavorites(page: Int) async throws -> Response
    func toggleFavorite(movieId: Int, isFavorite: Bool) async throws
}

// MARK: - Service

struct MovieService: MovieServiceProtocol {
    
    private let decoder: JSONDecoder
    
    init(decoder: JSONDecoder = JSONDecoder()) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        decoder.dateDecodingStrategy = .formatted(formatter)
        self.decoder = decoder
        decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    // fetch movies, parameters could either be .search or .discover
    func fetchMovies(endpoint: Endpoint, page: Int) async throws -> Response {
        var queryItems = endpoint.baseQueryItems
        queryItems.append(URLQueryItem(name: "page", value: String(page)))
        
        let request = try buildRequest(endpoint: endpoint, queryItems: queryItems)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try decoder.decode(Response.self, from: data)
    }
    
    func fetchFavorites(page: Int) async throws -> Response {
        var queryItems = Endpoint.favorites.baseQueryItems
        queryItems.append(URLQueryItem(name: "page", value: String(page)))

        let request = try buildRequest(endpoint: .favorites, queryItems: queryItems)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try decoder.decode(Response.self, from: data)
    }
    
    func toggleFavorite(movieId: Int, isFavorite: Bool) async throws {
        var request = try buildRequest(endpoint: .toggleFavorite, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        
        let body = FavoriteRequest(mediaType: "movie", mediaId: movieId, favorite: isFavorite)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    // MARK: - Private Helper
    // this functions takes in an endpoint, i.e.
    // enum .discover -> "/discover/movie"
    // and constructs a URLRequest
    private func buildRequest(
        endpoint: Endpoint,
        method: String = "GET",
        queryItems: [URLQueryItem] = []
    ) throws -> URLRequest {
        guard var components = URLComponents(string: Constants.baseURL + endpoint.path) else {
            throw URLError(.badURL)
        }
        
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
            "accept": "application/json",
            "Authorization": "Bearer \(Constants.apiKey)"
        ]
        return request

    }
}
