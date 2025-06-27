//  Utility.swift
//  yandex_project
//
//  Created by ulwww on 18.06.25.

import SwiftUI

enum Utility {
    static let amount: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        nf.minimumFractionDigits = 0
        nf.locale = Locale(identifier: "ru_RU")
        return nf
    }()

    static let currency: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.locale = Locale(identifier: "ru_RU")
        nf.currencySymbol = "₽"
        nf.currencyCode = "RUB"
        nf.maximumFractionDigits = 2
        nf.minimumFractionDigits = 0
        return nf
    }()

    enum DateStyles {
        static let time: Date.FormatStyle =
            .dateTime
            .hour(.twoDigits(amPM: .omitted))
            .minute(.twoDigits)
        static let monthYear: Date.FormatStyle =
            .dateTime
            .month(.wide)
            .year(.defaultDigits)
    }

    enum Strings {
        static let total = "Всего"
        static let operations = "ОПЕРАЦИИ"
        static let history = "Моя история"
        static let todayIncome = "Доходы сегодня"
        static let todayOutcome = "Расходы сегодня"
        static let start = "Начало"
        static let end = "Конец"
        static let sum = "Сумма"
        static let sort = "Сортировка"
        static let sortByDate = "По дате"
        static let sortByAmount = "По сумме"
        static let back = "Назад"
    }

    enum Colors {
        static let accent = Color(red: 108/255, green: 94/255, blue: 177/255)
        static let background = Color(.systemGray6)
        static let iconBackground = Color.green.opacity(0.2)
    }
    enum Icons {
        static let history = "clock"
        static let plus = "plus"
        static let chevron = "chevron.right"
        static let sort = "arrow.up.arrow.down"
        static let checkmark = "checkmark"
        static let back = "chevron.left"
        static let export = "doc.text"
    }
}

