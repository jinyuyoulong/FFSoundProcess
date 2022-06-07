#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "MSBAudioCapture.h"
#import "MSBAudioCaptureManager.h"
#import "MSBAudioCompositioner.h"
#import "MSBAudioConvertor.h"
#import "MSBAudioFileManager.h"
#import "MSBAudioKitInterface.h"
#import "MSBAudioMacro.h"
#import "MSBAudioManager.h"
#import "MSBAudioMIDITool.h"
#import "MSBAudioProcessor.h"
#import "MSBAudioTensorflowManager.h"
#import "MSBRecordManager.h"
#import "MSBSoundProcess-Bridging-Header.h"
#import "MSBSoundProcessHeader.h"
#import "MSBUnityAudioCaptureInterface.h"
#import "Header_audio.h"
#import "PCM2Wav.h"
#import "pcm_wav.h"
#import "XBAudioFileDataReader.h"
#import "XBAudioPCMDataReader.h"
#import "XBAudioPlayAndRecoder.h"
#import "XBAudioPlayer.h"
#import "XBAudioTool.h"
#import "XBAudioUnitPlayer.h"
#import "XBAudioUnitRecorder.h"
#import "XBDataWriter.h"
#import "XBExtAudioFileRef.h"
#import "XBPCMPlayer.h"

FOUNDATION_EXPORT double MSBSoundProcessVersionNumber;
FOUNDATION_EXPORT const unsigned char MSBSoundProcessVersionString[];

