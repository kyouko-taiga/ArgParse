import XCTest

extension ArgParseTests {
    static let __allTests = [
        ("testFlag", testFlag),
        ("testMultipleArguments", testMultipleArguments),
        ("testNoArgument", testNoArgument),
        ("testOption", testOption),
        ("testOptionWithAlias", testOptionWithAlias),
        ("testOptionWithAutoConversion", testOptionWithAutoConversion),
        ("testOptionWithCustomConversion", testOptionWithCustomConversion),
        ("testOptionWithDefault", testOptionWithDefault),
        ("testPositional", testPositional),
        ("testPositionalWithAutoConversion", testPositionalWithAutoConversion),
        ("testPositionalWithCustomConversion", testPositionalWithCustomConversion),
        ("testPositionalWithDefault", testPositionalWithDefault),
        ("testPrintUsage", testPrintUsage),
        ("testRequiredOption", testRequiredOption),
        ("testRequiredPositional", testRequiredPositional),
        ("testVariadicOption", testVariadicOption),
        ("testVariadicOptionWithArity", testVariadicOptionWithArity),
        ("testVariadicPositional", testVariadicPositional),
        ("testVariadicPositionalWithArity", testVariadicPositionalWithArity),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(ArgParseTests.__allTests),
    ]
}
#endif
