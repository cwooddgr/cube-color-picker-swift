import XCTest
@testable import CubeColorPicker

final class DebugToggleTests: XCTestCase {

    override func tearDown() {
        // Restore the default so the toggle cannot leak into other
        // tests run in the same process.
        CubeColorPickerDebug.solidFaces = false
        super.tearDown()
    }

    func testSolidFacesDefaultsToFalse() {
        XCTAssertFalse(CubeColorPickerDebug.solidFaces)
    }

    func testSolidFacesIsSettable() {
        CubeColorPickerDebug.solidFaces = true
        XCTAssertTrue(CubeColorPickerDebug.solidFaces)

        CubeColorPickerDebug.solidFaces = false
        XCTAssertFalse(CubeColorPickerDebug.solidFaces)
    }

    func testTearDownRestoresDefault() {
        // Flip it; tearDown should set it back for the next test.
        CubeColorPickerDebug.solidFaces = true
        XCTAssertTrue(CubeColorPickerDebug.solidFaces)
    }
}
