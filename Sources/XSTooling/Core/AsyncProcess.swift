import Foundation

extension Process {
     var async: AsyncProcess {
        AsyncProcess(process: self)
    }
}

final class AsyncProcess {
    private let _process: Process
    private let _lock = NSLock()

    fileprivate init(process: Process) {
        self._process = process
    }

    /// Runs the process with the current environment.
    func run() async throws {
        try await withTaskCancellationHandler {
            try Task.checkCancellation() // can be canceled before running
            try await _run()
        } onCancel: {
            _terminate()
        }
    }

    private func _run() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            var runningError: Error?
            _lock.lock()
            _process.terminationHandler = { _ in
                continuation.resume()
            }
            do {
                try _process.run() // waiting for the `terminationHandler` call
            } catch {
                // `terminationHandler` is not called if if an error occurred
                runningError = error
            }
            _lock.unlock()

            if let runningError = runningError {
                continuation.resume(throwing: runningError)
            }
        }
    }

    private func _terminate() {
        _lock.lock()
        if _process.isRunning { // can be canceled without starting
            _process.terminate() // crash if not running
        }
        _lock.unlock()
    }
}
