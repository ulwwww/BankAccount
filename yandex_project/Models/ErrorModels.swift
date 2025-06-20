//
//  ErrorModels.swift
//  yandex_project
//
//  Created by ulwww on 12.06.25.
//
import Foundation

enum ErrorModels: LocalizedError {
    case emptyDataTransaction
    case errorDateFormat
    case errorIdFormat(id: Int)
    case errorTransaction
    case errorCSVFormat
    case missingRequiredFieldCSV(name: String, count: Int)
    case rowFieldCountMismatch(row: Int, expected: Int, actual: Int)
    var errorDescription: String? {
        switch self {
        case .emptyDataTransaction:
            return "Empty data transaction"
        case .errorDateFormat:
            return "Invalid date format"
        case .errorIdFormat(let id):
            return "Invalid id format \(id)"
        case .errorTransaction:
            return "Error transaction"
        case .errorCSVFormat:
            return "Uncorrect format CSV"
        case .missingRequiredFieldCSV(let name, let count):
            return "Empty required field \(name) in row \(count)"
        case .rowFieldCountMismatch(let row, let expected, let actual):
            return "Row \(row) field count mismatch: expected \(expected), actual \(actual)"
        }
    }
}
