#!/usr/bin/env swift

// Workflow commands for GitHub Actions
// https://docs.github.com/en/actions/writing-workflows/choosing-what-your-workflow-does/workflow-commands-for-github-actions

let regex = #/(?<file>.+\.swift):(?<line>\d+):(?<column>\d+): (?<severity>.+): \[(?<title>.+)\] (?<message>.+)/#
while let line = readLine() {
    if let match = try? regex.firstMatch(in: line) {
        let (_, file, line, column, severity, title, message) = match.output
        print("::\(severity) file=\(file),line=\(line),col=\(column),title=\(title)::\(message)")
    } else {
        print(line)
    }
}
