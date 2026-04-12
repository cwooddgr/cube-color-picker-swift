import XCTest
@testable import CubeColorPicker

final class ProjectionTests: XCTestCase {

    let scale: Double = 100.0
    let center = Vec2(x: 150, y: 150)

    // MARK: - project()

    func testProjectOrigin() {
        let result = project(Vec3(x: 0, y: 0, z: 0), scale: scale, center: center)
        XCTAssertEqual(result.x, center.x, accuracy: 0.001)
        XCTAssertEqual(result.y, center.y, accuracy: 0.001)
    }

    func testProjectXAxis() {
        // Moving along +x should go right and slightly down (isometric)
        let result = project(Vec3(x: 1, y: 0, z: 0), scale: scale, center: center)
        XCTAssertGreaterThan(result.x, center.x)
        XCTAssertGreaterThan(result.y, center.y) // y increases downward, +x goes "down-right"
    }

    func testProjectYAxis() {
        // Moving along +y should go left and slightly down
        let result = project(Vec3(x: 0, y: 1, z: 0), scale: scale, center: center)
        XCTAssertLessThan(result.x, center.x)
        XCTAssertGreaterThan(result.y, center.y)
    }

    func testProjectZAxis() {
        // Moving along +z should go straight up
        let result = project(Vec3(x: 0, y: 0, z: 1), scale: scale, center: center)
        XCTAssertEqual(result.x, center.x, accuracy: 0.001)
        XCTAssertLessThan(result.y, center.y) // y decreases = upward
    }

    func testProjectSymmetry() {
        // Projecting (1,0,0) and (0,1,0) should be symmetric about the vertical axis
        let px = project(Vec3(x: 1, y: 0, z: 0), scale: scale, center: center)
        let py = project(Vec3(x: 0, y: 1, z: 0), scale: scale, center: center)
        XCTAssertEqual(px.x - center.x, -(py.x - center.x), accuracy: 0.001)
        XCTAssertEqual(px.y, py.y, accuracy: 0.001)
    }

    // MARK: - cubeVertices()

    func testCubeVerticesCount() {
        let verts = cubeVertices(extent: Vec3(x: 1, y: 1, z: 1))
        XCTAssertEqual(verts.count, 8)
    }

    func testCubeVerticesOrigin() {
        let verts = cubeVertices(extent: Vec3(x: 1, y: 1, z: 1))
        XCTAssertEqual(verts[0].x, 0)
        XCTAssertEqual(verts[0].y, 0)
        XCTAssertEqual(verts[0].z, 0)
    }

    func testCubeVerticesFarCorner() {
        let verts = cubeVertices(extent: Vec3(x: 0.5, y: 0.7, z: 0.3))
        XCTAssertEqual(verts[7].x, 0.5, accuracy: 0.001)
        XCTAssertEqual(verts[7].y, 0.7, accuracy: 0.001)
        XCTAssertEqual(verts[7].z, 0.3, accuracy: 0.001)
    }

    // MARK: - getAxisHandlePos()

    func testGetAxisHandlePos() {
        let ext = Vec3(x: 0.8, y: 0.6, z: 0.4)
        for i in 0..<3 {
            let handlePos = getAxisHandlePos(axisIndex: i, cubeExtent: ext, scale: scale, center: center)
            var expectedVec = Vec3(x: 0, y: 0, z: 0)
            expectedVec[i] = ext[i]
            let expected = project(expectedVec, scale: scale, center: center)
            XCTAssertEqual(handlePos.x, expected.x, accuracy: 0.001)
            XCTAssertEqual(handlePos.y, expected.y, accuracy: 0.001)
        }
    }

    // MARK: - getAxisDirections()

    func testAxisDirectionsAreNormalized() {
        let dirs = getAxisDirections()
        for dir in dirs {
            let len = sqrt(dir.x * dir.x + dir.y * dir.y)
            XCTAssertEqual(len, 1.0, accuracy: 0.001)
        }
    }

    // MARK: - faceHitTest()

    func testFaceHitTestCenter() {
        // Project the center of the top face (face 0)
        let ext = Vec3(x: 1, y: 1, z: 1)
        // Top face center: z=1 fixed, x=0.5, y=0.5
        let faceCenterPt = project(Vec3(x: 0.5, y: 0.5, z: 1), scale: scale, center: center)
        let hit = faceHitTest(faceIndex: 0, point: faceCenterPt, cubeExtent: ext, scale: scale, center: center)
        XCTAssertNotNil(hit)
        XCTAssertEqual(hit!.s, 0.5, accuracy: 0.05)
        XCTAssertEqual(hit!.t, 0.5, accuracy: 0.05)
    }

    func testFaceHitTestMiss() {
        let ext = Vec3(x: 1, y: 1, z: 1)
        // Point far from the cube
        let farPoint = Vec2(x: 0, y: 0)
        let hit = faceHitTest(faceIndex: 0, point: farPoint, cubeExtent: ext, scale: scale, center: center)
        XCTAssertNil(hit)
    }

    func testFaceHitTestDegenerate() {
        // Face with near-zero extent should return nil
        let ext = Vec3(x: 0.001, y: 0.001, z: 1)
        let pt = project(Vec3(x: 0, y: 0, z: 1), scale: scale, center: center)
        let hit = faceHitTest(faceIndex: 0, point: pt, cubeExtent: ext, scale: scale, center: center)
        XCTAssertNil(hit)
    }

    // MARK: - faceHitTestUnclamped()

    func testFaceHitTestUnclampedAlwaysReturns() {
        let ext = Vec3(x: 1, y: 1, z: 1)
        // Point outside face but unclamped should still return clamped result
        let farPoint = project(Vec3(x: 2, y: 2, z: 1), scale: scale, center: center)
        let hit = faceHitTestUnclamped(faceIndex: 0, point: farPoint, cubeExtent: ext, scale: scale, center: center)
        XCTAssertNotNil(hit)
        // Values should be clamped to [0, 1]
        XCTAssertGreaterThanOrEqual(hit!.s, 0)
        XCTAssertLessThanOrEqual(hit!.s, 1)
        XCTAssertGreaterThanOrEqual(hit!.t, 0)
        XCTAssertLessThanOrEqual(hit!.t, 1)
    }

    // MARK: - FACES constant

    func testFacesCount() {
        XCTAssertEqual(FACES.count, 3)
    }

    func testFacesAxes() {
        // Top face: z fixed
        XCTAssertEqual(FACES[0].fixedAxis, 2)
        XCTAssertEqual(FACES[0].uAxis, 0)
        XCTAssertEqual(FACES[0].vAxis, 1)

        // Right face: x fixed
        XCTAssertEqual(FACES[1].fixedAxis, 0)
        XCTAssertEqual(FACES[1].uAxis, 1)
        XCTAssertEqual(FACES[1].vAxis, 2)

        // Left face: y fixed
        XCTAssertEqual(FACES[2].fixedAxis, 1)
        XCTAssertEqual(FACES[2].uAxis, 0)
        XCTAssertEqual(FACES[2].vAxis, 2)
    }
}
