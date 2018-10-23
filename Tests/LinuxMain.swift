import XCTest

import ArgParseTests

var tests = [XCTestCaseEntry]()
tests += ArgParseTests.__allTests()

XCTMain(tests)
