//
//  MemoriesCVC.swift
//  HappyDays
//
//  Created by David E Bratton on 6/28/19.
//  Copyright © 2019 David Bratton. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech

class MemoriesCVC: UICollectionViewController {

    var memories = [URL]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
        loadMemories()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkPermissions()
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func loadMemories() {
        memories.removeAll()
        // attempt to load all memories in our document directory
        guard let files = try?
            FileManager.default.contentsOfDirectory(at: getDocumentsDirectory(), includingPropertiesForKeys: nil, options: []) else { return }
        // loop over ever file found
        for file in files {
            let filename = file.lastPathComponent
            //check it ends with ".thumb" so dont count each memory more than once
            if filename.hasSuffix(".thumb") {
                // get the root name of the memory (i.e., without path extension
                let noExtension = filename.replacingOccurrences(of: ".thumb", with: "")
                // create a full path from the memory
                let memoryPath = getDocumentsDirectory().appendingPathComponent(noExtension)
                // add it to array
                memories.append(memoryPath)
            }
        }
        // reload our list of memories
        // need to use this approach, since the searchbar is in collection header and in section 0
        collectionView.reloadSections(IndexSet(integer: 1))
    }

    func checkPermissions() {
        let photosAuthorized = PHPhotoLibrary.authorizationStatus() == .authorized
        let recordingAuthorized = AVAudioSession.sharedInstance().recordPermission == .granted
        let transcribeAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        let authorized = photosAuthorized && recordingAuthorized && transcribeAuthorized
        if !authorized {
            if let vc = storyboard?.instantiateViewController(withIdentifier: "FirstRun") {
                navigationController?.present(vc, animated: true)
            }
        }
    }
    
    @objc func addTapped() {
        let vc = UIImagePickerController()
        vc.modalPresentationStyle = .formSheet
        vc.delegate = self
        navigationController?.present(vc, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true, completion: nil)
        if let possibleImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            saveNewMemory(image: possibleImage)
            loadMemories()
        }
    }
    
    func saveNewMemory(image: UIImage) {
        // create a unique name for this memory
        let memoryName = "memory-\(Date().timeIntervalSince1970)"
        // use a unique name to create filenames for the full size image and thumb
        let imageName = memoryName + ".jpg"
        let thumbnailName = memoryName + ".thumb"
        do {
            // create a URL where we can write the JPEC to
            let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
            // convert the UIImage into JPEG data object

            if let jpegData = image.jpegData(compressionQuality: 80) {
                // write that data to the URL we created
                try jpegData.write(to: imagePath, options: [.atomicWrite])
            }
            // create thumbnail here
            if let thumbnail = resize(image: image, to: 200) {
                let imagePath = getDocumentsDirectory().appendingPathComponent(thumbnailName)
                if let jpegData = thumbnail.jpegData(compressionQuality: 80) {
                    try jpegData.write(to: imagePath, options: [.atomicWrite])
                }
            }
        } catch {
            print("Failed to save to disk")
        }
    }
    
    func resize(image: UIImage, to width: CGFloat) -> UIImage? {
        // calculate how much we need to bring the width down to match target size
        let scale = width / image.size.width
        
        // bring the height down by same amount so that aspect ration is preserved
        let height = image.size.height * scale
        
        // create a new image context we can draw
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
        
        // draw the original image into the context
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // pull out the resized version
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // end the context so UIKit can clean up
        UIGraphicsEndImageContext()
        
        // send it back to caller
        return newImage
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 0
        } else {
            return memories.count
        }
    }
    
    func imageURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("jpg")
    }
    
    func thumbnailURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("thumb")
    }
    
    func audioURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("m4a")
    }
    
    func transcriptionURL(for memory: URL) -> URL {
        return memory.appendingPathExtension("txt")
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Memory", for: indexPath) as! MemoryCell
        let memory = memories[indexPath.row]
        let imageName = thumbnailURL(for: memory).path
        let image = UIImage.init(contentsOfFile: imageName)
        cell.imageView.image = image
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == 1 {
            return CGSize.zero
        } else {
            return CGSize(width: 0, height: 50)
        }
    }
}

extension MemoriesCVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout {
    
}
