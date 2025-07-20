//
//  CategoriesService.swift
//  yandex_project
//
//  Created by ulwww on 10.06.25.
//

import Foundation

final class CategoriesService {
    private let networkClient: NetworkClient

    public init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    public func categories() async throws -> [Category] {
        let dtos: [CategoryDTO] = try await networkClient.request(method: .get, path: "categories")
        return dtos.map { $0.toDomain() }
    }

    public func categories(direction: Direction) async throws -> [Category] {
        let dtos: [CategoryDTO] = try await networkClient.request(
            method: .get,
            path: "categories/type/\(direction.rawValue)"
        )
        return dtos.map { $0.toDomain() }
    }
}
