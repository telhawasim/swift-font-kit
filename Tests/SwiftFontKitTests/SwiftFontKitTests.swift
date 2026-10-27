import XCTest
import Foundation
@testable import SwiftFontKit

final class SwiftFontKitTests: XCTestCase {

    func testGoogleFontRequest() {
        let request = FontRequest.google("Inter", weight: .bold, style: .italic)

        XCTAssertEqual(request.source, .google("Inter"))
        XCTAssertEqual(request.weight, .bold)
        XCTAssertEqual(request.style, .italic)
    }

    func testGoogleSpecimenURL() throws {
        let url = try XCTUnwrap(
            URL(string: "https://fonts.google.com/specimen/Inter")
        )

        let request = try FontRequest.specimen(url, weight: .semibold)

        XCTAssertEqual(request.source, .google("Inter"))
        XCTAssertEqual(request.weight, .semibold)
    }

    func testInvalidSpecimenURL() throws {
        let url = try XCTUnwrap(
            URL(string: "https://example.com/specimen/Inter")
        )

        XCTAssertThrowsError(try FontRequest.specimen(url))
    }

    func testSupportedFontSignature() {
        let trueType = Data([
            0x00, 0x01, 0x00, 0x00
        ])

        let openType = Data("OTTO".utf8)
        let html = Data("<html>".utf8)

        XCTAssertTrue(FontSignature.isSupported(trueType))
        XCTAssertTrue(FontSignature.isSupported(openType))
        XCTAssertFalse(FontSignature.isSupported(html))
        XCTAssertFalse(FontSignature.isSupported(Data()))
    }

    func testCacheRoundTrip() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let cache = FontDiskCache(rootDirectory: directory)
        let request = FontRequest.google("Inter")

        let url = try XCTUnwrap(
            URL(string: "https://example.com/Inter-Regular.ttf")
        )

        let asset = FontAsset(
            remoteURL: url,
            filename: "Inter-Regular.ttf"
        )

        let data = Data([
            0x00, 0x01, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00
        ])

        let storedURL = try cache.store(
            request: request,
            asset: asset,
            data: data
        )

        let cachedURL = try XCTUnwrap(
            cache.cachedFile(for: request)
        )

        XCTAssertEqual(storedURL, cachedURL)
        XCTAssertEqual(try Data(contentsOf: cachedURL), data)
    }

    func testCorruptedCacheIsRejected() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)

        defer {
            try? FileManager.default.removeItem(at: directory)
        }

        let cache = FontDiskCache(rootDirectory: directory)
        let request = FontRequest.google("Roboto")

        let url = try XCTUnwrap(
            URL(string: "https://example.com/Roboto-Regular.ttf")
        )

        let stored = try cache.store(
            request: request,
            asset: FontAsset(
                remoteURL: url,
                filename: "Roboto-Regular.ttf"
            ),
            data: Data([0x00, 0x01, 0x00, 0x00])
        )

        try Data("corrupted".utf8).write(to: stored)

        XCTAssertNil(cache.cachedFile(for: request))
    }

    func testCatalogResolvesStaticWeight() async throws {
        let catalog = GoogleFontGithubCatalog(
            transport: MockCatalogTransport()
        )

        let asset = try await catalog.resolve(
            family: "Poppins",
            weight: .bold,
            style: .normal
        )

        XCTAssertEqual(asset.filename, "Poppins-Bold.ttf")
    }

    func testMissingCatalogVariantThrows() async throws {
        let catalog = GoogleFontGithubCatalog(
            transport: MockCatalogTransport()
        )

        do {
            _ = try await catalog.resolve(
                family: "Poppins",
                weight: .black,
                style: .italic
            )

            XCTFail("Expected unavailable variant error")
        } catch FontKitError.variantUnavailable {
            // Expected.
        }
    }
}

private struct MockCatalogTransport: FontTransport {
    func get(
        _ url: URL,
        maximumBytes: Int
    ) async throws -> Data {
        let json = """
        [
          {
            "name": "Poppins-Regular.ttf",
            "type": "file",
            "download_url": "https://raw.githubusercontent.com/google/fonts/main/ofl/poppins/Poppins-Regular.ttf"
          },
          {
            "name": "Poppins-Bold.ttf",
            "type": "file",
            "download_url": "https://raw.githubusercontent.com/google/fonts/main/ofl/poppins/Poppins-Bold.ttf"
          }
        ]
        """

        return Data(json.utf8)
    }
}
