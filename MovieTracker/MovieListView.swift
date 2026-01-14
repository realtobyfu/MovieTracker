//
//  ContentView.swift
//  MovieTracker
//
//  Created by Tobias Fu on 1/10/26.
//

import SwiftUI

struct MovieListView: View {
    
    @State private var isLoading: Bool = false
    @State private var movies = [Movie]()
    @State private var searchText: String = ""
    @State private var errorMessage: String?
    @State private var currentPage: Int = 1
    @State private var totalPages: Int?
    
    var body: some View {
        NavigationStack {
            if isLoading {
                ProgressView()
            } else {
                List {
                    ForEach(movies) { movie in
                        NavigationLink(movie.title, value: movie)
                    }
                    
                    if currentPage < (totalPages ?? 0) {
                        ProgressView()
                        .task {
                            currentPage += 1
                            if searchText == "" {
                                try? await fetchMovies()
                            } else {
                                try? await searchMovies(text: searchText)
                            }
                        }
                    }
                }
                .navigationDestination(for: Movie.self) { movie in
                    MovieDetailView(movie: movie)
                }
            }
        }
        .navigationTitle("Movies")
        .searchable(text: $searchText, prompt: "Search Movies")
        .task(id: searchText) {
            isLoading = true
            defer { isLoading = false }
            do {
                try await searchMovies(text: searchText)
            } catch {
                errorMessage = error.localizedDescription
                movies = []
            }
        }
        .task () {
            do {
                try await fetchMovies()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func searchMovies(text: String) async throws {
        
        if (totalPages != nil) {
            guard currentPage <= totalPages! else { return }
        }

        var comps = URLComponents(string: "https://api.themoviedb.org/3/search/movie")!
        
        comps.queryItems = [
            URLQueryItem(name: "query", value: text),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "language", value: "en-US"),
            URLQueryItem(name: "page", value: String(currentPage))
        ]
        

        var request = URLRequest(url: comps.url!)
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        request.allHTTPHeaderFields = [
          "accept": "application/json",
          "Authorization": "Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiJjMWU0YjMyYWIzN2U1MDg2ZmU1YzA5NTIxYzBlNjdhNyIsInN1YiI6IjU2NTYzOTFlOTI1MTQxMDllODAwMDMyZSIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.CnjFlQK6eKafVglC_aN3jx98dn9TD_SulgMz86RGohw"
        ]

        let (data, _) = try await URLSession.shared.data(for: request)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        decoder.dateDecodingStrategy = .formatted(formatter)

        let response = try decoder.decode(Response.self, from: data)
        if currentPage == 1 {
            movies = response.results
        } else {
            movies.append(contentsOf: response.results)
        }
        totalPages = response.totalPages
        print("Searched \(text), repsonse: \(movies)")
    }
    
    
    
    func fetchMovies() async throws {
        
        if (totalPages != nil) {
            guard currentPage <= totalPages! else { return }
        }
        var comps = URLComponents(string: "https://api.themoviedb.org/3/discover/movie")
        
        comps?.queryItems = [
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "language", value: "en-US"),
            URLQueryItem(name: "page", value: "\(currentPage)")
        ]
        
        // create the URL
        guard let url = comps?.url else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(Constants.apiKey)", forHTTPHeaderField: "Authorization")
        
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        decoder.dateDecodingStrategy = .formatted(formatter)
        let response = try? decoder.decode(Response.self, from: data)
        
        movies.append(contentsOf: response?.results ?? [])
        totalPages = response?.totalPages
    }
}




#Preview {
    MovieListView()
}
