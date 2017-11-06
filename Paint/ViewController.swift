//
//  ViewController.swift
//  Paint
//
//  Created by Edward Huang on 10/22/17.
//  Copyright © 2017 Eddie Huang. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var distanceSlider: UISlider!
    
    /// True means that it's a dot; False means it's a connecting line
    var drawNodes = [SCNNode]()
    
    var debug = false
    
    var breakConnection = false
    
    let minimumDistance: Float = 0.1
    let maximumDistance: Float = 1.0
    
    var distance: Float = 1.0
    var crossHairNode: SCNNode!
    
    let crossHairOffsetDistance: Float = 0.03
    
    var timer = Timer()
    
    @IBAction func distanceChanged(_ sender: UISlider) {
        let value = sender.value
    
        distance = minimumDistance + (maximumDistance - minimumDistance) * value
        
        crossHairNode.position = SCNVector3(0, 0, -distance + crossHairOffsetDistance)
    }
    
    
    
    @IBAction func reset(_ sender: Any) {
        while let node = drawNodes.popLast() {
            node.removeFromParentNode()
        }
    }
    @IBAction func toggleDebug(_ sender: Any) {
        debug = !debug
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = debug
        
        if debug {
            sceneView.debugOptions = SCNDebugOptions(rawValue: ARSCNDebugOptions.showWorldOrigin.rawValue | ARSCNDebugOptions.showFeaturePoints.rawValue)
        } else {
            sceneView.debugOptions = SCNDebugOptions(rawValue: 0)
        }
        
        let debugAlert = UIAlertController(title: nil, message: "Debugging is \(debug ? "on" : "off")", preferredStyle: UIAlertControllerStyle.alert)
        
        present(debugAlert, animated: true) {
            sleep(1)
            debugAlert.dismiss(animated: true)
        }
        
        reset(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
        
        // Add cross hair
        guard let crossHairScene = SCNScene(named: "art.scnassets/crossHair.scn") else {
            fatalError("Could not get crossHair scene")
        }
        let crossHairNode = SCNNode()
        for child in crossHairScene.rootNode.childNodes {
            crossHairNode.addChildNode(child)
        }
        
        self.crossHairNode = crossHairNode
        
        // Set the distance marker
        distance = (minimumDistance + maximumDistance) / 2
        distanceSlider.value = distance
        
        let cameraNode = getCameraNode()
        crossHairNode.position = SCNVector3(0.0, 0.0, -distance + crossHairOffsetDistance)
        cameraNode.addChildNode(crossHairNode)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // MARK：Drawing
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        timer.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.0, target: self, selector: #selector(draw), userInfo: nil, repeats: true)
    }
 
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        timer.invalidate()
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        timer.invalidate()
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
    
    // MARK: Private Methods
    
    @objc private func draw() {
        // This is where we get our dots from
        let sphereScene = SCNScene(named: "art.scnassets/dot.scn")!
        
        let dotNode = SCNNode()
        for child in sphereScene.rootNode.childNodes {
            child.geometry?.firstMaterial?.lightingModel = .physicallyBased
            dotNode.addChildNode(child)
        }
        
        let position = self.getPositionInFrontOfCamera(distance: self.distance)
        dotNode.position = position
        self.sceneView.scene.rootNode.addChildNode(dotNode)
        self.drawNodes.append(dotNode)
    }
    
    private func getCameraNode() -> SCNNode {
        for node in sceneView.scene.rootNode.childNodes {
            if node.camera != nil {
                return node
            }
        }
        
        fatalError("Could not get camera node")
    }
    
    private func getDistance(_ a: SCNVector3, _ b: SCNVector3) -> Float {
        let dX = a.x - b.x
        let dY = a.y - b.y
        let dZ = a.z - b.z
        
        let sumSqr = pow(dX, 2) + pow(dY, 2) + pow(dZ, 2)
        
        return sqrt(sumSqr)
    }
    
    private func getAveragePosition(_ a: SCNVector3, _ b: SCNVector3) -> SCNVector3 {
        return SCNVector3((a.x + b.x)/2, (a.y + b.y)/2, (a.z + b.z)/2)
    }
    
    private func getPositionInFrontOfCamera(distance: Float) -> SCNVector3 {
        
        let cameraNode = getCameraNode()
        
        let positionRelativeToCamera = SCNVector3(0.0, 0.0, -distance)
        
        let worldPosition = cameraNode.convertPosition(positionRelativeToCamera, to: sceneView.scene.rootNode)
        
        return worldPosition
    }
    
    private func getCameraTranslationAndRotation() -> (translation: vector_float3, rotation: vector_float3) {
        guard let camera = sceneView.session.currentFrame?.camera else {
            fatalError("Could not get camera transform")
        }
        let cameraTranslation = MDLTransform(matrix: camera.transform).translation
        let cameraRotation = camera.eulerAngles
        
        return (translation: cameraTranslation, rotation: cameraRotation)
    }
    
    // MARK: Delegation
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
    }
}
