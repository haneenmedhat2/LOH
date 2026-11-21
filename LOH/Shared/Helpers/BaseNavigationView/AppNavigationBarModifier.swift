//
//  AppNavigationBarModifier.swift
//  CTF
//
//  Created by Mohamed Hadwa on 19/11/2025.
//

import SwiftUI

struct AppNavigationBarModifier: ViewModifier {
    let title: String
    var background = AppColor.surface

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
            .toolbar(.visible, for: .navigationBar)
            .toolbarBackground(background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(AppColor.primary)
            .appNativeNavigationAppearance()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(AppFont.navigationTitle)
                        .foregroundStyle(AppColor.text)
                }
            }
    }
}

/// Figma styling for UIKit's native navigation items; UIKit still owns back actions and gestures.
enum AppNavigationStyle {
    static var titleFont: UIFont { AppFont.uiFont(.bold, size: 17, relativeTo: .headline) }

    static let backIndicator = indicator(pointsRight: false)
    static let rightBackIndicator = indicator(pointsRight: true)

    private static func indicator(pointsRight: Bool) -> UIImage? {
        guard let image = UIImage(named: LOHAsset.flowBack.rawValue) else {
            return nil
        }
        let size = CGSize(width: 22, height: 22)
        let arrow = UIGraphicsImageRenderer(size: size)
            .image { context in
                if !pointsRight {
                    context.cgContext.translateBy(x: size.width, y: 0)
                    context.cgContext.scaleBy(x: -1, y: 1)
                }
                image.draw(in: CGRect(origin: .zero, size: size))
            }
        return arrow.withRenderingMode(.alwaysOriginal)
    }

    static let photoBackIndicator = photoIndicator(pointsRight: false)
    static let photoRightBackIndicator = photoIndicator(pointsRight: true)

    private static func photoIndicator(pointsRight: Bool) -> UIImage? {
        guard let image = UIImage(named: "lohHomeBack") else {
            return nil
        }
        return UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40))
            .image { context in
                UIColor(AppColor.surface).setFill()
                UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: 40, height: 40))
                    .fill()
                if !pointsRight {
                    context.cgContext.translateBy(x: 40, y: 0)
                    context.cgContext.scaleBy(x: -1, y: 1)
                }
                image.draw(in: CGRect(x: 10, y: 10, width: 20, height: 20))
            }
            .withRenderingMode(.alwaysOriginal)
    }
}

extension View {
    func appNativeNavigationAppearance(photo: Bool = false) -> some View {
        background(
            AppNativeNavigationAppearance(photo: photo)
                .frame(width: 0, height: 0))
    }
}

/// SwiftUI supplies per-screen appearances that override UIAppearance settings.
/// Update only their typography and indicator, preserving each screen's background
/// and UIKit's back item, history menu, pop transitions, and gesture recognizers.
private struct AppNativeNavigationAppearance: UIViewControllerRepresentable {
    @ObservedObject private var language = AppLanguageManager.shared
    var photo = false

    func makeUIViewController(context: Context) -> Controller {
        let controller = Controller()
        controller.photo = photo
        controller.layoutDirection = language.layoutDirection
        return controller
    }

    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.photo = photo
        controller.layoutDirection = language.layoutDirection
        controller.applyAppearance()
    }

    final class Controller: UIViewController {
        var photo = false
        var layoutDirection: LayoutDirection = .leftToRight

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            applyAppearance()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            applyAppearance()
        }

        func applyAppearance() {
            var ancestor = parent
            while let owner = ancestor {
                if let navigation = owner.navigationController,
                    navigation.viewControllers.contains(where: { $0 === owner })
                {
                    let item = owner.navigationItem
                    let bar = navigation.navigationBar
                    // UIKit can keep the launch language's image mirroring after an
                    // in-app language change, even when the bar moves to the other side.
                    let semantic: UISemanticContentAttribute = layoutDirection == .rightToLeft
                        ? .forceRightToLeft : .forceLeftToRight
                    let useRightImage = (layoutDirection == .rightToLeft)
                        != (UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft)
                    let image = photo
                        ? (useRightImage ? AppNavigationStyle.photoRightBackIndicator : AppNavigationStyle.photoBackIndicator)
                        : (useRightImage ? AppNavigationStyle.rightBackIndicator : AppNavigationStyle.backIndicator)
                    UIView.performWithoutAnimation {
                        if bar.semanticContentAttribute != semantic {
                            bar.semanticContentAttribute = semantic
                        }
                        style(item, at: \.standardAppearance, fallback: bar.standardAppearance, image: image)
                        style(
                            item, at: \.scrollEdgeAppearance, fallback: bar.scrollEdgeAppearance ?? bar.standardAppearance,
                            image: image)
                        style(
                            item, at: \.compactAppearance, fallback: bar.compactAppearance ?? bar.standardAppearance,
                            image: image)
                        style(
                            item, at: \.compactScrollEdgeAppearance,
                            fallback: bar.compactScrollEdgeAppearance ?? bar.standardAppearance, image: image)
                    }
                    return
                }
                ancestor = owner.parent
            }
        }

        private func style(
            _ item: UINavigationItem,
            at keyPath: ReferenceWritableKeyPath<UINavigationItem, UINavigationBarAppearance?>,
            fallback: UINavigationBarAppearance,
            image: UIImage?
        ) {
            let appearance = item[keyPath: keyPath] ?? fallback
            let font = AppNavigationStyle.titleFont
            let matchesImage = image.map { appearance.backIndicatorImage.isEqual($0) } ?? true
            guard !matchesImage || appearance.titleTextAttributes[.font] as? UIFont != font else {
                return
            }
            let copy = appearance.copy()
            copy.setBackIndicatorImage(image, transitionMaskImage: image)
            copy.titleTextAttributes[.font] = font
            copy.titleTextAttributes[.foregroundColor] = UIColor(AppColor.text)
            item[keyPath: keyPath] = copy
        }
    }
}
