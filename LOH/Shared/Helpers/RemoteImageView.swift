//
//  RemoteImageView.swift
//  CTF
//
//  Created by Mohamed Hadwa on 08/12/2025.
//

import SwiftUI
import Kingfisher

struct RemoteImageView: View {

    let url: String?

    var body: some View {
        KFImage.url(AppServices.remoteURL(url ?? ""))
            .placeholder {
                Image("lohLogo")
                    .resizable()

                Rectangle()
                    .fill(AppColor.canvas.opacity(0.2))
                    .overlay {
                        ProgressView()
                    }
            }
            .resizable()
    }
}
