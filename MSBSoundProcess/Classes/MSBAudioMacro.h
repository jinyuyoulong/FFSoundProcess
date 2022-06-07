//
//  MSBAudioMacro.h
//  MSBSoundProcess
//
//  Created by 范金龙 on 2021/2/23.
//

#ifndef MSBAudioMacro_h
#define MSBAudioMacro_h

#define kAudioRecordPCMFile @"record.pcm"
#define kAudioRecordConvertedPCMFile @"convert.pcm"
#define kAudioRecordConvertedWAVFile @"convert.wav"
//#define kAudioRecordConvertedMP3 @"convert.mp3"

#define kAudioMusicName @"compositionedAudio.m4a"
#define kAudioFileName @"audio"

#define kMSBAudioChannelNumber 1
#define kMSBAudioSampleRate 44100

#ifdef DEBUG
#define MSBAudioLog(fmt, ...) if(MSBUnityAudioCaptureInterface.shared.islog){NSLog((@"音频采集pod:" fmt), ##__VA_ARGS__);}
#else
#define MSBAudioLog(...);
#endif




#endif /* MSBAudioMacro_h */
