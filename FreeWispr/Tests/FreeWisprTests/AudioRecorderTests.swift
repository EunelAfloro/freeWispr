import XCTest
@testable import FreeWisprCore

final class AudioRecorderTests: XCTestCase {

    func testInitialState() {
        let recorder = AudioRecorder()
        XCTAssertFalse(recorder.isRecording)
    }
}
