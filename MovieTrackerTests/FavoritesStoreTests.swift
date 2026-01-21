//
//  FavoritesStoreTests.swift
//  MovieTrackerTests
//
//  Created by Tobias Fu on 1/19/26.
//

import Testing
import Foundation
@testable import MovieTracker

@Suite("FavoritesStore Tests")
struct FavoritesStoreTests {

    // MARK: - Load Favorites
    @Test("loadFavorites populates both IDs and movies")
    @MainActor
    func loadFavoritesPopulatesBoth() async {
        let mock = MockMovieService()
        mock.favoritesToReturn = [.sample]
        let store = FavoritesStore(service: mock)

        await store.loadFavorites()
        #expect(store.favoriteIDs.contains(Movie.sample.id))
        #expect(store.favoriteMovies.count == 1)
        #expect(mock.fetchFavoritesCalled)
    }

    @Test("loadFavorites deduplicates movies")
    @MainActor
    func loadFavoritesDeduplicates() async {
        let mock = MockMovieService()
        mock.favoritesToReturn = [.sample]
        let store = FavoritesStore(service: mock)

        await store.loadFavorites()
        await store.refresh()  // Load again

        #expect(store.favoriteMovies.count == 1)  // Not duplicated
    }

    // MARK: - Toggle Favorite

    @Test("toggle adds movie to both Set and array")
    @MainActor
    func toggleAdds() async throws {
        let mock = MockMovieService()
        let store = FavoritesStore(service: mock)

        try await store.toggleFavorite(movie: .sample)

        #expect(store.isFavorite(Movie.sample.id))
        #expect(store.favoriteMovies.count == 1)
        #expect(mock.toggleFavoriteCalled)
        #expect(mock.lastToggleFavoriteValue == true)
    }

    @Test("toggle removes movie from both Set and array")
    @MainActor
    func toggleRemoves() async throws {
        let mock = MockMovieService()
        let store = FavoritesStore(service: mock)

        // Add first
        try await store.toggleFavorite(movie: .sample)
        // Then remove
        try await store.toggleFavorite(movie: .sample)

        #expect(!store.isFavorite(Movie.sample.id))
        #expect(store.favoriteMovies.isEmpty)
        #expect(mock.lastToggleFavoriteValue == false)
    }

    @Test("toggle reverts on API error")
    @MainActor
    func toggleRevertsOnError() async {
        let mock = MockMovieService()
        mock.errorToThrow = URLError(.badServerResponse)
        let store = FavoritesStore(service: mock)

        do {
            try await store.toggleFavorite(movie: .sample)
            Issue.record("Expected error to be thrown")
        } catch {
            // Expected
        }

        #expect(!store.isFavorite(Movie.sample.id))
        #expect(store.favoriteMovies.isEmpty)
    }

    // MARK: - Sync Invariant

    @Test("favoriteIDs and favoriteMovies count always match")
    @MainActor
    func syncInvariant() async throws {
        let mock = MockMovieService()
        mock.favoritesToReturn = [.sample]
        let store = FavoritesStore(service: mock)

        await store.loadFavorites()
        #expect(store.favoriteIDs.count == store.favoriteMovies.count)

        try await store.toggleFavorite(movie: .sample2)
        #expect(store.favoriteIDs.count == store.favoriteMovies.count)

        try await store.toggleFavorite(movie: .sample)
        #expect(store.favoriteIDs.count == store.favoriteMovies.count)
    }
}
