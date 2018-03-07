public struct ArgumentParser {

    public typealias ParseResult = [String: Any]

    public init<S>(_ arguments: S) where S: Sequence, S.Element == Argument {
        var seen: Set<String> = []
        for arg in arguments {
            precondition(!seen.contains(arg.name), "Duplicate argument: '\(arg.name)'")
            seen.insert(arg.name)
            if arg.isPositional {
                positionals.append(arg)
            } else {
                options.insert(arg)
            }
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    public func parse(_ commandLine: [String]) throws -> ParseResult {
        // Command line should at least contain the program name.
        guard commandLine.count > 0 else {
            throw ArgumentParserError.emptyCommandLine
        }

        // Make sure there's at least command line argument, or that there's no required arguments.
        var required = (positionals + options).filter { $0.isRequired }
        guard commandLine.count > 1 || required.isEmpty else {
            throw ArgumentParserError.missingArguments(required)
        }

        var unparsedPositionals = positionals
        var result: ParseResult = [:]
        var index = 1

        while index < commandLine.count {
            var arg: Argument

            // Parse an option if it starts with `-`, or a positional otherwise.
            // Notice that in the former case, the index is advanced by 1 so the name of the
            // option doesn't appear within its values.
            if commandLine[index].starts(with: "-") {
                let name = String(commandLine[index].drop(while: { $0 == "-" }))
                guard let i = options.index(where: { $0.name == name || $0.alias == name }) else {
                    throw ArgumentParserError.unexpectedArgument(name)
                }
                arg = options[i]
                index += 1
            } else {
                guard !unparsedPositionals.isEmpty else {
                    throw ArgumentParserError.unexpectedArgument(commandLine[index])
                }
                arg = unparsedPositionals.removeFirst()
            }

            // Consumes as many values as possible, up to the maximum arity.
            var values: ArraySlice = commandLine.dropFirst(index)
            values = values
                .prefix(while: { !$0.starts(with: "-") })
                .prefix(arg.arity?.upperBound ?? 1)

            // Make sure enough values were provided.
            if let arity = arg.arity {
                guard values.count >= arity.lowerBound else {
                    throw ArgumentParserError.invalidArity(
                        argument: arg, provided: values.count)
                }
            } else {
                guard values.count == 1 else {
                    throw ArgumentParserError.invalidArity(
                        argument: arg, provided: values.count)
                }
            }

            // Parse the argument's values.
            result[arg.name] = try arg.isVariadic
                ? arg.parse(values)
                : arg.parse(values.first!)

            if let i = required.index(of: arg) {
                required.remove(at: i)
            }

            index += values.count
        }

        // Make sure all required arguments were provided.
        guard required.isEmpty else {
            throw ArgumentParserError.missingArguments(required)
        }

        // Store missing arguments' default value.
        for arg in (unparsedPositionals + options)
            where result[arg.name] == nil && arg.defaultValue != nil
        {
            result[arg.name] = arg.defaultValue
        }

        return result
    }

    private(set) var positionals: [Argument] = []
    private(set) var options: Set<Argument> = []

}

extension ArgumentParser: ExpressibleByArrayLiteral {

    public init(arrayLiteral elements: Argument...) {
        self.init(elements)
    }

}

public struct Argument {

    public typealias Arity = ClosedRange<Int>

    /// The name of the argument.
    public var name: String

    /// The alias (or short name) of the argument.
    /// Only relevant for non-positional arguments.
    public var alias: String?

    /// The default value of the argument.
    public let defaultValue: Any?

    /// The arity of the argument.
    public var arity: Arity?

    /// Whether or not the argument is variadic.
    ///
    /// - Note: An argument is considered variadic if its arity isn't `nil`, even if the actual
    ///   represented range isn't greater than 1.
    public var isVariadic: Bool {
        return self.arity != nil
    }

    /// Whether or not the argument is positional.
    public var isPositional: Bool

    /// Whether or not the argument is required.
    public var isRequired: Bool

    /// A textual description of the argument.
    public var description: String?

    /// A function that processes the command line value(s) for this argument.
    public let parse: (Any) throws -> Any

    /// Creates a positional argument.
    public static func positional<T>(
        _ name: String,
        defaultValue: T? = nil,
        isRequired: Bool = false,
        description: String? = nil,
        parse: @escaping (String) throws -> T)
        -> Argument
    {
        return Argument(
            name: name,
            alias: nil,
            defaultValue: defaultValue.map { $0 as Any },
            arity: nil,
            isPositional: true,
            isRequired: isRequired,
            description: description,
            parse: { try parse($0 as! String) as Any }) // swiftlint:disable:this force_cast
    }

    /// Creates a positional argument.
    public static func positional(
        _ name: String,
        defaultValue: String? = nil,
        isRequired: Bool = false,
        description: String? = nil)
        -> Argument
    {
        return .positional(
            name, defaultValue: defaultValue, isRequired: isRequired, description: description,
            parse: { $0 })
    }

    /// Creates a variadic positional argument.
    public static func variadic<T>(
        _ name: String,
        defaultValue: T? = nil,
        arity: Arity = 1...Int.max,
        isRequired: Bool = false,
        description: String? = nil,
        parse: @escaping (ArraySlice<String>) throws -> T)
        -> Argument
    {
        return Argument(
            name: name,
            alias: nil,
            defaultValue: defaultValue.map { $0 as Any },
            arity: arity,
            isPositional: true,
            isRequired: isRequired,
            description: description,
            parse: { try parse($0 as! ArraySlice<String>) as Any }) // swiftlint:disable:this force_cast
    }

    /// Creates a variadic positional argument.
    public static func variadic(
        _ name: String,
        defaultValue: [String]? = nil,
        arity: Arity = 1...Int.max,
        isRequired: Bool = false,
        description: String? = nil)
        -> Argument
    {
        return .variadic(
            name, defaultValue: defaultValue, arity: arity, isRequired: isRequired,
            description: description, parse: { Array($0) })
    }

    /// Creates an option.
    public static func option<T>(
        _ name: String,
        alias: String? = nil,
        defaultValue: T? = nil,
        isRequired: Bool = false,
        description: String? = nil,
        parse: @escaping (String) throws -> T)
        -> Argument
    {
        return Argument(
            name: name,
            alias: alias,
            defaultValue: defaultValue.map { $0 as Any },
            arity: nil,
            isPositional: false,
            isRequired: isRequired,
            description: description,
            parse: { try parse($0 as! String) as Any }) // swiftlint:disable:this force_cast
    }

    /// Creates an option.
    public static func option(
        _ name: String,
        alias: String? = nil,
        defaultValue: String? = nil,
        isRequired: Bool = false,
        description: String? = nil)
        -> Argument
    {
        return .option(
            name, alias: alias, defaultValue: defaultValue, isRequired: isRequired,
            description: description, parse: { $0 })
    }

    /// Creates a variadic option.
    public static func variadicOption<T>(
        _ name: String,
        alias: String? = nil,
        defaultValue: T? = nil,
        arity: Arity = 1...Int.max,
        isRequired: Bool = false,
        description: String? = nil,
        parse: @escaping (ArraySlice<String>) throws -> T)
        -> Argument
    {
        return Argument(
            name: name,
            alias: alias,
            defaultValue: defaultValue.map { $0 as Any },
            arity: arity,
            isPositional: false,
            isRequired: isRequired,
            description: description,
            parse: { try parse($0 as! ArraySlice<String>) as Any }) // swiftlint:disable:this force_cast
    }

    /// Creates a variadic option.
    public static func variadicOption(
        _ name: String,
        alias: String? = nil,
        defaultValue: [String]? = nil,
        arity: Arity = 1...Int.max,
        isRequired: Bool = false,
        description: String? = nil)
        -> Argument
    {
        return .variadicOption(
            name, alias: alias, defaultValue: defaultValue, arity: arity, isRequired: isRequired,
            description: description, parse: { Array($0) })
    }

    /// Creates a flag.
    public static func flag(
        _ name: String,
        alias: String? = nil,
        defaultValue: Bool = false,
        description: String? = nil)
        -> Argument
    {
        return Argument(
            name: name,
            alias: alias,
            defaultValue: defaultValue,
            arity: 0...0,
            isPositional: false,
            isRequired: false,
            description: description,
            parse: { _ in true })
    }

}

extension Argument: Hashable {

    public var hashValue: Int {
        return name.hashValue
    }

    public static func == (lhs: Argument, rhs: Argument) -> Bool {
        return lhs.name == rhs.name
    }

}

public protocol InitializableFromString {

    init(from: String) throws

}

extension Int: InitializableFromString {

    public init(from string: String) {
        self.init(string)!
    }

}

extension Argument {

    /// Creates a positional argument.
    public static func positional<T: InitializableFromString>(
        _ name: String,
        defaultValue: T? = nil,
        isRequired: Bool = false,
        description: String? = nil,
        parse: @escaping (String) throws -> T = T.init)
        -> Argument
    {
        return Argument(
            name: name,
            alias: nil,
            defaultValue: defaultValue.map { $0 as Any },
            arity: nil,
            isPositional: true,
            isRequired: isRequired,
            description: description,
            parse: { try parse($0 as! String) as Any }) // swiftlint:disable:this force_cast
    }

    /// Creates a variadic positional argument.
    public static func variadic<T: InitializableFromString>(
        _ name: String,
        defaultValue: [T]? = nil,
        arity: Arity = 1...Int.max,
        isRequired: Bool = false,
        description: String? = nil,
        parse: @escaping (ArraySlice<String>) throws -> [T] = { try $0.map(T.init) })
        -> Argument
    {
        return Argument(
            name: name,
            alias: nil,
            defaultValue: defaultValue.map { $0 as Any },
            arity: arity,
            isPositional: true,
            isRequired: isRequired,
            description: description,
            parse: { try parse($0 as! ArraySlice<String>) as Any }) // swiftlint:disable:this force_cast
    }

    /// Creates an option.
    public static func option<T: InitializableFromString>(
        _ name: String,
        alias: String? = nil,
        defaultValue: T? = nil,
        isRequired: Bool = false,
        description: String? = nil,
        parse: @escaping (String) throws -> T = T.init)
        -> Argument
    {
        return Argument(
            name: name,
            alias: alias,
            defaultValue: defaultValue.map { $0 as Any },
            arity: nil,
            isPositional: false,
            isRequired: isRequired,
            description: description,
            parse: { try parse($0 as! String) as Any }) // swiftlint:disable:this force_cast
    }

    /// Creates a variadic option.
    public static func variadicOption<T: InitializableFromString>(
        _ name: String,
        alias: String? = nil,
        defaultValue: [T]? = nil,
        arity: Arity = 1...Int.max,
        isRequired: Bool = false,
        description: String? = nil,
        parse: @escaping (ArraySlice<String>) throws -> [T] = { try $0.map(T.init) })
        -> Argument
    {
        return Argument(
            name: name,
            alias: alias,
            defaultValue: defaultValue.map { $0 as Any },
            arity: arity,
            isPositional: false,
            isRequired: isRequired,
            description: description,
            parse: { try parse($0 as! ArraySlice<String>) as Any }) // swiftlint:disable:this force_cast
    }

}

enum ArgumentParserError: Error {

    case emptyCommandLine
    case missingArguments([Argument])
    case unexpectedArgument(String)
    case invalidArity(argument: Argument, provided: Int)

}

extension Dictionary where Key == String, Value == Any {

    public func result<T>(for key: Key) -> T? {
        return self[key] as? T
    }

}
