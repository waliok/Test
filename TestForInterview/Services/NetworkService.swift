//
//  NetworkService.swift
//  TestForInterview
//
//  Created by Valentyn Nesterenko on 21/10/2025.
//

import Foundation

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
    
    private let baseURL = "https://api.themoviedb.org/3"
    private let apiKey = Helper.apiKey
    
    private func buildURL(path: String, params: [String:String] = [:]) -> URL? {
        guard var comps = URLComponents(string: baseURL + path) else { return nil }
        var queryItems = [URLQueryItem(name: "language", value: "en-US")]
        params.forEach { queryItems.append(URLQueryItem(name: $0.key, value: $0.value)) }
        comps.queryItems = queryItems
        return comps.url
    }
    
    func request<T: Decodable>(path: String, params: [String:String] = [:], completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = buildURL(path: path, params: params) else {
            completion(.failure(NSError(domain: "Network", code: -1, userInfo: [NSLocalizedDescriptionKey:"Invalid URL or missing API key"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(Helper.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: request) { data, resp, error in
            if let err = error {
                completion(.failure(err))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain:"Network", code:-2, userInfo:nil)))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let decoded = try decoder.decode(T.self, from: data)
                completion(.success(decoded))
            } catch {
                if let json = String(data: data, encoding: .utf8) {
                    print("JSON: \(json)")
                }
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
