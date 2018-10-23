import XCTest
@testable import ArgParse

class ArgParseTests: XCTestCase {

  func testNoArgument() {
    let parser = ArgumentParser()

    // Should throw .emptyCommandLine
    XCTAssertThrowsError(try parser.parse([]))

    // Should produce an empty ParseResult.
    let parseResult = try? parser.parse(["program"])
    XCTAssertNotNil(parseResult)
    XCTAssert(parseResult!.isEmpty)

    // Should throw .unexpectedArgument
    XCTAssertThrowsError(try parser.parse(["program", "p0"]))
    XCTAssertThrowsError(try parser.parse(["program", "-o"]))
    XCTAssertThrowsError(try parser.parse(["program", "--option"]))
  }

  func testPositional() {
    let parser: ArgumentParser = [.positional("foo")]

    // Should produce an empty ParseResult.
    do {
      let parseResult = try? parser.parse(["program"])
      XCTAssertNotNil(parseResult)
      XCTAssert(parseResult!.isEmpty)
    }

    // Should produce `["foo": "bar"]`
    do {
      let parseResult = try? parser.parse(["program", "bar"])
      XCTAssertNotNil(parseResult)
      XCTAssertEqual(parseResult!.result(for: "foo"), "bar")
    }

    // Should throw .unexpectedArgument
    XCTAssertThrowsError(try parser.parse(["program", "bar", "baz"]))
    XCTAssertThrowsError(try parser.parse(["program", "bar", "-o"]))
    XCTAssertThrowsError(try parser.parse(["program", "bar", "--option"]))
  }

  func testRequiredPositional() {
    let parser: ArgumentParser = [.positional("foo", isRequired: true)]

    // Should throw .missingArguments
    XCTAssertThrowsError(try parser.parse(["program"]))

    // Should produce `["foo": "bar"]`
    do {
      let parseResult = try? parser.parse(["program", "bar"])
      XCTAssertNotNil(parseResult)
      XCTAssertEqual(parseResult!.result(for: "foo"), "bar")
    }
  }

  func testVariadicPositional() {
    let parser: ArgumentParser = [.variadic("foo")]

    // Should produce an empty ParseResult.
    do {
      let parseResult = try? parser.parse(["program"])
      XCTAssertNotNil(parseResult)
      XCTAssert(parseResult!.isEmpty)
    }

    // Should produce `["foo": ["bar"]]`
    do {
      let parseResult = try? parser.parse(["program", "bar"])
      XCTAssertNotNil(parseResult)
      let foo: [String]? = parseResult!.result(for: "foo")
      XCTAssertNotNil(foo)
      XCTAssertEqual(foo!, ["bar"])
    }

    // Should produce `["foo": ["bar", "baz", "qux"]]`
    do {
      let parseResult = try? parser.parse(["program", "bar", "baz", "qux"])
      XCTAssertNotNil(parseResult)
      let foo: [String]? = parseResult!.result(for: "foo")
      XCTAssertNotNil(foo)
      XCTAssertEqual(foo!, ["bar", "baz", "qux"])
    }
  }

  func testVariadicPositionalWithArity() {
    let parser: ArgumentParser = [.variadic("foo", arity: 2...3)]

    // Should produce an empty ParseResult.
    do {
      let parseResult = try? parser.parse(["program"])
      XCTAssertNotNil(parseResult)
      XCTAssert(parseResult!.isEmpty)
    }

    // Should throw .invalidArity
    XCTAssertThrowsError(try parser.parse(["program", "bar"]))

    // Should produce `["foo": ["bar", "baz"]]`
    do {
      let parseResult = try? parser.parse(["program", "bar", "baz"])
      XCTAssertNotNil(parseResult)
      let foo: [String]? = parseResult!.result(for: "foo")
      XCTAssertNotNil(foo)
      XCTAssertEqual(foo!, ["bar", "baz"])
    }

    // Should produce `["foo": ["bar", "baz", "qux"]]`
    do {
      let parseResult = try? parser.parse(["program", "bar", "baz", "qux"])
      XCTAssertNotNil(parseResult)
      let foo: [String]? = parseResult!.result(for: "foo")
      XCTAssertNotNil(foo)
      XCTAssertEqual(foo!, ["bar", "baz", "qux"])
    }

    // Should throw .unexpectedArgument
    XCTAssertThrowsError(try parser.parse(["program", "program", "bar", "baz", "qux", "quux"]))
  }

  func testPositionalWithDefault() {
    let parser: ArgumentParser = [.positional("foo", defaultValue: "qux")]

    // Should produce `["foo": "bar"]`
    do {
      let parseResult = try? parser.parse(["program", "bar"])
      XCTAssertNotNil(parseResult)
      XCTAssertEqual(parseResult!.result(for: "foo"), "bar")
    }

    // Should produce `["foo": "qux"]`
    do {
      let parseResult = try? parser.parse(["program"])
      XCTAssertNotNil(parseResult)
      XCTAssertEqual(parseResult!.result(for: "foo"), "qux")
    }
  }

  func testPositionalWithAutoConversion() {
    let parser: ArgumentParser = [.positional("foo", defaultValue: 0)]

    // Should produce `["foo": 1]`
    do {
      let parseResult = try? parser.parse(["program", "1"])
      XCTAssertNotNil(parseResult)
      XCTAssertEqual(parseResult!.result(for: "foo"), 1)
    }

    // Should produce `["foo": 0]`
    do {
      let parseResult = try? parser.parse(["program"])
      XCTAssertNotNil(parseResult)
      XCTAssertEqual(parseResult!.result(for: "foo"), 0)
    }
  }

  func testPositionalWithCustomConversion() {
    let parser: ArgumentParser = [
      .positional("foo") { (val: String) -> CustomType in
        val == "foo" ? .foo : .bar
      }
    ]

    // Should produce `["foo": .foo]`
    do {
      let parseResult = try? parser.parse(["program", "foo"])
      XCTAssertNotNil(parseResult)
      XCTAssertEqual(parseResult!.result(for: "foo"), CustomType.foo)
    }
  }

  func testOption() {
    let parser: ArgumentParser = [.option("foo")]

    // Should produce an empty ParseResult.
    do {
      let parseResult = try? parser.parse(["program"])
      XCTAssertNotNil(parseResult)
      XCTAssert(parseResult!.isEmpty)
    }

    // Should produce `["foo": "bar"]`
    do {
      let parseResult = try? parser.parse(["program", "--foo", "bar"])
      XCTAssertNotNil(parseResult)
      XCTAssertEqual(parseResult!.result(for: "foo"), "bar")
    }

    // Should throw .unexpectedArgument
    XCTAssertThrowsError(try parser.parse(["program", "baz"]))
    XCTAssertThrowsError(try parser.parse(["program", "baz", "--foo", "bar"]))
    XCTAssertThrowsError(try parser.parse(["program", "--foo", "bar", "baz"]))

    // Should throw .invalidArity
    XCTAssertThrowsError(try parser.parse(["program", "--foo"]))
  }

  func testOptionWithAlias() {
    let parser: ArgumentParser = [.option("foo", alias: "f")]

    // Should produce `["foo": "bar"]`
    do {
      let parseResult = try? parser.parse(["program", "-f", "bar"])
      XCTAssertNotNil(parseResult)
      XCTAssertEqual(parseResult!.result(for: "foo"), "bar")
    }
  }

  func testRequiredOption() {
    let parser: ArgumentParser = [.option("foo", isRequired: true)]

    // Should throw .missingArguments
    XCTAssertThrowsError(try parser.parse(["program"]))

    // Should produce `["foo": "bar"]`
    do {
      let parseResult = try? parser.parse(["program", "--foo", "bar"])
      XCTAssertNotNil(parseResult)
      XCTAssertEqual(parseResult!.result(for: "foo"), "bar")
    }
  }

  func testVariadicOption() {
    let parser: ArgumentParser = [.variadicOption("foo")]

    // Should produce an empty ParseResult.
    do {
      let parseResult = try? parser.parse(["program"])
      XCTAssertNotNil(parseResult)
      XCTAssert(parseResult!.isEmpty)
    }

    // Should produce `["foo": ["bar"]]`
    do {
      let parseResult = try? parser.parse(["program", "--foo", "bar"])
      XCTAssertNotNil(parseResult)
      let foo: [String]? = parseResult!.result(for: "foo")
      XCTAssertNotNil(foo)
      XCTAssertEqual(foo!, ["bar"])
    }

    // Should produce `["foo": ["bar", "baz", "qux"]]`
    do {
      let parseResult = try? parser.parse(["program", "--foo", "bar", "baz", "qux"])
      XCTAssertNotNil(parseResult)
      let foo: [String]? = parseResult!.result(for: "foo")
      XCTAssertNotNil(foo)
      XCTAssertEqual(foo!, ["bar", "baz", "qux"])
    }
  }

  func testVariadicOptionWithArity() {
    let parser: ArgumentParser = [.variadicOption("foo", arity: 2...3)]

    // Should produce an empty ParseResult.
    do {
      let parseResult = try? parser.parse(["program"])
      XCTAssertNotNil(parseResult)
      XCTAssert(parseResult!.isEmpty)
    }

    // Should throw .invalidArity
    XCTAssertThrowsError(try parser.parse(["program", "--foo", "bar"]))

    // Should produce `["foo": ["bar", "baz"]]`
    do {
      let parseResult = try? parser.parse(["program", "--foo", "bar", "baz"])
      XCTAssertNotNil(parseResult)
      let foo: [String]? = parseResult!.result(for: "foo")
      XCTAssertNotNil(foo)
      XCTAssertEqual(foo!, ["bar", "baz"])
    }

    // Should produce `["foo": ["bar", "baz", "qux"]]`
    do {
      let parseResult = try? parser.parse(["program", "--foo", "bar", "baz", "qux"])
      XCTAssertNotNil(parseResult)
      let foo: [String]? = parseResult!.result(for: "foo")
      XCTAssertNotNil(foo)
      XCTAssertEqual(foo!, ["bar", "baz", "qux"])
    }

    // Should throw .unexpectedArgument
    XCTAssertThrowsError(try parser.parse(["program", "program", "--foo", "bar", "baz", "qux", "quux"]))
  }

  func testOptionWithDefault() {
    let parser: ArgumentParser = [.option("foo", defaultValue: "qux")]

    // Should produce `["foo": "bar"]`
    do {
      let parseResult = try? parser.parse(["program", "--foo", "bar"])
      XCTAssertNotNil(parseResult)
      XCTAssertEqual(parseResult!.result(for: "foo"), "bar")
    }

    // Should produce `["foo": "qux"]`
    do {
      let parseResult = try? parser.parse(["program"])
      XCTAssertNotNil(parseResult)
      XCTAssertEqual(parseResult!.result(for: "foo"), "qux")
    }
  }

  func testOptionWithAutoConversion() {
    let parser: ArgumentParser = [.option("foo", defaultValue: 0)]

    // Should produce `["foo": 1]`
    do {
      let parseResult = try? parser.parse(["program", "--foo", "1"])
      XCTAssertNotNil(parseResult)
      XCTAssertEqual(parseResult!.result(for: "foo"), 1)
    }

    // Should produce `["foo": 0]`
    do {
      let parseResult = try? parser.parse(["program"])
      XCTAssertNotNil(parseResult)
      XCTAssertEqual(parseResult!.result(for: "foo"), 0)
    }
  }

  func testOptionWithCustomConversion() {
    let parser: ArgumentParser = [
      .option("foo") { (val: String) -> CustomType in
        val == "foo" ? .foo : .bar
      }
    ]

    // Should produce `["foo": .foo]`
    do {
      let parseResult = try? parser.parse(["program", "--foo", "foo"])
      XCTAssertNotNil(parseResult)
      XCTAssertEqual(parseResult!.result(for: "foo"), CustomType.foo)
    }
  }

  func testFlag() {
    let parser: ArgumentParser = [.flag("foo")]

    // Should produce `["foo": true]`
    do {
      let parseResult = try? parser.parse(["program", "--foo"])
      XCTAssertNotNil(parseResult)
      XCTAssertEqual(parseResult!.result(for: "foo"), true)
    }

    // Should produce `["foo": false]`
    do {
      let parseResult = try? parser.parse(["program"])
      XCTAssertNotNil(parseResult)
      XCTAssertEqual(parseResult!.result(for: "foo"), false)
    }

    // Should throw .unexpectedArgument
    XCTAssertThrowsError(try parser.parse(["program", "--foo", "bar"]))
  }

  func testMultipleArguments() {
    let parser: ArgumentParser = [
      .variadic("inputs", isRequired: true),
      .option("output", alias: "o"),
      .flag("optimized", alias: "O"),
      ]

    // Should produce `["inputs": ["a", "b"], "output": "c", "optimized": true]`
    let lines = [
      "program -o c -O a b",
      "program -O -o c a b",
      "program -O a b -o c",
      "program a b -o c --optimized",
      "program a b --output c --optimized",
    ]
    for line in lines {
      let commandLine = line.split(separator: " ").map(String.init)
      let parseResult = try? parser.parse(commandLine)
      XCTAssertNotNil(parseResult)
      let inputs: [String]? = parseResult!.result(for: "inputs")
      XCTAssertNotNil(inputs)
      XCTAssertEqual(inputs!, ["a", "b"])
      XCTAssertEqual(parseResult!.result(for: "output"), "c")
      XCTAssertEqual(parseResult!.result(for: "optimized"), true)
    }

    // Should throw .missingArguments
    XCTAssertThrowsError(try parser.parse(["program", "-O"]))
  }

  func testPrintUsage() {
    let parser: ArgumentParser = [
      .variadic("inputs", isRequired: true, description: "The input files"),
      .option("output", alias: "o", description: "The output file"),
      .flag("optimized", alias: "O", description: "Enable optimizations"),
      ]

    var usage = ""
    parser.printUsage(to: &usage)
    XCTAssertFalse(usage.isEmpty)
  }

}

enum CustomType {

  case foo, bar

}
