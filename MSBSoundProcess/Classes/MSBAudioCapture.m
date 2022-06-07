//
//  MSBAudioCapture.m
//  MSBSoundProcess
//
//  Created by 范金龙 on 2021/2/15.
//

#import "MSBAudioCapture.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "MSBAudioMacro.h"
#import "MSBUnityAudioCaptureInterface.h"
NSString *const MSBAudioComponentFailedToCreateNotification = @"MSBAudioComponentFailedToCreateNotification";

@interface MSBAudioCapture ()
{
    BOOL recording;
}

@property (nonatomic, assign) AudioComponentInstance componetInstance;
@property (nonatomic, assign) AudioComponent component;
@property (nonatomic, strong) dispatch_queue_t taskQueue;

@end

@implementation MSBAudioCapture

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
        desc.mSampleRate = kMSBAudioSampleRate;
        desc.mFormatID = kAudioFormatLinearPCM;
        desc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
        desc.mChannelsPerFrame = kMSBAudioChannelNumber;
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
        
        [session setPreferredSampleRate:kMSBAudioSampleRate error:nil];
        
        [session setCategory:AVAudioSessionCategoryPlayAndRecord
                 withOptions:AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers
                       error:nil];

        [session setActive:YES withOptions:kAudioSessionSetActiveFlag_NotifyOthersOnDeactivation error:nil];
        
        [session setActive:YES error:nil];
    
    }
    return self;
}

- (void)dealloc {
    typeof(self) __weak weakSelf = self;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    dispatch_sync(self.taskQueue, ^{
        if (weakSelf.componetInstance) {
            weakSelf.isRunning = NO;
            AudioOutputUnitStop(self.componetInstance);
            AudioComponentInstanceDispose(self.componetInstance);
            weakSelf.componetInstance = nil;
            weakSelf.component = nil;
        }
    });
}


#pragma mark -- Setter
//- (void)setRunning:(BOOL)running {
//    if (_running == running) return;
//    NSError *error = nil;
//
//    _running = running;
//    typeof(self) __weak weakSelf = self;
//
//    if (_running) {
//        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
//        [[AVAudioSession sharedInstance] setActive:YES error:&error];
////        dispatch_async(self.taskQueue, ^{
//            weakSelf.isRunning = YES;
//        MSBAudioLog(@"MicrophoneSource: startRunning");
//        OSStatus status = AudioOutputUnitStart(weakSelf.componetInstance);
//        if (status == noErr) {
//            MSBAudioLog(@"AudioOutputUnitStart 正确");
//        }
////        });
//    } else {
//        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
////        [[AVAudioSession sharedInstance] setActive:NO error:&error];
//
//        self.isRunning = NO;
//        MSBAudioLog(@"MicrophoneSource: stopRunning");
//        OSStatus status = AudioOutputUnitStop(weakSelf.componetInstance);
//        if (status == noErr) {
//            MSBAudioLog(@"AudioOutputUnitStop 正确");
//        }
//
//    }
//}

- (void)startAudio
{
    if (!self.isRunning) {
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord
                                         withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                                               error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
        self.isRunning = YES;
        MSBAudioLog(@"MicrophoneSource: startRunning");
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            OSStatus status = AudioOutputUnitStart(self.componetInstance);
            if (status == noErr) {
                MSBAudioLog(@"AudioOutputUnitStart 正确");
            }

        });
    }
}

- (void)stopAudio
{
    if (self.isRunning) {
        self.isRunning = NO;
        MSBAudioLog(@"MicrophoneSource: stopRunning");
        OSStatus status = AudioOutputUnitStop(self.componetInstance);
        if (status == noErr) {
            MSBAudioLog(@"AudioOutputUnitStop 正确");
        }
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
        [[NSNotificationCenter defaultCenter] postNotificationName:MSBAudioComponentFailedToCreateNotification object:nil];
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
    MSBAudioLog(@"handleRouteChange reason is %@", seccReason);

    NSArray* inputs = [[AVAudioSession sharedInstance] currentRoute].inputs;
    NSArray* output = [[AVAudioSession sharedInstance] currentRoute].outputs;
    MSBAudioLog(@"current inputs:%@",inputs);
    MSBAudioLog(@"current output:%@",output);

    NSArray* availableInputs = [[AVAudioSession sharedInstance] availableInputs];
    MSBAudioLog(@"current available availableInputs:%@",availableInputs);

    BOOL hasMicphone = [[AVAudioSession sharedInstance] isInputAvailable];
    MSBAudioLog(@"hasMicphone:%d",hasMicphone);

    MSBAudioLog(@"hasHeadset:%d",[self hasHeadset]);
    
//    for (AVAudioSessionPortDescription* desc in availableInputs) {
//        if ([desc.portType isEqualToString:AVAudioSessionPortBuiltInMic]) {// 内置麦克风
//            MSBAudioLog(@"current available inputs：AVAudioSessionPortBuiltInMic");
//        }else if([desc.portType isEqualToString:AVAudioSessionPortLineIn]){
//            MSBAudioLog(@"current available inputs:AVAudioSessionPortLineIn");
//        }else if ([desc.portType isEqualToString:AVAudioSessionPortHeadsetMic]){// 耳机线中的麦克风
//            MSBAudioLog(@"current available inputs:AVAudioSessionPortHeadsetMic");
//        }
//    }
//
//    for (AVAudioSessionPortDescription *desc in inputArray) {
//        if ([desc.portType isEqualToString:self.audioSessionPort]) {
//            NSError *error;
//            [[AVAudioSession sharedInstance] setPreferredInput:desc error:&error];
//        }
//    }
    if ([session.currentRoute.inputs count] > 0) {
        AVAudioSessionPortDescription *input = [[session.currentRoute.inputs count] ? session.currentRoute.inputs : nil objectAtIndex:0];
        MSBAudioLog(@"session.currentRoute.inputs:%@ input.portType:%@",session.currentRoute.inputs,input.portType);
        if (input.portType == AVAudioSessionPortHeadsetMic) {
            MSBAudioLog(@"input type is headsetMic");
        }else if (input.portType == AVAudioSessionPortBuiltInMic){
            MSBAudioLog(@"input type is builtInMic");
        }
    }else {
        MSBAudioLog(@"session.currentRoute.inputs:%@",session.currentRoute.inputs);
    }
    
    
}

- (void)printCurrentCategory {
    
    UInt32 audioCategory = 0;
    UInt32 size = sizeof(audioCategory);
    AudioSessionGetProperty(kAudioSessionProperty_AudioCategory, &size, audioCategory);
    
    if ( audioCategory == kAudioSessionCategory_UserInterfaceSoundEffects ){
        MSBAudioLog(@"current category is : dioSessionCategory_UserInterfaceSoundEffects");
    } else if ( audioCategory == kAudioSessionCategory_AmbientSound ){
        MSBAudioLog(@"current category is : kAudioSessionCategory_AmbientSound");
    } else if ( audioCategory == kAudioSessionCategory_AmbientSound ){
        MSBAudioLog(@"current category is : kAudioSessionCategory_AmbientSound");
    } else if ( audioCategory == kAudioSessionCategory_SoloAmbientSound ){
        MSBAudioLog(@"current category is : kAudioSessionCategory_SoloAmbientSound");
    } else if ( audioCategory == kAudioSessionCategory_MediaPlayback ){
        MSBAudioLog(@"current category is : kAudioSessionCategory_MediaPlayback");
    } else if ( audioCategory == kAudioSessionCategory_LiveAudio ){
        MSBAudioLog(@"current category is : kAudioSessionCategory_LiveAudio");
    } else if ( audioCategory == kAudioSessionCategory_RecordAudio ){
        MSBAudioLog(@"current category is : kAudioSessionCategory_RecordAudio");
    } else if ( audioCategory == kAudioSessionCategory_PlayAndRecord ){
        MSBAudioLog(@"current category is : kAudioSessionCategory_PlayAndRecord");
    } else if ( audioCategory == kAudioSessionCategory_AudioProcessing ){
        MSBAudioLog(@"current category is : kAudioSessionCategory_AudioProcessing");
    } else {
        MSBAudioLog(@"current category is : unknow");
    }
    
}

#pragma mark ----- 检查输出设备是否有耳机
- (BOOL)hasHeadset {
#if TARGET_IPHONE_SIMULATOR
#warning *** Simulator mode: audio session code works only on a device
    return NO;
#else
    CFStringRef route;
    UInt32 propertySize = sizeof(CFStringRef);
    AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &propertySize, &route);
    if((route == NULL) || (CFStringGetLength(route) == 0)){
        // Silent Mode
        MSBAudioLog(@"AudioRoute: SILENT, do nothing!");
    } else {
        NSString* routeStr = (__bridge NSString*)route;
        MSBAudioLog(@"AudioRoute: %@", routeStr);
        /* Known values of route:
         * "Headset"
         * "Headphone"
         * "Speaker"
         * "SpeakerAndMicrophone"
         * "HeadphonesAndMicrophone"
         * "HeadsetInOut"
         * "ReceiverAndMicrophone"
         * "Lineout"
         */
        NSRange headphoneRange = [routeStr rangeOfString : @"Headphone"];
        NSRange headsetRange = [routeStr rangeOfString : @"Headset"];
        if (headphoneRange.location != NSNotFound) {
            return YES;
        } else if(headsetRange.location != NSNotFound) {
            return YES;
        }
    }
    return NO;
#endif
}

#pragma mark ---- 强制修改声音输出设备
- (void)resetCategory {
    if (!recording) {
        MSBAudioLog(@"Will Set category to static value = AVAudioSessionCategoryPlayback!");
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                               error:nil];
    }
}

- (void)handleInterruption:(NSNotification *)notification {
    NSInteger reason = 0;
    NSString *reasonStr = @"";
    if ([notification.name isEqualToString:AVAudioSessionInterruptionNotification]) {
        //Posted when an audio interruption occurs.
        reason = [[[notification userInfo] objectForKey:AVAudioSessionInterruptionTypeKey] integerValue];
        if (reason == AVAudioSessionInterruptionTypeBegan) {
            if (self.isRunning) {
                dispatch_sync(self.taskQueue, ^{
                    MSBAudioLog(@"MicrophoneSource: stopRunning");
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
                        MSBAudioLog(@"MicrophoneSource: startRunning");
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
    
    MSBAudioLog(@"handleInterruption: %@ reason %@", [notification name], reasonStr);
}

#pragma mark -- CallBack
static OSStatus handleInputBuffer(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
    @autoreleasepool {
        
        MSBAudioCapture *source = (__bridge MSBAudioCapture *)inRefCon;
        if (source == nil) {
            return -1;
        }

        AudioBuffer buffer;
        buffer.mData = NULL;
        buffer.mDataByteSize = 0;
        buffer.mNumberChannels = 1;

        AudioBufferList buffers;
        buffers.mNumberBuffers = 1;
        buffers.mBuffers[0] = buffer;
        
        // 将回调数据传给_buffList
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
                NSData * data = [NSData dataWithBytes:buffers.mBuffers[0].mData length:buffers.mBuffers[0].mDataByteSize];
                [source.delegate captureOutput:source audioData: data];
            }
        }
        return status;
    }
}
@end
