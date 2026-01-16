//
//  MovieDetailView.swift
//  MovieTracker
//
//  Created by Tobias Fu on 1/12/26.
//

import SwiftUI

struct MovieDetailView: View {
    @Environment(FavoritesStore.self) var favoritesStore
    let movie: Movie
    var isFavorite: Bool { favoritesStore.isFavorite(id: movie.id) }
    
    var body: some View {
        VStack(spacing: 10) {
            if movie.posterPath != nil {
                AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500" + (movie.posterPath!))) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
                .scaledToFit()
                .frame(width: 300)
            }

            
            Text((movie.title))
                .font(.title)
            
            if movie.originalTitle != movie.title {
                Text("Original Title: \(movie.originalTitle)")
                    .font(.subheadline)
            }
            if let releaseDate = movie.releaseDate {
                Text("Relase Date: \(releaseDate)")
            }
            if let score = movie.voteAverage {
                Text("Average Score: \(score.description)")
            }
            
            if let overview = movie.overview {
                Text("Overview: \(overview)")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        try? await favoritesStore.toggleFavorite(movieId: movie.id)
                    }
                } label: {
                        Image(systemName: isFavorite ? "heart.fill":"heart")
                            .foregroundStyle(isFavorite ? .red : .gray)
                }
            }
        }
    }
}

#Preview {
    MovieDetailView(movie: .sample)
}
