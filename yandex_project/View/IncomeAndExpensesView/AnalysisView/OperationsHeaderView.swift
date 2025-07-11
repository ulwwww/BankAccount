//
//  OperationsHeaderView.swift
//  yandex_project
//
//  Created by ulwww on 12.07.25.
//
import UIKit

final class OperationsHeaderView: UIView {
    private let titleLabel = UILabel()
    private let sortButton = UIButton(type: .system)
    var onSortTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        titleLabel.text = "ОПЕРАЦИИ"
        titleLabel.font = .preferredFont(forTextStyle: .caption1)
        titleLabel.textColor = .secondaryLabel

        let sortButton = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.title = "Сортировка"
        config.baseForegroundColor = UIColor(Utility.Colors.accent)
        config.baseBackgroundColor = UIColor(Utility.Colors.accent.opacity(0.1))
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 8, bottom: 8, trailing: 8)
        sortButton.configuration = config
        sortButton.addTarget(self, action: #selector(didTap), for: .touchUpInside)

        let data = UIStackView(arrangedSubviews: [titleLabel, UIView(), sortButton])
        data.axis = .horizontal
        data.alignment = .center
        data.spacing = 8

        addSubview(data)
        data.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            data.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            data.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            data.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            data.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
        ])
    }

    @objc private func didTap() {
        onSortTapped?()
    }

    required init?(coder: NSCoder) { fatalError() }
}
