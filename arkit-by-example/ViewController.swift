//
//  ViewController.swift
//  arkit-by-example
//
//  Created by Can Bal on 8/5/17.
//  Copyright © 2017 CB. All rights reserved.
//

import ARKit
import SceneKit
import UIKit

class ViewController: UIViewController, UIPopoverPresentationControllerDelegate, ARSCNViewDelegate, UIGestureRecognizerDelegate, SCNPhysicsContactDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var messageViewer: MessageView!
    
    // A dictionary of all the current planes being rendered in the scene
    var planes = [UUID: Plane]()
    var planesHidden: Bool = false
    // A list of all the cubes being rendered in the scene
    var cubes: [SCNNode] = []
    
    // Config parameters
    var config: Config = Config()
    var arConfig: ARWorldTrackingSessionConfiguration = ARWorldTrackingSessionConfiguration()
    
   override func viewDidLoad() {
        super.viewDidLoad()
    
        setupScene()
        setupLights()
        setupPhysics()
        setupRecognizers()
        
        // Create an ARSession config object we can re-use
        arConfig.isLightEstimationEnabled = true
        arConfig.planeDetection = .horizontal
        
        config.showStatistics = false
        config.showWorldOrigin = true
        config.showFeaturePoints = true
        config.showPhysicsBodies = false
        config.detectPlanes = true
        updateConfig()
        
        // Stop the screen from dimming while we are using the app
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Run the view's session
        sceneView.session.run(arConfig, options: ARSession.RunOptions(rawValue: 0))
        showMessage(message: "Tracking is initializing")
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
    
    func setupScene() {
        // Set the view's delegate
        sceneView.delegate = self
        
        // Make things look pretty :)
        sceneView.antialiasingMode = .multisampling4X
        
        // This is the object that we add all of our geometry to, if you want
        // to render something you need to add it here
        let scene = SCNScene()

        // Set the scene to the view
        sceneView.scene = scene
    }
    
    func setupPhysics() {
        // For our physics interactions, we place a large node a couple of meters below the world
        // origin, after an explosion, if the geometry we added has fallen onto this surface which
        // is place way below all of the surfaces we would have detected via ARKit then we consider
        // this geometry to have fallen out of the world and remove it
        let bottomPlane = SCNBox(width: 1000, height: 0.5, length: 1000, chamferRadius: 0)
        let bottomMaterial = SCNMaterial()
        
        // Make it transparent so you can't see it
        bottomMaterial.diffuse.contents = UIColor(white: 1.0, alpha: 0.0)
        bottomPlane.materials = [bottomMaterial]
        let bottomNode = SCNNode(geometry: bottomPlane)
        
        // Place it way below the world origin to catch all falling cubes
        bottomNode.position = SCNVector3Make(0, -10, 0);
        bottomNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
        bottomNode.physicsBody?.categoryBitMask = CollisionCategory.bottom.rawValue
        bottomNode.physicsBody?.contactTestBitMask = CollisionCategory.cube.rawValue
        sceneView.scene.rootNode.addChildNode(bottomNode)
        sceneView.scene.physicsWorld.contactDelegate = self
    }
    
    func setupLights() {
        // Turn off all the default lights SceneKit adds since we are handling it ourselves
        sceneView.autoenablesDefaultLighting = false
        sceneView.automaticallyUpdatesLighting = false
        
        let env = UIImage(named: "./Assets.scnassets/Environment/spherical.jpg")
        sceneView.scene.lightingEnvironment.contents = env
    }
    
    func setupRecognizers() {
        // Single tap will insert a new piece of geometry into the scene
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(insertCubeFrom(_:)))
        tapGestureRecognizer.numberOfTapsRequired = 1
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        // Press and hold will open a config menu for the selected geometry
        let materialGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(geometryConfigFrom(_:)))
        materialGestureRecognizer.minimumPressDuration = 0.5
        materialGestureRecognizer.numberOfTouchesRequired = 1
        sceneView.addGestureRecognizer(materialGestureRecognizer)
        
        // Press and hold with two fingers causes explosion
        let explodeGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(explodeFrom(_:)))
        explodeGestureRecognizer.minimumPressDuration = 1
        explodeGestureRecognizer.numberOfTouchesRequired = 2
        sceneView.addGestureRecognizer(explodeGestureRecognizer)
    }
    
    @objc func insertCubeFrom(_ sender: UITapGestureRecognizer) {
        // Take the screen space tap coordinates and pass them to the
        // hitTest method on the ARSCNView instance
        let tapPoint = sender.location(in: sceneView)
        let result = sceneView.hitTest(tapPoint, types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
        
        // If the intersection ray passes through any plane geometry they
        // will be returned, with the planes ordered by distance
        // from the camera
        if (result.count == 0) {
            return;
        }
        // If there are multiple hits, just pick the closest plane
        insertCube(hitResult: result.first!)
    }
    
    @objc func explodeFrom(_ sender: UILongPressGestureRecognizer) {
        if (sender.state != .began) {
            return;
        }
        
        // Perform a hit test using the screen coordinates to see if the user pressed on a plane.
        let holdPoint = sender.location(in: sceneView)
        let result = sceneView.hitTest(holdPoint, types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
        if (result.count == 0) {
            return;
        }
        
        let hitResult = result.first!
        DispatchQueue.global(qos: .userInitiated).async {
            self.explode(hitResult)
        }
    }
    
    @objc func geometryConfigFrom(_ sender: UILongPressGestureRecognizer) {
        if (sender.state != .began) {
            return;
        }
        
        // Perform a hit test using the screen coordinates to see if the user pressed on
        // any 3D geometry in the scene, if so we will open a config menu for that
        // geometry to customize the appearance
        
        let holdPoint = sender.location(in: sceneView)
        var results = [SCNHitTestResult]()
        if #available(iOS 12.0, *) {
            results = sceneView.hitTest(holdPoint,
                                        options: [SCNHitTestOption.boundingBoxOnly: true,
                                                  SCNHitTestOption.searchMode: SCNHitTestSearchMode.all])
        } else {
            results = sceneView.hitTest(holdPoint,
                                        options: [SCNHitTestOption.boundingBoxOnly: true,
                                                  SCNHitTestOption.firstFoundOnly: false])
        }
        for result in results {
            // We add all the geometry as children of the Plane/Cube SCNNode object, so we can
            // get the parent and see what type of geometry this is
            let parentNode = result.node.parent
            if (parentNode is Cube) {
                (parentNode as! Cube).changeMaterial()
                return
            } else if (parentNode is Plane) {
                (parentNode as! Plane).changeMaterial()
                return
            }
        }
    }
    
    func hidePlanes() {
        for plane in planes {
            plane.value.hide()
        }
    }
    
    func disableTracking(disabled: Bool) {
        // Stop detecting new planes or updating existing ones.
        if (disabled) {
            arConfig.planeDetection = []
        } else {
            arConfig.planeDetection = .horizontal
        }
        sceneView.session.run(arConfig)
    }
    
    func explode(_ hitResult: ARHitTestResult) {
        // For an explosion, we take the world position of the explosion and the position of each piece of geometry
        // in the world. We then take the distance between those two points, the closer to the explosion point the
        // geometry is the stronger the force of the explosion.
        
        // The hitResult will be a point on the plane, we move the explosion down a little bit below the
        // plane so that the goemetry fly upwards off the plane
        let explosionYOffset: Float = 0.1
        
        let position = SCNVector3Make(hitResult.worldTransform.columns.3.x,
                                      hitResult.worldTransform.columns.3.y - explosionYOffset,
                                      hitResult.worldTransform.columns.3.z)
        
        // We need to find all of the geometry affected by the explosion, ideally we would have some
        // spatial data structure like an octree to efficiently find all geometry close to the explosion
        // but since we don't have many items, we can just loop through all of the current geoemtry
        for cubeNode in cubes {
            // The distance between the explosion and the geometry
            var distance = SCNVector3Make(cubeNode.worldPosition.x - position.x,
                                          cubeNode.worldPosition.y - position.y,
                                          cubeNode.worldPosition.z - position.z)
            
            let len = sqrtf(distance.x * distance.x + distance.y * distance.y + distance.z * distance.z)
            
            // Set the maximum distance that the explosion will be felt, anything further than 2 meters from
            // the explosion will not be affected by any forces
            let maxDistance: Float = 2;
            var scale = max(0, (maxDistance - len))
            
            // Scale the force of the explosion
            scale = scale * scale * 5;
            
            // Scale the distance vector to the appropriate scale
            distance.x = distance.x / len * scale;
            distance.y = distance.y / len * scale;
            distance.z = distance.z / len * scale;
            
            // Apply a force to the geometry. We apply the force at one of the corners of the cube
            // to make it spin more, vs just at the center
            cubeNode.childNodes.first?.physicsBody?.applyForce(distance, at: SCNVector3Make(0.05, 0.05, 0.05), asImpulse: true)
        }
    }
    
    func insertCube(hitResult: ARHitTestResult) {
        // We insert the geometry slightly above the point the user tapped
        // so that it drops onto the plane using the physics engine
        let insertionYOffset: Float = 0.5
        let position = SCNVector3Make(
            hitResult.worldTransform.columns.3.x,
            hitResult.worldTransform.columns.3.y + insertionYOffset,
            hitResult.worldTransform.columns.3.z)
        let cube = Cube(position: position, material: Cube.currentMaterial())
        cubes.append(cube)
        sceneView.scene.rootNode.addChildNode(cube)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Called just before we transition to the config screen
        let configController = segue.destination as! ConfigViewController
        
        // NOTE: I am using a popover so that we do't get the viewWillAppear method called when
        // we close the popover, if that gets called (like if you did a modal settings page), then
        // the session configuration is updated and we lose tracking. By default it shouldn't but
        // it still seems to.
        configController.modalPresentationStyle = .popover
        configController.popoverPresentationController?.delegate = self
        configController.config = config
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    @IBAction func settingsUnwind(segue: UIStoryboardSegue) {
        // Called after we navigate back from the config screen
        let configView = segue.source as! ConfigViewController
        config.showPhysicsBodies = configView.physicsBodies.isOn
        config.showFeaturePoints = configView.featurePoints.isOn
        config.showWorldOrigin = configView.worldOrigin.isOn
        config.showStatistics = configView.statistics.isOn
        updateConfig()
    }
    
    @IBAction func detectPlanesChanged(sender: UISwitch) {
        let enabled = sender.isOn
        if (config.detectPlanes == enabled) {
            return
        }
        
        config.detectPlanes = enabled
        if (enabled) {
            disableTracking(disabled: false)
        } else {
            disableTracking(disabled: true)
        }
    }
    
    func updateConfig() {
        var opts: SCNDebugOptions = []
        if (config.showWorldOrigin) {
            opts.insert(ARSCNDebugOptions.showWorldOrigin)
        }
        if (config.showFeaturePoints) {
            opts.insert(ARSCNDebugOptions.showFeaturePoints)
        }
        if (config.showPhysicsBodies) {
            opts.insert(SCNDebugOptions.showPhysicsShapes)
        }
        sceneView.debugOptions = opts
        
        if (config.showStatistics) {
            sceneView.showsStatistics = true
        } else {
            sceneView.showsStatistics = false
        }
    }
    
    func refresh() {
        planes.removeAll()
        cubes.removeAll()
        sceneView.session.run(arConfig, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: - SCNPhysicsContactDelegate
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        // Here we detect a collision between pieces of geometry in the world, if one of the pieces
        // of geometry is the bottom plane it means the geometry has fallen out of the world. just remove it
        let nodeACategoryBitMask = contact.nodeA.physicsBody?.categoryBitMask ?? 0
        let nodeBCategoryBitMask = contact.nodeB.physicsBody?.categoryBitMask ?? 0
        let contactMask = nodeACategoryBitMask | nodeBCategoryBitMask
        
        if (contactMask == (CollisionCategory.bottom.rawValue | CollisionCategory.cube.rawValue)) {
            if (nodeACategoryBitMask == CollisionCategory.bottom.rawValue) {
                contact.nodeB.removeFromParentNode()
            } else {
                contact.nodeA.removeFromParentNode()
            }
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let estimate = sceneView.session.currentFrame?.lightEstimate
        if (estimate == nil) {
            return
        }
        
        // A value of 1000 is considered neutral, lighting environment intensity normalizes
        // 1.0 to neutral so we need to scale the ambientIntensity value
        let intensity = estimate!.ambientIntensity / 1000.0
        sceneView.scene.lightingEnvironment.intensity = intensity
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if (!(anchor is ARPlaneAnchor)) {
            return;
        }
        let plane = planes[anchor.identifier]
        plane?.update(anchor: anchor as! ARPlaneAnchor)
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if (!(anchor is ARPlaneAnchor)) {
            return;
        }
        let plane = Plane(anchor: anchor as! ARPlaneAnchor, hidden: false, material: Plane.currentMaterial())
        planes[anchor.identifier] = plane
        node.addChildNode(plane)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        planes.removeValue(forKey: anchor.identifier)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
        // noop
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            showMessage(message: "Camera tracking is not available on this device")
            break
        case .limited(ARCamera.TrackingStateReason.excessiveMotion):
            showMessage(message: "Limited tracking: slow down the movement of the device")
            break
        case .limited(ARCamera.TrackingStateReason.insufficientFeatures):
            showMessage(message: "Limited tracking: too few feature points, view ares with more textures")
            break
        case .limited(ARCamera.TrackingStateReason.none):
            showMessage(message: "Limited tracking: unknown reason")
            break
        case .normal:
            showMessage(message: "Tracking is back to normal")
            break
        default:
            break
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        showMessage(message: "A session error has occurred")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        let alert = UIAlertController(title: "Interruption", message: "The tracking session has been interrupted. The session will reset once the interruption has completed", preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "OK", style: .default)
        
        alert.addAction(ok)

        present(alert, animated: true, completion: {() in })
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        showMessage(message: "Tracking session has been reset due to interruption")
        refresh()
    }
    
    func showMessage(message: String) {
        messageViewer.queueMessage(message: message)
    }
}
