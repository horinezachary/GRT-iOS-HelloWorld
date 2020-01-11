
//
//  PredictionViewController.swift
//  GRT-iOS-HelloWorld
//
//  Created by Nicholas Arner on 8/22/17.
//  Copyright © 2017 Nicholas Arner. All rights reserved.
//

import UIKit
import GRTiOS
import SwiftR

class PredictionViewController: UIViewController {
    
    @IBOutlet var gestureOneCountLabel: UILabel!
    @IBOutlet var gestureTwoCountLabel: UILabel! 
    @IBOutlet var gestureThreeCountLabel: UILabel!
    
    @IBOutlet weak var graphView: SRMergePlotView! {
        didSet {
            graphView.title = "Accelerometer Data"
            graphView.totalSecondsToDisplay = 0.5
        }
    }

    var gestureOneCount: UInt = 0
    var gestureTwoCount: UInt = 0
    var gestureThreeCount: UInt = 0
    
    fileprivate let accelerometerManager = AccelerometerManager()

    var currentClassLabel = 0 as UInt
    var labelUpdateTime = Date.timeIntervalSinceReferenceDate
    let vector = VectorDouble()
    var pipeline: GestureRecognitionPipeline?
    
    override func viewDidLoad() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.pipeline = appDelegate.pipeline!

        initPipeline()
        graphView.totalChannelsToDisplay = 3
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        accelerometerManager.stop()
        resetGestureCount()
    }
    
    func resetGestureCount() {
        gestureOneCountLabel.text = "Gesture 1 count: "
        gestureTwoCountLabel.text = "Gesture 2 count: "
        gestureThreeCountLabel.text = "Gesture 3 count: "
        gestureOneCount = 0
        gestureTwoCount = 0
        gestureThreeCount = 0
    }
    
    func initPipeline(){
        
        //Load the GRT pipeline and the training data files from the documents directory
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let pipelineURL = documentsUrl.appendingPathComponent("train.grt")
        let classificiationDataURL = documentsUrl.appendingPathComponent("trainingData.csv")

        let pipelineResult:Bool = pipeline!.load(pipelineURL)
        let classificationDataResult:Bool = pipeline!.loadClassificationData(classificiationDataURL)
        
        if pipelineResult == false {
            let userAlert = UIAlertController(title: "Error", message: "Couldn't load pipeline", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
            userAlert.addAction(cancel)
            self.present(userAlert, animated: true, completion: { [weak self] in })
        }
        
        if classificationDataResult == false {
            let userAlert = UIAlertController(title: "Error", message: "Couldn't load classification data", preferredStyle: .alert)
            self.present(userAlert, animated: true, completion: { [weak self] in })
            let cancel = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
            userAlert.addAction(cancel)
        }
        
        //If the files have been loaded successfully, we can train the pipeline, and then start real-time gesture prediction
        else if (classificationDataResult && pipelineResult) {
            pipeline?.train()
            performGesturePrediction()
        }
    }
    
    func performGesturePrediction() {
        accelerometerManager.start { (x, y, z) -> Void in
            self.vector.clear()
            self.vector.pushBack(x)
            self.vector.pushBack(y)
            self.vector.pushBack(z)
            //Use the incoming accellerometer data to predict what the performed gesture class is
            self.pipeline?.predict(self.vector)

            DispatchQueue.main.async {
                self.updateGestureCountLabels(gesture: (self.pipeline?.predictedClassLabel)!)
                print("PRECITED GESTURE", self.pipeline?.predictedClassLabel ?? 0);
                self.graphView.addData([x, y, z])
            }
            
        }
    }
    
    func updateGestureCountLabels(gesture: UInt){
        
        if gesture == 0 {
            //do nothing
        } else if (gesture == 1){
            gestureOneCount = gestureOneCount + 1
            let gestureOneCountVal = String(gestureOneCount)
            gestureOneCountLabel.text = ("Gesture 1 count: " + gestureOneCountVal)
        } else if (gesture == 2){
            gestureTwoCount = gestureTwoCount + 1
            let gestureTwoCountVal = String(gestureTwoCount)
            gestureTwoCountLabel.text = ("Gesture 2 count: " + gestureTwoCountVal)
        } else if (gesture == 3){
            gestureThreeCount = gestureThreeCount + 1
            let gestureThreeCountVal = String(gestureThreeCount)
            gestureThreeCountLabel.text = ("Gesture 3 count: " + gestureThreeCountVal)
        }
        
    }

}
