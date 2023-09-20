import XCTest
@testable import People

final class PostalAddressTests: XCTestCase {
    func testID() throws {
        XCTAssertEqual("123 Main, NY, NY, USA", PostalAddressValue(
            street: "123 Main",
            subLocality: "",
            city: "NY",
            state: "NY",
            postalCode: "",
            country: "USA"
        ).id)
    }
    func formattedCityState() throws {
        XCTAssertEqual("New York, NY", PostalAddressValue(
            street: "123 Main",
            subLocality: "Somewhere",
            city: "New York",
            state: "NY",
            postalCode: "12345",
            country: "USA"
        ).id)
        XCTAssertEqual("CA", PostalAddressValue(
            street: "123 Main",
            subLocality: "",
            city: "Sacramento",
            state: "CA",
            postalCode: "12345",
            country: "USA"
        ).id)
        XCTAssertEqual("Madison", PostalAddressValue(
            street: "123 Main",
            subLocality: "Somewhere",
            city: "Madison",
            state: "Wisconsin",
            postalCode: "12345",
            country: "USA"
        ).id)
    }
}
