//
//  Transaction.swift
//  yandex_project
//
//  Created by ulwww on 09.06.25.
//

import Foundation

struct Transaction: Codable, Identifiable, Hashable {
    var id: Int
    let accountId: Int
    let categoryId: Int
    let amount: Decimal
    let comment: String
    let transactionDate: Date
    let createdAt: Date
    let updatedAt: Date
    
    enum KeyForTransaction: String, CodingKey {
        case id
        case accountId
        case categoryId
        case amount
        case comment
        case transactionDate
        case createdAt
        case updatedAt
    }
    
    init(id: Int, accountId: Int, categoryId: Int, amount: Decimal, comment: String, transactionDate: Date, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.accountId = accountId
        self.categoryId = categoryId
        self.amount = amount
        self.comment = comment
        self.transactionDate = transactionDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let keyedContainer = try decoder.container(keyedBy: KeyForTransaction.self)
        id = try keyedContainer.decode(Int.self, forKey: .id)
        accountId = try keyedContainer.decode(Int.self, forKey: .accountId)
        categoryId = try keyedContainer.decode(Int.self, forKey: .categoryId)
        amount = try keyedContainer.decode(Decimal.self, forKey: .amount)
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let transactionDateString = try keyedContainer.decode(String.self, forKey: .transactionDate)
        guard let transactionDateVal = dateFormatter.date(from: transactionDateString) else {
            throw DecodingError.dataCorruptedError(forKey: .transactionDate, in: keyedContainer, debugDescription: "error date format")
        }
        transactionDate = transactionDateVal
        let createdAtStr = try keyedContainer.decode(String.self, forKey: .createdAt)
        guard let createdAtVal = dateFormatter.date(from: createdAtStr) else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: keyedContainer, debugDescription: "error date format")
        }
        createdAt = createdAtVal
        let updatedAtStr = try keyedContainer.decode(String.self, forKey: .updatedAt)
        guard let updatedAtVal = dateFormatter.date(from: updatedAtStr) else {
            throw DecodingError.dataCorruptedError(forKey: .updatedAt, in: keyedContainer, debugDescription: "error date format")
        }
        updatedAt = updatedAtVal
        comment = try keyedContainer.decodeIfPresent(String.self, forKey: .comment) ?? ""
    }
}

extension Transaction {
    private static let timeFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    static func parse(jsonObject: Any) -> Transaction? {
        guard JSONSerialization.isValidJSONObject(jsonObject), let info = try? JSONSerialization.data(withJSONObject: jsonObject, options: []) else {
             return nil
        }
        let decoder = JSONDecoder()
        return try? decoder.decode(Transaction.self, from: info)
    }
    
    var jsonObject: Any {
        var jsonDictionary: [String: Any] = [
            "id" : id,
            "accountId": accountId,
            "categoryId": categoryId,
            "amount": NSDecimalNumber(decimal: amount),
            "transactionDate": Self.timeFormatter.string(from: transactionDate),
            "createdAt": Self.timeFormatter.string(from: createdAt),
            "updatedAt": Self.timeFormatter.string(from: updatedAt),
        ]

        jsonDictionary["comment"] = comment
        return jsonDictionary
    }
}

extension Transaction {
    private static func spliterator(_ s: String, separator: Character = ",") -> [String] {
        var flag = false
        var ans: [String] = []
        var cur = ""
        for ch in s {
            if ch == "\"" {
                flag.toggle()
            } else if ch == separator && !flag {
                ans.append(cur)
                cur = ""
            } else {
                cur.append(ch)
            }
        }
        ans.append(cur)
        return ans
    }
    
    static func parseCSV(_ csv: String) throws -> [Transaction] {
        let arrData = ["id", "accountId", "categoryId", "amount", "comment", "transactionDate", "createdAt", "updatedAt"]
        let lines = csv.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        guard !lines.isEmpty else {
            throw ErrorModels.errorCSVFormat
        }
        let head = spliterator(lines[0])
        guard head == arrData else {
            throw ErrorModels.errorCSVFormat
        }
        let dict = Dictionary(uniqueKeysWithValues: head.enumerated().map {($1, $0)})
        let fmt = Transaction.timeFormatter
        func raw(_ name: String, from rowVal: [String], row: Int) throws -> String {
            guard let idx = dict[name], idx < rowVal.count else {
                throw ErrorModels.missingRequiredFieldCSV(name: name, count: row)
            }
            let v = rowVal[idx].trimmingCharacters(in: .whitespaces)
            return v
        }
        func parse<T>(_ s: String, name: String, row: Int, transform: (String) -> T?) throws -> T {
            if let x = transform(s) {
                return x
            }
            throw ErrorModels.missingRequiredFieldCSV(name: name, count: row)
        }
        var ans: [Transaction] = []
        for (i, l) in lines.dropFirst().enumerated() {
            let r = i + 2
            let c = spliterator(l)
            guard c.count == head.count else {
                throw ErrorModels.rowFieldCountMismatch(row: r, expected: head.count, actual: c.count)
            }
            let strID = try raw("id", from: c, row: r)
            let strAcc = try raw("accountId", from: c, row: r)
            let strCateg = try raw("categoryId", from: c, row: r)
            let strAmt = try raw("amount", from: c, row: r)
            let strCmnt = try raw("comment", from: c, row: r)
            let strTxn = try raw("transactionDate", from: c, row: r)
            let strCrt = try raw("createdAt", from: c, row: r)
            let strUpd = try raw("updatedAt", from: c, row: r)
            let id = try parse(strID, name: "id", row: r) { Int($0) }
            let acc = try parse(strAcc, name: "accountId", row: r) { Int($0) }
            let categ = try parse(strCateg, name: "categoryId", row: r) { Int($0) }
            let amt = try parse(strAmt, name: "amount", row: r) {Decimal(string: $0, locale: .current)}
            let txn = try parse(strTxn, name: "transactionDate", row: r) { fmt.date(from: $0) }
            let crt = try parse(strCrt, name: "createdAt", row: r) { fmt.date(from: $0) }
            let upd = try parse(strUpd, name: "updatedAt", row: r) { fmt.date(from: $0) }
            let cmnt = strCmnt.isEmpty ? nil : strCmnt
            ans.append(Transaction(id: id, accountId: acc, categoryId: categ, amount: amt, comment: cmnt ?? "",
                                      transactionDate: txn, createdAt: crt, updatedAt: upd))
        }
        return ans
    }
}
