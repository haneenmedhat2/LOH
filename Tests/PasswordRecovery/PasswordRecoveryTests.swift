import Foundation

@main
struct PasswordRecoveryTests {
    static func main() {
        let now = Date(timeIntervalSince1970: 1000)
        let model = PasswordRecoveryModel(previewEnabled: true)
        assert(!model.validPhone)
        model.phone = "٠٥٥١٢٣٤٥٦٧"
        assert(model.validPhone)
        model.sendCode(now: now)
        assert(model.step == .code && model.remainingSeconds(now: now) == 60)
        model.code = "9999"; model.verify(now: now)
        assert(model.step == .code && model.errorKey == "recovery.invalidCode")
        model.code = "١٢٣٤"; model.verify(now: now)
        assert(model.step == .password)
        model.password = "abcdef"; model.confirmation = "different"
        assert(!model.finish(now: now))
        model.confirmation = "abcdef"
        assert(model.finish(now: now))
        assert(model.password.isEmpty && model.confirmation.isEmpty && model.code.isEmpty)
        assert(!model.finish(now: now))
        model.back(); model.back(); model.sendCode(now: now)
        model.verify(now: now.addingTimeInterval(301))
        assert(model.errorKey == "recovery.expired")
        model.resend(now: now.addingTimeInterval(301))
        assert(model.errorKey == nil && model.remainingSeconds(now: now.addingTimeInterval(301)) == 60)
        model.code = "1234"; model.verify(now: now.addingTimeInterval(302))
        model.back(); assert(model.step == .code && model.code.isEmpty)
        assert(!model.finish(now: now.addingTimeInterval(303)))
        let live = PasswordRecoveryModel(previewEnabled: false)
        live.phone = "551234567"; live.sendCode(now: now)
        assert(live.step == .phone && live.errorKey == "recovery.unavailable")
        assert(AuthInput.normalizedDigits("+٩٦٦ ٥٥١٢٣٤٥٦٧") == "966551234567")
        print("PASS: recovery validation, invalid/expired OTP, resend cooldown, back navigation, password matching, clearing secrets and disabled service guard")
    }
}
