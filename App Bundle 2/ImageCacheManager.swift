//
//  ImageCacheManager.swift
//  App Bundle 2
//
//  Created by lilit on 30.07.25.
//
import Foundation
import UIKit
class ImageCacheManager {

    static let shared = ImageCacheManager()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        cacheDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ImageCache")
        createCacheDirectoryIfNeeded()
    }

    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
                print("cache directory created at: \(cacheDirectory.path)")
            } catch {
                print("failed when creating cache directory: \(error.localizedDescription)")
            }
        }
    }

    private func filePath(for url: URL) -> URL {
        let fileName = url.absoluteString.data(using: .utf8)?.base64EncodedString() ?? UUID().uuidString
        return cacheDirectory.appendingPathComponent(fileName)
    }

    func saveImage(_ image: UIImage, for url: URL) {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            print("Could not convert image to data for saving.")
            return
        }

        createCacheDirectoryIfNeeded()

        let fileURL = filePath(for: url)
        do {
            try data.write(to: fileURL)
            print("Saved image to cache: \(fileURL.lastPathComponent)")
        } catch {
            print("error saving image: \(error.localizedDescription)")
        }
    }

    func getImage(for url: URL) -> UIImage? {
        let fileURL = filePath(for: url)
        if fileManager.fileExists(atPath: fileURL.path) {
            return UIImage(contentsOfFile: fileURL.path)
        }
        return nil
    }

    func clearCache() {
        do {
            let cachedFiles = try fileManager.contentsOfDirectory(atPath: cacheDirectory.path)
            for file in cachedFiles {
                let filePath = cacheDirectory.appendingPathComponent(file)
                try fileManager.removeItem(at: filePath)
                print("removed cached file: \(file)")
            }
            print("image cache cleared.")
        } catch {
            print("error clearing cache: \(error.localizedDescription)")
        }
    }
}
