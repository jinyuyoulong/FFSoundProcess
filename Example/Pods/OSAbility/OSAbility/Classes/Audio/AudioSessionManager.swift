//
//  DDAudioSessionManager.swift
//  DaDaClass
//
//  Created by RandomJ on 2018/1/23.
//  Copyright © 2018年 dadaabc. All rights reserved.
//
//暂时没有开始使用

import UIKit
import AVFoundation
//import OSAbility_Example

@objc(OSAudioSessionManager)
@objcMembers
public class AudioSessionManager: NSObject {
    public static let _shared = AudioSessionManager()
    
    public static func shared() -> AudioSessionManager {
        return _shared
    }

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(audioSessionRouteChanged(noti:)),
                                               name: AVAudioSession.routeChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(getInterruptionNoti(noti:)),
                                               name: AVAudioSession.interruptionNotification, object: nil)
        
//        UIApplication.shared.keyWindow?.addSubview(self.textview)
    }
    
    public static let routeChangeNoti: NSNotification.Name = Notification.Name(rawValue: "AudioSessionRouteChangeNoti")
    
    public static let InterruptionNoti = Notification.Name(rawValue: "AudioSessionInterruptionNoti")
    
    /*
     外放模式
     录音模式
     --后台播放模式--
     --前台x是否录音--
     */
    
    public var originModel = AudioSessionModel(category: .ambient, options: .defaultToSpeaker, mode: .default)
    
    lazy var textview: UITextView = {
        let view = UITextView()
        view.frame = CGRect(x: 10, y: 400, width: UIScreen.main.bounds.width-20, height: 300)
        view.text = "dada"
        view.backgroundColor = .gray
        return view
    }()
    // MARK: - 通知
    
    /// audio session 改变前的监听
    /// - Parameter noti: 消息体
    func audioSessionRouteChanged(noti: Notification) {
       // 分发到业务
        NotificationCenter.default.post(name: AudioSessionManager.routeChangeNoti,
                                        object: nil, userInfo: noti.userInfo)
        
        guard let userInfo = noti.userInfo else { return }
        var seccReason = ""
        guard let reason = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt else {return}
        
        switch reason {
        case AVAudioSession.RouteChangeReason.newDeviceAvailable.rawValue:
            seccReason = "有新设备可用"
            // 一般为接入了耳机
        case AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue:
            seccReason = "老设备不可用"
            guard let previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription else {
                return
            }
            let previousOutput = previousRoute.outputs[0]
            let portType = previousOutput.portType
            print("音频模式更改: \(portType)")
            if portType == AVAudioSession.Port.headphones {
                //在这里暂停播放, 更改输出设备，录音时背景音需要重置。否则无法消音
                print("耳机🎧模式")
            } else if portType == AVAudioSession.Port.builtInSpeaker {
                
            }
        case AVAudioSession.RouteChangeReason.categoryChange.rawValue:
            seccReason = "类别Cagetory改变了"
        case AVAudioSession.RouteChangeReason.override.rawValue:
            seccReason = "App重置了输出设置"
        case AVAudioSession.RouteChangeReason.wakeFromSleep.rawValue:
            seccReason = "从睡眠状态呼醒"
        case AVAudioSession.RouteChangeReason.noSuitableRouteForCategory.rawValue:
            seccReason = "当前Category下没有合适的设备"
            
        case AVAudioSession.RouteChangeReason.routeConfigurationChange.rawValue:
            seccReason = "Rotuer的配置改变了"
//        case AVAudioSession.RouteChangeReason.unknown,
        default:
            seccReason = "未知原因"
        }
        
        print("音频模式更改：\(seccReason) \(reason) \(String(describing: userInfo))")
        self.showMsg(text: "音频模式更改：\(seccReason) \(reason) \(String(describing: userInfo))")
    }
    
    
    /// 音频中断通知
    /// - Parameter noti: 消息体
    func getInterruptionNoti(noti: Notification) {
        NotificationCenter.default.post(name: AudioSessionManager.InterruptionNoti,
                                        object: nil,
                                        userInfo: noti.userInfo)
        
        guard let info = noti.userInfo else { return }
        print("音频中断通知： \(String(describing: info))")
        self.showMsg(text: "音频中断通知： \(String(describing: info))")
        guard let type = info[AVAudioSessionInterruptionTypeKey] as? UInt else {
            print("音频中断通知： InterruptionType 错误")
            return
        }
        
        if type == AVAudioSession.InterruptionType.began.rawValue {
            if #available(iOS 14.5, *) {
                if let options = info[AVAudioSessionInterruptionReasonKey] as? UInt  {
                    if options == AVAudioSession.InterruptionReason.appWasSuspended.rawValue {
                        print("音频中断原因 应用程序被暂停")
                    } else if options == AVAudioSession.InterruptionReason.builtInMicMuted.rawValue {
                        print("音频中断原因 内置麦克风")
                    }else {
                        print("音频中断原因 默认")
                    }
                }
            } else {
                // Fallback on earlier versions
            }
        }else {
            if let options = info[AVAudioSessionInterruptionOptionKey] as? UInt  {
                print("音频中断选项 shouldResume \(options)")
                if options == AVAudioSession.InterruptionOptions.shouldResume.rawValue {
                    // 继续播放
                }
            }
            if #available(iOS 14.5, *) {
                if let options = info[AVAudioSessionInterruptionReasonKey] as? UInt  {
                    if options == AVAudioSession.InterruptionReason.appWasSuspended.rawValue {
                        print("音频中断原因 应用程序被暂停")
                    } else if options == AVAudioSession.InterruptionReason.builtInMicMuted.rawValue {
                        print("音频中断原因 内置麦克风")
                    }else {
                        print("音频中断原因 默认")
                    }
                }
            } else {
                // Fallback on earlier versions
            }
        }
       
    }

    func showMsg(text: String) {
        self.textview.text = text+"\n"+self.textview.text
    }
    // MARK: - 设置AudioSession
    
    
    /// 保存当前的模式
    public func saveLastestAudioSession() {
        originModel.category = AVAudioSession.sharedInstance().category
        originModel.options = AVAudioSession.sharedInstance().categoryOptions
        originModel.mode = AVAudioSession.sharedInstance().mode
//        print("当前 category typtes \(originModel.category) \(originModel.options) \(originModel.model)")
    }
    
    @objc
    /// 恢复保存的模式
    public func resetOriginAudioSession() {
        print("resetOriginAudioSession befer \(originModel.category) \(originModel.options) \(originModel.mode)")
        let session  = AVAudioSession.sharedInstance()
        try? session.setCategory(originModel.category, mode: originModel.mode, options: originModel.options)
        try? session.setActive(true)
        print("resetOriginAudioSession after \(originModel.category) \(originModel.options) \(originModel.mode)")
    }
    
    @objc
    /// 设置录音模式
    public func setRecordSession() {
//        saveLastestAudioSession()
        
        let session  = AVAudioSession.sharedInstance()
        let options:AVAudioSession.CategoryOptions = [.allowBluetoothA2DP, .allowBluetooth,
                                                      .allowAirPlay, .defaultToSpeaker]
        try? session.setCategory(.playAndRecord, mode: .videoRecording,options: options)
        try? session.setActive(true)
        print("当前 category typtes \(session.category) \(session.categoryOptions) \(session.mode)")
    }
    @objc
    // TODO: 待测试 是否只支持扬声器播放
    /// 设置播放模式
    public func setPlayerSession() {
//        saveLastestAudioSession()
        let session  = AVAudioSession.sharedInstance()
        let options:AVAudioSession.CategoryOptions = [.allowBluetoothA2DP, .allowBluetooth,
                                                      .allowAirPlay, .defaultToSpeaker]
        // MultiRoute 扬声器和蓝牙音响不能同时播放
        try? session.setCategory(.playAndRecord, mode: .default,options: options)
        try? session.setActive(true)
    }
    @objc
    /// 设置后台播放模式
    public func setPlaybackSession() {
//        saveLastestAudioSession()
        let session  = AVAudioSession.sharedInstance()
        let options:AVAudioSession.CategoryOptions = [.allowBluetoothA2DP, .allowBluetooth,
                                                      .allowAirPlay, .defaultToSpeaker]
        try? session.setCategory(.playback, mode: .default,options: options)
        try? session.setActive(true)
    }
    // MARK: - 老代码
    /**
     *  听筒和扬声器的切换 - 兼容老代码
     */
    @objc public static func speaker(on shouldTurnOnSpeaker: Bool) throws {
        do {
            let port: AVAudioSession.PortOverride = shouldTurnOnSpeaker ? .speaker : .none
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(port)
        } catch {
            throw error
        }
    }

    /**
     *  听筒和扬声器的切换
     *
     *  @param speaker   是否转为扬声器，NO则听筒
     *  @param temporary 决定使用kAudioSessionProperty_OverrideAudioRoute还是kAudioSessionProperty_OverrideCategoryDefaultToSpeaker，两者的区别请查看本组的博客文章:http://km.oa.com/group/gyui/articles/show/235957
     */
    @objc public static func redirectAudioRoute(with speaker: Bool, temporary: Bool) {
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.category != .playAndRecord {
            return
        }
        if temporary {
            try? audioSession.overrideOutputAudioPort(speaker ? .speaker : .none)
        } else {
            try? audioSession.setCategory(audioSession.category, options: speaker ? .defaultToSpeaker : [])
        }
    }

    /**
     *  设置category为setPlayAndRecordCategory
     */
    @objc public static func setPlayAndRecordCategory() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
            try AVAudioSession.sharedInstance().setActive(true)
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        } catch _ {
            print( "Could not set audio category")
        }
    }

    /**
     *  设置category
     *
     *  @param category 使用iOS7的category，iOS6的会自动适配
     */
    @objc public static func setAudioSession(category: String) {
        let categories = [
            AVAudioSession.Category.ambient,
            AVAudioSession.Category.soloAmbient,
            AVAudioSession.Category.playback,
            AVAudioSession.Category.record,
            AVAudioSession.Category.playAndRecord,
//            AVAudioSession.Category.audioProcessing
        ]

        // 如果不属于系统category，返回
        guard categories.contains(AVAudioSession.Category(rawValue: category)) else {
            return
        }

        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category(rawValue: category))
    }

    @objc public static func categoryForLowVersion(with category: String) -> Int {
        if category == AVAudioSession.Category.ambient.rawValue {
            return kAudioSessionCategory_AmbientSound
        }
        if category == AVAudioSession.Category.soloAmbient.rawValue {
            return kAudioSessionCategory_SoloAmbientSound
        }
        if category == AVAudioSession.Category.playback.rawValue {
            return kAudioSessionCategory_MediaPlayback
        }
        if category == AVAudioSession.Category.record.rawValue {
            return kAudioSessionCategory_RecordAudio
        }
        if category == AVAudioSession.Category.playAndRecord.rawValue {
            return kAudioSessionCategory_PlayAndRecord
        }
//        if category == AVAudioSession.Category.audioProcessing.rawValue {
//            return kAudioSessionCategory_AudioProcessing
//        }
        return kAudioSessionCategory_AmbientSound
    }
    
    /// 检测是否连接蓝牙
    /// - Returns: 是否为蓝牙音频输出
    func isBleToothOutput() -> Bool {
        let currentRount = AVAudioSession.sharedInstance().currentRoute
        let outputProtDesc = currentRount.outputs[0]
        if outputProtDesc.portType == AVAudioSession.Port.bluetoothA2DP {
            print("BleTooth 当前输出的线路是蓝牙输出，并且已连接")
            return true
        }else {
            print("BleTooth 当前是spearKer输出")
            return false
        }
    }
}
