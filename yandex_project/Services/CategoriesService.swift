//
//  CategoriesService.swift
//  yandex_project
//
//  Created by ulwww on 10.06.25.
//

import Foundation

final class CategoriesService {
    private let networkClient: NetworkClient
    private var storage = StorageManager.shared.categories

    public init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    public func categories() async throws -> [Category] {
        do {
            let dtos: [CategoryDTO] = try await networkClient.request(method: .get, path: "categories")
            let domains = dtos.map { $0.toDomain() }
            try await storage.saveCategories(domains)
            return domains
        } catch {
            do {
                return try await storage.getAllCategories()
            } catch {
                throw ErrorService.notFoundCategories
            }
        }
    }

    public func categories(direction: Direction) async throws -> [Category] {
        do {
            let dtos: [CategoryDTO] = try await networkClient.request(
                method: .get,
                path: "categories/type/\(direction.rawValue)"
            )
            let domains = dtos.map { $0.toDomain() }
            let allDtos: [CategoryDTO] = try await networkClient.request(method: .get, path: "categories")
            let allDomains = allDtos.map { $0.toDomain() }
            try await storage.saveCategories(allDomains)
            return domains
        } catch {
            do {
                return try await storage.getCategories(by: direction)
            } catch {
                throw ErrorService.notFoundCategories
            }
        }
    }
}


