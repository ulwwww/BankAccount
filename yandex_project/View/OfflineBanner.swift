//
//  OfflineBanner.swift
//  yandex_project
//
//  Created by ulwww on 18.07.25.
//

import UIKit

extension Notification.Name {
    static let offlineModeEnabled = Notification.Name("offlineModeEnabled")
    static let offlineModeDisabled = Notification.Name("offlineModeDisabled")
}

class OfflineBanner {
    static let shared = OfflineBanner()
    private var banner: UIView?
    private init() {}
    func show(in window: UIWindow?) {
        guard banner == nil, let w = window else { return }
        let view = UIView(frame: CGRect(x: 0, y: w.safeAreaInsets.top, width: w.bounds.width, height: 30))
        view.backgroundColor = .red
        let label = UILabel(frame: view.bounds)
        label.text = "Offline mode"
        label.textAlignment = .center
        label.textColor = .white
        view.addSubview(label)
        w.addSubview(view)
        banner = view
    }
    func hide() {
        banner?.removeFromSuperview()
        banner = nil
    }
}

extension UITabBarController {
    func registerOfflineNotification() {
        NotificationCenter.default.addObserver(forName: .offlineModeEnabled, object: nil, queue: .main) { _ in
            OfflineBanner.shared.show(in: self.view.window)
        }
        NotificationCenter.default.addObserver(forName: .offlineModeDisabled, object: nil, queue: .main) { _ in
            OfflineBanner.shared.hide()
        }
    }
}

