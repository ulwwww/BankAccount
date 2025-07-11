//
//  DatePickerCell.swift
//  yandex_project
//
//  Created by ulwww on 12.07.25.
//
import UIKit

final class DatePickerCell: UITableViewCell {
    static let reuseId = "DatePickerCell"
    let titleLabel = UILabel()
    let picker = UIDatePicker()
    var onChange: ((Date) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        titleLabel.font = .systemFont(ofSize: 16)
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.locale = Locale(identifier: "ru_RU")
        picker.maximumDate = Date()
        picker.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
        picker.tintColor = UIColor(Utility.Colors.accent)
        picker.layer.cornerRadius = 30

        let data = UIStackView(arrangedSubviews: [titleLabel, UIView(), picker])
        data.axis = .horizontal
        data.alignment = .center
        data.spacing = 8
        contentView.addSubview(data)
        data.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            data.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            data.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            data.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            data.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
        ])
    }

    @objc private func valueChanged() {
        onChange?(picker.date)
    }

    required init?(coder: NSCoder) { fatalError() }
}

