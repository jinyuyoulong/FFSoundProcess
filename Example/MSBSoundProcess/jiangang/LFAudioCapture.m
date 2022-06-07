//
//  LFAudioCapture.m
//  dongciSDK
//
//  Created by Yang Jiangang on 2018/12/19.
//  Copyright © 2018 welines. All rights reserved.
//

#import "LFAudioCapture.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "MSBAudioTools.h"

NSString *const LFAudioComponentFailedToCreateNotification = @"LFAudioComponentFailedToCreateNotification";

@interface LFAudioCapture ()
{
    BOOL recording;
}

@property (nonatomic, assign) AudioComponentInstance componetInstance;
@property (nonatomic, assign) AudioComponent component;
@property (nonatomic, strong) dispatch_queue_t taskQueue;
@property (nonatomic, assign) BOOL isRunning;

@end

@implementation LFAudioCapture

#pragma mark -- LiftCycle

- (instancetype)init {
    if(self = [super init]){
        self.isRunning = NO;
        self.taskQueue = dispatch_queue_create("Jiangang.audioCapture.Queue", NULL);
        
        AVAudioSession *session = [AVAudioSession sharedInstance];
        
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleRouteChange:)
                                                     name: AVAudioSessionRouteChangeNotification
                                                   object: session];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(handleInterruption:)
                                                     name: AVAudioSessionInterruptionNotification
                                                   object: session];
        
        AudioComponentDescription acd;
        acd.componentType = kAudioUnitType_Output;
        //acd.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
        acd.componentSubType = kAudioUnitSubType_RemoteIO;
        acd.componentManufacturer = kAudioUnitManufacturer_Apple;
        acd.componentFlags = 0;
        acd.componentFlagsMask = 0;
        
        self.component = AudioComponentFindNext(NULL, &acd);
        
        OSStatus status = noErr;
        status = AudioComponentInstanceNew(self.component, &_componetInstance);
        
        if (noErr != status) {
            [self handleAudioComponentCreationFailure];
        }
        
        UInt32 flagOne = 1;
        
        AudioUnitSetProperty(self.componetInstance, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flagOne, sizeof(flagOne));
        
        AudioStreamBasicDescription desc = {0};
        desc.mSampleRate = 44100;
        desc.mFormatID = kAudioFormatLinearPCM;
        desc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
        desc.mChannelsPerFrame = 1;
        desc.mFramesPerPacket = 1;
        desc.mBitsPerChannel = 16;
        desc.mBytesPerFrame = desc.mBitsPerChannel / 8 * desc.mChannelsPerFrame;
        desc.mBytesPerPacket = desc.mBytesPerFrame * desc.mFramesPerPacket;
        
        AURenderCallbackStruct cb;
        cb.inputProcRefCon = (__bridge void *)(self);
        cb.inputProc = handleInputBuffer;
        AudioUnitSetProperty(self.componetInstance, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &desc, sizeof(desc));
        AudioUnitSetProperty(self.componetInstance, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &cb, sizeof(cb));
        
        status = AudioUnitInitialize(self.componetInstance);
        
        if (noErr != status) {
            [self handleAudioComponentCreationFailure];
        }
        
        [session setPreferredSampleRate:44100 error:nil];
        
        [session setCategory:AVAudioSessionCategoryPlayAndRecord
                 withOptions:AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers
                       error:nil];

        [session setActive:YES withOptions:kAudioSessionSetActiveFlag_NotifyOthersOnDeactivation error:nil];
        
        [session setActive:YES error:nil];
    
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    dispatch_sync(self.taskQueue, ^{
        if (self.componetInstance) {
            self.isRunning = NO;
            AudioOutputUnitStop(self.componetInstance);
            AudioComponentInstanceDispose(self.componetInstance);
            self.componetInstance = nil;
            self.component = nil;
        }
    });
}

#pragma mark -- Setter
- (void)setRunning:(BOOL)running {
    if (_running == running) return;
    _running = running;
    if (_running) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
        dispatch_async(self.taskQueue, ^{
            self.isRunning = YES;
            NSLog(@"MicrophoneSource: startRunning");
            AudioOutputUnitStart(self.componetInstance);
        });
    } else {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
        dispatch_sync(self.taskQueue, ^{
            self.isRunning = NO;
            NSLog(@"MicrophoneSource: stopRunning");
            AudioOutputUnitStop(self.componetInstance);
        });
    }
}

- (void)setAudioSessionPort:(AVAudioSessionPort)audioSessionPort{
    _audioSessionPort = audioSessionPort;
    NSArray* availableInputs = [[AVAudioSession sharedInstance] availableInputs];
    for (AVAudioSessionPortDescription *desc in availableInputs) {
        if ([desc.portType isEqualToString:audioSessionPort]) {
            NSError *error;
            [[AVAudioSession sharedInstance] setPreferredInput:desc error:&error];
        }
    }
}

#pragma mark -- CustomMethod
- (void)handleAudioComponentCreationFailure {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:LFAudioComponentFailedToCreateNotification object:nil];
    });
}

#pragma mark -- NSNotification
- (void)handleRouteChange:(NSNotification *)notification {
    
    AVAudioSession *session = [ AVAudioSession sharedInstance];
    NSString *seccReason = @"";
    NSInteger reason = [[[notification userInfo] objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (reason) {
    
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
        
            seccReason = @"The route changed because no suitable route is now available for the specified category.";
        
            break;
    
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
        
            seccReason = @"The route changed when the device woke up from sleep.";
        
            break;
    
        case AVAudioSessionRouteChangeReasonOverride:
        
            seccReason = @"The output route was overridden by the app.";
        
            break;
    
        case AVAudioSessionRouteChangeReasonCategoryChange:
        
            seccReason = @"The category of the session object changed.";
        
            break;
   
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        
            seccReason = @"The previous audio output path is no longer available.";
        
            break;
   
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
        
            seccReason = @"A preferred new audio output path is now available.";
        
            break;
    
        case AVAudioSessionRouteChangeReasonUnknown:
    
        default:
       
            seccReason = @"The reason for the change is unknown.";
        break;
    }
    NSLog(@"handleRouteChange reason is %@", seccReason);

    NSArray* inputs = [[AVAudioSession sharedInstance] currentRoute].inputs;
    NSArray* output = [[AVAudioSession sharedInstance] currentRoute].outputs;
    NSLog(@"current inputs:%@",inputs);
    NSLog(@"current output:%@",output);

    NSArray* availableInputs = [[AVAudioSession sharedInstance] availableInputs];
    NSLog(@"current available availableInputs:%@",availableInputs);

    BOOL hasMicphone = [MSBAudioTools hasMicphone];
    NSLog(@"hasMicphone:%d",hasMicphone);

    NSLog(@"hasHeadset:%d",[MSBAudioTools hasHeadset]);
    
    for (AVAudioSessionPortDescription* desc in availableInputs) {
        if ([desc.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {// 内置麦克风
            NSLog(@"current available inputs：AVAudioSessionPortBuiltInMic 内置麦克风");
        }else if([desc.portType isEqualToString:AVAudioSessionPortLineIn]){
            NSLog(@"current available inputs:AVAudioSessionPortLineIn");
        }else if ([desc.portType isEqualToString:AVAudioSessionPortHeadsetMic]){// 耳机线中的麦克风
            NSLog(@"current available inputs:AVAudioSessionPortHeadsetMic 耳机线中的麦克风");
        }
    }

//    for (AVAudioSessionPortDescription *desc in inputArray) {
//        if ([desc.portType isEqualToString:self.audioSessionPort]) {
//            NSError *error;
//            [[AVAudioSession sharedInstance] setPreferredInput:desc error:&error];
//        }
//    }
    
    AVAudioSessionPortDescription *input = [[session.currentRoute.inputs count] ? session.currentRoute.inputs : nil objectAtIndex:0];
    NSLog(@"session.currentRoute.inputs:%@ input.portType:%@",session.currentRoute.inputs,input.portType);
    if (input.portType == AVAudioSessionPortHeadsetMic) {
        NSLog(@"input type is headsetMic");
    }else if (input.portType == AVAudioSessionPortBuiltInMic){
        NSLog(@"input type is builtInMic");
    }
    
}

- (void)printCurrentCategory {
    
    UInt32 audioCategory;
    UInt32 size = sizeof(audioCategory);
    AudioSessionGetProperty(kAudioSessionProperty_AudioCategory, &size, audioCategory);
    
    if ( audioCategory == kAudioSessionCategory_UserInterfaceSoundEffects ){
        NSLog(@"current category is : dioSessionCategory_UserInterfaceSoundEffects");
    } else if ( audioCategory == kAudioSessionCategory_AmbientSound ){
        NSLog(@"current category is : kAudioSessionCategory_AmbientSound");
    } else if ( audioCategory == kAudioSessionCategory_AmbientSound ){
        NSLog(@"current category is : kAudioSessionCategory_AmbientSound");
    } else if ( audioCategory == kAudioSessionCategory_SoloAmbientSound ){
        NSLog(@"current category is : kAudioSessionCategory_SoloAmbientSound");
    } else if ( audioCategory == kAudioSessionCategory_MediaPlayback ){
        NSLog(@"current category is : kAudioSessionCategory_MediaPlayback");
    } else if ( audioCategory == kAudioSessionCategory_LiveAudio ){
        NSLog(@"current category is : kAudioSessionCategory_LiveAudio");
    } else if ( audioCategory == kAudioSessionCategory_RecordAudio ){
        NSLog(@"current category is : kAudioSessionCategory_RecordAudio");
    } else if ( audioCategory == kAudioSessionCategory_PlayAndRecord ){
        NSLog(@"current category is : kAudioSessionCategory_PlayAndRecord");
    } else if ( audioCategory == kAudioSessionCategory_AudioProcessing ){
        NSLog(@"current category is : kAudioSessionCategory_AudioProcessing");
    } else {
        NSLog(@"current category is : unknow");
    }
    
}

#pragma mark ---- 强制修改声音输出设备
//强制修改系统声音输出设备
- (void)resetOutputTarget {
    BOOL hasHeadset = [MSBAudioTools hasHeadset];
    NSLog (@"Will Set output target is_headset = %@ .", hasHeadset ? @"YES" : @"NO");
//    UInt32 audioRouteOverride = hasHeadset ?
//    kAudioSessionOverrideAudioRoute_None:kAudioSessionOverrideAudioRoute_Speaker;
////    该属性只有当category为kAudioSessionCategory_PlayAndRecord或者AVAudioSessionCategoryRecord时才能使用
//    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
//    AVAudioSessionCategoryOptions optionskey = hasHeadset ? AVAudioSessionCategoryOptionAllowBluetooth : AVAudioSessionCategoryOptionDefaultToSpeaker;
    AVAudioSessionCategory category = hasHeadset ? AVAudioSessionCategoryPlayAndRecord : AVAudioSessionCategorySoloAmbient;

    [session setCategory:category error:nil];
}

- (void)resetInputTarget {
    BOOL hasHeadset = [MSBAudioTools hasHeadset];
    NSLog (@"Will Set input target is_headset = %@ .", hasHeadset ? @"YES" : @"NO");
//    UInt32 audioRouteOverride = hasHeadset ?
//    kAudioSessionOverrideAudioRoute_None:kAudioSessionCategory_PlayAndRecord;
//    AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(audioRouteOverride), &audioRouteOverride);
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
//    AVAudioSessionCategoryOptions optionskey = hasHeadset ? AVAudioSessionCategoryOptionAllowBluetooth : AVAudioSessionCategoryOptionDefaultToSpeaker;
    AVAudioSessionCategory category = hasHeadset ? AVAudioSessionCategoryPlayAndRecord : AVAudioSessionCategorySoloAmbient;
    [session setCategory:category error:nil];
    
}

- (BOOL)checkAndPrepareCategoryForRecording {
    recording = YES;
    BOOL hasMicphone = [MSBAudioTools hasMicphone];
    NSLog(@"Will Set category for recording! hasMicophone = %@", hasMicphone?@"YES":@"NO");
    if (hasMicphone) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                               error:nil];
    }
    [self resetOutputTarget];
    return hasMicphone;
}

- (void)resetCategory {
    if (!recording) {
        NSLog(@"Will Set category to static value = AVAudioSessionCategoryPlayback!");
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                               error:nil];
    }
}

//void audioRouteChangeListenerCallback (
//                                       void                      *inUserData,
//                                       AudioSessionPropertyID    inPropertyID,
//                                       UInt32                    inPropertyValueSize,
//                                       const void                *inPropertyValue
//                                       ) {
//
//    if (inPropertyID != kAudioSessionProperty_AudioRouteChange) return;
//    // Determines the reason for the route change, to ensure that it is not
//    //        because of a category change.
//
//    CFDictionaryRef    routeChangeDictionary = inPropertyValue;
//    CFNumberRef routeChangeReasonRef =
//    CFDictionaryGetValue (routeChangeDictionary,
//                          CFSTR (kAudioSession_AudioRouteChangeKey_Reason));
//    SInt32 routeChangeReason;
//    CFNumberGetValue (routeChangeReasonRef, kCFNumberSInt32Type, &routeChangeReason);
//    NSLog(@" ======================= RouteChangeReason : %d", routeChangeReason);
//    LFAudioCapture *_self = (__bridge LFAudioCapture *) inUserData;
//    if (routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable) {
//
//        [_self resetSettings];
//
//        if (![_self hasHeadset]) {
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"ununpluggingHeadse
//                                                                object:nil];
//        }
//
//    } else if (routeChangeReason == kAudioSessionRouteChangeReason_NewDeviceAvailable) {
//
//        [_self resetSettings];
//        if (![_self hasMicphone]) {
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"pluggInMicrophone"
//                                                                object:nil];
//        }
//
//    } else if (routeChangeReason == kAudioSessionRouteChangeReason_NoSuitableRouteForCategory) {
//
//        [_self resetSettings];
//
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"lostMicroPhone"
//                                                            object:nil];
//
//    }else{
//
//    }
//
////    [_self printCurrentCategory];
//
//}

- (void)handleInterruption:(NSNotification *)notification {
    NSInteger reason = 0;
    NSString *reasonStr = @"";
    if ([notification.name isEqualToString:AVAudioSessionInterruptionNotification]) {
        //Posted when an audio interruption occurs.
        reason = [[[notification userInfo] objectForKey:AVAudioSessionInterruptionTypeKey] integerValue];
        if (reason == AVAudioSessionInterruptionTypeBegan) {
            if (self.isRunning) {
                dispatch_sync(self.taskQueue, ^{
                    NSLog(@"MicrophoneSource: stopRunning");
                    AudioOutputUnitStop(self.componetInstance);
                });
            }
        }
        if (reason == AVAudioSessionInterruptionTypeEnded) {
            reasonStr = @"AVAudioSessionInterruptionTypeEnded";
            NSNumber *seccondReason = [[notification userInfo] objectForKey:AVAudioSessionInterruptionOptionKey];
            switch ([seccondReason integerValue]) {
            case AVAudioSessionInterruptionOptionShouldResume:
                if (self.isRunning) {
                    dispatch_async(self.taskQueue, ^{
                        NSLog(@"MicrophoneSource: startRunning");
                        AudioOutputUnitStart(self.componetInstance);
                    });
                }
                // Indicates that the audio session is active and immediately ready to be used. Your app can resume the audio operation that was interrupted.
                break;
            default:
                break;
            }
        }
    };
    
    NSLog(@"handleInterruption: %@ reason %@", [notification name], reasonStr);
}

#pragma mark -- CallBack
static OSStatus handleInputBuffer(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    @autoreleasepool {
        LFAudioCapture *source = (__bridge LFAudioCapture *)inRefCon;
        if (!source) return -1;

        AudioBuffer buffer;
        buffer.mData = NULL;
        buffer.mDataByteSize = 0;
        buffer.mNumberChannels = 1;

        AudioBufferList buffers;
        buffers.mNumberBuffers = 1;
        buffers.mBuffers[0] = buffer;

        OSStatus status = AudioUnitRender(source.componetInstance,
                                          ioActionFlags,
                                          inTimeStamp,
                                          inBusNumber,
                                          inNumberFrames,
                                          &buffers);

        if (source.muted) {
            for (int i = 0; i < buffers.mNumberBuffers; i++) {
                AudioBuffer ab = buffers.mBuffers[i];
                memset(ab.mData, 0, ab.mDataByteSize);
            }
        }

        if (!status) {
            if (source.delegate && [source.delegate respondsToSelector:@selector(captureOutput:audioData:)]) {
                [source.delegate captureOutput:source audioData:[NSData dataWithBytes:buffers.mBuffers[0].mData length:buffers.mBuffers[0].mDataByteSize]];
            }
        }
        
        return status;
    }
}

@end
