import XCTest

final class TDIInteractionUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testThreeDistinctPhysicalHolds() throws {
        let app = XCUIApplication()
        app.launch()

        let signature = app.staticTexts["tdiVariantSignature"]
        let releases = app.staticTexts["tdiReleaseCounter"]
        let next = app.buttons["tdiNextHypothesis"]
        XCTAssertTrue(signature.waitForExistence(timeout: 25))
        for (index, code) in ["SYSTEM", "LENS", "MEMBRANE"].enumerated() {
            let expected = "\(index + 1)/3|\(code)|NEUTRAL|HOLD-1.2"
            XCTAssertEqual(signature.label, expected)
            let button = app.buttons["tdi\(code)Button"]
            XCTAssertTrue(button.waitForExistence(timeout: 8))
            XCTAssertEqual(button.label, "START")
            XCTAssertEqual(button.value as? String, "\(code)|NEUTRAL|GLASS")
            XCTAssertEqual(releases.label, "RELEASES 0")
            Thread.sleep(forTimeInterval: 1.0)
            button.press(forDuration: 1.2)
            XCTAssertEqual(releases.label, "RELEASES 1")
            Thread.sleep(forTimeInterval: 0.9)
            if index < 2 { next.tap() }
        }
        XCTAssertEqual(signature.label, "3/3|MEMBRANE|NEUTRAL|HOLD-1.2")
    }
}
