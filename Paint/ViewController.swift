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
    
    
    /// True means that it's a dot; False means it's a connecting line
    var pastNodes = [(node: SCNNode, dot: Bool)]()
    
    var breakConnection = false
    
    @IBAction func reset(_ sender: Any) {
        while let (pastNode, _) = pastNodes.popLast() {
            pastNode.removeFromParentNode()
        }
    }
    
    @IBAction func undo(_ sender: Any) {
        guard let (lastNode, isDot) = pastNodes.popLast() else {
            return
        }
        guard isDot else {
            fatalError("Unexpected line node")
        }
        
        lastNode.removeFromParentNode()
        
        guard let (secondToLastNode, isDot2) = pastNodes.popLast(), isDot2 == false else {
            return
        }
        
        secondToLastNode.removeFromParentNode()
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
        print("Number of child nodes: \(sceneView.scene.rootNode.childNodes.count)")
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
        let offSet: Float = 1
        
        let dotPosition = getPositionInFrontOfCamera(distance: offSet)
        
        if let (lastNode, isDot) = pastNodes.last, breakConnection == false {
            guard isDot else {
                fatalError("Unexpected line node")
            }
            let lastPosition = lastNode.position
            addConnectionNode(lastPosition, dotPosition)
        }
        
        addDotNode(position: dotPosition)
        
        breakConnection = false
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
    private func addConnectionNode(_ a: SCNVector3, _ b: SCNVector3) {
        let averagePosition = getAveragePosition(a, b)
        let distance = getDistance(a, b)
        let lineGeom = SCNCylinder(radius: 0.03, height: CGFloat(distance))
        lineGeom.firstMaterial?.diffuse.contents = UIColor.red
        
        let lineNode = SCNNode(geometry: lineGeom)
        
        lineNode.position = averagePosition
        
        var xRot = atan((b.z - a.z)/(b.y - a.y))
        var yRot: Float = 0.0
        var zRot = acos((b.x - a.x)/(b.y - a.y))
        
        xRot = xRot.isNaN ? Float.pi / 2 : xRot
        yRot = yRot.isNaN ? Float.pi / 2 : yRot
        zRot = zRot.isNaN ? Float.pi / 2 : zRot
        
        let rotation = SCNVector3(xRot, yRot, zRot)
        
        print("a: \(a)")
        print("b: \(b)")
        print("rotation: \(xRot.radiansToDegrees), \(yRot.radiansToDegrees), \(zRot.radiansToDegrees)")
        
        lineNode.eulerAngles = rotation
        
        sceneView.scene.rootNode.addChildNode(lineNode)
        pastNodes.append((node: lineNode, dot: false))
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
    
    private func addDotNode(position: SCNVector3) {
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
        
        pastNodes.append((node: dotNode, dot: true))
    }
    
    private func getPositionInFrontOfCamera(distance: Float) -> SCNVector3 {
        var (translation, rotation) = getCameraTranslationAndRotation()
        let zOffSet = distance * cos(rotation.x) * cos(rotation.y)
        let yOffSet = distance * sin(rotation.x) * sin(rotation.z)
        let xOffSet = distance * sin(rotation.y) * sin(rotation.z)
        
        translation.z -= zOffSet
        translation.y -= yOffSet
        translation.x += xOffSet
        
        return SCNVector3(translation)
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
