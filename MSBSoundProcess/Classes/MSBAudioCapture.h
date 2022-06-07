//
//  MSBAudioCapture.h
//  MSBSoundProcess
//
//  Created by 范金龙 on 2021/2/15.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "MSBAudioMacro.h"

NS_ASSUME_NONNULL_BEGIN



#pragma mark -- AudioCaptureNotification
/** compoentFialed will post the notification */
extern NSString *_Nullable const MSBAudioComponentFailedToCreateNotification;

@class MSBAudioCapture;
/** MSBAudioCapture callback audioData */
@protocol MSBAudioCaptureDelegate <NSObject>
- (void)captureOutput:(nullable MSBAudioCapture *)capture audioData:(nullable NSData*)audioData;
@end


@interface MSBAudioCapture : NSObject

#pragma mark - Attribute
///=============================================================================
/// @name Attribute
///=============================================================================

/** The delegate of the capture. captureData callback */
@property (nullable, nonatomic, weak) id<MSBAudioCaptureDelegate> delegate;

/** The muted control callbackAudioData,muted will memset 0.*/
@property (nonatomic, assign) BOOL muted;

/** The running control start capture or stop capture*/
//@property (nonatomic, assign) BOOL running;
@property (nonatomic, assign) BOOL isRunning;

/** The audioCapture audioSessionPort, change AVAudioSession category cause this value not match with the true. */
@property (nonatomic, assign) AVAudioSessionPort audioSessionPort;

#pragma mark - Initializer
///=============================================================================
/// @name Initializer
///=============================================================================
//- (nullable instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (nullable instancetype)new UNAVAILABLE_ATTRIBUTE;


- (void)startAudio;

- (void)stopAudio;


@end

NS_ASSUME_NONNULL_END
