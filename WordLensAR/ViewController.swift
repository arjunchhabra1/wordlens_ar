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
//import Firebase
//import FirebaseFirestore
//import SCLAlertView

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
        
        //  e = Echo3D()
        
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
}


