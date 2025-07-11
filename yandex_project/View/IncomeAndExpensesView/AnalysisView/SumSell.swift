//
//  SumSell.swift
//  yandex_project
//
//  Created by ulwww on 12.07.25.
//
import UIKit

final class SumCell: UITableViewCell {
    static let reuseId = "SumCell"
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        titleLabel.font = .systemFont(ofSize: 16)
        valueLabel.font = .systemFont(ofSize: 16)
        valueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        let data = UIStackView(arrangedSubviews: [titleLabel, UIView(), valueLabel])
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

    func configure(text: String, value: String) {
        titleLabel.text = text
        valueLabel.text = value
    }

    required init?(coder: NSCoder) { fatalError() }
}
