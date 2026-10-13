import XCTest
@testable import Insomnia

/// `DurationInput.digit(keyCode:characters:)`: what a key press enters into a
/// pill. The French AZERTY layout is the case that motivated it: its top row
/// types `& é " ' ( § è ! ç à` on a bare press, digits only with Shift.
final class DurationKeyTests: XCTestCase {
    /// ANSI key codes of the digit row, in the order the keys are printed.
    private let row: [UInt16] = [18, 19, 20, 21, 23, 22, 26, 28, 25, 29]
    /// What the French layout types for them on a bare press.
    private let frenchBare = ["&", "é", "\"", "'", "(", "§", "è", "!", "ç", "à"]

    func testFrenchBarePressOfTheDigitRowEntersTheDigit() {
        for (i, code) in row.enumerated() {
            let expected = (i + 1) % 10
            XCTAssertEqual(DurationInput.digit(keyCode: code, characters: frenchBare[i]), expected, "key code \(code)")
        }
    }

    func testShiftedPressStillEntersTheDigit() {
        XCTAssertEqual(DurationInput.digit(keyCode: 21, characters: "4"), 4)
        XCTAssertEqual(DurationInput.digit(keyCode: 29, characters: "0"), 0)
        // US layout, Shift held: the key types "$" but it is the 4 key.
        XCTAssertEqual(DurationInput.digit(keyCode: 21, characters: "$"), 4)
    }

    func testKeypadEntersTheDigit() {
        let keypad: [(UInt16, Int)] = [(82, 0), (83, 1), (84, 2), (85, 3), (86, 4), (87, 5), (88, 6), (89, 7), (91, 8), (92, 9)]
        for (code, digit) in keypad {
            XCTAssertEqual(DurationInput.digit(keyCode: code, characters: String(digit)), digit, "key code \(code)")
        }
    }

    func testTheRowCoversEveryDigitOnce() {
        let digits = row.compactMap { DurationInput.digit(keyCode: $0, characters: nil) }
        XCTAssertEqual(Set(digits), Set(0...9))
        XCTAssertEqual(digits.count, 10)
    }

    func testOtherKeysEnterNothingUnlessTheyTypeAnASCIIDigit() {
        XCTAssertNil(DurationInput.digit(keyCode: 0, characters: "a"))   // kVK_ANSI_A
        XCTAssertNil(DurationInput.digit(keyCode: 0, characters: "q"))   // the same key on AZERTY
        XCTAssertNil(DurationInput.digit(keyCode: 4, characters: "h"))   // the Hours shortcut
        XCTAssertNil(DurationInput.digit(keyCode: 36, characters: "\r")) // return
        XCTAssertNil(DurationInput.digit(keyCode: 0, characters: nil))
        XCTAssertNil(DurationInput.digit(keyCode: 0, characters: "12"))
        XCTAssertNil(DurationInput.digit(keyCode: 0, characters: "٤"))  // an Eastern Arabic digit, not ASCII
        // A key that is not on the row but types a digit (another layout, an input method) counts.
        XCTAssertEqual(DurationInput.digit(keyCode: 0, characters: "7"), 7)
    }
}
