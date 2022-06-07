//
//  AudioSessionModel.swift
//  OSAbility
//
//  Created by 范金龙 on 2021/12/27.
//

import UIKit
import AVFoundation

@objc
open class AudioSessionModel: NSObject {
    public var category: AVAudioSession.Category
    public var options: AVAudioSession.CategoryOptions
    public var mode: AVAudioSession.Mode
    
    @objc
    public init(category: AVAudioSession.Category, options: AVAudioSession.CategoryOptions,
                mode: AVAudioSession.Mode) {
        self.category = category
        self.options = options
        self.mode = mode
        super.init()
    }
}
