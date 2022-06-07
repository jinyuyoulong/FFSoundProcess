//
//  MSBAudioConvertor.m
//  MSBSoundProcess
//
//  Created by 范金龙 on 2021/2/18.
//

#import "MSBAudioConvertor.h"
#import <unistd.h>
#import <mach/mach_time.h>
#import <CoreMedia/CMSync.h>
#import <AudioToolbox/AudioToolbox.h>
#import <PFAudioLib/lame.h>
#import "MSBAudioCapture.h"
#import "MSBAudioMacro.h"
#import "MSBUnityAudioCaptureInterface.h"

float   g_avtimfdiff = 0;
Float64 g_vstarttime = 0.0;
#define kXDXAnyWhereVoiceDemoPathComponent  "VoiceDemo"
#define kBufferDurationSeconds              .5
#define kXDXRecoderAudioBytesPerPacket      2
#define kXDXRecoderAACFramesPerPacket       1024
#define kXDXRecoderPCMTotalPacket           512
#define kXDXRecoderPCMFramesPerPacket       1
#define kXDXRecoderConverterEncodeBitRate   64000
#define kXDXAudioSampleRate                 48000.0
#define kTVURecoderPCMMaxBuffSize           2048

// Audio Unit Set Property
#define INPUT_BUS  1      ///< A I/O unit's bus 1 connects to input hardware (microphone).
#define OUTPUT_BUS 0      ///< A I/O unit's bus 0 connects to output hardware (speaker).

//voice memos Macro
#ifdef __XDX_VICE_FEATURE__
#include "XDXCommonDef.h"
#define kAudioStoreFileExtend "caf"
#endif

//XDXVOIPMessageQueue collectPcmQueue;

AudioConverterRef               _encodeConvertRef = NULL;   ///< convert param
AudioStreamBasicDescription     _targetDes;                 ///< destination format

AudioBufferList* convertPCMToAAC (MSBAudioConvertor *recoder);

static int          pcm_buffer_size = 0;
static uint8_t      pcm_buffer[kTVURecoderPCMMaxBuffSize*2];

static int          catchCount = 0;
static float        firstTime  = 0;

#pragma mark Calculate DB
enum ChannelCount
{
    k_Mono = 1,
    k_Stereo
};

void caculate_bm_db(void * const data ,size_t length ,int64_t timestamp, ChannelCount channelModel,
                    float channelValue[2],bool isAudioUnit) {
    int16_t *audioData = (int16_t *)data;
    
    if (channelModel == k_Mono) {
        int     sDbChnnel     = 0;
        int16_t curr          = 0;
        int16_t max           = 0;
        size_t traversalTimes = 0;
        
        if (isAudioUnit) {
            traversalTimes = length/2;// 由于512后面的数据显示异常  需要全部忽略掉
        }else{
            traversalTimes = length;
        }
        
        for(int i = 0; i< traversalTimes; i++) {
            curr = *(audioData+i);
            if(curr > max) max = curr;
        }
        
        if(max < 1) {
            sDbChnnel = -100;
        }else {
            sDbChnnel = (20*log10((0.0 + max)/32767) - 0.5);
        }
        
        channelValue[0] = channelValue[1] = sDbChnnel;
        
    } else if (channelModel == k_Stereo){
        int sDbChA = 0;
        int sDbChB = 0;
        
        int16_t nCurr[2] = {0};
        int16_t nMax[2] = {0};
        
        for(unsigned int i=0; i<length/2; i++) {
            nCurr[0] = audioData[i];
            nCurr[1] = audioData[i + 1];
            
            if(nMax[0] < nCurr[0]) nMax[0] = nCurr[0];
            
            if(nMax[1] < nCurr[1]) nMax[1] = nCurr[0];
        }
        
        if(nMax[0] < 1) {
            sDbChA = -100;
        } else {
            sDbChA = (20*log10((0.0 + nMax[0])/32767) - 0.5);
        }
        
        if(nMax[1] < 1) {
            sDbChB = -100;
        } else {
            sDbChB = (20*log10((0.0 + nMax[1])/32767) - 0.5);
        }
        
        channelValue[0] = sDbChA;
        channelValue[1] = sDbChB;
    }
}


#pragma mark ---------------------------------- CallBack : collect pcm and  convert  -------------------------------------
OSStatus encodeConverterComplexInputDataProc(AudioConverterRef              inAudioConverter,
                                             UInt32                         *ioNumberDataPackets,
                                             AudioBufferList                *ioData,
                                             AudioStreamPacketDescription   **outDataPacketDescription,
                                             void                           *inUserData) {
    
    ioData->mBuffers[0].mData           = inUserData;
    ioData->mBuffers[0].mNumberChannels = _targetDes.mChannelsPerFrame;
    ioData->mBuffers[0].mDataByteSize   = kXDXRecoderAACFramesPerPacket * kXDXRecoderAudioBytesPerPacket * _targetDes.mChannelsPerFrame;
    
    return 0;
}
// PCM -> AAC
AudioBufferList* convertPCMToAAC (MSBAudioConvertor *recoder) {
    
    UInt32   maxPacketSize    = 0;
    UInt32   size             = sizeof(maxPacketSize);
    OSStatus status;
    
    status = AudioConverterGetProperty(_encodeConvertRef,
                                       kAudioConverterPropertyMaximumOutputPacketSize,
                                       &size,
                                       &maxPacketSize);
    //    log4cplus_info("AudioConverter","kAudioConverterPropertyMaximumOutputPacketSize status:%d \n",(int)status);
    
    AudioBufferList *bufferList             = (AudioBufferList *)malloc(sizeof(AudioBufferList));
    bufferList->mNumberBuffers              = 1;
    bufferList->mBuffers[0].mNumberChannels = _targetDes.mChannelsPerFrame;
    bufferList->mBuffers[0].mData           = malloc(maxPacketSize);
    bufferList->mBuffers[0].mDataByteSize   = kTVURecoderPCMMaxBuffSize;
    
    AudioStreamPacketDescription outputPacketDescriptions;
    
    // inNumPackets设置为1表示编码产生1帧数据即返回，官方：On entry, the capacity of outOutputData expressed in packets in the converter's output format. On exit, the number of packets of converted data that were written to outOutputData. 在输入表示输出数据的最大容纳能力 在转换器的输出格式上，在转换完成时表示多少个包被写入
    UInt32 inNumPackets = 1;
    // inNumPackets设置为1表示编码产生1024帧数据即返回
    // Notice : Here, due to encoder characteristics, 1024 frames of data must be given to the encoder in order to complete a conversion, 在此处由于编码器特性,必须给编码器1024帧数据才能完成一次转换,也就是刚刚在采集数据回调中存储的pcm_buffer
    status = AudioConverterFillComplexBuffer(_encodeConvertRef,
                                             encodeConverterComplexInputDataProc,
                                             pcm_buffer,
                                             &inNumPackets,
                                             bufferList,
                                             &outputPacketDescriptions);

    if(status != noErr){
//        log4cplus_debug("Audio Recoder","set AudioConverterFillComplexBuffer status:%d inNumPackets:%d \n",(int)status, inNumPackets);
        free(bufferList->mBuffers[0].mData);
        free(bufferList);
        return NULL;
    }
    
    if (recoder.needsVoiceDemo) {
        // if inNumPackets set not correct, file will not normally play. 将转换器转换出来的包写入文件中，inNumPackets表示写入文件的起始位置
        OSStatus status = AudioFileWritePackets(recoder.mRecordFile,
                                                FALSE,
                                                bufferList->mBuffers[0].mDataByteSize,
                                                &outputPacketDescriptions,
                                                recoder.mRecordPacket,
                                                &inNumPackets,
                                                bufferList->mBuffers[0].mData);
        //        log4cplus_info("write file","write file status = %d",(int)status);
        if (status == noErr) {
            recoder.mRecordPacket += inNumPackets;  // 用于记录起始位置
        }
    }
    
    return bufferList;
}

#pragma mark - AudioUnit
static OSStatus RecordCallback(void *inRefCon,
                               AudioUnitRenderActionFlags *ioActionFlags,
                               const AudioTimeStamp *inTimeStamp,
                               UInt32 inBusNumber,
                               UInt32 inNumberFrames,
                               AudioBufferList *ioData) {
/*
      注意：如果采集的数据是PCM需要将dataFormat.mFramesPerPacket设置为1，而本例中最终要的数据为AAC,因为本例中使用的转换器只有每次传入1024帧才能开始工作,所以在AAC格式下需要将mFramesPerPacket设置为1024.也就是采集到的inNumPackets为1，在转换器中传入的inNumPackets应该为AAC格式下默认的1，在此后写入文件中也应该传的是转换好的inNumPackets,如果有特殊需求需要将采集的数据量小于1024,那么需要将每次捕捉到的数据先预先存储在一个buffer中,等到攒够1024帧再进行转换。
 */
    
    MSBAudioConvertor *recorder = (__bridge MSBAudioConvertor *)inRefCon;
    
    // 将回调数据传给_buffList
    AudioUnitRender(recorder->_audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, recorder->_buffList);
    
    void    *bufferData = recorder->_buffList->mBuffers[0].mData;
    UInt32   bufferSize = recorder->_buffList->mBuffers[0].mDataByteSize;
    //    printf("Audio Recoder Render dataSize : %d \n",bufferSize);
    
    float channelValue[2];
    caculate_bm_db(bufferData, bufferSize, 0, k_Mono, channelValue,true);
    recorder.volLDB = channelValue[0];
    recorder.volRDB = channelValue[1];
//    log4cplus_info("Audio Recorder", "demonVol - %f \n",channelValue[0]);
    
    // 由于PCM转成AAC的转换器每次需要有1024个采样点（每一帧2个字节）才能完成一次转换，所以每次需要2048大小的数据，这里定义的pcm_buffer用来累加每次存储的bufferData
    memcpy(pcm_buffer+pcm_buffer_size, bufferData, bufferSize);
    pcm_buffer_size = pcm_buffer_size + bufferSize;
    
    if(pcm_buffer_size >= kTVURecoderPCMMaxBuffSize) {
        AudioBufferList *bufferList = convertPCMToAAC(recorder);
        
        // 因为采样不可能每次都精准的采集到1024个样点，所以如果大于2048大小就先填满2048，剩下的跟着下一次采集一起送给转换器
        memcpy(pcm_buffer, pcm_buffer + kTVURecoderPCMMaxBuffSize, pcm_buffer_size - kTVURecoderPCMMaxBuffSize);
        pcm_buffer_size = pcm_buffer_size - kTVURecoderPCMMaxBuffSize;
        
        // free memory
        if(bufferList) {
            free(bufferList->mBuffers[0].mData);
            free(bufferList);
        }
    }
    return noErr;
}
#pragma mark - AudioQueue
static void inputBufferHandler(void *                                 inUserData,
                               AudioQueueRef                          inAQ,
                               AudioQueueBufferRef                    inBuffer,
                               const AudioTimeStamp *                 inStartTime,
                               UInt32                                 inNumPackets,
                               const AudioStreamPacketDescription*      inPacketDesc) {
    MSBAudioConvertor *recoder        = (__bridge MSBAudioConvertor *)inUserData;
    
    /*
     inNumPackets 总包数：音频队列缓冲区大小 （在先前估算缓存区大小为kXDXRecoderAACFramesPerPacket*2）/ （dataFormat.mFramesPerPacket (采集数据每个包中有多少帧，此处在初始化设置中为1) * dataFormat.mBytesPerFrame（每一帧中有多少个字节，此处在初始化设置中为每一帧中两个字节）），所以可以根据该公式计算捕捉PCM数据时inNumPackets。
     注意：如果采集的数据是PCM需要将dataFormat.mFramesPerPacket设置为1，而本例中最终要的数据为AAC,因为本例中使用的转换器只有每次传入1024帧才能开始工作,所以在AAC格式下需要将mFramesPerPacket设置为1024.也就是采集到的inNumPackets为1，在转换器中传入的inNumPackets应该为AAC格式下默认的1，在此后写入文件中也应该传的是转换好的inNumPackets,如果有特殊需求需要将采集的数据量小于1024,那么需要将每次捕捉到的数据先预先存储在一个buffer中,等到攒够1024帧再进行转换。
     */
    
    // Get DB
    float channelValue[2];
    caculate_bm_db(inBuffer->mAudioData, inBuffer->mAudioDataByteSize, 0, k_Mono, channelValue,true);
    recoder.volLDB = channelValue[0];
    recoder.volRDB = channelValue[1];
    
    // collect pcm data，可以在此存储
    // 由于PCM转成AAC的转换器每次需要有1024个采样点（每一帧2个字节）才能完成一次转换，所以每次需要2048大小的数据，这里定义的pcm_buffer用来累加每次存储的bufferData
    memcpy(pcm_buffer+pcm_buffer_size, inBuffer->mAudioData, inBuffer->mAudioDataByteSize);
    pcm_buffer_size = pcm_buffer_size + inBuffer->mAudioDataByteSize;
    
    if(pcm_buffer_size >= kTVURecoderPCMMaxBuffSize){
        AudioBufferList *bufferList = convertPCMToAAC(recoder);
        
        // 因为采样不可能每次都精准的采集到1024个样点，所以如果大于2048大小就先填满2048，剩下的跟着下一次采集一起送给转换器
        memcpy(pcm_buffer, pcm_buffer + kTVURecoderPCMMaxBuffSize, pcm_buffer_size - kTVURecoderPCMMaxBuffSize);
        pcm_buffer_size = pcm_buffer_size - kTVURecoderPCMMaxBuffSize;
        
        // free memory
        if(bufferList) {
            free(bufferList->mBuffers[0].mData);
            free(bufferList);
        }
    }
    // 出队
    AudioQueueRef queue = recoder.mQueue;
    if (recoder.isRunning) {
        AudioQueueEnqueueBuffer(queue, inBuffer, 0, NULL);
    }
}

@interface MSBAudioConvertor ()
-(void)setUpRecoderWithFormatID:(UInt32) formatID;

-(int)computeRecordBufferSizeFrom:(const AudioStreamBasicDescription *) format andDuration:(float) seconds;

-(void)copyEncoderCookieToFile;
@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MSBAudioConvertor

@synthesize needsVoiceDemo = mNeedsVoiceDemo;
// wav 转 mp3
+ (void)convertPCMToMp3:(NSString *)pcmFilePath
                success:(void(^)(NSString *outPath))success
                failure:(void(^)(NSError *error))failure {
    
    // 判断输入路径是否存在
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:pcmFilePath])
    {
        MSBAudioLog(@"文件不存在");
        return ;
    }
    
    // 输出路径
    NSString *mp3FilePath = [[pcmFilePath stringByDeletingPathExtension] stringByAppendingString:@".mp3"];
    @try {
        
        int channel = 1;
        int read, write;
        FILE *pcm = fopen([pcmFilePath cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
        if (!pcm) {
            return;
        }
        
        // 删除头，否则在前一秒钟会有杂音
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen([mp3FilePath cStringUsingEncoding:1], "wb");  //output 输出生成的Mp3文件位置
        
        const int PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        lame_t lame = lame_init();
        lame_set_num_channels(lame,channel);
        lame_set_in_samplerate(lame, kMSBAudioSampleRate);
        //        lame_set_out_samplerate(lame, kMSBAudioSampleRate/2); //设置输出数据采样率，默认和输入的一致
        //关键这一句！！！！！！！！！！！！
        lame_set_VBR_mean_bitrate_kbps(lame, 24);
        // lame_set_VBR(lame, vbr_default);//压缩级别参数：
        lame_set_brate(lame,16);/* CBR模式下的，CBR比特率 */
        lame_set_mode(lame,MONO);//输出通道数 模式参数:stereo 双，MONO 单
        lame_set_quality(lame,2);/* 2=high  5 = medium  7=low */
        
        lame_init_params(lame);
        
        do {
            read = (int)fread(pcm_buffer, channel*sizeof(short int), PCM_SIZE, pcm);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else {
                if (channel == 2) {
                    write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
                }else {//单声道走这
                    write = lame_encode_buffer(lame, pcm_buffer, NULL, read, mp3_buffer, MP3_SIZE);
                }
                
            }
            
            /*
             * 二进制形式写数据到文件中
             *
             * mp3_buffer：数据输出到文件的缓冲区首地址
             * write：一个数据块的字节数
             * 1：指定一次输出数据块的个数
             * mp3：文件指针
             */
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        lame_mp3_tags_fid(lame, mp3);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    } @catch (NSException *exception) {
        MSBAudioLog(@"%@", [exception description]);
        if (failure) {
            failure(nil);
        }
    } @finally {
        MSBAudioLog(@"PCM转换MP3转换成功");
        // 删除原始音源 wav
        if ([fm fileExistsAtPath:pcmFilePath]) {
//            [fm removeItemAtPath:pcmFilePath error:nil];
        }
        if (success) {
            success(mp3FilePath);
        }
    }
    
    double time = [MSBAudioConvertor audioDurationFromUrl:mp3FilePath];
    NSLog(@"当前转换的mp3时长是：%li",time);
}

+ (NSTimeInterval)audioDurationFromUrl:(NSString *)url {
    //只有这个方法获取时间是准确的 audioPlayer.duration获得的时间不准
    AVURLAsset* audioAsset = nil;
    NSDictionary *dic = @{AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)};
    if ([url hasPrefix:@"http://"]) {
        audioAsset =[AVURLAsset URLAssetWithURL:[NSURL URLWithString:url] options:dic];
    }else {//播放本机录制的文件
        audioAsset =[AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:url] options:dic];
    }
    CMTime audioDuration = audioAsset.duration;
    float audioDurationSeconds =CMTimeGetSeconds(audioDuration);
    return audioDurationSeconds;
}

//m4a转成mp3会损坏音频格式,先转为wav
+ (void)convertM4AToWAV:(NSString *)originalPath
                success:(void(^)(NSString *outputPath))success
                failure:(void(^)(NSError *error))failure {
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:originalPath])
    {
        MSBAudioLog(@"文件不存在");
        return ;
    }
    NSError *error = nil;
    NSURL *originalUrl = [NSURL fileURLWithPath:originalPath];
    NSString *outputPath = [[originalPath stringByDeletingPathExtension] stringByAppendingString:@".wav"];
    NSURL *outputURL = [NSURL fileURLWithPath:outputPath];
    if ([fm fileExistsAtPath:outputPath])
    {
        MSBAudioLog(@"outPutUrl：文件存在，删除");
        [fm removeItemAtPath:outputPath error:&error];
    }
    
   AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:originalUrl options:nil];    //读取原始文件信息
   
   AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:songAsset error:&error];
   if (error) {
       MSBAudioLog(@"error: %@", error);
       return;
   }
   AVAssetReaderOutput *assetReaderOutput = [AVAssetReaderAudioMixOutput
                                             assetReaderAudioMixOutputWithAudioTracks:songAsset.tracks
                                             audioSettings: nil];
   if (![assetReader canAddOutput:assetReaderOutput]) {
       MSBAudioLog(@"can't add reader output... die!");
       return;
   }
   [assetReader addOutput:assetReaderOutput];
   
    AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:outputURL fileType:AVFileTypeCoreAudioFormat error:&error];
   if (error) {
    MSBAudioLog(@"error: %@", error);
       return;
   }
   AudioChannelLayout channelLayout;
   memset(&channelLayout, 0, sizeof(AudioChannelLayout));
   channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
   
   /** 配置音频参数 */
   NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                   [NSNumber numberWithFloat:kMSBAudioSampleRate/2], AVSampleRateKey,
                                   [NSNumber numberWithInt:2], AVNumberOfChannelsKey,
                                   [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)], AVChannelLayoutKey,
                                   [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
                                   [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
                                   [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,
                                   [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                                   nil];
   AVAssetWriterInput *assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio                                                                                outputSettings:outputSettings];
   if ([assetWriter canAddInput:assetWriterInput]) {
       [assetWriter addInput:assetWriterInput];
   } else {
       MSBAudioLog(@"can't add asset writer input... die!");
       return;
   }
   assetWriterInput.expectsMediaDataInRealTime = NO;
   [assetWriter startWriting];
   [assetReader startReading];
   AVAssetTrack *soundTrack = [songAsset.tracks objectAtIndex:0];
   CMTime startTime = CMTimeMake (0, soundTrack.naturalTimeScale);
   [assetWriter startSessionAtSourceTime:startTime];
   __block UInt64 convertedByteCount = 0;
   dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
   [assetWriterInput requestMediaDataWhenReadyOnQueue:mediaInputQueue  usingBlock: ^{
       while (assetWriterInput.readyForMoreMediaData) {
           CMSampleBufferRef nextBuffer = [assetReaderOutput copyNextSampleBuffer];
           if (nextBuffer) {
               // append buffer
               [assetWriterInput appendSampleBuffer: nextBuffer];
               convertedByteCount += CMSampleBufferGetTotalSampleSize (nextBuffer);
           } else {
               [assetWriterInput markAsFinished];
               [assetWriter finishWritingWithCompletionHandler:^{
               }];
               [assetReader cancelReading];
               
               NSDictionary *outputFileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[outputURL path] error:nil];
               MSBAudioLog(@"FlyElephant %lld",[outputFileAttributes fileSize]);
               // 删除原始音源
               if ([fm fileExistsAtPath:originalPath])
               {
                   [fm removeItemAtPath:originalPath error:nil];
               }
               success(outputPath);
               break;
           }
       }
   }];
}
+ (void)convertM4AToMp3:(NSString *)originalPath
                success:(void(^)(NSString *mp3Path))success
                failure:(void(^)(NSError *error))failure {
    [MSBAudioConvertor convertM4AToWAV:originalPath
                               success:^(NSString *outputPath) {
        [MSBAudioConvertor convertPCMToMp3:outputPath
                                   success:^(NSString * _Nonnull mp3Path) {
            success(mp3Path);
        } failure:^(NSError * _Nonnull error) {
            failure(error);
        }];
    } failure:^(NSError *error) {
        failure(error);
    }];
}

@end
