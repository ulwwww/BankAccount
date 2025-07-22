//
//StorageManager.swift
//yandex_project
//
//Created by ulwww on 18.07.25.
//

import SwiftData
import Foundation

enum StorageType: String {
    case swiftData, coreData
}

final class StorageManager {
    static let shared = StorageManager()
    let transactions: TransactionsStorageProtocol
    let categories: CategoriesStorageProtocol
    let account: BankAccountStorageProtocol
    let backup: BackupStorageProtocol

    private let container: ModelContainer

    private init() {
        let schema = Schema([
            CategoryEntity.self,
            BankAccountEntity.self,
            TransactionEntity.self,
            BackupOperationEntity.self
        ])

        let modelConfiguration = ModelConfiguration(schema: schema)
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }

        transactions = SwiftDataTransactionsStorage(container: container)
        categories = SwiftDataCategoriesStorage(container: container)
        account = SwiftDataAccountStorage(container: container)
        backup = SwiftDataBackupStorage(container: container)
    }

}
