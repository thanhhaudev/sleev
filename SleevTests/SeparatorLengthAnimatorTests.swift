@testable import Sleev
import XCTest

final class SeparatorLengthAnimatorTests: XCTestCase {
    func test_interpolate_atProgressZero_returnsFrom() {
        XCTAssertEqual(
            LengthInterpolation.interpolate(from: 8, to: 1928, progress: 0),
            8,
            accuracy: 0.001
        )
    }

    func test_interpolate_atProgressOne_returnsTo() {
        XCTAssertEqual(
            LengthInterpolation.interpolate(from: 8, to: 1928, progress: 1),
            1928,
            accuracy: 0.001
        )
    }

    func test_interpolate_atProgressHalf_returnsGeometricMidpoint() {
        // smoothstep(0.5) = 0.5 * 0.5 * (3 - 1) = 0.5, so progress 0.5 maps
        // to the geometric midpoint: 8 + (1928 - 8) * 0.5 = 968.
        XCTAssertEqual(
            LengthInterpolation.interpolate(from: 8, to: 1928, progress: 0.5),
            968,
            accuracy: 0.001
        )
    }

    func test_interpolate_appliesEaseInCurve() {
        // smoothstep(0.25) = 0.25 * 0.25 * (3 - 0.5) = 0.15625
        // 8 + (1928 - 8) * 0.15625 = 8 + 300 = 308.
        XCTAssertEqual(
            LengthInterpolation.interpolate(from: 8, to: 1928, progress: 0.25),
            308,
            accuracy: 0.001
        )
    }

    func test_interpolate_belowZeroProgress_clampsToFrom() {
        XCTAssertEqual(
            LengthInterpolation.interpolate(from: 8, to: 1928, progress: -0.5),
            8,
            accuracy: 0.001
        )
    }

    func test_interpolate_aboveOneProgress_clampsToTo() {
        XCTAssertEqual(
            LengthInterpolation.interpolate(from: 8, to: 1928, progress: 1.5),
            1928,
            accuracy: 0.001
        )
    }
}
