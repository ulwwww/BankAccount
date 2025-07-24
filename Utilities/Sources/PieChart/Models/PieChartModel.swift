//
//  PieChartModel.swift
//  Utilities
//
//  Created by ulwww on 24.07.25.
//
import Foundation

public struct PieChartEntity {
    let value: Decimal
    let label: String
    
    public init(value: Decimal, label: String) {
        self.value = value
        self.label = label
    }
}
