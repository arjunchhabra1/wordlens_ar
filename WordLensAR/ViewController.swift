//
//  ViewController.swift
//  WordLensAR
//
//  Created by arjun on 7/27/23.
//

import UIKit
import SceneKit
import ARKit
import SpriteKit
import AVFoundation
import Firebase
import FirebaseFirestore
import SCLAlertView

class ViewController: UIViewController, ARSCNViewDelegate, AVSpeechSynthesizerDelegate{
    
    @IBOutlet weak var arButton: UIButton!
    
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var speechButton: UIButton!
    
    @IBOutlet var sceneView: ARSCNView!
    var myPlaneNode: SCNNode! = nil
    @IBOutlet weak var scanView: UIImageView!
    // the z poisition of the dragging point
    var panStartZ: CGFloat?
    var lastPanPosition: SCNVector3?
    var text:String!
    var ocrRequest: VNRecognizeTextRequest!
    
    //var e:Echo3D!
    
    var arNode: SCNNode!
    
    var arRunning = false
    var speechRunning = false
    
    var configuration: ARWorldTrackingConfiguration!
    
    // AV Foundation Speech
    //    @IBOutlet weak var speakBtn: UIButton!
    let speechSynthesizer = AVSpeechSynthesizer()
    var count: Int = 0
    var message: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //disable cancel button
        cancelButton.isUserInteractionEnabled = false
        cancelButton.isHidden = true
        
        // Set the view's delegate
        sceneView.delegate = self
        speechSynthesizer.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        //set scene view to automatically add omni directional light when needed
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        
        e = Echo3D()
        
        // round corners
        scanView.layer.cornerRadius = 15
        scanView.clipsToBounds = true
        
        speechButton.layer.cornerRadius = 15
        speechButton.clipsToBounds = true
        
        cancelButton.layer.cornerRadius = 15
        cancelButton.clipsToBounds = true
        
        arButton.layer.cornerRadius = 15
        arButton.clipsToBounds = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
        
        addPinchGesture() // pinch gesture for box
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(addObjToSceneView(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        //addPanGesture()
        
        //sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
    }
    
    private func addPinchGesture() {
//        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
//        //self.scanView.addGestureRecognizer(pinchGesture)
//        let pinchGesture2 = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch2(_:)))
//        self.sceneView.addGestureRecognizer(pinchGesture2)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        //add a plane node to the scene
        
        //get the width and height of the plane anchor
        let w = CGFloat(planeAnchor.extent.x)
        let h = CGFloat(planeAnchor.extent.z)
        
        //create a new plane
        let plane = SCNPlane(width: w, height: h)
        
        //set the color of the plane
        plane.materials.first?.diffuse.contents = UIColor.init(red: 0, green: 0, blue: 100, alpha: 0.1)
        
        //create a plane node from the scene plane
        let planeNode = SCNNode(geometry: plane)
        
        //get the x, y, and z locations of the plane anchor
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        
        //set the plane position to the x,y,z postion
        planeNode.position = SCNVector3(x,y,z)
        
        //turn th plane node so it lies flat horizontally, rather than stands up vertically
        planeNode.eulerAngles.x = -.pi / 2
        
        //set the name of the plane
        planeNode.name = "plain"
        
        //save the plane (used to later toggle the transparency of th plane)
        myPlaneNode = planeNode
        
        //add plane to scene
        node.addChildNode(planeNode)
        
    }
    func doAdd(withGestureRecognizer recognizer: UIGestureRecognizer){
        //get the location of the tap
        let tapLocation = recognizer.location(in: sceneView)
        
        
        //a hit test to see if the user has tapped on an existing plane
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        
        //make sure a result of the hit test exists
        guard let hitTestResult = hitTestResults.first else { return }
        
        //get the translation, or where we will be adding our node
        let translation = SCNVector3Make(hitTestResult.worldTransform.columns.3.x, hitTestResult.worldTransform.columns.3.y, hitTestResult.worldTransform.columns.3.z)
        let x = translation.x
        let y = translation.y
        let z = translation.z
        
        //load scene (3d model) from echo3D using the entry id of the users selected button
        
        //make sure the scene has a scene node
        //        guard let selectedNode =  SCNScene(named: "art.scnassets/Wolf.usdz")!.rootNode.childNodes.first else {return}
        
        if let selectedNode = arNode{
            //set the position of the node
            selectedNode.position = SCNVector3(x,y,z)
            
            //scale down the node using our scale constants
            let action = SCNAction.scale(by: 0.005, duration: 0.3)
            selectedNode.runAction(action)
            
            //add the node to our scene
            sceneView.scene.rootNode.addChildNode(selectedNode)
        }
    }
    @objc func addObjToSceneView(withGestureRecognizer recognizer: UIGestureRecognizer){
        doAdd(withGestureRecognizer: recognizer)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, let planeNode = node.childNodes.first,
              let plane = planeNode.geometry as? SCNPlane
        else {return}
        
        //update the plane node, as plane anchor information updates
        
        //get the width and the height of the planeAnchor
        let w = CGFloat(planeAnchor.extent.x)
        let h = CGFloat(planeAnchor.extent.z)
        
        //set the plane to the new width and height
        plane.width = w
        plane.height = h
        
        //get the x y and z position of the plane anchor
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        
        //set the nodes position to the new x,y, z location
        planeNode.position = SCNVector3(x, y, z)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    @IBAction func cancelPressed(_ sender: UIButton) {
        // reveal speech and ar buttons
        speechButton.isUserInteractionEnabled = true
        speechButton.isHidden = false
        arButton.isUserInteractionEnabled = true
        arButton.isHidden = false
        
        //hide cancel button
        cancelButton.isHidden = true
        cancelButton.isUserInteractionEnabled = false
        
        // reveal scan view
        scanView.isHidden = false
        
        if(arRunning){
            // remove AR image
            if(!(arNode==nil)){
                if let arAnchor = sceneView.anchor(for: arNode) as? ARPlaneAnchor {
                    sceneView.session.remove(anchor: arAnchor)
                }
                arNode.removeFromParentNode()
            }
            arNode = nil
            
            // stop plane tracking
            configuration.planeDetection = []
            sceneView.session.run(configuration)
            
            //remove AR plane
            if(!(myPlaneNode==nil)){
                if let planeAnchor = sceneView.anchor(for: myPlaneNode) as? ARPlaneAnchor {
                    sceneView.session.remove(anchor: planeAnchor)
                }
                myPlaneNode.removeFromParentNode()
            }
            myPlaneNode = nil
            
            
            arRunning = false
            
        }
        else if (speechRunning){
            Pause()
            speechRunning = false
        }
    }
    
    func Pause(){
        speechSynthesizer.pauseSpeaking(at: .immediate)
        speechRunning = false
        
        // show speech and ar buttons
        speechButton.isUserInteractionEnabled = true
        speechButton.isHidden = false
        arButton.isUserInteractionEnabled = true
        arButton.isHidden = false
        
        // hide cancel button
        cancelButton.isHidden = true
        cancelButton.isUserInteractionEnabled = false
        
        // show scan view
        scanView.isHidden = false
    }
    @IBAction func speechPressed(_ sender: UIButton) {
        // hide speech and ar buttons
        speechButton.isUserInteractionEnabled = false
        speechButton.isHidden = true
        arButton.isUserInteractionEnabled = false
        arButton.isHidden = true
        
        //reveal cancel button
        cancelButton.isHidden = false
        cancelButton.isUserInteractionEnabled = true
        
        // hide scan view
        scanView.isHidden = true
        
        speechRunning = true
        
        let screenShot = snapshot(of: scanView.frame)!
        //UIImageWriteToSavedPhotosAlbum(screenShot, self, nil, nil)
        // Get the CGImage on which to perform requests.
        guard let cgImage = screenShot.cgImage else { return }

        // Create a new image-request handler.
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)

        // Create a new request to recognize text.
        let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)

        do {
            // Perform the text-recognition request.
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the requests: \(error).")
        }
        
    }
    @IBAction func arPress(_ sender: UIButton) {
        // hide speech and ar buttons
        speechButton.isUserInteractionEnabled = false
        speechButton.isHidden = true
        arButton.isUserInteractionEnabled = false
        arButton.isHidden = true
        
        // disable pinch gesture
        //TODO:
        
        //reveal cancel button
        cancelButton.isHidden = false
        cancelButton.isUserInteractionEnabled = true
        
        // hide scan view
        scanView.isHidden = true
        
        arRunning = true
        
        let screenShot = snapshot(of: scanView.frame)!
        //UIImageWriteToSavedPhotosAlbum(screenShot, self, nil, nil)
        // Get the CGImage on which to perform requests.
        guard let cgImage = screenShot.cgImage else { return }

        // Create a new image-request handler.
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)

        // Create a new request to recognize text.
        let request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)

        do {
            // Perform the text-recognition request.
            try requestHandler.perform([request])
        } catch {
            print("Unable to perform the requests: \(error).")
        }
    }
    
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        guard let observations =
                request.results as? [VNRecognizedTextObservation] else {
            return
        }
        let recognizedStrings = observations.compactMap { observation in
            // Return the string of the top VNRecognizedText instance.
            return observation.topCandidates(1).first?.string
        }
        
        print(recognizedStrings)
        self.message = recognizedStrings
        
        if(arRunning){
            // increment AR_reads
            incrementARReads()
            
            // detect AR plane
            configuration.planeDetection = .horizontal
            sceneView.session.run(configuration)
            
            guard message.indices.count != 0 else {
                SCLAlertView().showWarning("Invalid Writing", subTitle: "Unable to recognize. Please try again.")
                return
            }
            
            // retrieve AR model
            retrieveARModelDirectly(named: message[0])  // only 1st word
            
        }
        else if(speechRunning){
            // increment speech_reads
            incrementSpeechReads()
            
            Start()
        }
        
    }
    
    func incrementARReads(){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yy"
         
        let date = Date()
        
        let dateString = dateFormatter.string(from: date)
        
        let db = Firestore.firestore()
        let docRef = db.collection("Data").document(dateString)
        
        //get user document
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                //check if AR_reads field exists
                if var AR_reads =  document.get("AR_reads") as? Int{
                    //increment AR_reads
                    AR_reads+=1
                    //push to firebase
                    document.reference.updateData([
                    "AR_reads": AR_reads
                    ])
                    print("Updated AR_Reads in firebase")
                } else{
                    print("Error updating AR_Reads in firebase!")
                }
            } else {
                print("Document does not exist: creating new date document")
                //create new document for today's date
                // Add a new document in collection
                db.collection("Data").document(dateString).setData([
                    "AR_reads": 1,
                    "speech_reads": 0,
                    "written_correct": 0 ,
                    "written_incorrect" : 0,
                ]) { err in
                    if let err = err {
                        print("Error writing new document: \(err)")
                    } else {
                        print("New document successfully written!")
                    }
                }
            }
        }
    }
    
    func incrementSpeechReads(){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yy"
         
        let date = Date()
        
        let dateString = dateFormatter.string(from: date)
        
        let db = Firestore.firestore()
        let docRef = db.collection("Data").document(dateString)
        
        //get user document
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                //check if speech_reads field exists
                if var speech_reads =  document.get("speech_reads") as? Int{
                    //increment speech_reads
                    speech_reads+=1
                    //push to firebase
                    document.reference.updateData([
                    "speech_reads": speech_reads
                    ])
                    print("Updated speech_reads in firebase")
                } else{
                    print("Error updating speech_reads in firebase!")
                }
            } else {
                print("Document does not exist: creating new date document")
                //create new document for today's date
                // Add a new document in collection
                db.collection("Data").document(dateString).setData([
                    "AR_reads": 0,
                    "speech_reads": 1,
                    "written_correct": 0 ,
                    "written_incorrect" : 0,
                ]) { err in
                    if let err = err {
                        print("Error writing new document: \(err)")
                    } else {
                        print("New document successfully written!")
                    }
                }
            }
        }
    }
    
    func retrieveARModelDirectly(named word: String){
        e.loadSceneFromFilename(filename: "\(word).glb") {
            (selectedScene) in
            //make sure the scene has a scene node
            guard let selectedNode = selectedScene.rootNode.childNodes.first else {return}
            arNode = selectedNode
        }
    }
    func retrieveARModelID(named word: String){
        //e.loadSceneFromEntryID(entryID: "9b677aec-5859-4459-a51e-42d6de0ea4bf"){
//        e.loadSceneFromFilename(filename: "\(word).glb") {
//            (selectedScene) in
//            //make sure the scene has a scene node
//            guard let selectedNode = selectedScene.rootNode.childNodes.first else {return}
//            arNode = selectedNode
//        }
//        return
        // retrieve model id from firebase
        let db = Firestore.firestore()
        let docRef = db.collection("echo3DModels").document(word)
        //get location document
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                if var identifier = document.get("identifier") as? String{
                    // retrieve model from echo3D
                    print("retrieved \(word) id from firebase")
                    self.retrieveEcho3DModel(with: identifier)
                }
           }
           else {
               print("Document does not exist. \(word) model not downloaded")
           }
       }
    }
    func retrieveEcho3DModel(with identifier: String){
        //load scene (3d model) from echo3D using the entry id
        e.loadSceneFromEntryID(entryID: identifier) { (selectedScene) in
            //make sure the scene has a scene node
            guard let selectedNode = selectedScene.rootNode.childNodes.first else {return}
            arNode = selectedNode
//            //get the translation, or where we will be adding our node
//            let translation = SCNVector3Make(myPlaneNode.worldTransform.columns.3.x, myPlaneNode.worldTransform.columns.3.y, myPlaneNode.worldTransform.columns.3.z
//            let y = translation.y
//            let z = translation.z
//
//            //set the position of the node
//            selectedNode.position = SCNVector3(x,y,z)
//
//            //scale down the node using our scale constants
//            let action = SCNAction.scale(by: 0.005, duration: 0.3)
//
//            selectedNode.runAction(action)
//
//
//            //add the node to our scene
//            sceneView.scene.rootNode.addChildNode(selectedNode)
        }
        
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        //
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        speechSynthesizer.stopSpeaking(at: .word)
        Pause()
        
        count+=1
        if count < message.count {
            let speechUtterance = AVSpeechUtterance(string: message[count])
            DispatchQueue.main.async {
                self.speechSynthesizer.speak(speechUtterance)
            }
        }else{
            count = 0
//            speechRunning = false
            //speakBtn.isSelected = false
        }
    }
    
    func Start(){
        if speechSynthesizer.isSpeaking{
            speechSynthesizer.stopSpeaking(at: .immediate)
        }else{
            guard message.indices.count != 0 else {
                SCLAlertView().showWarning("Invalid Writing", subTitle: "Unable to recognize. Please try again.")
                return Pause()
            }
            
            let speechUtterance = AVSpeechUtterance(string: (message[count]))
            DispatchQueue.main.async {
                self.speechSynthesizer.speak(speechUtterance)
            }
        }
    }
    

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    private func addPinchGesture() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        //self.scanView.addGestureRecognizer(pinchGesture)
        let pinchGesture2 = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch2(_:)))
        self.sceneView.addGestureRecognizer(pinchGesture2)
    }
    
    @objc func handlePinch(_ sender: UIPinchGestureRecognizer) {
        if sender.state == .began || sender.state == .changed {
            let mode = _mode(sender)
            if(mode=="H"){
                sender.view?.transform = (sender.view?.transform.scaledBy(x: sender.scale, y: 1))!
                 sender.scale = 1.0
            }
            else if(mode=="V"){
                sender.view?.transform = (sender.view?.transform.scaledBy(x: 1, y: sender.scale))!
                 sender.scale = 1.0
            }
            else{
                sender.view?.transform = (sender.view?.transform.scaledBy(x: sender.scale, y: sender.scale))!
                 sender.scale = 1.0
            }
        }}
    @objc func handlePinch2(_ sender: UIPinchGestureRecognizer) {
        if sender.state == .began || sender.state == .changed {
            let mode = _mode(sender)
            if(mode=="H"){
                scanView.transform = (scanView.transform.scaledBy(x: sender.scale
                                                                  , y: 1))
                
                //let pinchScaleX = Float(sender.scale) * planeNode.scale.x
                //planeNode.scale = SCNVector3(pinchScaleX, planeNode.scale.y, planeNode.scale.z)
                sender.scale = 1.0
                
            }
            else if(mode=="V"){
                scanView.transform = (scanView.transform.scaledBy(x: 1, y: sender.scale))
                
                //let pinchScaleY = Float(sender.scale) * planeNode.scale.y
                //planeNode.scale = SCNVector3(planeNode.scale.x, pinchScaleY, planeNode.scale.z)
                sender.scale = 1.0
            }
            //else{
                //scanView.transform = (scanView.transform.scaledBy(x: scanView.contentScaleFactor, y: scanView.contentScaleFactor))
                //scanView.contentScaleFactor = 1.0
                //scale = 1.0
            //}
        }}
    func _mode(_ sender: UIPinchGestureRecognizer)->String {

        // very important:
        if sender.numberOfTouches < 2 {
            print("avoided an obscure crash!!")
            return ""
        }

        let A = sender.location(ofTouch: 0, in: self.view)
        let B = sender.location(ofTouch: 1, in: self.view)

        let xD = abs( A.x - B.x )
        let yD = abs( A.y - B.y )
        if (xD == 0) { return "V" }
        if (yD == 0) { return "H" }
        let ratio = xD / yD
        // print(ratio)
        if (ratio > 1) { return "H" }
        if (ratio <= 1) { return "V" }
        return "D"
    }
    func snapshot(of rect: CGRect? = nil) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, self.view.isOpaque, 0)
        self.view.drawHierarchy(in: self.view.bounds, afterScreenUpdates: true)
        let fullImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let image = fullImage, let rect = rect else { return fullImage }
        let scale = image.scale
        let scaledRect = CGRect(x: rect.origin.x * scale, y: rect.origin.y * scale, width: rect.size.width * scale, height: rect.size.height * scale)
        guard let cgImage = image.cgImage?.cropping(to: scaledRect) else { return nil }
        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }
}
extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

extension UIColor {
    open class var transparentLightBlue: UIColor {
        return UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 0.50)
    }
}



