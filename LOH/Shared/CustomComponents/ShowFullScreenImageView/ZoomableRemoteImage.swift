//
//  ZoomableRemoteImage.swift
//  CTF
//
//  Created by Mohamed Hadwa on 22/12/2025.
//

import SwiftUI
import UIKit
import Kingfisher

struct ZoomableRemoteImage: View {
    let url: String

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var failed = false

    private var remoteURL: URL? {
        guard let value = URL(string: url),
            ["https", "http"].contains(value.scheme?.lowercased() ?? ""),
            value.host?.isEmpty == false
        else {
            return nil
        }
        return value
    }

    var body: some View {
        Group {
            if let remoteURL {
                KFImage(remoteURL)
                    .onFailure { _ in
                        failed = true
                    }
                    .placeholder {
                        if failed {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.white)
                        } else {
                            ProgressView()
                                .tint(.white)
                        }
                    }
                    .resizable()
            } else if let image = UIImage(named: url) {
                Image(uiImage: image)
                    .resizable()
            } else {
                Image("lohLogo")
                    .resizable()
            }
        }
        .scaledToFit()
        .scaleEffect(scale)
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    let delta = value / lastScale
                    lastScale = value
                    scale = min(max(scale * delta, 1), 4)
                }
                .onEnded { _ in
                    lastScale = 1
                    if scale < 1 {
                        scale = 1
                    }
                }
        )
        .onTapGesture(count: 2) {
            withAnimation(.easeOut(duration: 0.2)) {
                scale = (scale > 1) ? 1 : 2
            }
        }
    }
}

extension View {
    func imageViewer(
        isPresented: Binding<Bool>,
        urls: [String],
        startIndex: Int
    ) -> some View {
        fullScreenCover(isPresented: isPresented) {
            FullScreenImageViewer(urls: urls, startIndex: startIndex)
        }
    }
}
