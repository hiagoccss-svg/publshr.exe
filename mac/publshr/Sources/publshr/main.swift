import Darwin

private let version = "0.1.0"

private func printUsage() {
    let prog = CommandLine.arguments.first.flatMap { path in
        path.split(separator: "/").last.map(String.init)
    } ?? "publshr"
    print(
        """
        \(prog) \(version)

        Usage:
          \(prog) [options]

        Options:
          -h, --help     Show this message
          -v, --version  Print version

        This macOS build mirrors the Windows publshr.exe CLI. Add subcommands here as the tool grows.
        """
    )
}

@main
enum Entry {
    static func main() {
        let args = Array(CommandLine.arguments.dropFirst())

        if args.isEmpty {
            printUsage()
            exit(0)
        }

        switch args[0] {
        case "-h", "--help":
            printUsage()
        case "-v", "--version":
            print(version)
        default:
            fputs("Unknown option: \(args[0])\n", stderr)
            printUsage()
            exit(2)
        }
    }
}
