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
    public let baseURL: URL
    private let token: String?

    public init(session: URLSession = .shared, baseURL: URL, token: String? = nil) {
        self.session = session
        self.baseURL = baseURL
        self.token = token
    }

    public func request<Req: Encodable, Res: Decodable>(method: HTTPMethod, path: String, body: Req? = nil, headers: [String: String] = [:]) async throws -> Res {
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let url = baseURL.appendingPathComponent(trimmed)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        headers.forEach { field, value in
            request.setValue(value, forHTTPHeaderField: field)
        }

        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw HTTPError.encodingError(error)
            }
        }

        let (data, response) = try await session.data(for: request)

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

    public func request<Res: Decodable>(
        method: HTTPMethod,
        path: String,
        headers: [String: String] = [:]
    ) async throws -> Res {
        return try await request(method: method, path: path, body: Optional<EmptyBody>.none, headers: headers)
    }

    private struct EmptyBody: Encodable {}
}

extension NetworkClient {
    public func request<Res: Decodable>(
        url: URL,
        method: HTTPMethod = .get,
        responseType: Res.Type
    ) async throws -> Res {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else
        {
            throw HTTPError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1, data: data)
        }
        return try JSONDecoder().decode(Res.self, from: data)
    }
}
