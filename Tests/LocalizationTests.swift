import Foundation
import Testing
@testable import Closeout

struct LocalizationTests {
    private func table(_ language: String) throws -> [String: String] {
        let path = try #require(Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: language))
        return try #require(NSDictionary(contentsOfFile: path) as? [String: String])
    }

    /// Words that legitimately stay identical in Vietnamese.
    private let sameInBothLanguages: Set<String> = ["Email", "Closeout Pro"]

    @Test func everyEnglishKeyHasVietnamese() throws {
        let vi = try table("vi")
        let en = try table("en")
        #expect(!vi.isEmpty)
        // en has the plural key in a .stringsdict; every other key must exist in vi with a real translation.
        for (key, english) in en {
            let vietnamese = try #require(vi[key], "missing vi for \(key)")
            #expect(!vietnamese.isEmpty)
            if !sameInBothLanguages.contains(key) { #expect(vietnamese != english, "untranslated: \(key)") }
        }
        #expect(vi.count >= en.count)
    }

    @Test func vietnameseLookupWorks() throws {
        let path = try #require(Bundle.main.path(forResource: "vi", ofType: "lproj"))
        let bundle = try #require(Bundle(path: path))
        #expect(String(localized: "Jobs", bundle: bundle) == "Công việc")
        #expect(String(localized: "Preview report", bundle: bundle) == "Xem trước báo cáo")
        #expect(String(localized: "+\(3) more", bundle: bundle) == "+3 mục khác")
    }

    @Test func infoPlistStringsCoverCameraPurpose() throws {
        let path = try #require(Bundle.main.path(forResource: "vi", ofType: "lproj"))
        let bundle = try #require(Bundle(path: path))
        let text = bundle.localizedString(forKey: "NSCameraUsageDescription", value: nil, table: "InfoPlist")
        #expect(text.contains("camera"))
    }
}
