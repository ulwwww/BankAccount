//
//  TransactionsFileCache.swift
//  yandex_project
//
//  Created by ulwww on 10.06.25.
//
import Foundation

class TransactionsFileCache {
    private let url : URL
    private(set) var transactions: [Transaction] = []
    init(fileName: String) throws {
    guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
        throw NSError(domain: "", code: 0, userInfo: nil)
    }
    self.url = docs.appendingPathComponent(fileName)
    }
    
    func save() throws {
        let arr = transactions.map {$0.jsonObject}
        guard JSONSerialization.isValidJSONObject(arr) else {
            throw NSError(domain: "TransactionsFileCache", code: 0, userInfo: nil)
        }
        let data = try JSONSerialization.data(withJSONObject: arr, options: [])
        try data.write(to: url, options: .atomic)
    }
    
    func remove(id: Int) {
            transactions.removeAll(where: { $0.id == id })
    }
    
    @discardableResult
    func add(_ transaction: Transaction) -> Bool {
        if transactions.contains(where: { $0.id == transaction.id }) {
            return false
        }
        transactions.append(transaction)
        return true
    }
    func load() throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            transactions = []
            return
        }
        let data = try Data(contentsOf: url)
        let valRaw = try JSONSerialization.jsonObject(with: data, options: [])
        guard let arr = valRaw as? [Any] else {
             throw NSError(domain: "TransactionsFileCache", code: 0, userInfo: nil)
        }
        let set = Set(arr.compactMap {Transaction.parse(jsonObject: $0)})
        transactions = Array(set)
    }
}
