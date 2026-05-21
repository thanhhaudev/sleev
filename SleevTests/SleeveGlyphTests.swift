import AppKit
@testable import Sleev
import XCTest

final class SleeveGlyphTests: XCTestCase {
    func test_allElements_matchesWrappedNaturalSize() {
        let full = SleeveGlyph.naturalSize(
            forHeight: 14, showsPill: true, showsDots: true, showsChevron: true
        )
        let wrapped = SleeveGlyph.naturalSize(forHeight: 14, wrapped: true)
        XCTAssertEqual(full.width, wrapped.width)
        XCTAssertEqual(full.height, wrapped.height)
    }

    func test_pill_addsPadding() {
        let withPill = SleeveGlyph.naturalSize(
            forHeight: 14, showsPill: true, showsDots: true, showsChevron: true
        )
        let withoutPill = SleeveGlyph.naturalSize(
            forHeight: 14, showsPill: false, showsDots: true, showsChevron: true
        )
        XCTAssertEqual(withPill.width, withoutPill.width + 14)
        XCTAssertEqual(withPill.height, withoutPill.height + 4)
    }

    func test_fewerElements_areNarrower() {
        let both = SleeveGlyph.naturalSize(
            forHeight: 14, showsPill: false, showsDots: true, showsChevron: true
        )
        let dotsOnly = SleeveGlyph.naturalSize(
            forHeight: 14, showsPill: false, showsDots: true, showsChevron: false
        )
        let chevronOnly = SleeveGlyph.naturalSize(
            forHeight: 14, showsPill: false, showsDots: false, showsChevron: true
        )
        XCTAssertLessThan(dotsOnly.width, both.width)
        XCTAssertLessThan(chevronOnly.width, dotsOnly.width)
    }

    func test_noGlyphElements_stillHasPositiveWidth() {
        let pillOnly = SleeveGlyph.naturalSize(
            forHeight: 14, showsPill: true, showsDots: false, showsChevron: false
        )
        XCTAssertGreaterThan(pillOnly.width, 0)
    }
}
