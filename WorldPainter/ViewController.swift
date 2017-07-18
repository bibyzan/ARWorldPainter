//
//  ViewController.swift
//  WorldPainter
//
//  Created by Bennett Rasmussen on 7/16/17.
//  Copyright © 2017 Bennett Rasmussen. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import ChromaColorPicker


struct Point3D {
    var x = Float()
    var y = Float()
    var z = Float()
}

class ViewController: UIViewController, ChromaColorPickerDelegate, ARSCNViewDelegate {
    var colorPicker: ChromaColorPicker?
    var currentColor: UIColor = .white
    var paintTimer: Timer?
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var paintSlider: UISlider!
    @IBOutlet weak var sizeLabel: UILabel!
    
    func colorPickerDidChooseColor(_ colorPicker: ChromaColorPicker, color: UIColor) {
        self.colorPicker?.isHidden = true
        
        self.currentColor = color
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        self.sceneView.delegate = self
        self.sceneView.session.run(configuration)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func randomFloat(min: Float, max: Float)->Float {
        return (Float(arc4random()) / 0xFFFFFFF) * (max - min) + min
    }
    
    @objc func paintSphere() {
        let node = SCNNode(geometry: SCNSphere(radius: CGFloat(self.paintSlider.value)))
        
        node.geometry = node.geometry!.copy() as? SCNGeometry
        node.geometry?.firstMaterial = node.geometry?.firstMaterial!.copy() as? SCNMaterial
        node.geometry?.firstMaterial?.diffuse.contents = self.currentColor
        
        let cameraCoordinates = getCameraCoordinates(sceneView: sceneView)
        node.position = SCNVector3(cameraCoordinates.x, cameraCoordinates.y, cameraCoordinates.z)
        
        sceneView.scene.rootNode.addChildNode(node)
        
        let roll = sceneView.session.currentFrame?.camera.eulerAngles[0]
        let pitch = sceneView.session.currentFrame?.camera.eulerAngles[1]
        let yaw = sceneView.session.currentFrame?.camera.eulerAngles[2]
        
        print("roll:\(roll!) pitch:\(pitch!) yaw:\(yaw!)")
        print("z:\(cameraCoordinates.z) x:\(cameraCoordinates.x) y:\(cameraCoordinates.y)")
    }
    
    @IBAction func changeColorTouch(_ sender: Any) {
        self.hideControls()
        if let colorPicker = self.colorPicker {
            colorPicker.isHidden = !colorPicker.isHidden
        } else {
            self.colorPicker = ChromaColorPicker(frame: CGRect(x: self.view.frame.width - 300, y: self.view.frame.height - 400, width: 300, height: 300))
            self.colorPicker!.delegate = self //ChromaColorPickerDelegate
            self.colorPicker!.padding = 5
            self.colorPicker!.stroke = 3
            self.colorPicker!.hexLabel.textColor = UIColor.white
            
            self.view.addSubview(colorPicker!)
        }
        
        
    }
    
    @IBAction func startPaintingTouch(_ sender: Any) {
        self.paintTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(paintSphere), userInfo: nil, repeats: true)
    }
    
    @IBAction func endPaintingTouch(_ sender: Any) {
        self.paintTimer?.invalidate()
    }
    
    @IBAction func addCupTouch(_ sender: Any) {
        let cupNode = SCNNode()
        
        let cameraCoordinates = getCameraCoordinates(sceneView: sceneView)
        cupNode.position = SCNVector3(cameraCoordinates.x, cameraCoordinates.y, cameraCoordinates.z)
        
        guard let virtualObjectScene = SCNScene(named: "cup.scn", inDirectory: "Models.scnassets/cup") else {
            return
        }
        
        let wrapperNode = SCNNode()
        for child in virtualObjectScene.rootNode.childNodes {
            child.geometry?.firstMaterial?.lightingModel = .physicallyBased
            wrapperNode.addChildNode(child)
        }
        cupNode.addChildNode(wrapperNode)
        
        sceneView.scene.rootNode.addChildNode(cupNode)
        
    }
    
    @IBAction func paintSizeChanged(_ sender: Any) {
        self.sizeLabel.text = "\(self.paintSlider.value)m"
    }
    
    @IBAction func changeBrushSizeTapped(_ sender: Any) {
        self.colorPicker?.isHidden = true
        self.paintSlider.isHidden = !self.paintSlider.isHidden
        self.sizeLabel.isHidden = !self.sizeLabel.isHidden
    }
    
    func hideControls() {
        self.sizeLabel.isHidden = true
        self.colorPicker?.isHidden = true
        self.paintSlider.isHidden = true
    }
    
    func getCameraCoordinates(sceneView: ARSCNView)->Point3D {
        let cameraTransform = sceneView.session.currentFrame?.camera.transform
        let cameraCoordinates = MDLTransform(matrix: cameraTransform!)
        
        var point = Point3D()
        point.z = cameraCoordinates.translation.z
        point.y = cameraCoordinates.translation.y
        point.x = cameraCoordinates.translation.x
        
        return point
    }
    
    
}

