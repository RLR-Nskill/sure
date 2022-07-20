//
//  ViewController.swift
//  sure
//
//  Created by cl_umeda_011 on 2022/03/02.
//

import UIKit
import ARKit

class ViewController: UIViewController,ARSessionDelegate {
    
    @IBOutlet weak var LabelA: UILabel!
    @IBOutlet weak var LabelB: UILabel!
    @IBOutlet var Cam: ARSCNView!
    var frameCounter = 0
    var handPosepredectionInterval = 1
    
    let model = try? MyHandPoseClassifier5Final_4(configuration: MLModelConfiguration())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let configuration = ARWorldTrackingConfiguration()
        Cam.scene = SCNScene()
        Cam.session.delegate = self
        Cam.session.run(configuration)
        // Do any additional setup after loading the view.
    }
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // 今回はARSessionからカメラフレームを取得します
            let pixelBuffer = frame.capturedImage
            // 手のポーズの検出リクエストを作成
            let handPoseRequest = VNDetectHumanHandPoseRequest()
            // 取得する手の数
            handPoseRequest.maximumHandCount = 1

            // カメラフレームで検出リクエストを実行
            // カメラから取得したフレームは90度回転していて、
            // そのまま推論にかけるとポーズを正しく認識しなかったりするので、
            // orientationを確認する
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
            do {
                try handler.perform([handPoseRequest])
            } catch {
                assertionFailure("HandPoseRequest failed: \(error)")
            }

            guard let handPoses = handPoseRequest.results, !handPoses.isEmpty else {
                return
            }

            // 取得した手のデータ
            guard let observation = handPoses.first else { return }

            
            // 毎フレーム、モデルの推論を実行すると処理が重くなり、
            // ARのレンダリングをブロックする可能性があるので、インターバルをあけて推論実行する
            frameCounter += 1
        if frameCounter % handPosepredectionInterval == 0 {
                    makePrediction(handPoseObservation: observation)
                    frameCounter = 0
                }
        }
    func makePrediction(handPoseObservation: VNHumanHandPoseObservation) {
            // 手のポイントの検出結果を多次元配列に変換
            guard let keypointsMultiArray = try? handPoseObservation.keypointsMultiArray() else { fatalError() }
            do {
                // モデルに入力して推論実行
                let prediction = try model!.prediction(poses: keypointsMultiArray)
                let label = prediction.label // 最も信頼度の高いラベル
                guard let confidence = prediction.labelProbabilities[label] else { return } // labelの信頼度
                print("label:\(prediction.label)\nconfidence:\(confidence)")
                LabelB.text=prediction.label
            } catch {
                print("Prediction error")
            }
        }
}
