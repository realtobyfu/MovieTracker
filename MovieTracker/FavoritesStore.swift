//
//  FavoritesStore.swift
//  MovieTracker
//
//  Created by Tobias Fu on 1/15/26.
//

import Foundation

@MainActor @Observable
final class FavoritesStore {
    private let service: MovieServiceProtocol
    private(set) var favoritesIDs: Set<Int> = []
    var isLoaded = false
    
    nonisolated init(service: MovieServiceProtocol = MovieService()) {
        self.service = service
    }

    func isFavorite(id: Int) -> Bool{
        return favoritesIDs.contains(id)
    }
    
    // This only runs initially with app startup
    func loadFavorites() async {
        guard !isLoaded else { return }
        
        do {
            let response = try await service.fetchFavorites(page: 1)
            favoritesIDs = Set(response.results.map {$0.id})
        } catch {
            // fail silently - favorites just won't show as filled
        }
    }
    
    func toggleFavorite(movieId: Int) async throws {
        let willBeFavorite = !favoritesIDs.contains(movieId)
        
        if willBeFavorite {
            favoritesIDs.insert(movieId)
        } else {
            favoritesIDs.remove(movieId)
        }
        
        do {
            try await service.toggleFavorite(movieId: movieId, isFavorite: willBeFavorite)
        } catch {
            if willBeFavorite {
                favoritesIDs.remove(movieId)
            } else {
                favoritesIDs.insert(movieId)
            }
            throw error
        }
        
        func refresh() async {
            isLoaded = false
            await loadFavorites()
        }
    }
}
