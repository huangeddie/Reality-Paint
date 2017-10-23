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
    @IBOutlet weak var distanceLabel: UILabel!
    
    
    /// True means that it's a dot; False means it's a connecting line
    var pastNodes = [(node: SCNNode, dot: Bool)]()
    
    var breakConnection = false
    
    @IBAction func reset(_ sender: Any) {
        while let (pastNode, _) = pastNodes.popLast() {
            pastNode.removeFromParentNode()
        }
        
        updateDistanceLabel()
    }
    
    @IBAction func undo(_ sender: Any) {
        guard let (lastNode, isDot) = pastNodes.popLast() else {
            return
        }
        guard isDot else {
            fatalError("Unexpected line node")
        }
        
        lastNode.removeFromParentNode()
        
        while let (lineNode, isDot2) = pastNodes.last, isDot2 == false {
            lineNode.removeFromParentNode()
            pastNodes.removeLast()
        }
        
        updateDistanceLabel()
    }
    @IBAction func `breakConnection`(_ sender: Any) {
        breakConnection = true
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Debug
        sceneView.debugOptions = SCNDebugOptions(rawValue: ARSCNDebugOptions.showWorldOrigin.rawValue | ARSCNDebugOptions.showFeaturePoints.rawValue)
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
        
        let cameraNode = getCameraNode()
        crossHairNode.position = SCNVector3(0.0, 0.0, -0.1)
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

    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let height = sceneView.bounds.height
        let width = sceneView.bounds.width
        let centerPoint = CGPoint(x: width / 2, y: height / 2)
        let results = sceneView.hitTest(centerPoint, types: .featurePoint)
        
        guard let firstHit = results.last else {
            return
        }
        
        let dotPosition = SCNVector3(MDLTransform(matrix: firstHit.worldTransform).translation)
        
        if let (lastNode, isDot) = pastNodes.last, breakConnection == false {
            guard isDot else {
                fatalError("Unexpected line node")
            }
            let lastPosition = lastNode.position
            addConnectionNodes(lastPosition, dotPosition)
        }
        
        addDotNode(position: dotPosition)
        
        breakConnection = false
        
        updateDistanceLabel()
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
    private func updateDistanceLabel() {
        if let (a,b) = getLastTwoDotsIfConnected() {
            let distance = getDistance(a, b)
            
            distanceLabel.text = "\((distance * 100).rounded() / 100.0) m"
        } else {
            distanceLabel.text = "-"
        }
    }
    
    private func getLastTwoDotsIfConnected() -> (SCNVector3,SCNVector3)? {
        
        guard let (lastNode, isDot) = pastNodes.last, pastNodes.count > 2 else {
            return nil
        }
        
        guard isDot else {
            fatalError("Unexpected connection node")
        }
        
        let (_, isDot2) = pastNodes[pastNodes.count - 2]
        
        if isDot2 {
            // This was a broken connection
            return nil
        }
        
        for i in (0..<(pastNodes.count - 1)).reversed() {
            let (pastNode, isDot3) = pastNodes[i]
            if isDot3 {
                return (pastNode.position, lastNode.position)
            }
        }
        fatalError("Could not get expected last two dots that were connected")
    }
    
    private func getCameraNode() -> SCNNode {
        for node in sceneView.scene.rootNode.childNodes {
            if node.camera != nil {
                return node
            }
        }
        
        fatalError("Could not get camera node")
    }
    
    private func addConnectionNodes(_ a: SCNVector3, _ b: SCNVector3) {
        let deltaVector = b - a
        let distance = getDistance(a, b)
        
        let radius: Float = 0.01
        
        let numberOfConnectionNodes = Int(round(distance / radius))
        
        let stepVector = deltaVector / Float(numberOfConnectionNodes + 1)
        for i in 1...numberOfConnectionNodes {
            let position = a + (Float(i) * stepVector)
            
            addDotNode(position: position, connector: false)
        }
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
    
    private func addDotNode(position: SCNVector3, connector: Bool = true) {
        guard let sphereScene = SCNScene(named: "art.scnassets/dot.scn") else {
            fatalError("Could not get dot scene")
        }
        let dotNode = SCNNode()
        for child in sphereScene.rootNode.childNodes {
            child.geometry?.firstMaterial?.lightingModel = .physicallyBased
            dotNode.addChildNode(child)
        }
        
        dotNode.position = position
        sceneView.scene.rootNode.addChildNode(dotNode)
        
        pastNodes.append((node: dotNode, dot: connector))
    }
    
    private func getPositionInFrontOfCamera(distance: Float) -> SCNVector3 {
        
        let height = sceneView.bounds.height
        let width = sceneView.bounds.width
        let centerPoint = CGPoint(x: width / 2, y: height / 2)
        let results = sceneView.hitTest(centerPoint, types: .featurePoint)
        
        var (cameraTranslation, cameraRotation) = getCameraTranslationAndRotation()
        
        guard let farthestHitTest = results.last else {
            // Do it with trig
            let zOffSet = distance * cos(cameraRotation.x) * cos(cameraRotation.y)
            let yOffSet = distance * sin(cameraRotation.x) * sin(cameraRotation.z)
            let xOffSet = distance * sin(cameraRotation.y) * sin(cameraRotation.z)
            
            cameraTranslation.z -= zOffSet
            cameraTranslation.y -= yOffSet
            cameraTranslation.x += xOffSet
            
            return SCNVector3(cameraTranslation)
        }
        
        let hitDistance = farthestHitTest.distance
        let hitTranslation = MDLTransform(matrix: farthestHitTest.worldTransform).translation
        
        let unitDeltaVector = (SCNVector3(hitTranslation) - SCNVector3(cameraTranslation)) / Float(hitDistance)
        
        return SCNVector3(cameraTranslation) + unitDeltaVector * distance
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
