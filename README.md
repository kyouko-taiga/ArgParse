# ArgParse

[![Build Status](https://travis-ci.org/kyouko-taiga/ArgParse.svg?branch=master)](https://travis-ci.org/kyouko-taiga/ArgParse)

Pure Swift utility for command-line options and arguments,
inspired by Python's [argpase](https://docs.python.org/3/library/argparse.html) module.

## Usage example

The following code is a Swift program that takes a list of integers
and filters out the even numbers unless asked otherwise.

```swift
import ArgParse

let parser: ArgumentParser = [
  .variadic("elements", defaultValue: [Int]()),
  .flag("keep-even", alias: "-e"),
]

if let parseResult = try? parser.parse(CommandLine.arguments) {
  let elements: [Int] = parseResult.result(for: "elements")!
  let keepEven: Bool = parseResult.result(for: "keep-even")!
  print(elements.filter { $0 % 2 != 0 || keepEven })
}
```
