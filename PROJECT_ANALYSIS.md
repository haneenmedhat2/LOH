# LOH Project Analysis and Structure

Last reviewed: 2026-10-27.

## Project overview

LOH is an iOS customer app for discovering offers and coupons, browsing merchants, and managing purchases and an account. The current implementation combines live LOH authentication, catalog, purchases, and account services with live order creation and API-backed customer support tickets.

The repository also retains code from an older transport application, including passenger, goods, and flatbed orders, tracking, and related notifications. These files should not be mistaken for the active LOH product flows. Standalone chat is removed. Support-ticket replies use the ticket reply API without sockets.

## Design and API references

### Figma

- Design file: [LOH UI — node 0:1](https://www.figma.com/design/FYN2HgYcuBioezCOg51Ubv/ui?node-id=0-1&t=SjWIEKB7w0K0DOC2-1)
- File key: `FYN2HgYcuBioezCOg51Ubv`
- Root node: `0:1`
- The link was supplied by the project owner. The remote design was not inspected during this documentation pass.
- Local design resources include asset catalogs, semantic UI tokens, fonts, and `LOH*AssetManifest.json` files under `LOH/Shared/Resourses/`.

### Postman collection

- File: [NewLoh.postman_collection-3.json](/Users/haneen/Downloads/NewLoh.postman_collection-3.json)
- Absolute path: `/Users/haneen/Downloads/NewLoh.postman_collection-3.json`
- The updated `-3.json` path was supplied by the owner but was not present on disk when checked. The collection overview below was inspected from the previous `-2.json` version.
- Collection name: `NewLoh`
- Format: Postman Collection v2.1.
- This file is outside the repository; the path is specific to the current workstation.
- Configured app API base URL: `https://upgrade.loh.com.sa/api/`, defined in `APIEnvironment` in `LOH/Networking/LOHAPI/APIClient.swift`.

The collection includes these main groups:

| Group | Coverage |
| --- | --- |
| Settings | App settings, static pages, onboarding, categories, cities, interests, home, coupon details, announcements |
| Client / Auth | Registration, activation, login, logout, password recovery, city/interests selection, profile, notifications, account deletion, contact and complaints |
| Client / Logic / Home | Home data, search, static filters, nearby offers, ending-soon offers, categories |
| Client / Logic / Purcheses | User coupons, coupon details, cashback; folder spelling matches the collection |
| Client / Logic / Order | Order creation |
| Client / Logic / Follow and Rate | Store following, store ratings, rating tags |
| Client / Logic / Payments | Listing, adding, renaming, deleting, and selecting default payment cards |
| Vendor | Vendor authentication, notifications, profile, chats, support tickets, receipts, sales, coupon delivery, and reports |

Collection URLs use several variable names, including `base-url`, `url`, `local_url`, and `baseUrl`. Resolve the intended environment before using a request; do not assume all requests share the app's configured base URL. An endpoint's presence in the collection does not mean the app implements it. Credentials and secret values are intentionally omitted from this document.

## Technology and configuration

| Area | Implementation |
| --- | --- |
| UI | SwiftUI with UIKit bridges where needed |
| Minimum deployment target | iOS 16.4 |
| Swift language setting | Swift 5 |
| Xcode project / scheme | `LOH.xcodeproj` / `LOH` |
| Bundle identifier | `com.aait.LOHH` |
| Architecture | MVVM with coordinator-based navigation |
| State | `ObservableObject`, `@Published`, environment objects, Combine |
| Live networking | `URLSession`, async/await, Codable |
| Authentication storage | Keychain |
| Localization | Arabic and English, including RTL layout |
| Appearance | Light color scheme with shared semantic design tokens |
| Dependencies | Swift Package Manager |

Resolved packages include Alamofire, Kingfisher, Lottie, IQKeyboardManager, Firebase, and Google Maps. Package presence does not imply an integration is currently enabled.

## Repository structure

```text
LOH/
├── Core/                       App entry point, root view, service flags, Info.plist, assets
├── App/
│   ├── SplashView/             Startup and session restoration UI
│   ├── Onboarding/             Intro pages and loading state
│   ├── AuthCycle/              Login, registration, OTP, recovery, preferences
│   ├── MainTabs/               Home, Offers, Purchases, My Account tabs
│   ├── HomeCycle/              Separate screen folders plus Shared models and views
│   ├── PurchasesCycle/         Live Purchases, PurchaseDetails, and PurchaseCode screens with only their needed layers
│   ├── MoreCycle/              Account, settings, profile, support, older utility views
│   ├── NotificationView/       Notification screens and models
│   ├── OrdersCycle/            Legacy transport order flows
│   └── SheetsAndPopUpsViews/   Shared sheets and popup flows
├── Coordinator/               App root, authentication, tabs, and feature navigation
├── Networking/
│   ├── LOHAPI/                Independent live LOH API client and services
│   ├── Endpoints/             Older endpoint definitions
│   ├── HandelRequest/         Legacy request construction
│   ├── HandleResponse/        Legacy execution, decoding, and error handling
│   └── BaseResponse/          Legacy response envelopes
├── Shared/
│   ├── CustomComponents/      Reusable controls and composed UI
│   ├── Helpers/               Theme, navigation, loaders, alerts, location utilities
│   ├── Localization/          Language manager and Arabic/English string tables
│   ├── Resourses/             Fonts, asset accessors, manifests, animations
│   ├── Foundation/            Extensions and shared data helpers
│   └── Validation/            Input validation
└── FCM/                       Push payload types and Firebase configuration
LOH.xcodeproj/                 Build configuration, scheme, package resolution
Tests/                        Standalone Swift tests with Python runners
```

Directory spellings above match the repository, including `Resourses` and `HandelRequest`.

Every app screen lives in its own folder containing `View`. Add `Model` and `ViewModel` only when the screen has files for those layers; remove unused folders instead of retaining placeholders. A screen's custom controls belong in `View/CustomViews`; reusable UI and data belong in the cycle's `Shared/View` and `Shared/Model`. Screens may use existing shared state or render supplied values without owning a model or view model. Coordinators remain in `Coordinator` and API implementations remain in `Networking/LOHAPI`.

Home screens are no longer bundled in `HomeView/View` or combined checkout/sheet files:

```text
App/HomeCycle/
├── Home/                       View, Model, ViewModel
├── HomeMerchant/               View, Model, and ViewModel
│   └── View/HomeMerchantView.swift
├── HomeOfferDetail/            View, View/CustomViews, and ViewModel
├── HomeSearch/                 Search screen, load key, and HomeOfferListModel
├── HomeFavorites/
├── HomeCity/
├── HomeFilter/
├── HomeNotifications/
├── HomePurchasesPreview/
├── HomeOrderReview/
├── HomePayment/
├── HomePaymentProcessing/
├── HomePaymentSuccess/
├── HomeQRCode/
└── Shared/
    ├── Model/                 Offer catalog, localization, checkout receipt
    └── View/                  Images, prices, chips, sheet controls, checkout UI
```

Screen folders contain only the layers they use. Home banners and ending-soon cards belong to `Home/View/CustomViews`; search rows belong to `HomeSearch/View/CustomViews`. Shared login, directions, and checkout controls are independent files in `Shared/View`. `HomeOfferListModel` is now separate from `HomeViewModel`, with the same search state and behavior.

Auth location, city selection, preferences, password-changed, language, and account-success screens also have their own folders. Password recovery's observable state lives in `PasswordRecovery/ViewModel`. Splash, main tabs, shared popup flows, and account-deletion result screens follow the same convention. Xcode's synchronized `LOH` group discovers the files automatically. `python3 Tests/Structure/run.py` checks that app files stay in the screen/shared layers, every screen has a `View` directory, and optional layers contain Swift files when present.

The More screens follow `AllMoreViews/<Feature>/<Screen>/{View,Model,ViewModel}`. Features with a single screen, such as Profile and Documents, contain those three directories directly:

```text
App/MoreCycle/
├── MoreView/                       More tab and menu
├── Shared/
│   ├── Model/AccountValidation.swift
│   ├── View/MoreAccountEnvironment.swift
│   └── ViewModel/AccountRequestController.swift
└── AllMoreViews/
    ├── Payments/
    │   ├── PaymentCard/
    │   │   ├── View/PaymentCardView.swift
    │   │   ├── Model/PaymentCardModel.swift
    │   │   └── ViewModel/PaymentCardViewModel.swift
    │   └── AddPaymentCard/
    │       ├── View/AddPaymentCardView.swift
    │       ├── Model/AddPaymentCardModel.swift
    │       └── ViewModel/AddPaymentCardViewModel.swift
    ├── Profile/                    View, Model, ViewModel
    ├── Tickets/
    │   ├── TicketList/             View, Model, ViewModel
    │   ├── NewTicket/              View, Model, ViewModel
    │   └── TicketDetails/          View, Model, ViewModel
    ├── Help/
    │   └── Join/                   View, Model, ViewModel
    ├── Settings/
    │   ├── AccountSettings/        View, Model, ViewModel
    │   ├── Notifications/          View, Model, ViewModel
    │   ├── ChangePassword/         View, Model, ViewModel
    │   ├── Language/               View, Model, ViewModel
    │   ├── Security/               View, Model, ViewModel
    │   └── DeleteAccount/          View, Model, ViewModel
    └── Documents/                  View, Model, ViewModel
```

Screen-specific controls, dialogs, and success content live in their screen's `View/CustomViews` directory. Controls reused across account features, including the profile-image placeholder, live in `Shared/CustomComponents/Account`. Older utility screens also remain under `AllMoreViews`.

The former combined `MoreCycle/Account` directory and `AccountViewModel` have been removed. `MoreAccountStore`, alongside `MoreCoordinator`, constructs the shared More statistics, profile, saved-card, ticket, notification, and language view models and resets them on session changes. It contains no endpoint implementations. `AccountRequestController` handles loading/error state and session-scoped request completion. Each feature view model owns its data and operations; add-card, join, password, and ticket forms have separate screen state. Checkout observes the same `PaymentCardViewModel` as More so changes to saved cards propagate to both flows.

## Startup, navigation, and state ownership

1. `Core/NewSwiftUIBaseApp.swift` is the `@main` entry point. It configures keyboard handling, navigation appearance, locale, layout direction, and the application delegate.
2. `Core/AppRootView.swift` creates the app coordinator and injects shared alert state.
3. `Coordinator/BaseCoordinator/AppCoordinator.swift` manages splash, authentication, and main-tab roots. It restores sessions and handles expiration and logout.
4. `AuthCoordinator` routes onboarding and authentication, including required city and interest selection and guest entry.
5. `TabsCoordinator` owns separate Home and Offers coordinators sharing one `HomeViewModel`, a shared `NotificationsViewModel`, plus purchase and account-related state.
6. `MainTabsRootView` renders Home, Offers, Purchases, and My Account. The internal `.orders` tab identifier currently displays purchases while legacy services are disabled.

Pushed screens use the native navigation back button and interactive pop gesture. Titles match Figma's Tajawal Bold at 17 pt (`#1C1C1E`); the native back indicator uses the existing 22 pt gold `lohFlowBack` export (Figma node `13:5689`). Its image selection accounts for both SwiftUI's screen direction and UIKit's automatic mirroring at app launch, so it points right in Arabic and left in English, including after switching languages. Only the indicator's appearance is customized: there is no custom back button, pop action, or gesture override. Password recovery and account-deletion confirmation use navigation destinations for their individual steps, so Back returns to the preceding step. Root, processing, and completion screens retain their existing back-navigation restrictions; the Add Card modal uses a Cancel action to dismiss.

`AuthSession` has four stages: signed out, city selection, interest selection, and authenticated. Tokens are kept in Keychain; session restoration fetches the authoritative profile. Session resets clear relevant local feature state.

## Networking boundaries

### Active LOH API

`Networking/LOHAPI/` contains:

- `APIClient.swift`: HTTPS request construction, multipart form fields, language and bearer headers, response-envelope decoding, and session-expiration notifications.
- `AuthService.swift`: Login, signup, activation, recovery, profile, city/interests selection, and logout requests.
- Password recovery sends `POST forget-password-send-code` with `phone`, verifies the OTP through `POST activate?_method=patch`, then submits `POST reset-password` with `phone` and `password`. Recovery activation does not create a logged-in session or route to city selection.
- `AuthSession.swift`: Keychain storage and authentication lifecycle.
- `IntrosService.swift`: Customer onboarding content via `GET intros?type=user`; response models include audience type and tags (`id`, `name`, `icon`).
- `HomeService.swift`: Home sections, categories, filters, paginated offer lists, details, and cities.
- `AccountService.swift`: Authenticated account requests and `GET user-stats`.
- `AccountSettingsService.swift`: `POST update-password?_method=patch`, `PATCH change-lang?lang=ar|en`, `DELETE delete-account`, and public `GET security-privacy`, `privacy`, `terms`, and `about`.
- `NotificationService.swift`: All seven `Client / Auth / Notifications` requests, using the active LOH client and authenticated session.
- `PurchaseService.swift`: Authenticated `GET user-coupons` and `GET user-coupon-details/{id}` from `Client / Logic / Purcheses`.
- `PaymentService.swift`: Dedicated `LOHAccountService` methods for all five `Client / Logic / Payments` requests. Payment models live with their screens under `AllMoreViews/Payments`. Profile and payment requests/responses are logged in Debug. At the owner's request on 2026-10-27, the shared `APILogger` preserves all logged header, query, body, and response JSON values without replacing fields with `[REDACTED]`; nested objects such as voucher `code` remain visible as objects. Requests explicitly marked `sensitive` still skip logging entirely. Network console output remains compiled only in Debug.

Account integration uses the available `NewLoh.postman_collection-2.json`; the supplied `-3.json` path is still absent. The collection has no saved response examples for card lists or notification preferences. Their decoders have mocked coverage but still require verification against authenticated backend responses. Vendor ticket routes are not used with customer credentials.

Purchases use the same available collection. `PurchasesCycle/Purchases/{Model,View,ViewModel}` owns the list, status tabs, pagination, and retry state. `PurchasesCycle/PurchaseDetails/{Model,View,ViewModel}` loads each selected server ID before displaying its details or code. All omits `status`; the remaining purchase filters send `ready`, `used`, and `ended`. The Purchases cashback tab was removed at the owner's request. The More screen separately loads its balance from `GET cash-back`. All four tab counts come from the server `counts` object (`all`, `ready`, `used`, `ended`), with pagination totals retained as a fallback for older responses. Repeated catalog coupon IDs remain separate purchased vouchers instead of being discarded. Requests carry the current bearer token and language, and late responses cannot overwrite a newer filter or session. Logout clears the purchase cache.

The list integration uses the owner’s `user-coupons?page=1` response from 2026-10-26. It decodes `store_address`, numeric `rating` with `is_rated`, `coupon_number`, `qr`, `available_count`, and separate purchased-voucher/catalog/store IDs. An unrated zero remains hidden. The list QR URL is retained as metadata; the usage-code screen continues loading fresh voucher details before showing a code. `Tests/Purchases/Fixtures/user-coupons-current.json` preserves this response and covers decoding, tab counts, status handling, and stale responses.

The purchase details integration uses the owner's `user-coupon-details/910` response from 2026-10-26. `PurchaseDetail` keeps purchased-voucher ID `910` separate from nested coupon `197`, order `524`, and store `78`. The model decodes the header, store/address, coupon description, order/payment metadata, localized purchase/expiry dates, usage instructions, and rating metadata. `code` is an object containing `coupon_number`, `qr`, `is_active`, and nullable `status_text`, decoded by `PurchaseVoucherCode`. The original console sample replaced that entire object with `[REDACTED]`; treating it as a string caused both details and usage-code screens to reject the response. Debug decoding failures now report the field path and expected/actual JSON types without revealing values. The detail screen shows server values and existing ratings when `is_rated` is true; eligible used vouchers also support the documented store-rating request described below. `PurchaseDetailData` also accepts the older direct coupon, `coupon` wrapper, or documented `coupons` list through an explicit compatibility adapter. The service always matches the requested purchased-voucher ID. Unknown/mismatched shapes remain retryable errors.

Purchase details have distinct layouts for `ready`, `used`, and `ended`, following Figma frames `6:3579`, `6:3718`, and `6:3887` and the owner's 2026-10-27 screenshots. `PurchaseDetails/View/CustomViews` contains the status header, offer/receipt card, usage instructions, inactive code, and rating card. Ready vouchers show a centered QR status header, a full-width photo above readable offer/order information, server-provided usage instructions, a privacy note, and a pinned Show code action only for an active code. The offer card uses natural page scrolling rather than the Figma frame's clipped inner viewport. Used vouchers show a green confirmation, compact receipt, read-only crossed-out code, and rating controls; ended vouchers show neutral expiry copy, purchase/payment information, and an unavailable code. API fields absent from the response, including discount and distance, are not fabricated. All purchase detail routes hide the tab bar, which reappears when returning to the purchases list. Returning to the purchase list refreshes it, and foregrounding details refreshes voucher availability unless a rating is being submitted.

Store ratings use `POST rate-store/{storeID}` from `/Users/haneen/Downloads/NewLoh.postman_collection.json` (Client / Logic / Rate / rate-store). The owner confirmed that the URL uses the store ID (`78` in the supplied voucher), not the original coupon ID or purchased-voucher ID. The multipart body sends integer `rating` (1–5), a nonempty optional `comment`, and repeated `tags[]` fields for selected server tag IDs. Public `GET rating-tags` returns `{id, name}` entries; the live response is saved in `Tests/Purchases/Fixtures/rating-tags.json`. Unknown tag IDs are never fabricated. `can_rate`, `is_rated`, a valid store ID, and used status determine eligibility. `PurchaseDetailViewModel` prevents duplicate submissions, shows server failures inline without losing input, and only marks a rating as saved after a successful response. A response for an old session cannot change the displayed rating. No live ratings are submitted during verification. Tests cover the request contract, store-ID mapping, tag decoding/selection, repeated multipart tag fields, Unicode comment limits, eligibility, errors, duplicate submission prevention, and session isolation.

The Rate your experience button (or a star on an unrated card) opens `PurchaseRating/View/PurchaseRatingSheet.swift`, following frame `16:686`. It uses a white native bottom sheet with a 28-point corner radius, merchant logo/offer summary, five selectable stars, localized rating level, a 250-character optional comment and counter, selectable API-provided tags, Submit, Close, and Not now. `PurchaseRatingViewModel` owns the draft and tag-loading/retry state; the detail model retains voucher eligibility and the authenticated submission. Errors keep the sheet and draft open, and duplicate submissions/dismissal are disabled while sending. After confirmed success, the sheet dismisses before presenting `PurchaseRatingSuccessPopup` as a transparent full-screen cover, dimming the navigation and tab bars. The rounded white dialog uses frame `16:773` and the supplied success screenshot, with the success badge, confirmation text, and Done action. Session changes dismiss both presentations and prevent a stale response from showing success. Existing image borders and icon-free location text in purchase details are preserved.

Purchase cards follow Figma components `13:6774` and `13:6821`: a 110-point offer image, bold store/offer names, readable status text, location, copyable voucher number (or legacy order reference), stacked full-width code/details actions, and a rating footer only for submitted ratings. A ready row always offers Show code, even if the list omits the code. `PurchaseCode/View/PurchaseCodeView.swift` follows frame `13:6016` and reuses the authenticated details view model to fetch the selected purchased voucher ID. It shows the server store logo, offer/location summary, the backend QR image, the exact voucher number with a copy action, and the code status. A QR generated from the exact number is retained as a fallback if the image fails to load. An inactive code cannot be displayed or copied even when the outer voucher status is `ready`; used and expired vouchers are also blocked. Returning from the background refreshes voucher availability. The directions action searches Apple Maps for the actual store name/address; this response supplies no branch coordinates. The supplied nested response also decodes as a purchase row, while the legacy flat list remains supported. Redacted example values never become redeemable codes. No demo payload or checkout preview is inserted into live purchases. `Tests/Purchases/Fixtures/user-coupon-details-910-code-object.json` preserves the confirmed response shape with non-redeemable test values and covers the original decoding failure, active/inactive codes, QR URLs, nullable status text, and safe diagnostics. The earlier `user-coupon-details-910.json` remains a masked-log compatibility case. Tests also verify nested IDs, localized dates, payment/header/instruction/rating fields, ready navigation without a list code, and QR encode/decode round trips preserving leading zeros and spaces.

Account deletion uses the documented authenticated `DELETE delete-account` through `AccountSettingsService` after explicit confirmation, with no body or query parameters. The delete view model owns processing/failure/completion state, prevents duplicate deletion, and clears the token and cached user only after a confirmed success for the same session. The coordinator clears account, home, notification, and purchase caches while retaining the completion screen; its button returns to login. Deletion request/response logs are visible in Debug. There is no simulated deletion OTP or preview success message.

The More logout button places its title before the icon in the current reading direction. Its white confirmation sheet uses 28-point rounded corners. More's logout confirmation calls authenticated `DELETE sign-out` through `AuthService` and `AuthSession`, with no body or query parameters. A successful response clears the session, feature caches, and navigation before returning to login. Failures preserve the session and offer retry (or an explicit local sign-out); a late response from an older session cannot clear a newer login. Profile city changes use `select-city` because `update-profile` does not document a city field.

`AccountProfileView` fetches `GET profile` on entry before populating its draft, then loads city options. Save sends multipart fields to `POST update-profile?_method=put` and uses the returned profile to refresh both the form and session data. Saving is disabled until the initial profile request succeeds.

`MoreScreen` displays the shared cached profile, then refreshes it with `GET profile`. It also fetches authenticated `GET user-stats` on entry and pull-to-refresh. The screenshot-supplied response maps `used_offers_count` to offers used, `orders_count` to total orders, and the server-formatted `member_since` to the membership date. `MoreView/Model/MoreUserStats.swift` decodes the response and `MoreView/ViewModel/MoreViewModel.swift` owns its session-scoped cached state. Counts show a dash before the first successful load; failed refreshes keep the last values and use the shared error alert. Cashback is loaded separately through authenticated `GET cash-back`: `data.total` supplies the balance; `settlements` is not used by the More summary. The balance refreshes when More appears and on pull-to-refresh, shows a dash until loaded, retains its last successful value on request failure, and clears on session reset. Successful profile responses update the session and persisted user summary. Both profile screens refresh the avatar even when the server reuses its image URL. Profile row values are centered. Birthdates accept ISO dates and localized Gregorian dates such as `15 مايو 2000`; the row and date picker use the parsed date, and updates serialize `yyyy-MM-dd`. The edit-profile success dialog uses a transparent full-screen presentation so the dimming layer covers the navigation bar and safe areas; dismissing it returns to the More root.

Payment methods load with `GET payment-cards`, add with `POST add-payment-cards`, rename with `POST payment-cards/{id}/rename?_method=patch`, set default with `POST payment-cards/{id}/set-default?_method=patch`, and delete with `DELETE delete-payment-cards/{id}`. The supplied collection requires `holder_name`, `card_number`, `expiry`, `cvv`, and `is_default` for both add and default selection. Default selection therefore asks the user to confirm their card details; full card numbers and CVVs are never retained in saved-card state. Successful mutations refresh the list. A refresh failure displays a retry without repeating the mutation or claiming that the card list is empty. Saved-card rows follow Figma frame `6:4883` with full-width bordered 16-point rounded cards, 16-point insets, spaced brand/title/options content, a non-compressing default badge with a minimum text height, and a separate expiry row. Long card titles move the default badge below the title when needed. The secure-payment title and explanatory copy match the design in Arabic with English equivalents. The add-card form uses separate original-color, aspect-fit mada, Mastercard, and Visa logos in compact 29–30-point-wide slots with 8-point spacing; saved-card logos retain their own larger size.

`AccountJoinView` uses `AccountPhoneTextInput` to synchronize the visible native input and form binding on every keystroke, including Arabic/Persian digit paste and cursor edits. The Join contract accepts 9–10 phone digits, business/contact names up to 191 characters, a required email up to 191 characters, and optional notes up to 255 characters. A complete form enables submission; invalid values then show field errors before any request. The view no longer rewrites the phone or names in `onChange`, and its success summary preserves the submitted phone digits.

`AccountPasswordView` separates password tips by 12 points and allows multiline tips to wrap without clipping. It submits `old_password` and `password` as multipart fields to `update-password?_method=patch`, then clears password fields only on success. `AccountLanguageView` sends the selected language in both the `change-lang` query and `lang` header; it changes the app language only after server success. Both requests are visible in Debug logging, with password values masked.

`AccountSecurityView` loads `security-privacy`; `AccountDocumentView` maps privacy policy to `privacy`, terms and conditions to `terms`, and About to `about`. These GET requests are public and use the current language header. Live responses for `about` and `security-privacy` contain `header`, `items`, and `footer` blocks, while `privacy` and `terms` return plain text. `AccountDocumentContent` supports both formats, and `AccountRemoteDocument` renders server titles, descriptions, and available images. Content reloads when the endpoint or language changes, with loading, empty, error, and retry states.

Security uses its own `AccountSecurityContentView`, matching Figma's `security-privacy` frame (`13:9684`): a compact hero, grouped protection rows, a privacy-policy navigation card, and the API footer. It reuses the exported Settings icons as fallbacks when API artwork is missing or loading, keeps API titles/descriptions dynamic, and hides the tab bar while this screen is pushed; returning to More restores it.

`HomeViewModel` owns catalog state shared between screens. `HomeOfferListModel` owns individual list/search results and pagination. Generation checks and cancellation handling prevent superseded requests from overwriting newer results in these models.

`HomeOfferDetail/ViewModel/HomeOfferDetailViewModel.swift` owns the selected coupon, loading/error/retry state, favorite presentation, and purchase eligibility/login presentation. The coordinator injects the existing service and catalog/favorite callbacks; the detail view and its view model do not depend on `HomeViewModel`. Responses from a superseded language request, cancelled task, or previous authentication session are discarded. The former `HomeOfferLoaderView` was removed, and both offer-ID and offer-object routes now open the same detail screen. `HomeOfferDetailView` logs its name for all entry paths.

Home-to-details navigation retains the tapped offer's image, store name, and title while fetching the complete coupon. The detail screen keeps the same root layout during loading, success, and retry; placeholders occupy the detail content and purchase bar until the response arrives. `hasLoadedDetails` gates pricing, store navigation, and purchase eligibility so a listing summary cannot authorize checkout. The view model is created lazily through `StateObject`, avoiding repeated construction when navigation destinations are evaluated.

Offer details follow Figma frame `13:4667`: an edge-to-edge gallery extends behind the native navigation bar with separate share/favorite circles and an actual image-count badge. The gallery remains above the scrolling content, and the total/purchase bar remains at the bottom. Store identity, the visible View store action, price/status, feature tiles, text sections, full terms sheet, and branch card use the shared fonts/assets and adapt to Arabic/English and larger text. The View store action also works for API coupons. Its merchant destination requests the selected coupon’s `store.id` from `GET store/{storeID}`; the coupon ID is never used as a store ID. Shared merchant logos, branch cards, and offer rows live in `HomeCycle/Shared/View`.

`HomeMerchant` has dedicated `Model`, `View`, and `ViewModel` folders. `LOHMerchantService` loads the complete store response, validates the requested ID, and passes `category_id` for the server-provided category chips (ID 17 represents All Categories in the supplied contract). The screen follows Figma frame `13:4864`: only the full-bleed cover stays fixed; the fully visible circular logo below the cover, centered identity, follow/directions actions, available statistics, expandable About, three-column offers, and illustrated location card scroll together above the native tab bar. The cover and offer images have subtle borders, and category chips follow the current language's leading-to-trailing direction. Missing cover images use the LOH placeholder; absent ratings, distances, About copy, and directions are omitted. Directions use a validated HTTP(S) link or valid supplied coordinates, never a guessed address. Local assets remain available for catalog previews.

Follow uses `POST store/{storeID}/toggle-follow` with the current session, then reloads the store to confirm server state. Guests see a follow-specific sign-in prompt. Requests are serialized for follow actions; category/language requests reject stale, cancelled, and prior-session results. The view model keeps store identity visible during reloads, offers retry on failure, and prevents old-category offers from appearing below the newly selected chip. `HomeMerchantView` logs its name. `Tests/API/Fixtures/store-78.json` records the supplied response, and `MerchantTests` covers decoding, ID/header/query construction, follow requests, nullable metadata, directions, category races, retries, and session/cancellation behavior.

The global native navigation bar allows translucent layout; individual screen appearances still control its background. This lets photo screens extend behind both the status bar and native navigation controls rather than leaving a white band above the image. Tapping a gallery photo opens `FullScreenImageViewer` at the selected index with aspect-fit images, paging, zoom, and a close control. The viewer supports local assets and HTTP(S) images through Kingfisher, independently of the legacy `AppServices.isEnabled` switch, and logs its screen name.

The home-page models were updated on 2026-10-25 against the owner's populated `home-page?city_id=1` response. Compact `ending_soon` offers may omit `name` and return a null `discount`; these no longer prevent the whole page from decoding. Offer summaries retain `currency`, `is_favorite`, `ends_in`, and `ends_in_seconds`. The numeric duration anchors the live countdown when no absolute expiry is supplied; cards use the returned category when the offer name is absent, and opening an offer still fetches its details by ID. Home uses the server greeting/subtitle and cashback button/image, while retaining localized or asset fallbacks for missing values. Banner models preserve platform images, type, coupon name, and start/end dates; inside banners route to coupon details and outside banners open their web link. Returned banner dates are not filtered locally. `user.image`, `cart_count`, and `show_ad` are retained in state without adding new avatar, cart, or ad UI. Server favorite flags initialize the cached state. Favorite hearts now use `POST coupon/{id}/toggle-favorite` and apply its returned `is_favorite` value; confirmed changes survive catalog refreshes and are cleared on session reset. `Tests/API/Fixtures/home-page-riyadh.json` preserves the supplied response for regression coverage.

Coupon details also support the owner's `coupon/196` response, saved in `Tests/API/Fixtures/coupon-196.json`. The decoder maps `coupon_name`, `about`, nested `store` metadata, `images`, `features`, array-based `includes`, `terms.items`, and `branch`, while retaining compatibility with the older flat fields and text-based includes/conditions. The detail screen uses the returned gallery, store logo/verification, feature titles, terms and full-terms sheet, and branch status. Null rating and distance values do not produce placeholder ratings or distances. `is_available` controls purchase eligibility, and `availability_status`/`available_time_text` supply the status copy. The detail screen shows `service_fee` and uses the authoritative `total_price` (11 ريال in the supplied example); checkout carries these prices through review, payment, and confirmation. Branch directions appear only for a supplied HTTP(S) URL, with no generated map location when coordinates and links are absent. Fulfillment, address/option flags, times, coordinates, and option/location metadata are retained; populated option selection is not implemented from the empty sample. Detail responses must match the requested coupon ID. `CouponDetailsTests` covers this fixture, nullable content, older responses, structured metadata, and ID validation using mocked HTTP.

`HomeBannerView.swift` renders the Home carousel with the Figma hero's typography, overlaid API title/description, white localized Explore button, and active capsule page indicator. Banner artwork uses aspect-fit inside a 180-point, Dynamic Type-aware card, with a blurred image backdrop filling any unused space; other `HomePhoto` call sites retain their existing fill behavior. The full card and its visible CTA share the same validated coupon/web action. Missing titles and descriptions are omitted rather than replaced with coupon names or sample promotional claims. The Explore button is hidden when both API fields are null, empty, or whitespace-only; the image retains its validated tap action. The current API burger image is itself a close-up, so preserving it in full does not recover the wider burger composition in the Figma asset. Ending-soon cards use an 8-point gap between text rows, a light gray favorite-button outline (gold when selected), and a near-white image outline/background. The 128-point-wide image fills the full card height as text grows, including at larger text sizes. Nearby offer cards use matching favorite and image borders. Their height follows the visible content instead of reserving 246 points, and the horizontal list aligns cards at the top, removing unused bottom space when titles or discounts are absent.

The home city picker shows the localized city hint below its title. Its search field follows Figma's 48-point height, 16-point corners, pale gray fill, muted placeholder, and exported search icon; the layout mirrors for Arabic and English and grows for larger text. Opening the picker prints `[Screen] HomeCitySheet` in the Debug console through the shared screen logger.

The Offers tab opens `HomeSearchView(isTabRoot: true)` and loads the live search catalog; Favorites remains a separate Home route. Search uses `GET search-offers` with the entered `name`, category/city selection, custom price and distance limits, availability toggles, sorting, and pagination. The results display the response's `total` and `city_name`, with pagination totals and the selected city as fallbacks. Empty results and API errors have separate states, and failed requests can be retried. The empty state is withheld until the first successful response. The screen follows the supplied search-results reference with an outlined search field, filter-count badge, quick controls, removable active-filter pills, a query/count heading and horizontal offer cards. The separate sorting menu is removed; quick controls still provide nearest and price ordering. Cards follow the supplied compact reference: the image fills the leading edge at the card’s natural height using the Ending Soon card’s 128-point width and canvas-colored border; merchant, offer, and prices sit alongside it, with the discount above the trailing rating and the metadata within the text column. Missing metadata is omitted without spacer slots, and the card height contracts with its content. Highest discount selects the largest discount preset returned by `static-filter` (confirmed by the owner); it sends that option ID as `discount`, since the backend rejects discount sorting. Nearest and price use the documented server sort values. Clearing filters resets category, price, distance, availability, discount, and rating without removing the entered query.

The filter sheet loads `GET static-filter` and `GET home/categories`. Price, discount, and rating titles/options come from the server. Selected presets send their IDs as `static_price`, `discount`, and `rate`; the live API rejects raw display thresholds such as `discount=20` or `rate=4.5`. Editing a price field clears its preset ID and sends custom `min_price`/`max_price` values instead. Filter categories are stored separately so opening the sheet never replaces the categories returned by `home-page`. Filters preserve the current category when opened and allow it to be cleared before applying.

### Notifications

The inbox keeps its `View`, `Model`, and `ViewModel` under `App/NotificationView/`. Notification preferences remain under `MoreCycle/AllMoreViews/Settings/Notifications/`, with their own View/Model/ViewModel. Both features use `Networking/LOHAPI/NotificationService.swift`.

| Method and path | Integration |
| --- | --- |
| `GET notifications?filter=all&page=1&paginate=20` | Inbox with `all`, `offers`, and `updates` filters; pagination and pull-to-refresh |
| `GET count-notifications` | Shared inbox count and Home bell badge |
| `PATCH read-notifications` | Mark all notifications as read |
| `PATCH read-notification/{id}` | Mark an unread notification as read when it is opened |
| `DELETE delete-notification/{id}` | Remove one notification after confirmation |
| `DELETE delete-notifications` | Remove all notifications after confirmation |
| `GET notification-settings` | Load `new_offers`, `order_updates`, and `offer_reminders` preferences |
| `POST notification-settings?_method=patch` | Update the changed preference as a multipart `0`/`1` field |
| `PATCH switch-notify` | Toggle the global setting and apply the returned `data.notify` value |

`HomeNotificationsView` and the coordinator's notification screen use the same live inbox. The decoder supports both saved Postman list formats: `data.data` with `data.pagination`, and the older `data.notifications.data` with nested pagination. The supplied live response also uses `data.sections`, `data.pagination`, and `data.unread_count`; an empty `sections` array is a successful empty inbox. Section wrappers containing `notifications`, `items`, or `data` arrays are supported, with populated wrappers covered by synthetic compatibility tests pending a populated live example. Malformed wrappers still produce an error rather than silently discarding notifications. The badge continues to refresh through `count-notifications`. Items use their server UUID, title, body, and formatted `created_at`. Pagination requests use the configured API base URL, not the collection's localhost pagination links.

The Home badge refreshes on Home loading/pull-to-refresh and existing notification-refresh events. Filter requests and session resets invalidate older responses. Failed refreshes retain cached items for the same filter; failed deletes retain the item. Successful deletes reload the first page and count so offset pagination does not skip an item. Guests are prompted to sign in. Only `is_clickable` notifications with a positive `coupon_id` open the live coupon-details route.

Read state is taken from each notification's `is_read` value when provided. The mark-all action uses `PATCH read-notifications`, while opening an unread clickable notification uses `PATCH read-notification/{id}`; local state is updated only after the server confirms success. Global settings initially load `profile.is_notify`; toggles stay disabled until preferences are loaded. APNs/Firebase delivery remains subject to the existing `externalSDKsEnabled` gate; this API integration does not enable external SDKs.

### Legacy services

`Core/AppServices.swift` currently sets both `isEnabled` and `externalSDKsEnabled` to `false`. The old Alamofire executor rejects requests while legacy services are disabled. The live LOH API client is independent of those switches.

## Current implementation status

| Feature | Observed implementation |
| --- | --- |
| Onboarding | Live intros service |
| Authentication and password recovery | Live LOH API services |
| Session restoration | Keychain token plus profile API |
| City and interest selection | Live API |
| Home, search, filters, offer details | Live API services |
| Favorites | In-memory set in `HomeViewModel` |
| Merchant details and follows | `LOHMerchantService`: `GET store/{id}` and `POST store/{id}/toggle-follow` |
| Recent searches | In-memory history |
| Checkout and payment results | `POST create-new-order`; server-confirmed completion |
| Usage codes after checkout | Live My Purchases; create-order returns no code or order ID |
| Purchases | Live list/filter/pagination/details/code requests; nested details mapped to the supplied response |
| Account profile | Live profile loading, localized birthdates, multipart updates/photo upload, API cities and city selection |
| More cashback balance | Authenticated `GET cash-back`, showing `data.total` |
| Payment cards | Live listing, add, rename, default selection, and removal; only masked metadata retained |
| Merchant joining | Live `join-us`, immediate phone input, 9–10 digit validation, and field errors |
| Notification inbox | Live listing, server filters, pagination, count, individual/all deletion, and clickable coupon routing |
| Notification preferences | Live `notification-settings` and `switch-notify` |
| Settings | Live password/language changes, account deletion, and plain-text/structured about/terms/privacy/security content |
| Customer support tickets | Live ticket types, paginated status-filtered list, details and creation; existing replies displayed with a presentation-only composer |
| Transport orders and tracking | Legacy code retained; legacy service gate disabled |

The collection provides potential integration references for several preview features. Each integration still requires checking its request fields, response shapes, authentication requirements, and intended environment.

## Design and localization conventions

- `Shared/Helpers/AppTheme.swift` defines semantic colors, spacing, radii, and common dimensions.
- `Shared/Resourses/AppFont.swift` centralizes typography.
- `Shared/Resourses/LOHAsset.swift` and the asset catalog provide reusable visual assets.
- `Shared/Localization/Language.swift` manages Arabic/English selection, system-language refresh, locale, and layout direction.
- Translations live under `Shared/Localization/Strings/en.lproj/` and `ar.lproj/`.
- Reuse shared controls and semantic tokens when extending screens.
- Format view code with four-space indentation and one SwiftUI modifier per line. Expand view-builder, action, and control-flow blocks; keep short value expressions such as `.black.opacity(0.1)` together. The root `.swift-format` configuration preserves these line breaks and disables code-rewriting rules. Run `xcrun swift-format format --in-place <view-file.swift>` when editing a view.

## Tests and verification

Tests are organized as standalone Swift executables compiled by Python runners, rather than relying solely on an Xcode test target. Some runners also verify localization and asset metadata.

Run from the repository root:

```sh
python3 Tests/Structure/run.py
python3 Tests/API/run.py
python3 Tests/HomeCycle/run.py
python3 Tests/Checkout/run.py
python3 Tests/Purchases/run.py
python3 Tests/PasswordRecovery/run.py
python3 Tests/MoreCycle/run.py
```

These cover screen folder structure, API request/response behavior, sessions, onboarding, home models, localization, checkout requests and receipts, purchases, password recovery, and account state. Model tests do not establish full application or UI correctness.

`Tests/Purchases` uses the saved Postman coupon-list fixture and mocked HTTP to check both routes, bearer/language headers, `ended` filtering, pagination/retry, duplicate IDs, formatted prices, empty/error responses, detail-ID matching, server-code display eligibility, and stale filter/session responses. No live purchases or redemptions are created by these tests.

`Tests/MoreCycle/AccountLifecycleTests.swift` verifies both authenticated deletion routes with controlled HTTP responses, including empty request bodies, language headers, retry after failure, duplicate deletion, successful credential cleanup, and late responses after switching accounts. These checks do not delete or sign out a live account.

`Tests/MoreCycle/NotificationTests.swift` exercises all seven notification requests, saved Postman fixtures, both response envelopes, pagination retry/deduplication, deletion failures and reloads, preference responses, guest access, cancellation, and stale filter/session responses. HTTP is mocked; these checks do not mutate live notifications.

`Tests/MoreCycle/AccountSettingsTests.swift` checks Join phone normalization and validation, multipart submission, password success/failure and secret clearing, language request encoding, all four public content routes, and live structured-content fixtures. Password changes and partnership submissions are tested with mocked HTTP rather than modifying a live account.

## Review scope

This analysis is based on source inspection, project configuration, dependency resolution metadata, test runners, and inspection of the supplied Postman collection. The Figma link is recorded as supplied. The original documentation pass was source-only. The account integration was subsequently verified with an iOS simulator build, mocked account/API tests, and localization checks. No live account mutations were performed.

### Offer checkout

Buy Offer opens order review, payment selection, processing, and success. The screens follow Figma frames `13:5116`, `13:5268`, `13:5793`, and `13:5882`, using native navigation titles, fixed step indicators, pinned review/payment actions, and the existing local assets. Step connectors share the circles’ vertical center, independent of label size. Review/payment use bordered cards with consistent insets, a larger offer image, aligned availability, separate metadata rows, and a distinct quantity/price area. Payment's `HomePaymentOfferCard` has a larger bordered image, merchant navigation, offer/location information, quantity, and a separate tinted total section. Review and payment own separate view models; processing owns the asynchronous submission. Real address/time metadata replaces preview labels, and decimal line totals include the coupon service fee and authoritative total price for the selected quantity. Saved cards load through the shared payment-card service and can be selected or deselected; adding a card refreshes the list. Credit cards use one payment option without a Visa/Mastercard segmented selector. The generic card option retains the API's `visa` default; a selected saved card supplies its brand (`visa`, `master`, or `mada`). Deselecting a saved card or choosing a general payment option clears that card's brand. No sample cashback balance is displayed.

`LOHCheckoutService` sends authenticated multipart `POST create-new-order` with exactly `amount` (quantity), `coupon_id`, and `payment_type`. Supported backend values are `visa`, `master`, `mada`, `stcpay`, `applepay`, and `cashback`; the Figma screen exposes Apple Pay, mada, credit cards, and cashback. The owner explicitly requested omitting `pay_data`. This does not invoke a separate payment gateway or transmit a saved-card ID. The owner’s 2026-10-27 response includes `data.order_id` and `data.offers`, decoded as `HomeCreatedOrderData` with the shared `PurchaseDetail`/`PurchaseVoucherCode` models. `HomePaymentSuccessView` displays every returned purchased voucher. The offer card follows the owner’s compact reference (Figma `6:3204`): merchant, offer image/name, paid amount/currency, location beneath the price, a pale-green usage-code panel with Copy, and an outlined full-code button. Receipt metadata and status remain decoded without adding rows or a badge to this card. Repeated order totals are never summed or multiplied by the selected quantity. Each Show full code action routes to `PurchaseCodeView` using the purchased-voucher ID (916 in the supplied response), which refreshes its current availability and QR data. Inactive/used/ended vouchers cannot display or copy a code. Duplicate voucher IDs, mismatched order IDs, and unrelated catalog coupon IDs are rejected. The earlier message-only success remains supported and links to My Purchases when no vouchers were returned.

Submission happens once per attempt; reappearance and repeated taps do not replay it. A timeout or uncertain response offers My Purchases before another attempt. Session changes discard late results. Successful checkout removes review/payment routes from the stack and resets the purchase cache. The old two-second simulated success transition is removed from the app flow. Explicit preview receipts remain isolated and non-redeemable. `create-new-order` uses the standard DEBUG request/response console logs; it is no longer hidden by the request's `sensitive` flag. `Tests/Checkout/run.py` covers the exact multipart request, visible DEBUG logs, both message-only and nested offer responses, multiple vouchers, authoritative paid amounts, code availability, mismatched IDs, pricing/quantity bounds, general/saved-card selection, duplicate submissions, errors, missing sessions, stale results, and local asset dimensions using mocked networking.

Home’s header includes a favorites button beside notifications. `HomeFavoritesView` loads all pages of `GET favorites` and renders the saved count and two-column reference cards without category filters or sorting controls. It uses coupon photos, store logos, names, currency, and available discount/distance data; missing details and unchanged original prices are omitted. The shared model prevents duplicate per-coupon mutations, keeps confirmed state on failure, discards old-session responses, and refreshes a list that overlapped a completed mutation. Guests can sign in from the favorites screen or heart action. The endpoint contract is taken from `NewLoh.postman_collection-2.json` and the owner’s supplied favorites/toggle response samples.

Customer support uses `ticket-types`, `my-tickets?status=all|open|in_progress|closed&page=…`, `my-tickets/{id}`, `send-ticket`, and `my-tickets/{id}/reply`. Ticket routes use numeric server IDs and success screens use the returned ticket reference and status. Ticket details show the related order, current status, and customer/support bubbles from the existing detail response; the submitted description is shown when no messages are returned. The ticket's `can_user_reply` controls the reply composer. Replies use the documented `replay` field, retain the draft on failure, and refresh the conversation after success. Standalone chat and conversation pagination remain removed. Client close-ticket UI is absent because the collection has no customer close endpoint. Supplied response fixtures live in `Tests/MoreCycle/Fixtures`.

### Guest mode
- Choosing Continue as guest clears credentials and persists guest browsing for the next launch. Accepting a login session or signing out clears that preference.
- Home, search, offer/merchant details, local city selection, language and public app documents remain accessible. Purchases uses the Figma `purchases-guest` state.
- Favorites, notifications, checkout, profile/payment/security changes, partnership submissions and support tickets require sign-in; protected navigation presents the shared `offer-login-sheet` prompt before loading account data.
- Successful sign-in/registration returns to the requested screen. Choosing Continue as guest clears that destination and always opens Home. No purchase, favorite, follow or submission is replayed automatically. The guest account screen hides personal statistics and logout.
