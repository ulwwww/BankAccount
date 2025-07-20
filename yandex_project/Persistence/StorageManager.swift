//
//  StorageManager.swift
//  yandex_project
//
//  Created by ulwww on 18.07.25.
//
//
//import SwiftData
//import Foundation
//
//enum StorageType: String {
//    case swiftData, coreData
//}
//
//@MainActor
//class StorageManager {
//    static let shared = StorageManager()
//    private(set) var type: StorageType
//    let transactionsStorage: TransactionsStorage
//    let transactionsBackup: TransactionsBackUpStorage
//    let accountsStorage: BankAccountsStorage
//    let accountsBackup: BankAccountsBackUpStorage
//    let categoriesStorage: CategoriesStorage
//    
//    private init() {
//        let model = Schema([TransactionEntity.self, BackupOperationEntity.self,
//                            BankAccountEntity.self, BackupAccountOperationEntity.self,
//                            CategoryEntity.self])
//        let container = try! ModelContainer(for: model)
//        self.type = StorageType(rawValue: UserDefaults.standard.string(forKey: "storageType") ?? "swiftData") ?? .swiftData
//        self.transactionsStorage = SwiftDataTransactionsStorage(container: container)
//        self.transactionsBackup = SwiftDataTransactionsBackUpStorage(container: container)
//        self.accountsStorage = SwiftDataBankAccountsStorage(container: container)
//        self.accountsBackup = SwiftDataBankAccountsBackUpStorage(container: container)
//        self.categoriesStorage = SwiftDataCategoriesStorage(container: container)
//        migrateIfNeeded()
//    }
//    private func migrateIfNeeded() {
//        let selected = StorageType(rawValue: UserDefaults.standard.string(forKey: "storageType") ?? "swiftData") ?? .swiftData
//        guard selected != type else { return }
//        type = selected
//    }
//}

