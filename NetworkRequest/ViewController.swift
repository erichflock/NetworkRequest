//
//  ViewController.swift
//  NetworkRequest
//
//  Created by Erich Flock on 17.01.21.
//

import UIKit

protocol URLSessionProtocol {
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}

extension URLSession: URLSessionProtocol {}

class ViewController: UIViewController {

    let searchButton = UIButton()
    private var dataTask: URLSessionDataTask?
    
    var session: URLSessionProtocol = URLSession.shared
    
    var handleResults: ([SearchResult]) -> Void = { _ in }
    
    private(set) var results: [SearchResult] = [] {
        didSet {
            handleResults(results)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .white
        setupSearchButton()
    }
    
    private func setupSearchButton() {
        searchButton.setTitle("Search", for: .normal)
        searchButton.setTitleColor(.systemBlue, for: .normal)
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        view.addSubview(searchButton)
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            searchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc private func searchButtonTapped() {
        searchForBook(terms: "out from boneville")
    }
    
    private func searchForBook(terms: String) {
        guard let encodedTerms = terms.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: "https://itunes.apple.com/search?media=ebook&term=\(encodedTerms)") else { return }
        let request = URLRequest(url: url)
        dataTask = session.dataTask(with: request) { [weak self] (data: Data?, response: URLResponse?, error: Error?) in
            guard let self = self else { return }
            
            var decoded: Search?
            var errorMessage: String?
            
            if let error = error {
                errorMessage = error.localizedDescription
            } else if let response = response as? HTTPURLResponse, response.statusCode != 200 {
                errorMessage = "Response: " + HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
            } else if let data = data {
                do {
                    decoded = try JSONDecoder().decode(Search.self, from: data)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if let decoded = decoded {
                    self.results = decoded.results
                }
                if let errorMessage = errorMessage {
                    self.showError(errorMessage)
                }
                self.dataTask = nil
                self.searchButton.isEnabled = true
            }
        }
        searchButton.isEnabled = false
        dataTask?.resume()
    }
    
    private func showError(_ message: String) {
        let title = "Network Problem"
        print("\(title): \(message)")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)
        alert.preferredAction = okAction
        present(alert, animated: true)
    }
}

struct Search: Decodable {
    let results: [SearchResult]
}

struct SearchResult: Decodable, Equatable {
    let artistName: String
    let trackName: String
    let averageUserRating: Float
    let genres: [String]
}
