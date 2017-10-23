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
    
    @IBAction func reset(_ sender: Any) {
        for node in sceneView.scene.rootNode.childNodes {
            if node.camera == nil && node.light == nil{
                node.removeFromParentNode()
            }
        }
    }
    
    @IBAction func undo(_ sender: Any) {
        
        if let lastNode = sceneView.scene.rootNode.childNodes.last {
            if lastNode.camera == nil && lastNode.light == nil{
                lastNode.removeFromParentNode()
            }
        }
        
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
        
        guard let sphereScene = SCNScene(named: "art.scnassets/sphere.scn") else {
            fatalError("Could not get sphere scene")
        }
        
        let wrapperNode = SCNNode()
        for child in sphereScene.rootNode.childNodes {
            child.geometry?.firstMaterial?.lightingModel = .physicallyBased
            wrapperNode.addChildNode(child)
        }
        
        let spherePosition = getPositionInFrontOfCamera(distance: offSet)
        
        wrapperNode.position = spherePosition
        sceneView.scene.rootNode.addChildNode(wrapperNode)
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
