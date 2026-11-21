//
//  AppLoaderView.swift
//  CTF
//
//  Created by Mohamed Hadwa on 23/11/2025.
//

import SwiftUI

struct AppLoaderView: View {
    var body: some View {
        ZStack {
            Color.gray.opacity(0.33)
                .ignoresSafeArea()
            BrandLoaderView(size: 112)
        }
    }
}

/// The app's clock mark, shared by launch and full-screen loading states.
struct BrandLoaderView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var size: CGFloat = 64

    var body: some View {
        LottieView(fileName: LoaderAsset.brandClockName, autoplay: !reduceMotion)
            .id(reduceMotion)
            .frame(width: size, height: size)
            .accessibilityLabel(Text("Loading".localized))
    }
}
