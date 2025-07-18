//
//  AnalysisViewController.swift
//  yandex_project
//
//  Created by ulwww on 7.07.25.
//

import UIKit
import Combine

private enum Section: Int, CaseIterable {
    case parameters, operations
}

class AnalysisViewController: UIViewController {
    private let viewModel: MyStoryViewModel
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let navBar = UINavigationBar()
    private var cancellables = Set<AnyCancellable>()
    var onBack: (() -> Void)? = nil
    
    init(direction: Direction) {
        self.viewModel = MyStoryViewModel(direction: direction, accountId: 1)
        super.init(nibName: nil, bundle: nil)
    }

    override func loadView() {
        super.loadView()
        view.backgroundColor = .systemGray6
        setupNavBar()
        setupTableView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.hidesBottomBarWhenPushed = false
        bindViewModel()
        Task { await viewModel.loadData() }
    }

    private func setupNavBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemGray6
        appearance.shadowColor = .clear

        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.backgroundColor = .systemGray6 
        navBar.isTranslucent = false
        navBar.prefersLargeTitles = true

        let navItem = UINavigationItem(title: "Анализ")
        navItem.largeTitleDisplayMode = .always
        navBar.items = [navItem]

        view.addSubview(navBar)
        navBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(DatePickerCell.self, forCellReuseIdentifier: DatePickerCell.reuseId)
        tableView.register(SumCell.self, forCellReuseIdentifier: SumCell.reuseId)
        tableView.register(AnalysisOperationCell.self, forCellReuseIdentifier: AnalysisOperationCell.reuseId)
        tableView.sectionHeaderTopPadding = 0
        tableView.backgroundColor = .systemGray6
    }

    private func bindViewModel() {
        Publishers.CombineLatest3(viewModel.$startDate, viewModel.$endDate, viewModel.$transactions)
            .merge(with: viewModel.$sortOption.map { [self] _ in (viewModel.startDate, self.viewModel.endDate, self.viewModel.transactions) })
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _, _ in
                self?.reloadAll()
            }
            .store(in: &cancellables)
    }

    private func reloadAll() {
        tableView.reloadSections(IndexSet([Section.parameters.rawValue, Section.operations.rawValue]), with: .automatic)
    }


    @objc private func backTapped() {
        onBack?()
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:)")
    }
}

extension AnalysisViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .parameters: return 3
        case .operations: return viewModel.sortedTransactions.count
        }
    }

    func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .parameters:
            switch indexPath.row {
            case 0, 1:
                let cell = tv.dequeueReusableCell(withIdentifier: DatePickerCell.reuseId, for: indexPath) as! DatePickerCell
                cell.titleLabel.text = indexPath.row == 0 ? "Период: начало" : "Период: конец"
                cell.picker.date = (indexPath.row == 0) ? viewModel.startDate : viewModel.endDate
                cell.onChange = { [weak self] newDate in
                    guard let self = self else { return }

                    if indexPath.row == 0 {
                        self.viewModel.startDate = newDate
                        if newDate > self.viewModel.endDate {
                            self.viewModel.endDate = newDate
                        }
                    } else {
                        self.viewModel.endDate = newDate
                        if newDate < self.viewModel.startDate {
                            self.viewModel.startDate = newDate
                        }
                    }
                    Task {
                        await self.viewModel.loadData()
                    }
                }
                return cell

            case 2:
                let cell = tv.dequeueReusableCell(withIdentifier: SumCell.reuseId, for: indexPath) as! SumCell
                let formatted = NumberFormatter.localizedString(from: NSDecimalNumber(decimal: viewModel.totalSum), number: .currency)
                cell.configure(text: "Сумма", value: formatted)
                return cell

            default:
                fatalError("unexpected row in parameters section")
            }

        case .operations:
            let tx = viewModel.sortedTransactions[indexPath.row]
            let cell = tv.dequeueReusableCell(withIdentifier: AnalysisOperationCell.reuseId, for: indexPath) as! AnalysisOperationCell
            var config = UIBackgroundConfiguration.listCell()
            config.backgroundInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 6)
            config.cornerRadius = 12
            cell.backgroundConfiguration = config
            let pct = String(format: "%.0f%%", viewModel.percentage(for: tx) * 100)
            cell.configure(emoji: viewModel.emojiMap[tx.categoryId] ?? "", title: tx.comment, amount: tx.amount, percentage: pct)
            let chevron = UIImageView(image: UIImage(systemName: Utility.Icons.chevron))
            chevron.tintColor = UIColor(Utility.Colors.accent)
            chevron.contentMode = .scaleAspectFit
            cell.accessoryView = chevron
            return cell
        }
    }
}

extension AnalysisViewController: UITableViewDelegate {
    func tableView(_ tv: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard Section(rawValue: section) == .operations else { return nil }
        let header = OperationsHeaderView()
        header.onSortTapped = { [weak self] in
            let alert = UIAlertController(title: "Сортировка", message: nil, preferredStyle: .actionSheet)
            MyStoryViewModel.SortOption.allCases.forEach { opt in
                alert.addAction(.init(title: opt.title, style: .default) { _ in
                    self?.viewModel.sortOption = opt
                })
            }
            alert.addAction(.init(title: "Отмена", style: .cancel))
            self?.present(alert, animated: true)
        }
        return header
    }

    func tableView(_ tv: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        Section(rawValue: section) == .operations ? 50 : .leastNormalMagnitude
    }

    func tableView(_ tv: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }
}


