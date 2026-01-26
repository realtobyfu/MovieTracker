//
//  MovieListViewModel.swift
//  MovieTracker
//
//  Created by Tobias Fu on 1/14/26.
//

import Foundation
import SwiftUI
import SafeDICore

@MainActor @Observable
final class MovieListViewModel {
    
    @Received private let service: MovieServiceProtocol
//    var mode: Mode = .discover
    var searchText: String = ""
    var isLoading: Bool = false
    var showError: Bool = false
    var movies = [Movie]()
    var errorMessage: String?
    var currentPage: Int = 1
    var totalPages: Int?
    private(set) var loadedIDs = Set<Int>()

    // Computed endpoint based on searchText
    private var endpoint: Endpoint {
        searchText.isEmpty ? .discover : .search(query: searchText)
    }

    public init(service: MovieServiceProtocol) {
        self.service = service
    }
    
    func loadPage() async {
        currentPage += 1
        await fetchAndAppend()
    }

    func resetAndLoad() async {
        currentPage = 1
        loadedIDs.removeAll()
        movies.removeAll()
        await fetchAndAppend()
    }

    private func fetchAndAppend() async {
        do {
            let response = try await service.fetchMovies(endpoint: endpoint, page: currentPage)
            let newMovies = response.results.filter { loadedIDs.insert($0.id).inserted }
            movies.append(contentsOf: newMovies)
            totalPages = response.totalPages
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func search() async {
        isLoading = true
        await resetAndLoad()
        isLoading = false
    }
}
