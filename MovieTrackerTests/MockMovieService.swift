//
//  MockMovieService.swift
//  MovieTrackerTests
//
//  Created by Tobias Fu on 1/18/26.
//

import Foundation
@testable import MovieTracker

class MockMovieService: MovieServiceProtocol {
    // MARK: - Configurable Responses
    var moviesToReturn: [Movie] = []
    var favoritesToReturn: [Movie] = []
    var totalPagesToReturn: Int = 1
    var errorToThrow: Error?
    
    // MARK: - Call Tracking
    var fetchMoviesCalled = false
    var fetchFavoritesCalled = false
    var toggleFavoriteCalled = false
    var lastToggleFavoriteId: Int?
    var lastToggleFavoriteValue: Bool?
    
    func fetchMovies(endpoint: Endpoint, page: Int) async throws -> Response {
        fetchMoviesCalled = true
        if let error = errorToThrow { throw error }
        return Response(
            page: page,
            results: moviesToReturn,
            totalPages: totalPagesToReturn,
            totalResults: moviesToReturn.count
        )
    }
    
    func fetchFavorites(page: Int) async throws -> Response {
        fetchFavoritesCalled = true
        if let error = errorToThrow { throw error }
        return Response(
            page: page,
            results: favoritesToReturn,
            totalPages: totalPagesToReturn,
            totalResults: favoritesToReturn.count
        )
    }
    
    func toggleFavorite(movieId: Int, isFavorite: Bool) async throws {
        toggleFavoriteCalled = true
        lastToggleFavoriteId = movieId
        lastToggleFavoriteValue = isFavorite
        if let error = errorToThrow { throw error }
    }
    
    
    // MARK: - Helpers
    func reset() {
        moviesToReturn = []
        favoritesToReturn = []
        totalPagesToReturn = 1
        errorToThrow = nil
        fetchMoviesCalled = false
        fetchFavoritesCalled = false
        lastToggleFavoriteId = nil
        lastToggleFavoriteValue = nil
    }
}
