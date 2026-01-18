//
//  FavoritesStore.swift
//  MovieTracker
//
//  Created by Tobias Fu on 1/15/26.
//

import Foundation

/// Single source of truth for favorites - holds both IDs (for quick lookup) and movies (for display)
@MainActor @Observable
final class FavoritesStore {
    nonisolated private let service: MovieServiceProtocol

    // Both are always kept in sync
    private(set) var favoriteIDs: Set<Int> = []
    private(set) var favoriteMovies: [Movie] = []

    // Pagination & loading state
    var currentPage = 1
    var totalPages: Int?
    var isLoading = false
    var errorMessage: String?

    nonisolated init(service: MovieServiceProtocol = MovieService()) {
        self.service = service
    }

    func isFavorite(_ movieId: Int) -> Bool {
        favoriteIDs.contains(movieId)
    }

    /// Initial load of favorites
    func loadFavorites() async {
        guard !isLoading else { return }
        isLoading = true

        do {
            let response = try await service.fetchFavorites(page: currentPage)
            for movie in response.results {
                // Only add if not already present (deduplication)
                if favoriteIDs.insert(movie.id).inserted {
                    favoriteMovies.append(movie)
                }
            }
            totalPages = response.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Load next page of favorites
    func loadNextPage() async {
        guard currentPage < (totalPages ?? 1) else { return }
        currentPage += 1
        await loadFavorites()
    }

    /// Refresh favorites from API
    func refresh() async {
        currentPage = 1
        favoriteIDs.removeAll()
        favoriteMovies.removeAll()
        await loadFavorites()
    }

    /// Toggle favorite - updates both Set and array, with optimistic update
    func toggleFavorite(movie: Movie) async throws {
        let willBeFavorite = !favoriteIDs.contains(movie.id)

        // Optimistic update
        if willBeFavorite {
            favoriteIDs.insert(movie.id)
            favoriteMovies.append(movie)
        } else {
            favoriteIDs.remove(movie.id)
            favoriteMovies.removeAll { $0.id == movie.id }
        }

        do {
            try await service.toggleFavorite(movieId: movie.id, isFavorite: willBeFavorite)
        } catch {
            // Revert on failure
            if willBeFavorite {
                favoriteIDs.remove(movie.id)
                favoriteMovies.removeAll { $0.id == movie.id }
            } else {
                favoriteIDs.insert(movie.id)
                favoriteMovies.append(movie)
            }
            throw error
        }
    }
}
