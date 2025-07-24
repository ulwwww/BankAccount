//
//  NetworkClient.swift
//  yandex_project
//
//  Created by ulwww on 15.07.25.
//

import Foundation

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public final class NetworkClient {
    private let session: URLSession
    public  let baseURL: URL
    private let token: String?

    public init(
        session: URLSession = .shared,
        baseURL: URL,
        token: String? = nil
    ) {
        self.session = session
        self.baseURL = baseURL
        self.token = token
    }

    public func request<Req: Encodable, Res: Decodable>(
        method: HTTPMethod,
        path: String,
        queryItems: [URLQueryItem]? = nil,
        body: Req? = nil,
        headers: [String:String] = [:]
    ) async throws -> Res {
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        var url = baseURL.appendingPathComponent(trimmed)

        if let queryItems = queryItems, !queryItems.isEmpty {
            guard var comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw HTTPError.invalidResponse
            }
            comps.queryItems = queryItems
            guard let u = comps.url else {
                throw HTTPError.invalidResponse
            }
            url = u
        }
        
        var req = URLRequest(url: url)
        req.httpMethod = method.rawValue
        if let token = token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        headers.forEach { field, value in
            req.setValue(value, forHTTPHeaderField: field)
        }

        if let body = body {
            do {
                req.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw HTTPError.encodingError(error)
            }
        }
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw HTTPError.httpError(statusCode: http.statusCode, data: data)
        }
        do {
            return try JSONDecoder().decode(Res.self, from: data)
        } catch {
            throw HTTPError.decodingError(error)
        }
    }

    public func request<Res: Decodable>(method: HTTPMethod, path: String, queryItems: [URLQueryItem]? = nil, headers: [String:String] = [:]) async throws -> Res {
        return try await request(
            method: method,
            path: path,
            queryItems: queryItems,
            body: Optional<EmptyBody>.none,
            headers: headers
        )
    }

    private struct EmptyBody: Encodable {}
}
