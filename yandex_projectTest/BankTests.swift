//
//  BankTests.swift
//  yandex_project
//
//  Created by ulwww on 13.06.25.
//

import Testing
import XCTest
import Foundation
@testable import yandex_project

struct BankTests {
    private static let date = "2025-06-12T12:30:01.641Z"
    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private let sampleTransactionJSON: [String: Any] = ["id": 1, "accountId": 100, "categoryId": 9, "amount": 126.5, "transactionDate": BankTests.date, "createdAt": BankTests.date, "updatedAt": BankTests.date, "comment": "Test transaction"]

    private let exp = Transaction(id: 1, accountId: 100, categoryId: 9, amount: Decimal(string: "126.5")!,
                                  comment: "Test transaction", transactionDate: isoFormatter.date(from: date)!, createdAt: isoFormatter.date(from: date)!, updatedAt: isoFormatter.date(from: date)!
    )

    @Test func testParseValidTransaction() throws {
        let parsed = try #require(Transaction.parse(jsonObject: sampleTransactionJSON))
        #expect(parsed.id == exp.id)
        #expect(parsed.accountId == exp.accountId)
        #expect(parsed.categoryId == exp.categoryId)
        #expect(parsed.amount == exp.amount)
        #expect(parsed.comment == exp.comment)
    }

    @Test func testParseMissingRequiredField() {
        var badJSON = sampleTransactionJSON
        badJSON.removeValue(forKey: "id")
        let parsed = Transaction.parse(jsonObject: badJSON)
        #expect(parsed == nil)
    }

    @Test func testParseInvalidFormat() {
        var badJSON = sampleTransactionJSON
        badJSON["amount"] = "not a number"
        let parsed = Transaction.parse(jsonObject: badJSON)
        #expect(parsed == nil)
    }

    @Test func testInvalidDateFormat() {
        var badJSON = sampleTransactionJSON
        badJSON["transactionDate"] = "not a date"
        let parsed = Transaction.parse(jsonObject: badJSON)
        #expect(parsed == nil)
    }

    @Test func testWithoutComment() throws {
        var noCommentJSON = sampleTransactionJSON
        noCommentJSON.removeValue(forKey: "comment")
        let parsed = try #require(Transaction.parse(jsonObject: noCommentJSON))
        #expect(parsed.comment == "")
    }

    @Test func testJSON() throws {
        let serialized = exp.jsonObject as? [String: Any] ?? [:]
        #expect(serialized["id"] as? Int == exp.id)
        #expect(serialized["accountId"] as? Int == exp.accountId)
        #expect(serialized["categoryId"] as? Int == exp.categoryId)
        #expect((serialized["amount"] as? NSDecimalNumber)?.stringValue == exp.amount.description)
        #expect(serialized["comment"] as? String == exp.comment)
        #expect(serialized["transactionDate"] as? String != nil)
        #expect(serialized["createdAt"] as? String != nil)
        #expect(serialized["updatedAt"] as? String != nil)
    }

    @Test func testJSONWithoutComment() {
        let tx = Transaction(id: 1, accountId: 100, categoryId: 9, amount: Decimal(string: " 126.5")!, comment: "",
                             transactionDate: Date(), createdAt: Date(), updatedAt: Date())
        let serialized = tx.jsonObject as? [String: Any] ?? [:]
        #expect(serialized["comment"] as? String == "")
    }

    @Test func testRoundTripConversion() throws {
        let firstPass = try #require(Transaction.parse(jsonObject: sampleTransactionJSON))
        let secondJSON = firstPass.jsonObject
        let secondPass = try #require(Transaction.parse(jsonObject: secondJSON))
        #expect(firstPass == secondPass)
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let s1 = df.string(from: firstPass.transactionDate)
        let s2 = df.string(from: secondPass.transactionDate)
        #expect(s1 == s2)
    }

    @Test func testWithExtraField() throws {
        var extendedJSON = sampleTransactionJSON
        extendedJSON["extraField"] = "should be ignored"
        let parsed = try #require(Transaction.parse(jsonObject: extendedJSON))
        #expect(parsed.id == exp.id)
        #expect(parsed.accountId == exp.accountId)
        #expect(parsed.categoryId == exp.categoryId)
        #expect(parsed.amount == exp.amount)
        #expect(parsed.comment == exp.comment)
    }

    @Test func testZeroTransaction() throws {
        var zeroJSON = sampleTransactionJSON
        zeroJSON["amount"] = 0
        let parsed = try #require(Transaction.parse(jsonObject: zeroJSON))
        #expect(parsed.amount == Decimal(0))
    }
}

