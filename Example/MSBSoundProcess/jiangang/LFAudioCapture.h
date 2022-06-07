//
//  LFAudioCapture.h
//  dongciSDK
//
//  Created by Yang Jiangang on 2018/12/19.
//  Copyright © 2018 welines. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#pragma mark -- AudioCaptureNotification
/** compoentFialed will post the notification */
extern NSString *_Nullable const LFAudioComponentFailedToCreateNotification;

@class LFAudioCapture;
/** LFAudioCapture callback audioData */
@protocol LFAudioCaptureDelegate <NSObject>
- (void)captureOutput:(nullable LFAudioCapture *)capture audioData:(nullable NSData*)audioData;
@end


@interface LFAudioCapture : NSObject

#pragma mark - Attribute
///=============================================================================
/// @name Attribute
///=============================================================================

/** The delegate of the capture. captureData callback */
@property (nullable, nonatomic, weak) id<LFAudioCaptureDelegate> delegate;

/** The muted control callbackAudioData,muted will memset 0.*/
@property (nonatomic, assign) BOOL muted;

/** The running control start capture or stop capture*/
@property (nonatomic, assign) BOOL running;

/** The audioCapture audioSessionPort, change AVAudioSession category cause this value not match with the true. */
@property (nonatomic, assign) AVAudioSessionPort audioSessionPort;

#pragma mark - Initializer
///=============================================================================
/// @name Initializer
///=============================================================================
//- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;
@end
