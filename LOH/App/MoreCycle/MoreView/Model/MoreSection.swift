//
//  MoreSection.swift
//  NewSwiftUIBase
//
//  Created by Mohamed Hadwa on 31/07/2025.
//
//

import SwiftUI

enum MoreRowID: Hashable {
    case settings
    case points
    case wallet
    case complaints
    case terms
    case about
    case privacy
    case logout

    case changeLanguage
    case login
}

struct MoreItemModel: Identifiable {
    let id: MoreRowID
    let title: String
    let imageName: String
    let showChevron: Bool
    let titleColor: Color
    let action: () -> Void

    var stringId: String { "\(id)" }
}

struct AnyMoreSection: Identifiable {
    let id = UUID()
    let title: String
    let items: [MoreItemModel]
}
