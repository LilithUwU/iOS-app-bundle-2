//
//  ViewController.swift
//  App Bundle 2
//
//  Created by lilit on 30.07.25.
//

import UIKit

enum ImageDownloadError: Error {
    case invalidData
    case unknown(Error)
}

class MemoryWarningObserver {

    init() {
        NotificationCenter.default.addObserver(self,
           selector: #selector(handleMemoryWarning),
           name: UIApplication.didReceiveMemoryWarningNotification,
           object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleMemoryWarning() {
        print("memory warning, clearing cache.")
        ImageCacheManager.shared.clearCache()
    }
}

class ViewController: UIViewController, UICollectionViewDataSource {

    private var imageUrls: [URL] = []
    private var images: [UIImage] = []
    private var collectionView: UICollectionView!
    private var memoryObserver: MemoryWarningObserver?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        setupCollectionView()
        setupClearCacheButton()
        memoryObserver = MemoryWarningObserver()

        imageUrls = (1...5).compactMap {
            URL(string: "https://picsum.photos/800/600?random=\($0)")
        }

        print("image url:")
        imageUrls.forEach { print(" \($0)") }

        loadImages()
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.bounds.width * 0.9, height: 200)
        layout.sectionInset = UIEdgeInsets(top: 20, left: 10, bottom: 20, right: 10)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.reuseIdentifier)
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear

        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100)
        ])
    }

    private func setupClearCacheButton() {
        let button = UIButton(type: .system)
        button.setTitle("Clear Image Cache", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(clearCacheTapped), for: .touchUpInside)

        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 10),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.widthAnchor.constraint(equalToConstant: 200),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func loadImages() {
        print("loadImages")
        ImageDownloader.shared.downloadImages(from: imageUrls) { [weak self] loadedImages in
            DispatchQueue.main.async {
                self?.images = loadedImages
                self?.collectionView.reloadData()
                print("update ui")
            }
        }
    }

    @objc private func clearCacheTapped() {
        ImageCacheManager.shared.clearCache()
        images.removeAll()
        collectionView.reloadData()
        print("clearCacheTapped")
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.reuseIdentifier, for: indexPath) as? ImageCell else {
            fatalError("Could not dequeue ImageCell")
        }

        let url = imageUrls[indexPath.item]

        if let cachedImage = ImageCacheManager.shared.getImage(for: url) {
            cell.imageView.image = cachedImage
        } else {
            cell.imageView.image = UIImage(systemName: "photo")

            ImageDownloader.shared.downloadImage(from: url) { result in
                DispatchQueue.main.async {
                    guard let updatedCell = collectionView.cellForItem(at: indexPath) as? ImageCell else { return }

                    switch result {
                    case .success(let image):
                        ImageCacheManager.shared.saveImage(image, for: url)
                        updatedCell.imageView.image = image
                    case .failure:
                        updatedCell.imageView.image = UIImage(systemName: "xmark.octagon")
                    }
                }
            }
        }

        return cell
    }
}
