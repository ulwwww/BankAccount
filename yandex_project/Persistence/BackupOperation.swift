//
//  BackupOperation.swift
//  yandex_project
//
//  Created by ulwww on 18.07.25.
//

import Foundation

struct BackupOperation: Codable {
    let id: Int
    let type: OperationType
    let payload: Data
}
