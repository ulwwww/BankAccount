//
//  LottieView.swift
//  yandex_project
//
//  Created by ulwww on 26.07.25.
//
import Lottie
import SwiftUI

struct Lottie: UIViewRepresentable {
    let name: String
    let onComplete: () -> Void
    
    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView(name: name)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .playOnce
        animationView.play { _ in onComplete()}
        return animationView
    }
    func updateUIView(_ uiView: LottieAnimationView, context: Context) {}
}

struct SplashView: View {
    @State private var isAnimationFinished = false
    var body: some View {
        if !isAnimationFinished {
            Lottie(name: "splash", onComplete: {
                self.isAnimationFinished = true
            })
        } else {
            MainTabView()
        }
    }
}
