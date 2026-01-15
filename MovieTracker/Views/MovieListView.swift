//
//  ContentView.swift
//  MovieTracker
//
//  Created by Tobias Fu on 1/10/26.
//

import SwiftUI

struct MovieListView: View {
    @State var vm = MovieListViewModel()
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
        .navigationTitle("Movies")
        .searchable(text: $vm.searchText, prompt: "Search Movies")
        .task(id: vm.searchText) {
            await vm.search()
        }
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
    MovieListView()
}
