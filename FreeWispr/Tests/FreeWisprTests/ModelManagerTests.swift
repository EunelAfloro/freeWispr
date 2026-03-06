import XCTest
@testable import FreeWispr

@MainActor
final class ModelManagerTests: XCTestCase {

    func testModelURLGeneration() {
        let manager = ModelManager()
        let url = manager.downloadURL(for: .base)
        XCTAssertEqual(
            url.absoluteString,
            "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin"
        )
    }

    func testModelLocalPath() {
        let manager = ModelManager()
        let path = manager.localModelPath(for: .base)
        XCTAssertTrue(path.path.contains("FreeWispr"))
        XCTAssertTrue(path.path.hasSuffix("ggml-base.bin"))
    }

    func testAllModelSizes() {
        let manager = ModelManager()
        for size in ModelSize.allCases {
            let url = manager.downloadURL(for: size)
            XCTAssertTrue(url.absoluteString.contains("ggml-\(size.rawValue).bin"))
        }
    }
}
