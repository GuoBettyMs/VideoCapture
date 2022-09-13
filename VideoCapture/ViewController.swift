//
//  ViewController.swift
//  VideoCapture
//
//  Created by gbt on 2022/9/13.
//
/*
    通过摄像头、话筒采集视频和音频
 */

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    fileprivate lazy var videoQueue = DispatchQueue.global()
    fileprivate lazy var audioQueue = DispatchQueue.global()
    
    fileprivate lazy var session: AVCaptureSession = AVCaptureSession()
    fileprivate lazy var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)

    fileprivate var videoOutput: AVCaptureVideoDataOutput?
    fileprivate var videoInput: AVCaptureDeviceInput?
    fileprivate var movieOutput: AVCaptureMovieFileOutput?
}


extension ViewController{
    // MARK:  视频的开始采集
    @IBAction func startCapture() {
        //设置视频的输入&输出
        setVideo()
        
        //设置音频的输入&输出
        setAudio()
        
        //添加写入的文件output
        let moviewOutput = AVCaptureMovieFileOutput()
        session.addOutput(moviewOutput)
        self.movieOutput = moviewOutput
        
        //设置写入的稳定性
        let connection = moviewOutput.connection(with: .video)
        connection?.preferredVideoStabilizationMode = .auto
        
        
        //给用户看到一个预览图层（可选）
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        
        //开始采集
        session.startRunning()
        
        //开始将采集到的画面写入到文件中
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/abc.mp4"
        let url = URL(fileURLWithPath: path)
        moviewOutput.startRecording(to: url, recordingDelegate: self)
        

    }
    
    // MARK:  视频的停止采集
    @IBAction func stopCapture() {
        
        movieOutput?.stopRecording()
        
        session.stopRunning()
        previewLayer.removeFromSuperlayer()
    }
    
    
    @IBAction func switchScene() {
        //获取之前的摄像头
        guard var position = videoInput?.device.position else {return }
        
        //获取当前应该显示的摄像头
        position = position == .front ? .back : .front
        
        //根据当前摄像头创建新的input
        let devices = AVCaptureDevice.devices(for:  .video) as? [AVCaptureDevice]
        guard let device = devices?.filter({ $0.position == position}).first else {return }
        
        //根据新的device 创建新的input
        guard let videoInput = try? AVCaptureDeviceInput(device: device) else{return }
        
        //在session中切换input
        session.beginConfiguration()
        session.removeInput(self.videoInput!)
        session.addInput(videoInput)
        session.commitConfiguration()
        self.videoInput = videoInput
        
    }
    
    
}

extension ViewController{
    // MARK: 设置视频的输入&输出
    fileprivate func setVideo(){
        
        //给捕捉会话设置输入源(摄像头)
        //获取摄像头设备
        guard let devices = AVCaptureDevice.devices(for: AVMediaType.video) as? [AVCaptureDevice] else{
            print("摄像头不可用")
            return
        }

        guard let device = devices.filter({$0.position == .front}).first else {return}
        
        //通过device 创建AVCaptureInput 对象
        guard let videoInput = try? AVCaptureDeviceInput(device: device) else {return }
        self.videoInput = videoInput
        
        //将input添加到会话中
        session.addInput(videoInput)
        
        //给捕捉会话设置输出源
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        session.addOutput(videoOutput)

        
        //获取video 对应的connection
        self.videoOutput = videoOutput
    }

    // MARK: 设置音频的输入&输出
    fileprivate func setAudio(){
        //设置音频的输入（话筒）
        //获取话筒设备
        guard let device = AVCaptureDevice.default(for: AVMediaType.audio) else{return}
        
        //根据device 创建AVCaptureInput
        guard let audioInput = try? AVCaptureDeviceInput(device: device) else {return}
        
        //将input添加到会话中
        session.addInput(audioInput)
        
        //给会话设置音频输出源
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: audioQueue)
        session.addOutput(audioOutput)
        
    }
    
}

// MARK: 获取数据
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate{
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if connection == videoOutput?.connection(with: .video){
            print("已经采集到 视频 画面")
        }else{
            print("已经采集到 音频 画面")
        }
    }
  
}

extension ViewController: AVCaptureFileOutputRecordingDelegate{
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("开始写入文件")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("结束写入文件")
    }
}
