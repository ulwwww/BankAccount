//
//  SpoilerView.swift
//  yandex_project
//
//  Created by ulwww on 28.06.25.
//
import SwiftUI
import UIKit

struct ShakeDetector: UIViewControllerRepresentable {
    var onShake: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        context.coordinator
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(onShake: onShake)
    }

    class Coordinator: UIViewController {
        let onShake: () -> Void
        init(onShake: @escaping () -> Void) {
            self.onShake = onShake
            super.init(nibName: nil, bundle: nil)
        }
        @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

        override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            if motion == .motionShake {
                onShake()
            }
        }
    }
}

final class EmitterView: UIView {
    override class var layerClass: AnyClass { CAEmitterLayer.self }
    override var layer: CAEmitterLayer { super.layer as! CAEmitterLayer }
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.emitterPosition = .init(x: bounds.midX, y: bounds.midY)
        layer.emitterSize = bounds.size
    }
}

struct SpoilerView: UIViewRepresentable {
    var isOn: Bool

    func makeUIView(context: Context) -> EmitterView {
        let emitterView = EmitterView()
        let emitterCell = CAEmitterCell()
        emitterCell.contents = UIImage(named: "textSpeckle_Normal")?.cgImage
        emitterCell.color = UIColor.black.cgColor
        emitterCell.contentsScale = 1.8
        emitterCell.emissionRange = .pi * 2
        emitterCell.lifetime = 1
        emitterCell.scale = 0.5
        emitterCell.velocityRange = 20
        emitterCell.alphaRange = 1
        emitterCell.birthRate = 4000
        emitterView.layer.emitterShape = .rectangle
        emitterView.layer.emitterCells = [emitterCell]
        return emitterView
    }

    func updateUIView(_ uiView: EmitterView, context: Context) {
        if isOn {
            uiView.layer.beginTime = CACurrentMediaTime()
        }
        uiView.layer.birthRate = isOn ? 1 : 0
    }
}

struct SpoilerModifier: ViewModifier {
    let isOn: Bool
    func body(content: Content) -> some View {
        content
            .opacity(isOn ? 0 : 1)
            .overlay { SpoilerView(isOn: isOn) }
    }
}

extension View {
    func spoiler(isOn: Bool) -> some View {
        modifier(SpoilerModifier(isOn: isOn))
            .animation(.default, value: isOn)
    }
}
