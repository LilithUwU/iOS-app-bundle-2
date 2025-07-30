//
//  ImageDownloader.swift
//  App Bundle 2
//
//  Created by lilit on 30.07.25.
//

import Foundation
import UIKit
class ImageDownloader {

    static let shared = ImageDownloader()

    private init() {}

    func downloadImage(from url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) {
        print("downloadImage: \(url.absoluteString)")

        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("download failed for \(url): \(error.localizedDescription)")
                completion(.failure(ImageDownloadError.unknown(error)))
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("http \(httpResponse.statusCode) for: \(url.absoluteString)")
            }

            guard let data = data, let image = UIImage(data: data) else {
                print("invalid image data for: \(url.absoluteString)")
                completion(.failure(ImageDownloadError.invalidData))
                return
            }

            print("downloaded: \(url.absoluteString)")
            completion(.success(image))
        }.resume()
    }

    func downloadImages(from urls: [URL], completion: @escaping ([UIImage]) -> Void) {
        var images: [UIImage] = []
        let group = DispatchGroup()

        for url in urls {
            group.enter()

            if let cachedImage = ImageCacheManager.shared.getImage(for: url) {
                print("Loaded from cache: \(url.absoluteString)")
                images.append(cachedImage)
                group.leave()
            } else {
                downloadImage(from: url) { result in
                    switch result {
                    case .success(let image):
                        images.append(image)
                        ImageCacheManager.shared.saveImage(image, for: url)
                    case .failure:
                        print("Skip image, download failure: \(url.absoluteString)")
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            print("all downloads complete. \(images.count) loaded.")
            completion(images)
        }
    }
}

