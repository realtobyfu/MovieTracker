//
//  FavoritesView.swift
//  MovieTracker
//
//  Created by Tobias Fu on 1/15/26.
//

import SwiftUI

struct FavoritesView: View {
    @State var vm = MovieListViewModel(favoriteVM: true)
    
    var body: some View {
        NavigationStack {
            if vm.isLoading {
                ProgressView()
            } else {
                List {
                    ForEach(vm.movies) { movie in
                        NavigationLink(movie.title, value: movie)
                    }
                    if vm.currentPage < (vm.totalPages ?? 0) {
                        ProgressView()
                        .task {
                            await vm.loadPage()
                        }
                    }
                }
                .navigationDestination(for: Movie.self) { movie in
                    MovieDetailView(movie: movie)
                }
            }
        }
        .task {
            await vm.resetAndLoad()
        }
        .navigationTitle("Favorties")
        .alert("Error", isPresented: $vm.showError) {
            Button("OK") {
                vm.errorMessage = nil
                vm.isLoading = false
            }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }
}

#Preview {
    FavoritesView()
}
