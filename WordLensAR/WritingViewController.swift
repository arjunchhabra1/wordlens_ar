//
//  WritingViewController.swift
//  WordLensAR
//
//  Created by arjun on 7/28/23.
//

import UIKit
import SceneKit
import ARKit
import SpriteKit
import AVFoundation
import Firebase
import FirebaseFirestore

class WritingViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet weak var writingButton: UIButton!
    
    @IBOutlet weak var cancelButton: UIButton!
    
//    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var scanView: UIImageView!
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    var myPlaneNode: SCNNode! = nil

    var text:String!
    var ocrRequest: VNRecognizeTextRequest!
    var arNode: SCNNode!
    
    var arRunning = false
    
    var count: Int = 0
    var message: [String] = []
    
    var words: [String] = []
    
    var configuration: ARWorldTrackingConfiguration!
    override func viewDidLoad() {
        super.viewDidLoad()

        //disable cancel button
        cancelButton.isUserInteractionEnabled = false
        cancelButton.isHidden = true
        
//        continueButton.isUserInteractionEnabled = false
//        continueButton.isHidden = true
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        //set scene view to automatically add omni directional light when needed
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
        
        // round corners
        scanView.layer.cornerRadius = 15
        scanView.clipsToBounds = true
       
        writingButton.layer.cornerRadius = 15
        writingButton.clipsToBounds = true
        
        cancelButton.layer.cornerRadius = 15
        cancelButton.clipsToBounds = true
        
        // load dictionary for autocorrect
        loadDict()
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
        
       
        //sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
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
        plane.materials.first?.diffuse.contents = UIColor.transparentLightBlue
       
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
            let action = SCNAction.scale(by: 0.001, duration: 0.3)
            selectedNode.runAction(action)
                
            (selectedNode.geometry as! SCNText).extrusionDepth = 0.0
            (selectedNode.geometry as! SCNText).flatness = 0.1
            
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
        // reveal writing button
        writingButton.isUserInteractionEnabled = true
        writingButton.isHidden = false
        
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
    }
    @IBAction func scanPressed(_ sender: UIButton) {
        // hide writing buttons
        writingButton.isUserInteractionEnabled = false
        writingButton.isHidden = true
        
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
            // detect AR plane
            configuration.planeDetection = .horizontal
            sceneView.session.run(configuration)
            
            
            // retrieve string from ML model
            //TODO
            
            /* using OCR for now*/
            // convert to lowercase
            let word = message[0].lowercased() // only first word!
            let result = isAWord(word)
            if(result==1){
                // correct word!
                //TODO
            }
            else if(result==0){
                let autoResult: String = String(cString: autocorrect(word))
                var fullNameArr = autoResult.components(separatedBy: " ")
//                continueButton.isUserInteractionEnabled = true
//                continueButton.isHidden = false
                words = fullNameArr
                self.performSegue(withIdentifier: "autocorrectsegue", sender: nil)
                print(fullNameArr)
            }
            
            // retrieve AR model
            let txt = SCNText(string: word, extrusionDepth: 0.0) // TODO: insert correct string
            txt.firstMaterial?.diffuse.contents = UIColor.black
            // When creating 2D text, just set extrusionDepth to 0.
            txt.extrusionDepth = 0.0
            arNode = SCNNode(geometry: txt)
        }
    }
    
    //
//    @IBAction func continuePressed(_ sender: UIButton){
//
//    }
    
    private func addPinchGesture() {
        let pinchGesture2 = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch2(_:)))
        self.sceneView.addGestureRecognizer(pinchGesture2)
    }
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
//extension float4x4 {
//    var translation: float3 {
//        let translation = self.columns.3
//        return float3(translation.x, translation.y, translation.z)
//    }
//}
//
//extension UIColor {
//    open class var transparentLightBlue: UIColor {
//        return UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 0.50)
//    }
//}
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if let nextViewController = segue.destination as? AutoCorrectViewController {
                //send name of selected file to ReviewMode VC
                nextViewController.nextWords = words
            }
        }
    }
    

