//
//  ViewController.swift
//  HappyDays
//
//  Created by David E Bratton on 6/28/19.
//  Copyright © 2019 David Bratton. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import Speech

class PermissionsVC: UIViewController {

    @IBOutlet weak var helpLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func requestPhotoPermissions() {
        PHPhotoLibrary.requestAuthorization { (authStatus) in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.requestRecordPermission()
                } else {
                    self.helpLabel.text = "Photos permission was declined, please enable it in settings then tap \"Continue\" again."
                }
            }
        }
    }
    
    func requestRecordPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { (allowed) in
            if allowed {
                self.requestTranscribePermissions()
            } else {
                self.helpLabel.text = "Recording permission was declined, please enable it in settings then tap \"Continue\" again."
            }
        }
    }
    
    func requestTranscribePermissions() {
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self.authorizationComplete()
                } else {
                    self.helpLabel.text = "Transcriber permission was declined, please enable it in settings then tap \"Continue\" again."
                }
            }
        }
    }
    
    func authorizationComplete() {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func requestPermissionBtnPressed(_ sender: UIButton) {
        requestPhotoPermissions()
    }
}
