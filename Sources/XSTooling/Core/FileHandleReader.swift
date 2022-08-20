import Foundation

final class FileHandleReader {
    fileprivate(set) var data = Data()

    fileprivate init() {}
}

extension FileHandle {
    func reader() -> FileHandleReader {
        assert(self.readabilityHandler == nil)

        let reader = FileHandleReader()

        self.readabilityHandler = { fileHandle in
            // invoke on serial queue
            let data = fileHandle.availableData

            if data.isEmpty {
                // stop
                fileHandle.readabilityHandler = nil
            } else {
                reader.data.append(data)
            }
        }
        return reader
    }
}
