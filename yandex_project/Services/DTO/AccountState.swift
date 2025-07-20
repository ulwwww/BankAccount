//
//  CategoryDTO.swift
//  yandex_project
//
//  Created by ulwww on 19.07.25.
//
import Foundation

struct AccountStateDTO: Codable {
    public let id: Int
    public let name: String?
    public let balance: Decimal?
    public let currency: String?
}
