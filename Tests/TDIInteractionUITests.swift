import XCTest

final class TDIInteractionUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testFourDistinctPhysicalHolds() throws {
        let app = XCUIApplication()
        app.launch()

        let signature = app.staticTexts["tdiVariantSignature"]
        let releases = app.staticTexts["tdiReleaseCounter"]
        let next = app.buttons["tdiNextHypothesis"]
        XCTAssertTrue(signature.waitForExistence(timeout: 25), "Scenario signature not found")

        let scenarios = ["SYSTEM", "MORPH", "MEMBRANE", "OPTICAL_LIP"]
        var failures: [String] = []

        for (index, code) in scenarios.enumerated() {
            let expectedSignature = "\(index + 1)/\(scenarios.count)|\(code)|NEUTRAL|HOLD-1.2"
            if signature.label != expectedSignature {
                failures.append("\(code): signature \(signature.label) != \(expectedSignature)")
            }

            let button = app.buttons["tdi\(code)Button"]
            if button.waitForExistence(timeout: 8) {
                if button.label != "START" {
                    failures.append("\(code): label \(button.label)")
                }
                if (button.value as? String) != "\(code)|NEUTRAL|GLASS" {
                    failures.append("\(code): unexpected accessibility value")
                }
                if releases.label != "RELEASES 0" {
                    failures.append("\(code): counter was \(releases.label) before touch")
                }

                Thread.sleep(forTimeInterval: 0.8)
                print("TDI_STAGE \(code) HOLD_BEGIN unix=\(Date().timeIntervalSince1970)")
                button.press(forDuration: 1.2)
                print("TDI_STAGE \(code) HOLD_END unix=\(Date().timeIntervalSince1970)")

                let counterUpdated = XCTNSPredicateExpectation(
                    predicate: NSPredicate(format: "label == %@", "RELEASES 1"),
                    object: releases
                )
                let updateResult = XCTWaiter.wait(for: [counterUpdated], timeout: 2.0)
                if updateResult != .completed {
                    failures.append("\(code): expected RELEASES 1, got \(releases.label)")
                    XCTContext.runActivity(named: "\(code) action missing") { _ in }
                }
                Thread.sleep(forTimeInterval: 0.8)
            } else {
                failures.append("\(code): START button not found")
            }

            if index < scenarios.count - 1 {
                if next.waitForExistence(timeout: 5) && next.isEnabled {
                    next.tap()
                } else {
                    failures.append("\(code): cannot advance to next scenario")
                    break
                }
            }
        }

        let report = failures.joined(separator: "; ")
        XCTAssertTrue(failures.isEmpty, "TDI gesture failures: \(report)")
    }
}
