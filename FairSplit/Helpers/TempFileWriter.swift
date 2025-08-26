import Foundation

enum TempFileWriter {
    static func writeTemporary(data: Data, fileName: String, fileExtension: String) throws -> URL {
        let dir = FileManager.default.temporaryDirectory
        let url = dir.appendingPathComponent(fileName).appendingPathExtension(fileExtension)
        try data.write(to: url, options: .atomic)
        return url
    }
}

