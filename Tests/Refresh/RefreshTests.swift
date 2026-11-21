import Foundation

@main
struct RefreshTests {
    @MainActor
    static func main() async {
        let controller = AppRefreshController()
        var started = false
        var completed = false
        let caller = Task {
            await controller.refresh {
                started = true
                do {
                    try await Task.sleep(nanoseconds: 100_000_000)
                    completed = true
                } catch {}
            }
        }
        while !started { await Task.yield() }
        caller.cancel()
        await caller.value
        precondition(completed, "Canceling SwiftUI's refresh task must not cancel the screen's request")

        started = false
        completed = false
        let leaving = Task {
            await controller.refresh {
                started = true
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    completed = true
                } catch {}
            }
        }
        while !started { await Task.yield() }
        controller.cancel()
        await leaving.value
        precondition(!completed, "Leaving the screen must cancel the refresh")
        print("PASS: refresh survives caller cancellation and stops when the screen disappears")
    }
}
