//
//  AutoCorrectViewController.swift
//  WordLensAR
//
//  Created by arjun on 7/28/23.
//

import UIKit
import AVFoundation

class AutoCorrectViewController: UIViewController, AVSpeechSynthesizerDelegate {
    
    var nextWords: [String]!
    let speechSynthesizer = AVSpeechSynthesizer()

    @IBOutlet weak var btn1: UIButton!
    @IBOutlet weak var btn2: UIButton!
    @IBOutlet weak var btn3: UIButton!
    
    @IBOutlet weak var s1: UIButton!
    @IBOutlet weak var s2: UIButton!
    @IBOutlet weak var s3: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        speechSynthesizer.delegate = self
        if(nextWords.count == 1){
            btn1.setTitle(nextWords[0], for: .normal)
            btn2.isUserInteractionEnabled = false
            btn2.isHidden = true
            btn3.isUserInteractionEnabled = false
            btn3.isHidden = true
        }else if(nextWords.count == 2){
            btn1.setTitle(nextWords[0], for: .normal)
            btn2.setTitle(nextWords[1], for: .normal)
            btn3.isUserInteractionEnabled = false
            btn3.isHidden = true
        }else if(nextWords.count > 2){
            btn1.setTitle(nextWords[0], for: .normal)
            btn2.setTitle(nextWords[1], for: .normal)
            btn3.setTitle(nextWords[2], for: .normal)
        }
        
    }
    
    @IBAction func speak1(_ sender: UIButton){
        sender.isSelected = !sender.isSelected
        if sender.isSelected{
            Start(title: (btn1.titleLabel?.text)!)
        }else{
            speechSynthesizer.pauseSpeaking(at: .immediate)
        }
    }
    @IBAction func speak2(_ sender: UIButton){
        sender.isSelected = !sender.isSelected
        if sender.isSelected{
            Start(title: (btn2.titleLabel?.text)!)
        }else{
            speechSynthesizer.pauseSpeaking(at: .immediate)
        }
    }
    @IBAction func speak3(_ sender: UIButton){
        sender.isSelected = !sender.isSelected
        if sender.isSelected{
            Start(title: (btn3.titleLabel?.text)!)
        }else{
            speechSynthesizer.pauseSpeaking(at: .immediate)
        }
    }
    
    @IBAction func btn1Tapped(_ sender: UIButton){
            // TODO: Yatharth
            // User tapped 1st btn -> go back to screen
            // (btn1.titleLabel?.text)!
    }
    
    @IBAction func btn2Tapped(_ sender: UIButton){
            // TODO: Yatharth
            // User tapped 2nd btn -> go back to screen
            // (btn2.titleLabel?.text)!
    }
    
    @IBAction func btn3Tapped(_ sender: UIButton){
            // TODO: Yatharth
            // User tapped 3rd btn -> go back to screen
            // (
    }
    
    
    func Start(title: String){
        if speechSynthesizer.isSpeaking{
            speechSynthesizer.stopSpeaking(at: .immediate)
        }else{
            let speechUtterance = AVSpeechUtterance(string: title)
            DispatchQueue.main.async {
                self.speechSynthesizer.speak(speechUtterance)
            }
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

