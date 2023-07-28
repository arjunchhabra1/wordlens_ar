//
//  OnboardingViewController.swift
//  WordLensAR
//
//  Created by arjun on 7/28/23.
//

import UIKit
import Lottie
import AVFoundation
import LocalAuthentication

struct Slide {
    let title: String
    let animationName: String
    let buttonColor: UIColor
    let buttonTitle: String
    let speechText: String
    
    static let collection: [Slide] = [
        .init(title: "DyslexiAR", animationName: "18077-book-read", buttonColor: .systemYellow, buttonTitle: "Next", speechText: "DyslexiAR is an assistive technology app designed to help dyslexic individuals read, write, and analyze their progress using augmented reality and machine learning"),
        .init(title: "Read", animationName: "6781-ar-search-animation-guide", buttonColor: .systemTeal, buttonTitle: "Next", speechText: "While reading, fit the scanning box over desired text and click the speech button to hear the text or click the AR button to view an AR model of the text"),
        .init(title: "Write", animationName: "9939-write-something", buttonColor: .systemGreen, buttonTitle: "Next", speechText: "While writing, fit the scanning box over desired text and click the scan button to project the correctly spelled word in augmented reality"),
        .init(title: "Analyze", animationName: "32257-report", buttonColor: .systemGreen, buttonTitle: "Get Started", speechText: "Analyze your progress and patterns using statistics collected from your data")
    ]
}

class OnboardingViewController: UIViewController, AVSpeechSynthesizerDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    private let slides: [Slide] = Slide.collection
    private var cont = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpCollectionView()
        setUpPageControl()
        
    }
    
    private func setUpPageControl(){
        pageControl.numberOfPages = slides.count
        let angle = CGFloat.pi/2
        pageControl.transform = CGAffineTransform(rotationAngle: angle)
    }
    
    private func setUpCollectionView(){
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        collectionView.collectionViewLayout = layout
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.isPagingEnabled = true
    }
    
    private func handleButtonActionTap(at indexPath: IndexPath){
        if indexPath.item == slides.count - 1{
            // last slide tapped
            showMainApp()
        }else{
            let nextIndex = indexPath.item + 1
            let nextIndexPath = IndexPath(item: nextIndex, section: 0)
            collectionView.scrollToItem(at: nextIndexPath, at: .top, animated: true)
            pageControl.currentPage = nextIndex
        }
    }
    
//    private func handleSpeechTap(at indexPath: IndexPath){
//    }
    
    private func showMainApp(){
//        let mainAppViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "mainApp")
//
//        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let sceneDelegate = windowScene.delegate as? UIWindowSceneDelegate, let window = sceneDelegate.window {
//            window?.rootViewController = mainAppViewController
//            UIView.transition(with: window ?? UIWindow.init(), duration: 0.25, options: .transitionCrossDissolve, animations: nil, completion: nil)
//        }
        
        let context: LAContext = LAContext()
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil){
            context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticating User") { (success, err) in
                if success {
                    print("Success")
                    self.cont = true
                }else{
                    print("Try Again")
                }
            }
        }
        transition()
        
//        let main = storyboard?.instantiateViewController(identifier: "mainApp") as? ViewController
//        view.window?.rootViewController = main
//        view.window?.makeKeyAndVisible()
    }
    
    private func transition(){
        if(cont){
            let main = storyboard?.instantiateViewController(identifier: "mainApp") as? ViewController
            view.window?.rootViewController = main
            view.window?.makeKeyAndVisible()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let index = Int(collectionView.contentOffset.y / scrollView.frame.size.height)
        pageControl.currentPage = index
    }
}

extension OnboardingViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return slides.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellId", for: indexPath) as! OnboardingCollectionViewCell
        let slide = slides[indexPath.item]
        cell.configure(with: slide)
        cell.actionButtonDidTap = { [weak self] in
            self?.handleButtonActionTap(at: indexPath)
            print(indexPath)
        }
//        cell.playButtonDidTap = { [weak self] in
//            self?.handleSpeechTap(at: indexPath)
//        }
        
//        var color = UIColor.clear
//        if indexPath.item % 2 == 0{
//            color = .red
//        }else{
//            color = .blue
//        }
//        cell.backgroundColor = color
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let itemWidth = collectionView.bounds.width
        let itemHeight = collectionView.bounds.height
        
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

class OnboardingCollectionViewCell: UICollectionViewCell, AVSpeechSynthesizerDelegate {
    @IBOutlet weak var animationView: AnimationView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    
    let speechSynthesizer = AVSpeechSynthesizer()
    
    var actionButtonDidTap: (() -> Void)?
    var playButtonDidTap: (() -> Void)?
    var speech: String?
    
    func configure(with slide: Slide){
        titleLabel.text = slide.title
        actionButton.backgroundColor = slide.buttonColor
        actionButton.setTitle(slide.buttonTitle, for: .normal)
        speech = slide.speechText
        
        let animation = Animation.named(slide.animationName)
        
        animationView.animation = animation
        animationView.loopMode = .loop
        
        if !animationView.isAnimationPlaying{
            animationView.play()
        }
    }
    
    @IBAction func actionButtonTapped(){
        actionButtonDidTap?()
    }
    
    @IBAction func playButtonTapped(_ sender: UIButton){
        sender.isSelected = !sender.isSelected
        if sender.isSelected{
            Start()
        }else{
            Pause()
        }
    }
    
    func Pause(){
        speechSynthesizer.pauseSpeaking(at: .immediate)
    }
    
    func Start(){
        if speechSynthesizer.isSpeaking{
            speechSynthesizer.stopSpeaking(at: .immediate)
        }else{
            let speechUtterance = AVSpeechUtterance(string: (speech!))
            DispatchQueue.main.async {
                self.speechSynthesizer.speak(speechUtterance)
            }
        }
    }
}
