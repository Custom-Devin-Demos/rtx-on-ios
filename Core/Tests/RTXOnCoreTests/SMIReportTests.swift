import XCTest
@testable import RTXOnCore

final class SMIReportTests: XCTestCase {
    private let sample = SMIReport(
        deviceName: "iPhone 16 Pro", systemVersion: "18.4", thermal: .nominal,
        memoryUsedBytes: 3_221_225_472, memoryTotalBytes: 8_589_934_592, cores: 6,
        uptime: 93_784, lowPower: false, campaignSolved: 12, campaignTotal: 30,
        dailyDay: 259, dailySolved: true, streak: 4,
        generatedAt: Date(timeIntervalSince1970: 1_700_000_000))

    func testEveryLineIsExactlyTableWidth() {
        for line in sample.tableLines where !line.isEmpty {
            XCTAssertEqual(line.count, SMIReport.width, line)
            XCTAssertTrue(line.hasPrefix("|") || line.hasPrefix("+"), line)
            XCTAssertTrue(line.hasSuffix("|") || line.hasSuffix("+"), line)
        }
    }

    func testDerivedValues() {
        XCTAssertEqual(sample.memoryUsedMiB, 3072)
        XCTAssertEqual(sample.memoryTotalMiB, 8192)
        XCTAssertEqual(sample.memoryPercent, 38)
        XCTAssertEqual(sample.uptimeLabel, "1d 2h")
        XCTAssertEqual(sample.perfState, "P0")
        XCTAssertEqual(sample.campaignPercent, 40)
        var eco = sample
        eco.lowPower = true
        eco.uptime = 3_725
        XCTAssertEqual(eco.perfState, "P8")
        XCTAssertEqual(eco.uptimeLabel, "1h 02m")
    }

    func testTextContainsKeyFacts() {
        let text = sample.text
        XCTAssertTrue(text.contains("iPhone 16 Pro"))
        XCTAssertTrue(text.contains("3072MiB / 8192MiB"))
        XCTAssertTrue(text.contains("RTX ON campaign 12/30"))
        XCTAssertTrue(text.contains("Daily #259 solved"))
        XCTAssertTrue(text.contains("Daily streak 4 days"))
        XCTAssertTrue(text.contains("Nominal"))
        print(text)
    }
}
