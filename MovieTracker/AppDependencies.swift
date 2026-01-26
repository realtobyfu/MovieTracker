//
//  AppDependencies.swift
//  MovieTracker
//
//  Created by Tobias Fu on 1/21/26.
//

import Foundation
import SafeDICore

@Instantiable(isRoot: true)
public final class AppDependencies {
    public init(
        movieService: MovieServiceProtocol,
        favoritesStore: FavoritesStore,
        movieListViewModel: MovieListViewModel
    ) {
        self.movieService = movieService
        self.favoritesStore = favoritesStore
        self.movieListViewModel = movieListViewModel
    }

    @Instantiated public let movieService: MovieServiceProtocol
    @Instantiated public let favoritesStore: FavoritesStore
    @Instantiated public let movieListViewModel: MovieListViewModel
}
