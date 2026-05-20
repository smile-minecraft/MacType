import Foundation

/// JSON 檔案儲存（Application Support/MacType/）
final class FileStore {
    private let fileManager = FileManager.default
    private let fileName: String

    /// 可注入的 baseURL（供測試使用）
    var baseURL: URL?

    init(fileName: String = "sessions.json") {
        self.fileName = fileName
    }

    // MARK: - Directory

    private var storageDirectory: URL? {
        if let baseURL = baseURL {
            return baseURL.appendingPathComponent("MacType", isDirectory: true)
        }
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            print("[FileStore] Cannot find Application Support directory")
            return nil
        }
        let dir = appSupport.appendingPathComponent("MacType", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            do {
                try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            } catch {
                print("[FileStore] Failed to create directory: \(error)")
                return nil
            }
        }
        return dir
    }

    private var fileURL: URL? {
        if let baseURL = baseURL {
            // 測試注入路徑：直接用 baseURL/fileName，不疊加 MacType 子目錄
            return baseURL.appendingPathComponent(fileName)
        }
        return storageDirectory?.appendingPathComponent(fileName)
    }

    // MARK: - Read

    func load<T: Decodable>(_ type: T.Type) -> T? {
        guard let url = fileURL else { return nil }
        guard fileManager.fileExists(atPath: url.path) else { return nil }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            print("[FileStore] Load failed: \(error)")
            return nil
        }
    }

    // MARK: - Write

    func save<T: Encodable>(_ value: T) {
        guard let url = fileURL else {
            print("[FileStore] No fileURL to save to")
            return
        }

        // 確保父目錄存在（支援 baseURL 注入模式）
        let parentDir = url.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: parentDir.path) {
            do {
                try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)
            } catch {
                print("[FileStore] Failed to create directory: \(error)")
                return
            }
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            print("[FileStore] Save failed: \(error)")
        }
    }

    // MARK: - Delete

    func delete() {
        guard let url = fileURL else { return }
        if fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.removeItem(at: url)
            } catch {
                print("[FileStore] Delete failed: \(error)")
            }
        }
    }
}