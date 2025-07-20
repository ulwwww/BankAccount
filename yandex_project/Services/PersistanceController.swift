//
//  PersistanceController.swift
//  yandex_project
//
//  Created by ulwww on 19.07.25.
//
//
import SwiftData

@MainActor
final class PersistenceController {
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    static let shared = PersistenceController()
    private init() {
        self.modelContainer = try! ModelContainer(for: Schema([TransactionEntity.self, BackupOperationEntity.self, BankAccountEntity.self, BackupAccountOperationEntity.self, CategoryEntity.self]))
        self.modelContext = ModelContext(modelContainer)
    }
}



