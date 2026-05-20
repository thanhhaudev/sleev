@testable import Sleev
import XCTest

final class CollapseLengthCalculatorTests: XCTestCase {
    func test_collapseLengthIsBoundedByMinimum() {
        XCTAssertEqual(CollapseLengthCalculator.collapseLength(forScreenWidth: 100), 500)
    }

    func test_collapseLengthIsBoundedByMaximum() {
        XCTAssertEqual(CollapseLengthCalculator.collapseLength(forScreenWidth: 10000), 4000)
    }

    func test_collapseLengthUsesScreenWidthPlusBuffer() {
        XCTAssertEqual(CollapseLengthCalculator.collapseLength(forScreenWidth: 1728), 1928)
    }

    func test_visibleSeparatorLength() {
        XCTAssertEqual(CollapseLengthCalculator.visibleSeparatorLength, 8)
    }
}
