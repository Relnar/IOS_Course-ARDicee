//
//  ViewController.swift
//  ARDicee
//
//  Created by Pierre-Luc Bruyere on 2018-11-03.
//  Copyright © 2018 Pierre-Luc Bruyere. All rights reserved.
//

import UIKit
import SceneKit
import ARKit


class ViewController: UIViewController, ARSCNViewDelegate
{
  // MARK: - Attributes

  @IBOutlet var sceneView: ARSCNView!

  private var diceArray = [SCNNode]()

  // MARK: -

  override func viewDidLoad()
  {
    super.viewDidLoad()

    // Set the view's delegate
    sceneView.delegate = self

    // Show statistics such as fps and timing information
    sceneView.showsStatistics = true

    sceneView.autoenablesDefaultLighting = true
  }

  override func viewWillAppear(_ animated: Bool)
  {
    super.viewWillAppear(animated)

    // Create a session configuration
    var configuration : ARConfiguration

    if ARWorldTrackingConfiguration.isSupported
    {
      let worldTrackingConfig = ARWorldTrackingConfiguration()
      worldTrackingConfig.planeDetection = .horizontal

      configuration = worldTrackingConfig
    }
    else
    {
      configuration = AROrientationTrackingConfiguration()
    }

    // Run the view's session
    sceneView.session.run(configuration)
  }

  override func viewWillDisappear(_ animated: Bool)
  {
    super.viewWillDisappear(animated)

    // Pause the view's session
    sceneView.session.pause()
  }

  // MARK: - ARSCNViewDelegate methods

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
  {
    super.touchesBegan(touches, with: event)

    if let touch = touches.first
    {
      let touchLocation = touch.location(in: sceneView)
      let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
      if let hitResult = results.first
      {
        addDice(atLocation: hitResult)
      }
    }
  }

  func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor)
  {
    guard let planeAnchor = anchor as? ARPlaneAnchor
    else
    {
      return
    }

    let planeNode = createPlane(with: planeAnchor)

    node.addChildNode(planeNode)
  }

  // MARK: - Navigation bar buttons

  @IBAction func rollDice(_ sender: UIBarButtonItem)
  {
    rollAll()
  }

  @IBAction func clearDices(_ sender: UIBarButtonItem)
  {
    for dice in diceArray
    {
      dice.removeFromParentNode()
    }
    diceArray.removeAll()
  }

  // MARK: - Private methods

  private func addDice(atLocation hitResult: ARHitTestResult)
  {
    let diceScene = SCNScene(named: "art.scnassets/diceCollada.scn")!
    guard let diceNode = diceScene.rootNode.childNode(withName: "Dice", recursively: true)
    else
    {
      fatalError("Error loading dice node")
    }

    diceNode.position = SCNVector3(hitResult.worldTransform.columns.3.x,
                                   hitResult.worldTransform.columns.3.y + (diceNode.boundingBox.max.y - diceNode.boundingBox.min.y) * 0.5,
                                   hitResult.worldTransform.columns.3.z)

    diceArray.append(diceNode)

    sceneView.scene.rootNode.addChildNode(diceNode)

    roll(dice: diceNode)
  }

  private func rollAll()
  {
    for dice in diceArray
    {
      roll(dice: dice)
    }
  }

  /// Roll a dice
  ///
  /// - Parameter dice: Dice to roll
  private func roll(dice: SCNNode)
  {
    let randomX = CGFloat(Float(Int.random(in: 1...4)) * Float.pi / 2.0)
    let randomZ = CGFloat(Float(Int.random(in: 1...4)) * Float.pi / 2.0)

    dice.runAction(SCNAction.rotateBy(x: randomX,
                                      y: 0.0,
                                      z: randomZ,
                                      duration: 0.5))
  }

  private func createPlane(with planeAnchor: ARPlaneAnchor) -> SCNNode
  {
    // Create a material with a grid texture
    let gridMaterial = SCNMaterial()
    gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")

    // Create the plane geometry and assign the grid texture
    let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
    plane.materials = [gridMaterial]

    // Create the plane node
    let planeNode = SCNNode()
    planeNode.position = SCNVector3(planeAnchor.center.x, 0.0, planeAnchor.center.z)
    planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1.0, 0.0, 0.0)
    planeNode.geometry = plane

    return planeNode
  }
}
