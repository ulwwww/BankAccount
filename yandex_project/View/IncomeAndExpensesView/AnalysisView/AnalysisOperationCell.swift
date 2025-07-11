//
//  AnalysisOperationCell.swift
//  yandex_project
//
//  Created by ulwww on 12.07.25.
//
import UIKit

final class AnalysisOperationCell: UITableViewCell {
    static let reuseId = "AnalysisOperationCell"
    private let iconView = UIView()
    private let emojiLabel = UILabel()
    private let titleLabel = UILabel()
    private let amountLabel = UILabel()
    private let percentLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        iconView.backgroundColor = UIColor(Utility.Colors.iconBackground)
        iconView.layer.cornerRadius = 15
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 30),
            iconView.heightAnchor.constraint(equalToConstant: 30)
        ])

        emojiLabel.font = .systemFont(ofSize: 20)
        iconView.addSubview(emojiLabel)
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: iconView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
        ])

        titleLabel.font = .systemFont(ofSize: 16)
        amountLabel.font = .systemFont(ofSize: 16)
        amountLabel.textAlignment = .right

        percentLabel.font = .systemFont(ofSize: 12)
        percentLabel.textColor = UIColor(Utility.Colors.accent)
        percentLabel.textAlignment = .right
        let leftStack = UIStackView(arrangedSubviews: [titleLabel])
        leftStack.axis = .vertical

        let rightStack = UIStackView(arrangedSubviews: [percentLabel, amountLabel])
        rightStack.axis = .vertical
        rightStack.alignment = .trailing
        rightStack.spacing = 2

        let data = UIStackView(arrangedSubviews: [iconView, leftStack, UIView(), rightStack])
        data.axis = .horizontal
        data.alignment = .center
        data.spacing = 12

        contentView.addSubview(data)
        data.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            data.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            data.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            data.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            data.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
        ])
    }

    func configure(emoji: String, title: String, amount: Decimal, percentage: String) {
        emojiLabel.text = emoji
        titleLabel.text = title
        percentLabel.text = percentage
        amountLabel.text = NumberFormatter
            .localizedString(from: NSDecimalNumber(decimal: amount), number: .currency)
    }

    required init?(coder: NSCoder) { fatalError() }
}

