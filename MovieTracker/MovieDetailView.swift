//
//  MovieDetailView.swift
//  MovieTracker
//
//  Created by Tobias Fu on 1/12/26.
//

import SwiftUI

struct MovieDetailView: View {
    let movie: Movie
    
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
//        .task {
//            image = await loadImage()
//        }
    }
    
//    func loadImage() async -> AsyncImage<Image> {
//        return AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500" + movie.posterPath))
//    }
}

#Preview {
    MovieDetailView(movie: .sample)
}
