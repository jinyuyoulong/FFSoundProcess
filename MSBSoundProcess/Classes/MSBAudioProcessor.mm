//
//  MSBAudioProcessor.m
//  MSBSoundProcess
//
//  Created by 范金龙 on 2021/10/13.
//

#import "MSBAudioProcessor.h"
#import <SoundProcess/SoundProcess.h>

//aec_test;播放器;
#import "XBPCMPlayer.h"
#import "XBAudioTool.h"
#import "XBAudioPlayer.h"
#import "XBAudioPCMDataReader.h"
#import "XBDataWriter.h"
#import "XBExtAudioFileRef.h"

//aec_test;recode;
#import "XBAudioUnitRecorder.h"
#import "XBAudioPlayAndRecoder.h"
#include <string>
#include <map>
#include <vector>
#include <queue>

//#import "MSBAudioCaptureManager.h"
#import "MSBAudioMacro.h"
#import "MSBUnityAudioCaptureInterface.h"
#import <OSAbility/OSAbility-umbrella.h>// mm文件不能引入swift库头文件

@interface MSBAudioProcessor ()<XBPCMPlayerDelegate>
{
    BOOL _isPreproocessedAudio;// 背景音解码标识
    BOOL _isProcessingData;
}

@property (nonatomic,strong) MSBVoicePreprocess *voicePreProcess;                   //3a处理对象;
@property (nonatomic,strong) MSBVoiceAnalysisProcess *voiceAnalysisProcess;         //音高检测对象;
@property (nonatomic,strong) MSBVoiceAnalysisPitchAndNoteInfo *m_analysisInfoPitchAndNoteInfo; //检测结构体;


@property (nonatomic,strong) XBPCMPlayer *m_palyer_aec;  //aec_test;播放器对象;
@property (nonatomic,strong) NSMutableData * m_player_pcm_alldata;  //要播放的pcm文件的所有数据;
@property (nonatomic,strong) XBAudioUnitRecorder *m_recorder_aec;  //aec_test;recoderd对象;

@property (nonatomic,strong) XBExtAudioFileRef *m_xbFile_aec_player; //aec_test;player写入文件对象;
@property (nonatomic,strong) XBExtAudioFileRef *m_xbFile_aec_recoder; //aec_test;recoderd写入文件对象;
@property (nonatomic,strong) NSMutableData * m_palyer_aec_outall_data;   //输出的play所有数据队列;
@property (nonatomic,assign) NSUInteger m_player_outall_data_length;   //输出的play播放过的所有数据
@property (nonatomic,strong) NSMutableData * m_recoder_aec_outall_data;   //输出的reoder所有数据队列;
@property (nonatomic,assign) FILE * m_testfilePath_fp_player;   //测试play写入文件用的文件句柄;
@property (nonatomic,assign) FILE * m_testfilePath_fp_recoder;   //测试recoder写入文件用的文件句柄;
@property (nonatomic,assign) FILE * m_testfilePath_fp_aecout;       //测试aec输出结果的文件句柄;
@property (nonatomic,strong) NSLock * m_lock_aec_player;                 //aec输入和输出锁player;
@property (nonatomic,assign) int m_aec_first_player_samples;                 //aec第一次获取数据samples数量;
@property (nonatomic,assign) int m_aec_first_record_samples;                 //aec第一次获取数据samples数量;
@property (nonatomic,assign) int m_aec_InSndCardBuf;                 //aec对齐毫秒数;
@property (nonatomic,strong) NSMutableData * m_out_aec_data;         //输出的aec输出的结果;
@property (nonatomic,strong) NSThread  *m_aec_AnalysisThread;        //aec分析线程具柄;
@property (nonatomic,assign) int m_Analysis_thread_isruning;         //aec分析线程是否启动;

@property (nonatomic,assign) int m_ispause;         //是否暂停;
@end

#define filepath [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"record.pcm"]

static std::vector<std::string> m_ScaleName;        //88个键，例如4C;
static std::vector<NSString *> m_percentage_vector; //录音过滤稳定用的百分比vector;


@implementation MSBAudioProcessor
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initScale_Name];
    }
    return self;
}


- (void)initScale_Name {
    //88个键字符串;
    std::string scale_Name[] ={"C","C♯/D♭","D","D♯/E♭","E","F","F♯/G♭","G","G♯/A♭","A","A♯/B♭","B"};
    for(int scale = 0; scale < 88; scale++)
    {
        if (scale<3) {
            std::string tempvalue_string;
            char temp_value[48] = {0};
            sprintf(temp_value,"%d%s",0,scale_Name[9+scale].c_str());
            tempvalue_string.append(temp_value);
            m_ScaleName.push_back(tempvalue_string);
            
        } else if(scale>=3 && scale<=86) {
            std::string tempvalue_string;
            char temp_value[48] = {0};
            sprintf(temp_value,"%d%s",((scale-3)/12+1),scale_Name[(scale-3)%12].c_str());
            tempvalue_string.append(temp_value);
            m_ScaleName.push_back(tempvalue_string);
        } else {
            std::string tempvalue_string;
            char temp_value[48] = {0};
            sprintf(temp_value,"%d%s",8,scale_Name[0].c_str());
            tempvalue_string.append(temp_value);
            m_ScaleName.push_back(tempvalue_string);
        }
    }
    //默认是暂停;
    self.m_ispause = 1;
    self.minOctave = 2;
    self.maxOctave = 6;
    self.filterPercentage = 0.35;
}
- (MSBVoicePreprocess *)voicePreProcess {
    if (!_voicePreProcess) {
        _voicePreProcess = [MSBVoicePreprocess createVoicePreprocess];
        [_voicePreProcess init:44100 channel:1];
    }
    return _voicePreProcess;
}

- (MSBVoiceAnalysisProcess *)voiceAnalysisProcess {
    if (!_voiceAnalysisProcess) {
        _voiceAnalysisProcess = [MSBVoiceAnalysisProcess createVoiceAnalysisProcess];
        [_voiceAnalysisProcess init:44100 channel:1];
    }
    return _voiceAnalysisProcess;
}

- (MSBRecordManager *)recorder {
    if (!_recorder) {
        _recorder = [[MSBRecordManager alloc] init];
    }
    return _recorder;
}

//- (NSMutableData *)m_palyer_outall_data {
//    if (!_m_palyer_outall_data) {
//        _m_palyer_outall_data = [[NSMutableData alloc]init];
//    }
//    return  _m_palyer_outall_data;
//}
#define aec_subPathPCM_far @"/Documents/test_aec_far.pcm"
#define aec_stroePath_far [NSHomeDirectory() stringByAppendingString:aec_subPathPCM_far]
#define aec_subPathPCM_near @"/Documents/test_aec_near.pcm"
#define aec_stroePath_near [NSHomeDirectory() stringByAppendingString:aec_subPathPCM_near]

// MARK: - 背景音预处理，播放器预初始化
- (void)preProcessBgAudioFile:(NSString*)path {
    self.m_player_outall_data_length = 0;
    // MARK: - 背景音预处理 mp3 --> pcm
    self.m_player_pcm_alldata = [NSMutableData dataWithData: [self.voicePreProcess processAudioDecode:path
                                                                                              dstRate:(int32_t)44100
                                                                                          dstChannels:(int32_t)1
                                                                                            dstFormat:(int32_t)1]];
    
    //打开播放器通过pcm文件;
    //self.m_palyer_aec = [[XBPCMPlayer alloc] initWithPCMFilePath:path rate:XBAudioRate_44k channels:(XBAudioChannel)1 bit:(XBAudioBit)16];
    
    //打开播放器通过pcm数据;
    //用完之后设置为空的方法;
    //[self.m_player_pcm_alldata resetBytesInRange:NSMakeRange(0, [self.m_player_pcm_alldata length])];
    //[self.m_player_pcm_alldata setLength:0];
    //self.m_player_pcm_alldata = [NSData dataWithContentsOfFile:path];
    
    //塞到播放器中;
    self.m_palyer_aec = [[XBPCMPlayer alloc] initWithPCMFileData:self.m_player_pcm_alldata
                                                            rate:XBAudioRate_44k
                                                        channels:(XBAudioChannel)1
                                                             bit:(XBAudioBit)16];
    self.m_palyer_aec.delegate = self;
    [self.m_palyer_aec play_init];
    _isPreproocessedAudio = true;
}
- (void)preClearCache {
    self.isMatch = false;
    
    [self stopplayerAndRecoder];
    
    //这里必须要重新创建否则里面的ffmpegfifo会一直增加导致回音消除的时候不齐消除失败，很重要;
    //重新创建3c问题;
    if (self.voicePreProcess != NULL)
    {
        self.voicePreProcess = NULL;
        self.voicePreProcess = [MSBVoicePreprocess createVoicePreprocess];
        [self.voicePreProcess init:44100 channel:1];
    }
    
    //重新创建清掉缓存;
    if (self.voiceAnalysisProcess != NULL)
    {
        self.voiceAnalysisProcess = NULL;
        self.voiceAnalysisProcess = [MSBVoiceAnalysisProcess createVoiceAnalysisProcess];
        [self.voiceAnalysisProcess init:44100 channel:1];
    }
}

- (void)startAudioCapture {
    
    [self preClearCache];
    
    if (_isHaveBgmusic) {
        // 背景音预处理，播放器预初始化
        // MARK: 开始播放背景音
        if (_isPreproocessedAudio) {
//            [self preProcessBgAudioFile:self.bgMusicPath];
            [self.m_palyer_aec play];
        } else {
            MSBAudioLog(@"  --- 背景音解码未完成");
            [self preProcessBgAudioFile:self.bgMusicPath];
            [self.m_palyer_aec play];
        }
        
    }
    self.m_ispause = 0;
    //录制;
    self.m_recorder_aec = [[XBAudioUnitRecorder alloc] initWithRate:XBAudioRate_44k
                                                                bit:XBAudioBit_16
                                                            channel:XBAudioChannel_1
                                                       Preferretime:0];
    // MARK: - 开始录制
    [self.m_recorder_aec start];
    
    // 通知业务 开始录制了
    if (MSBUnityAudioCaptureInterface.shared.delegate &&
        [MSBUnityAudioCaptureInterface.shared.delegate respondsToSelector:@selector(processeStarted)]) {
        [MSBUnityAudioCaptureInterface.shared.delegate processeStarted];
    }

    //清空数据;
    self.m_palyer_aec_outall_data = [NSMutableData alloc];
    self.m_recoder_aec_outall_data = [NSMutableData alloc];
    self.m_testfilePath_fp_player = NULL;
    self.m_testfilePath_fp_recoder = NULL;
    self.m_testfilePath_fp_aecout = NULL;
    self.m_aec_first_player_samples = 0;
    self.m_aec_first_record_samples = 0;
    self.m_aec_InSndCardBuf = 0;
    self.m_out_aec_data = [NSMutableData alloc];
    //用完之后设置为空的方法;
    [self.m_palyer_aec_outall_data resetBytesInRange:NSMakeRange(0, [self.m_palyer_aec_outall_data length])];
    [self.m_palyer_aec_outall_data setLength:0];
    //用完之后设置为空的方法;
    [self.m_recoder_aec_outall_data resetBytesInRange:NSMakeRange(0, [self.m_recoder_aec_outall_data length])];
    [self.m_recoder_aec_outall_data setLength:0];
    self.m_lock_aec_player = [[NSLock alloc] init];
    [self.m_aec_AnalysisThread cancel];
    self.m_aec_AnalysisThread = NULL;
    self.m_Analysis_thread_isruning = -1;
    
    //录音过滤稳定用的百分比vector;
    m_percentage_vector.clear();
     
}

//- (void)startAudioCaptureWithBgMusic {
//    [self preClearCache];
//
//    //dstFormat:1:s16;3是float;
//    if (self.m_player_pcm_alldata != nil && [self.m_player_pcm_alldata length] > 0) {
////        [self.m_player_pcm_alldata resetBytesInRange:NSMakeRange(0, [self.m_player_pcm_alldata length])];
////        [self.m_player_pcm_alldata setLength:0];
//    }
//    // 背景音预处理，播放器预初始化
//    [self preProcessBgAudioFile: self.bgMusicPath];
//    //
////    if (_isProcessedAudio) {
////        // MARK: 开始播放背景音
//        [self.m_palyer_aec play];
//        self.m_ispause = 0;
////    }
//
//
//    //播放背景音文件测试;
//    AudioStreamBasicDescription desc_far = [XBAudioTool allocAudioStreamBasicDescriptionWithMFormatID:XBAudioFormatID_PCM
//                                                                                         mFormatFlags:(XBAudioFormatFlags)(kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked)
//                                                                                          mSampleRate:XBAudioRate_44k
//                                                                                     mFramesPerPacket:1
//                                                                                    mChannelsPerFrame:XBAudioChannel_1
//                                                                                      mBitsPerChannel:XBAudioBit_16];
//    self.m_xbFile_aec_player = [[XBExtAudioFileRef alloc] initWithStorePath:aec_stroePath_far inputFormat:&desc_far];
//
//    //这里应该是填写空数据的;
//    //[self.m_palyer_aec play_init2];
//
//    //录制(这里注意设置preferretime:1之后缓冲区时长会变长,钢琴项目用，其他的输入0);
//    self.m_recorder_aec = [[XBAudioUnitRecorder alloc] initWithRate:XBAudioRate_44k
//                                                                bit:XBAudioBit_16
//                                                            channel:XBAudioChannel_1
//                                                       Preferretime:0];
//
//    // MARK: - 开始录制
//    [self.m_recorder_aec start];
//
//    // 通知业务 开始录制了
//    if (MSBUnityAudioCaptureInterface.shared.delegate &&
//        [MSBUnityAudioCaptureInterface.shared.delegate respondsToSelector:@selector(processeStarted)]) {
//        [MSBUnityAudioCaptureInterface.shared.delegate processeStarted];
//    }
//
//
//    //清空数据;
//    self.m_palyer_aec_outall_data = [NSMutableData alloc];
//    self.m_recoder_aec_outall_data = [NSMutableData alloc];
//    self.m_player_outall_data_length = 0;
//
//    self.m_testfilePath_fp_player = NULL;
//    self.m_testfilePath_fp_recoder = NULL;
//    self.m_testfilePath_fp_aecout = NULL;
//    self.m_aec_first_player_samples = 0;
//    self.m_aec_first_record_samples = 0;
//    self.m_aec_InSndCardBuf = 0;
//    self.m_out_aec_data = [NSMutableData alloc];
//    //用完之后设置为空的方法;
//    [self.m_palyer_aec_outall_data resetBytesInRange:NSMakeRange(0, [self.m_palyer_aec_outall_data length])];
//    [self.m_palyer_aec_outall_data setLength:0];
//
//    //用完之后设置为空的方法;
//    [self.m_recoder_aec_outall_data resetBytesInRange:NSMakeRange(0, [self.m_recoder_aec_outall_data length])];
//    [self.m_recoder_aec_outall_data setLength:0];
//    self.m_lock_aec_player = [[NSLock alloc] init];
//    [self.m_aec_AnalysisThread cancel];
//    self.m_aec_AnalysisThread = NULL;
//    self.m_Analysis_thread_isruning = -1;
//
////
//    //录音过滤稳定用的百分比vector;
//    m_percentage_vector.clear();
//}

- (void)startPlayAndRecordProcessWithPath:(NSString*)path {
    self.bgMusicPath = path;

    [self startAudioCapture];
    
    //取出来的播放背景音数据; 背景音音频流
    typeof(self) __weak aec_weakSelf_far = self;
    self.m_palyer_aec.player.bl_inputFull = ^(XBAudioUnitPlayer *player,
                                              AudioUnitRenderActionFlags *ioActionFlags,
                                              const AudioTimeStamp *inTimeStamp,
                                              UInt32 inBusNumber,
                                              UInt32 inNumberFrames,
                                              AudioBufferList *ioDat)
    {
        //加这个之后临时变量内存会自动被释放;
        @autoreleasepool {
            [aec_weakSelf_far playerInputDataParocess:player
                            ioActionFlags:ioActionFlags
                              inTimeStamp:inTimeStamp
                              inBusNumber:inBusNumber
                           inNumberFrames:inNumberFrames
                                   ioData:ioDat];
        }
    };
    //MARK: 音频采集回调 录音
    typeof(self) __weak aec_weakSelf_near = self;
    self.m_recorder_aec.bl_outputFull = ^(XBAudioUnitRecorder *player, AudioUnitRenderActionFlags *ioActionFlags,
                                          const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber,
                                          UInt32 inNumberFrames, AudioBufferList *ioData)
    {
        //加这个之后临时变量内存会自动被释放;
        @autoreleasepool {
            [aec_weakSelf_near audioMergeProcess:player ioActionFlags:ioActionFlags inTimeStamp:inTimeStamp
                        inBusNumber:inBusNumber inNumberFrames:inNumberFrames ioData:ioData];
        }
    };
    
    //MARK: 开始音高检测
    //加这个之后临时变量内存会自动被释放;
    @autoreleasepool {
        //音高检测(要在另一个线程里面处理 否则会影响这个线程的速度导致卡顿问题);
        self.m_aec_AnalysisThread = [[NSThread alloc]initWithTarget:self selector:@selector(Analysis_thread) object:nil];
        //开启线程
        [self.m_aec_AnalysisThread start];
        self.m_Analysis_thread_isruning = 0;
    }
    
    MSBAudioLog(@"aec paly and record ");
}
//MARK: 音频采集回调
- (void)audioMergeProcess:(XBAudioUnitRecorder *)player
            ioActionFlags:(AudioUnitRenderActionFlags *)ioActionFlags
              inTimeStamp:(const AudioTimeStamp *)inTimeStamp
              inBusNumber:(UInt32) inBusNumber
           inNumberFrames:(UInt32)inNumberFrames
                   ioData:(AudioBufferList *)ioData
{

    if (!_isProcessingData){return;}
    
    if (self.isHaveBgmusic) {
        NSTimeInterval recordTime2 = [[NSDate date]timeIntervalSince1970]*1000;
//        MSBAudioLog(@"@@@@2 == %lli",(long long int)recordTime2);
        //不是暂停;
        if(self.m_ispause == 0)
        {
            //这里是不管你取不取出来回调数据都会输出;
            //得到新数据; 麦克风采集的音频流
            NSData * data_newout_recoder = [NSData dataWithBytes:(char *)ioData->mBuffers[0].mData
                                                          length:ioData->mBuffers[0].mDataByteSize];
//            MSBAudioLog(@"data_newout_recoder = %d",data_newout_recoder.length);

            //写到文件中做测试;
            //[aec_weakSelf_near.m_xbFile_aec_recoder writeIoData:ioData inNumberFrames:inNumberFrames];
            
            // MARK: - 录音流追加处理
            //真正的aec处理;
            [self.m_lock_aec_player lock];
            //nsdata拼接到队列里；
            [self.m_recoder_aec_outall_data appendData:data_newout_recoder];
//            MSBAudioLog(@"m_recoder_aec_outall_data = %d",self.m_recoder_aec_outall_data.length);
            [self.m_lock_aec_player unlock];
            
            //降噪;
            NSData *outputdata_ans = [self.voicePreProcess preProcessAns:self.m_recoder_aec_outall_data
                                                             inSampleCnt:(int32_t)self.m_recoder_aec_outall_data.length / 2];
//            if (outputdata_ans.length > 0)
//            {
//                //写到record(已经做降噪)文件里做测试;
//                int writesize_recoder = fwrite(outputdata_ans.bytes,sizeof(char),outputdata_ans.length,self.m_testfilePath_fp_recoder);
//                MSBAudioLog(@"writesize_recoder = %d",writesize_recoder);
//            }
            
            //写到record(未降噪)文件里做测试;
            //int writesize_recoder = fwrite(self.m_recoder_aec_outall_data.bytes,sizeof(char),self.m_recoder_aec_outall_data.length,self.m_testfilePath_fp_recoder);
            //MSBAudioLog(@"writesize_recoder = %d",writesize_recoder);
            
            //写到play文件里做测试;
//            int writesize_player = fwrite(self.m_palyer_aec_outall_data.bytes,sizeof(char),self.m_palyer_aec_outall_data.length,self.m_testfilePath_fp_player);
//            MSBAudioLog(@"writesize_player = %d",writesize_player);
            
            //进入的是s16所以/2;
            //注意注意：这里的recoder和play的pcm格式一定要是44100，1声道，s16固定格式。其他格式会出现崩溃问题;
            //必须先启动play然后再启动record;用第一次的paly的samples数据量减去recoder的samples数据量除以采样率得到对其的毫秒数;
            //比如第一次play的samples数是1882,第一次的record的samples数量是940,采样率是44100;
            //得到的对其毫秒数就是(1882-940)*1000.0/44100 = 20毫秒;
            // MARK: - 波形对齐
            if((self.m_aec_first_player_samples == 0 ||
               self.m_aec_first_record_samples == 0) && self.m_aec_InSndCardBuf == 0)
            {
                self.m_aec_first_player_samples = (int32_t)self.m_palyer_aec_outall_data.length/2;
                self.m_aec_first_record_samples =(int32_t)self.m_recoder_aec_outall_data.length/2;
                self.m_aec_InSndCardBuf = (self.m_aec_first_player_samples - self.m_aec_first_record_samples)*1000.0/44100;
                //经过多次测试ios的AudioUnit播放启动延迟时间大概在20毫秒左右,根据不同机型做调整;
                if(self.m_aec_InSndCardBuf < 20)
                {
                    self.m_aec_InSndCardBuf = 20;
                }
            }
            NSString *testdocumentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
            //MARK: - 回音消除; 提供两路音频😁
            NSString *testdocumentPath_test = @"1111";
            NSData *aec_outputdata = [self.voicePreProcess preProcessAec:self.m_palyer_aec_outall_data //MARK: 背景音 音频流
                                                          inFarSampleCnt:((int32_t)self.m_palyer_aec_outall_data.length/2)
                                                              inNearData:outputdata_ans // 降噪后的 音频流
                                                         inNearSampleCnt:((int32_t)outputdata_ans.length/2)
                                                                filePath:testdocumentPath
                                                            InSndCardBuf:self.m_aec_InSndCardBuf];  //这个地址filePath不能填空值，可以填无效的值比如NSString *testdocumentPath_test = "1111";
            [self.recorder recordOutputAudioData:aec_outputdata];
            //结果写到文件里做测试;
//            int writesize_aecout = fwrite(aec_outputdata.bytes,sizeof(char),aec_outputdata.length,self.m_testfilePath_fp_aecout);
//            MSBAudioLog(@"writesize_aecout = %d",writesize_aecout);
            
            //用完之后设置为空的方法;
            [self.m_palyer_aec_outall_data resetBytesInRange:NSMakeRange(0, [self.m_palyer_aec_outall_data length])];
            [self.m_palyer_aec_outall_data setLength:0];
            //用完之后设置为空的方法;
            [self.m_recoder_aec_outall_data resetBytesInRange:NSMakeRange(0, [self.m_recoder_aec_outall_data length])];
            [self.m_recoder_aec_outall_data setLength:0];
            
            
            //增益(耗时很严重影响其他功能,可能导致丢数据问题，暂时不用);
            //NSData *agc_outputdata = [self.voicePreProcess
            //                           preProcessAgc:aec_outputdata inSampleCnt:aec_outputdata.length/2];
            
            //将数据拷贝出去用于检测;
            [self.m_out_aec_data setData:aec_outputdata];
            
            self.m_Analysis_thread_isruning = 1;
        } else {
             //用完之后设置为空的方法; 暂停时，清除缓存
            [self.m_recoder_aec_outall_data resetBytesInRange:NSMakeRange(0, [self.m_recoder_aec_outall_data length])];
            [self.m_recoder_aec_outall_data setLength:0];
        }
    } else {
        if (self.m_ispause == 0) {
            //这里是不管你取不取出来回调数据都会输出;
            //得到新数据;
            NSData * data_newout_recoder = [NSData dataWithBytes:(char *)ioData->mBuffers[0].mData
                                                          length:ioData->mBuffers[0].mDataByteSize];
//            MSBAudioLog(@"data_newout_recoder = %lu",(unsigned long)data_newout_recoder.length);
            
            //降噪;
            NSData *outputdata_ans = [self.voicePreProcess preProcessAns:data_newout_recoder
                                                             inSampleCnt:(int32_t)data_newout_recoder.length / 2];
    //        if (outputdata_ans.length > 0)
    //        {
    //            //写到record(已经做降噪)文件里做测试;
    //            int writesize_recoder = fwrite(outputdata_ans.bytes,sizeof(char),outputdata_ans.length,self.m_testfilePath_fp_recoder);
    //            MSBAudioLog(@"writesize_recoder = %d",writesize_recoder);
    //        }
            
            //必须加这个才能控制主线程的控件否则报错;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.recorder recordOutputAudioData:data_newout_recoder];
                [self porcessAudioData:outputdata_ans];
            });
        }
        
    }
    
}
//MARK: 音高检测(要在另一个线程里面处理 否则会影响这个线程的速度导致卡顿问题);
-(void)Analysis_thread
{
    //加这个之后临时变量内存会自动被释放;
    @autoreleasepool {
        //音高检测(要在另一个线程里面处理 否则会影响这个线程的速度导致卡顿问题);
        for(;;)
        {
            //监测当前线程是否被取消过，如果被取消了，则该线程退出。
            if ([[NSThread currentThread] isCancelled])
            {
                [NSThread exit];
            }
            if(self.m_Analysis_thread_isruning == -1)
            {
                break;
            }
            //这里必须加个锁;
            if(self.m_out_aec_data.length  == 0 ||
               self.m_Analysis_thread_isruning == 0)
            {
                [NSThread sleepForTimeInterval:0.001];
                continue;
            }
            
            //必须加这个才能控制主线程的控件否则报错;
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                //********:self.m_out_aec_data这个数据应该加锁，但为了播放不卡顿去掉锁在demo中;
                //[self.m_lock_aec_player lock];
                //[self.m_lock_aec_player unlock];
                
                [self porcessAudioData:self.m_out_aec_data];
               
                //用完之后设置为空的方法;
                [self.m_out_aec_data resetBytesInRange:NSMakeRange(0, [self.m_out_aec_data length])];
                [self.m_out_aec_data setLength:0];
            });
            
            self.m_Analysis_thread_isruning = 0;
        }
        
    }
    
    MSBAudioLog(@"Analysis_thread end");
}
- (void)stopPlayAndRecordProcessWithPath {
    self.m_ispause = 1;
    _isPreproocessedAudio = false;
    _isHaveBgmusic = false;
    _isProcessingData = false;
    [self stopplayerAndRecoder];
    
        
    //录音过滤稳定用的百分比vector;
    m_percentage_vector.clear();
    
    // 结束录音
//    [self stopRecord];
}
// MARK: -
- (void)onlyStartRecordAndProcessAudioData
{
    // .mm 文件不能和 swift头文件混编
//    [OSAudioSessionManager.shared resetOriginAudioSession];
//    [OSAudioSessionManager.shared setRecordSession];
    [self startAudioCapture];
    
    //这里取出来播放背景音+环境音数据;
    typeof(self) __weak aec_weakSelf_near = self;
    if (self.m_recorder_aec == NULL) {
        return;
    }
    self.m_recorder_aec.bl_outputFull = ^(XBAudioUnitRecorder *player, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
    {
        
        if (self.m_recorder_aec == NULL) {
            return;
        }
        //加这个之后临时变量内存会自动被释放;
        @autoreleasepool {
            [aec_weakSelf_near audioMergeProcess:player ioActionFlags:ioActionFlags
                        inTimeStamp:inTimeStamp inBusNumber:inBusNumber
                     inNumberFrames:inNumberFrames ioData:ioData];
        }
    };
    
    MSBAudioLog(@"only record ");
    
}

- (void)onlyStopRecordAndProcessAudioData
{
    [self stopplayerAndRecoder];

    
    //录音过滤稳定用的百分比vector;
    m_percentage_vector.clear();
    self.m_ispause = 1;
    _isPreproocessedAudio = false;
    _isHaveBgmusic = false;
    _isProcessingData = false;
    // 结束录音
//    [self stopRecord];
}
- (void)stopplayerAndRecoder {
    //关闭aec播放器;
    if(self.m_palyer_aec != NULL && !_isPreproocessedAudio)// 预处理状态复位时stop
    {
        [self.m_palyer_aec stop];
        self.m_palyer_aec = nil;
    }
    //关闭recoder;
    if(self.m_recorder_aec != NULL && self.m_recorder_aec.isRecording)
    {
        [self.m_recorder_aec stop];
        self.m_recorder_aec = nil;
    }
}
//停止aec按钮;
-(void)stopdoSth_aec
{
    //关闭aec播放器;
    if(self.m_palyer_aec != NULL)
    {
        [self.m_palyer_aec stop];
        self.m_palyer_aec = nil;
    }
    
    //关闭recoder;
    if(self.m_recorder_aec != NULL)
    {
        [self.m_recorder_aec stop];
        self.m_recorder_aec = nil;
    }
    
    //停止滚动条的定时器时长;
//    if(self.m_rulerprogress_shichang > 0)
//    {
//        dispatch_source_cancel(self.m_rulertimer_shichang);
//        self.m_rulerprogress_shichang = 0;
//        [self.m_rulerView_shichang.collectionView setContentOffset:CGPointZero animated:YES];
//    }
//    self.m_rulerprogress_shichang = 0;
        
    //录音过滤稳定用的百分比vector;
    m_percentage_vector.clear();
    self.m_ispause = 1;
}


// MARK: -
- (void)porcessAudioData:(nonnull NSData *)outputdata_ans {
    
    //vod外部检测;
    int ret = [self.voicePreProcess preProcessVod:outputdata_ans inSampleCnt:(int32_t)outputdata_ans.length / 2];
//    MSBAudioLog(@"***********  = %d",ret);
    
    //如果有声音;
    if(ret == 1)
    {
        //获取音高和最大音符;//通过音高算出音阶和调性;
        self.m_analysisInfoPitchAndNoteInfo = [self.voiceAnalysisProcess getPitchAndNote:outputdata_ans
                                                                             inSampleCnt:outputdata_ans.length / 2];
        [self processVideoInfo];
        
        if (MSBUnityAudioCaptureInterface.shared.delegate &&
            [MSBUnityAudioCaptureInterface.shared.delegate respondsToSelector:@selector(processedAudioIsHaveVoice:)]) {
            [MSBUnityAudioCaptureInterface.shared.delegate processedAudioIsHaveVoice:true];
        }
        
    } else {
        if (MSBUnityAudioCaptureInterface.shared.delegate &&
            [MSBUnityAudioCaptureInterface.shared.delegate respondsToSelector:@selector(processedAudioIsHaveVoice:)]) {
            [MSBUnityAudioCaptureInterface.shared.delegate processedAudioIsHaveVoice:false];
        }
    }
}
// 音频识别完成后，后续的处理
- (void)processVideoInfo {
        
    float temp_outPitch = 0.0;
    float temp_outNote = 0.0;
    temp_outPitch = self.m_analysisInfoPitchAndNoteInfo.mOutpitch;
    temp_outNote = self.m_analysisInfoPitchAndNoteInfo.mOutnote;

//    MSBAudioLog(@"m_analysisInfoPitchAndNoteInfo = %f : %f : %@ : %@\n",
//          temp_outPitch,
//          temp_outNote,
//          self.m_analysisInfoPitchAndNoteInfo.mOutoctaveString,
//          self.m_analysisInfoPitchAndNoteInfo.mOutnoteString);
    //改变控件颜色测试十二平均律; 返回模糊音名
    int res =  [self change_view_colou_Twelve_equal_law:temp_outPitch
                       widthoctaveString:self.m_analysisInfoPitchAndNoteInfo.mOutoctaveString
                           withoteString:self.m_analysisInfoPitchAndNoteInfo.mOutnoteString];
    if (res == 1) {// 高于35%
        //MARK:  返回音频解析的数据
        if (MSBUnityAudioCaptureInterface.shared.delegate &&
            [MSBUnityAudioCaptureInterface.shared.delegate respondsToSelector:@selector(processedAudioData:)]) {
            [MSBUnityAudioCaptureInterface.shared.delegate  processedAudioData: self.m_analysisInfoPitchAndNoteInfo];
        }
    }
    
    if(temp_outPitch > 0)
    {
        //1是时长滚动条;
//        int m_view_islog_or_change_colour = 1;// 获取匹配起始点
//        if (m_view_islog_or_change_colour == 1) {
        if (self.isMatch){
            //检测到的音符是什么;
            NSString * temp_stringpyin = [NSString stringWithFormat:@"%@%@", self.m_analysisInfoPitchAndNoteInfo.mOutoctaveString,
                self.m_analysisInfoPitchAndNoteInfo.mOutnoteString];
            // MARK: - 获取比对的音名
//            NSString *note = [self getHighlightNoteValue];
            [self matchNote: self.matchLevel note: self.matchNote
                  minOctave:self.minOctave maxOctave:self.maxOctave];// 音名比对
            
        
        
            
        }
        
    }
}
//MARK: - 音名比对
- (void)matchNote:(int)matchNumber note:(NSString*)note
        minOctave:(int)minOctave maxOctave:(int) maxOctave {
    //检测到的音符是什么;
    NSString * temp_stringpyin = [NSString stringWithFormat:@"%@%@",
                                  self.m_analysisInfoPitchAndNoteInfo.mOutoctaveString,
                                  self.m_analysisInfoPitchAndNoteInfo.mOutnoteString];
    
    //时长的滚动条;
    //滚动条获取当前高亮的字符是什么;
    NSString * temp_getname_shichang = note;
    //@"C",@"C♯/D♭",@"D",@"D♯/E♭",@"E",@"F",@"F♯/G♭",@"G",@"G♯/A♭",@"A",@"A♯/B♭",@"B"；
    
    //匹配准确度;
    int text_match_number_int = matchNumber;
    if(text_match_number_int != 0 &&
       text_match_number_int != 1 &&
       text_match_number_int != 2 &&
       text_match_number_int != 3 &&
       text_match_number_int != 4 &&
       text_match_number_int != 5)
    {
        text_match_number_int = 0;
    }
    //MARK: 拿到音名比对结果
    int success_orfaild_shichang;
    if (_matchType == 0) {// 默认区分八度
        
        //设置pyin检测到的光标位置;业务处理逻辑, 过滤非人声 一般八度高于7都不是人声
        if([self.m_analysisInfoPitchAndNoteInfo.mOutoctaveString intValue] >= minOctave &&
           [self.m_analysisInfoPitchAndNoteInfo.mOutoctaveString intValue] <= maxOctave)
        {
            success_orfaild_shichang = [self change_Accuracy:text_match_number_int
                                   string_getHighlightNoteValue_string:temp_getname_shichang
                                                    string_pyin_string:temp_stringpyin];
            MSBAudioLog(@" 音名比对结果： %d",success_orfaild_shichang);
    //        设置给unity你经过过滤后检测到的音符;
    //        [self setIndicatorPostionWithNoteValue:temp_stringpyin];
            //MARK: 比对结果回调+只返回人声数据
            if (MSBUnityAudioCaptureInterface.shared.delegate &&
                [MSBUnityAudioCaptureInterface.shared.delegate respondsToSelector:@selector(processedAudioMatchResult:analysisInfo:)]) {
                [MSBUnityAudioCaptureInterface.shared.delegate processedAudioMatchResult:success_orfaild_shichang
                                                                            analysisInfo:self.m_analysisInfoPitchAndNoteInfo];
            }
        }
    } else {
        
        //设置pyin检测到的光标位置;业务处理逻辑, 过滤非人声 一般八度高于7都不是人声
        if([self.m_analysisInfoPitchAndNoteInfo.mOutoctaveString intValue] >= 3 &&
           [self.m_analysisInfoPitchAndNoteInfo.mOutoctaveString intValue] <= 5)
        {
            success_orfaild_shichang = [self change_Accuracy_baima:text_match_number_int
                             string_getHighlightNoteValue_string:temp_getname_shichang
                                              string_pyin_string:temp_stringpyin];
            
            MSBAudioLog(@" 音名比对结果： %d",success_orfaild_shichang);
    //        设置给unity你经过过滤后检测到的音符;
    //        [self setIndicatorPostionWithNoteValue:temp_stringpyin];
            //MARK: 比对结果回调+只返回人声数据
            if (MSBUnityAudioCaptureInterface.shared.delegate &&
                [MSBUnityAudioCaptureInterface.shared.delegate respondsToSelector:@selector(processedAudioMatchResult:analysisInfo:)]) {
                [MSBUnityAudioCaptureInterface.shared.delegate processedAudioMatchResult:success_orfaild_shichang
                                                                            analysisInfo:self.m_analysisInfoPitchAndNoteInfo];
            }
        }
    }
    
    
    
    
}
///  获取当前高亮的音符 //获取unity给你返回的音符；
- (NSString *)getHighlightNoteValue{
//    if (self.noteQueue.count == 0) {
//        return nil;
//    }
//    Note *note = (Note *)self.noteQueue.lastObject;
//    return [self getCompleteNoteStringWithValue:note.keyvalue];
    return @"4C";
}
//设置给unity你经过过滤后检测到的音符;
// value 值为 @"4C",@"4C♯/D♭",@"4D",@"4D♯/E♭",@"4E",@"4F",@"4F♯/G♭",@"4G",@"4G♯/A♭",@"4A",@"4A♯/B♭",@"4B"...
- (void)setIndicatorPostionWithNoteValue:(NSString *)value { // 此函数不区分八度
    MSBAudioLog(@"用注释值设置指示器位置 %@",value);
//    if (self.lockIndicator) { // 吸附游标，其他值无效
//        Note *note = self.noteQueue.lastObject;
//        value = note.keyvalue;
//    }
//    // 字符串处理
//    if (value == nil || value.length == 0) {
//        return;
//    }
//    NSString *removeNumber = [value substringFromIndex:1];
//    NSRange range = [removeNumber rangeOfString:@"/"];
//    NSString *notDistinguish = removeNumber;
//    if (range.location != NSNotFound ) {
//        notDistinguish = [removeNumber substringToIndex:range.location];
//    }
//    UILabel *label = nil;
//    NSString *note = [self getSignNoteStringWithValue:notDistinguish];
//    if (note != nil) {
//        label = [self viewWithTag:[[self.tagDict objectForKey:note] intValue]];
//    }
//    if (self.lockIndicator && self.indicatorLayer.position.y == -(150-label.frame.origin.y)-5) {
//        return;
//    }
//    if (label != nil) {
//        [self.indicatorLayer removeAnimationForKey:animationKey];
//        self.isAnimation = NO;
//
//        CGPoint point = CGPointZero;
//        point.x = self.indicatorLayer.position.x;
//        point.y = -(150-label.frame.origin.y)-5;
//        self.indicatorLayer.position = point;
//    }
//    else{
//        [self downIndicator];
//    }
    
}
/// 设置当前高亮的音符的结果
- (void)audioMatchResult:(NSInteger)result{
    
    MSBAudioLog(@"progress = setResult +++++++++ = %ld",result);
    
//    if (self.noteQueue.count == 0 || self.cellQueue.count == 0) {
//
//        if (result == lose) {
//            self.lockIndicator = NO;
//            [self downIndicator];
//        }
//
//        return;
//    }
//
//    Note *note = (Note *)self.noteQueue.lastObject;
//    //    Scale *scale = [self.progressDict objectForKey:note.chordid];
//    //    if (scale  != nil && scale.state == 2) { // 已经成功了
//    //        return;
//    //    }else if(scale != nil && scale.state !=2){
//    //        scale.state = result;
//    //        [self.progressDict setValue:scale forKey:note.chordid];
//    //    }else{
//    //        Scale *scale = [[Scale alloc] init];
//    //        scale.state = result;
//    //        [self.progressDict setValue:scale forKey:note.chordid];
//    //    }
//
//    /// 实时调整正确长度
//    int time_start_in_s1000 = (int)([note.time_start_in_s doubleValue]*1000);
//    CGFloat curOffset = (_progress*1000 - time_start_in_s1000)/1000;  // offset 单位为百毫秒
//
//    // 保存状态
//    NSMutableArray *partArray = [self.progressDict objectForKey:note.chordid];
//    MSBPartData *lastPart = (MSBPartData *)partArray.lastObject;
//
//    // 频繁出现正确和下降的时候，下降小于100毫秒不处理
//    if (self.lastSuccessTimestamp > 0 && (NSInteger)([[NSDate date] timeIntervalSince1970] * 1000) < self.lastSuccessTimestamp + 100) {
//        return; // 100ms 不处理
//    }
//
//    /// 设置状态
//    MSBTimeRulerCollectionViewCellNewTwo *cell = (MSBTimeRulerCollectionViewCellNewTwo *)self.cellQueue.lastObject;
//    double time_start_in_s = [note.time_start_in_s doubleValue];
//    double x = time_start_in_s - floor(time_start_in_s);
//
//    if (result == lose) { // 吸附失效
//
//        double time_start_in_s = [note.time_start_in_s doubleValue];
//        double x = time_start_in_s - floor(time_start_in_s);
//
//        cell.curState = result;
//        [cell setMusicState:result withIndex:floor(x*10) offset:(curOffset * ([MSBShareInstance sharedInstance].space/0.1))];
//
//        self.lockIndicator = NO;
//        [self setIndicatorState:result WithValue:note.keyvalue];
//
//        lastPart.endState = result;
//
//        return;
//    }
//    if (lastPart.endState == result || result != success) { // 不重复设置
//
//        self.lockIndicator = NO;
//        [self setIndicatorState:result WithValue:note.keyvalue];
//        lastPart.endState = result;
//
//        return;
//    }
//
//    // 开始
//    if(partArray != nil){
//        // 开始下一个状态
//        MSBPartData *part = [[MSBPartData alloc] init];
//        part.state = result;
//        part.offset = curOffset * ([MSBShareInstance sharedInstance].space/0.1);
//        part.endState = result;
//        [partArray addObject:part];
//        [self.progressDict setValue:partArray forKey:note.chordid];
//    }else if(partArray == nil){
//        // 开始一个新的状态
//        NSMutableArray *array = [[NSMutableArray alloc] init];
//        MSBPartData *part = [[MSBPartData alloc] init];
//        part.state = result;
//        part.offset = curOffset * ([MSBShareInstance sharedInstance].space/0.1);
//        part.endState = result;
//        [array addObject:part];
//        [self.progressDict setValue:array forKey:note.chordid];
//    }
//
//    //  [cell setMusicState:result withIndex:floor(x*10)];
//
//    cell.curState = result;
//    [cell setMusicState:result withIndex:floor(x*10) offset:(curOffset * ([MSBShareInstance sharedInstance].space/0.1))];
//
//    // 设置游标颜色
//    [self setLabelState:result WithValue:note.keyvalue];
//    // 设置游标的位置
//    //  [self setIndicatorState:result WithValue:note.keyvalue];
//    // 吸附游标
//    self.lockIndicator = YES;
//    [self setIndicatorPostionWithNoteValue:note.keyvalue];
//
//    self.lastSuccessTimestamp = (NSInteger)([[NSDate date] timeIntervalSince1970] * 1000);
}

// MARK: -
//改变控件颜色逻辑十二平均律;
- (int)change_view_colou_Twelve_equal_law:(float)inpitch
                    widthoctaveString:(NSString *)inoctaveString
                     withoteString:(NSString *)noteString
{
    /*
    NSDate *datenow_runTflite2 = [NSDate date];//现在时间,你可以输出来看下是什么格式
    NSString *timeSp_runTflite2 = [NSString stringWithFormat:@"%ld", (long)([datenow_runTflite2 timeIntervalSince1970]*1000)];
    long long temp_rundsub = [timeSp_runTflite2 longLongValue] - [timeSp_runTflite1 longLongValue];
    */
    
    /*
    //中音区十二平均律;
    //@"C",@"C♯/D♭",@"D",@"D♯/E♭",@"E",@"F",@"F♯/G♭",@"G",@"G♯/A♭",@"A",@"A♯/B♭",@"B"；
    //C;
    self.yinTextview_average_C.backgroundColor = [UIColor yellowColor];
    //C♯/D♭;
    self.yinTextview_average_SC.backgroundColor = [UIColor yellowColor];
    //D;
    self.yinTextview_average_D.backgroundColor = [UIColor yellowColor];
    //D♯/E♭;
    self.yinTextview_average_SD.backgroundColor = [UIColor yellowColor];
    //E;
    self.yinTextview_average_E.backgroundColor = [UIColor yellowColor];
    //F;
    self.yinTextview_average_F.backgroundColor = [UIColor yellowColor];
    //F♯/G♭;
    self.yinTextview_average_SF.backgroundColor = [UIColor yellowColor];
    //G;
    self.yinTextview_average_G.backgroundColor = [UIColor yellowColor];
    //G♯/A♭;
    self.yinTextview_average_SG.backgroundColor = [UIColor yellowColor];
    //A;
    self.yinTextview_average_A.backgroundColor = [UIColor yellowColor];
    //A♯/B♭;
    self.yinTextview_average_SA.backgroundColor = [UIColor yellowColor];
    //B;
    self.yinTextview_average_B.backgroundColor = [UIColor yellowColor];
    */
   
    int ret = 0;
    int is_discard = 0;//是不是丢弃当前这个音;
    int is_all_Lessthan = 0; //如果所有的音都小于35%,则显示当前刚进来的那个音;
    
    //最大50个包可调;
    if(m_percentage_vector.size() <= 10)
    {
        m_percentage_vector.push_back(noteString);
    }
    else
    {
        std::vector<NSString *>::iterator temp_itr = m_percentage_vector.begin();
        m_percentage_vector.erase(temp_itr);
        m_percentage_vector.push_back(noteString);
    }
    
    float m_percentage_C = 0;
    float m_percentage_SC = 0;
    float m_percentage_D = 0;
    float m_percentage_SD = 0;
    float m_percentage_E = 0;
    float m_percentage_F = 0;
    float m_percentage_SF = 0;
    float m_percentage_G = 0;
    float m_percentage_SG = 0;
    float m_percentage_A = 0;
    float m_percentage_SA = 0;
    float m_percentage_B = 0;
    int m_percentage_C_size = 0;
    int m_percentage_SC_size = 0;
    int m_percentage_D_size = 0;
    int m_percentage_SD_size = 0;
    int m_percentage_E_size = 0;
    int m_percentage_F_size = 0;
    int m_percentage_SF_size = 0;
    int m_percentage_G_size = 0;
    int m_percentage_SG_size = 0;
    int m_percentage_A_size = 0;
    int m_percentage_SA_size = 0;
    int m_percentage_B_size = 0;
    
    for(int vector_size = 0; vector_size< m_percentage_vector.size(); vector_size++)
    {
        NSString * temp_noteString = m_percentage_vector[vector_size];
        
        //计算百分比;
        if([temp_noteString isEqualToString:@"C"] == TRUE)
        {
            m_percentage_C_size ++;
        }
        else if([temp_noteString isEqualToString:@"C♯/D♭"] == TRUE)
        {
            m_percentage_SC_size ++;
            
        }
        else if([temp_noteString isEqualToString:@"D"] == TRUE)
        {
            m_percentage_D_size ++;
        }
        else if([temp_noteString isEqualToString:@"D♯/E♭"] == TRUE)
        {
            m_percentage_SD_size ++;
        }
        else if([temp_noteString isEqualToString:@"E"] == TRUE)
        {
            m_percentage_E_size ++;
        }
        else if([temp_noteString isEqualToString:@"F"] == TRUE)
        {
            m_percentage_F_size ++;
        }
        else if([temp_noteString isEqualToString:@"F♯/G♭"] == TRUE)
        {
            m_percentage_SF_size ++;
        }
        else if([temp_noteString isEqualToString:@"G"] == TRUE)
        {
            m_percentage_G_size ++;
        }
        else if([temp_noteString isEqualToString:@"G♯/A♭"] == TRUE)
        {
            m_percentage_SG_size ++;
        }
        else if([temp_noteString isEqualToString:@"A"] == TRUE)
        {
            m_percentage_A_size ++;
        }
        else if([temp_noteString isEqualToString:@"A♯/B♭"] == TRUE)
        {
            m_percentage_SA_size ++;
        }
        else if([temp_noteString isEqualToString:@"B"] == TRUE)
        {
            m_percentage_B_size ++;
        }
        else{
            
        }
    }
    
    m_percentage_C = (1.0)*m_percentage_C_size/m_percentage_vector.size();
    m_percentage_SC = (1.0)*m_percentage_SC_size/m_percentage_vector.size();
    m_percentage_D = (1.0)*m_percentage_D_size/m_percentage_vector.size();
    m_percentage_SD = (1.0)*m_percentage_SD_size/m_percentage_vector.size();
    m_percentage_E = (1.0)*m_percentage_E_size/m_percentage_vector.size();
    m_percentage_F = (1.0)*m_percentage_F_size/m_percentage_vector.size();
    m_percentage_SF = (1.0)*m_percentage_SF_size/m_percentage_vector.size();
    m_percentage_G = (1.0)*m_percentage_G_size/m_percentage_vector.size();
    m_percentage_SG = (1.0)*m_percentage_SG_size/m_percentage_vector.size();
    m_percentage_A = (1.0)*m_percentage_A_size/m_percentage_vector.size();
    m_percentage_SA = (1.0)*m_percentage_SA_size/m_percentage_vector.size();
    m_percentage_B = (1.0)*m_percentage_B_size/m_percentage_vector.size();
    
//    printf("$$$$$$ : m_percentage_C %f\n",m_percentage_C);
//    printf("$$$$$$ : m_percentage_SC %f\n",m_percentage_SC);
//    printf("$$$$$$ : m_percentage_D %f\n",m_percentage_D);
//    printf("$$$$$$ : m_percentage_SD %f\n",m_percentage_SD);
//    printf("$$$$$$ : m_percentage_E %f\n",m_percentage_E);
//    printf("$$$$$$ : m_percentage_F %f\n",m_percentage_F);
//    printf("$$$$$$ : m_percentage_SF %f\n",m_percentage_SF);
//    printf("$$$$$$ : m_percentage_G %f\n",m_percentage_G);
//    printf("$$$$$$ : m_percentage_SG %f\n",m_percentage_SG);
//    printf("$$$$$$ : m_percentage_A %f\n",m_percentage_A);
//    printf("$$$$$$ : m_percentage_SA %f\n",m_percentage_SA);
//    printf("$$$$$$ : m_percentage_B %f\n",m_percentage_B);
    
    
    
    //判断百分比;
    {
        if(m_percentage_C < self.filterPercentage)
        {
            is_all_Lessthan ++;
//            self.yinTextview_average_C.backgroundColor = [UIColor yellowColor];
            if([noteString isEqualToString:@"C"] == TRUE)
            {
                is_discard = 1;
            }
        }
        if(m_percentage_SC < self.filterPercentage)
        {
            is_all_Lessthan ++;
//            self.yinTextview_average_SC.backgroundColor = [UIColor yellowColor];
            if([noteString isEqualToString:@"C♯/D♭"] == TRUE)
            {
                is_discard = 1;
            }
        }
        if(m_percentage_D < self.filterPercentage)
        {
            is_all_Lessthan ++;
//            self.yinTextview_average_D.backgroundColor = [UIColor yellowColor];
            if([noteString isEqualToString:@"D"] == TRUE)
            {
                is_discard = 1;
            }
        }
        if(m_percentage_SD < self.filterPercentage)
        {
            is_all_Lessthan ++;
//            self.yinTextview_average_SD.backgroundColor = [UIColor yellowColor];
            if([noteString isEqualToString:@"D♯/E♭"] == TRUE)
            {
                is_discard = 1;
            }
        }
        if(m_percentage_E < self.filterPercentage)
        {
            is_all_Lessthan ++;
//            self.yinTextview_average_E.backgroundColor = [UIColor yellowColor];
            if([noteString isEqualToString:@"E"] == TRUE)
            {
                is_discard = 1;
            }
        }
        if(m_percentage_F < self.filterPercentage)
        {
            is_all_Lessthan ++;
//            self.yinTextview_average_F.backgroundColor = [UIColor yellowColor];
            if([noteString isEqualToString:@"F"] == TRUE)
            {
                is_discard = 1;
            }
        }
        if(m_percentage_SF < self.filterPercentage)
        {
            is_all_Lessthan ++;
//            self.yinTextview_average_SF.backgroundColor = [UIColor yellowColor];
            if([noteString isEqualToString:@"F♯/G♭"] == TRUE)
            {
                is_discard = 1;
            }
        }
        if(m_percentage_G < self.filterPercentage)
        {
            is_all_Lessthan ++;
//            self.yinTextview_average_G.backgroundColor = [UIColor yellowColor];
            if([noteString isEqualToString:@"G"] == TRUE)
            {
                is_discard = 1;
            }
        }
        if(m_percentage_SG < self.filterPercentage)
        {
            is_all_Lessthan ++;
//            self.yinTextview_average_SG.backgroundColor = [UIColor yellowColor];
            if([noteString isEqualToString:@"G♯/A♭"] == TRUE)
            {
                is_discard = 1;
            }
        }
        if(m_percentage_A < self.filterPercentage)
        {
            is_all_Lessthan ++;
//            self.yinTextview_average_A.backgroundColor = [UIColor yellowColor];
            if([noteString isEqualToString:@"A"] == TRUE)
            {
                is_discard = 1;
            }
        }
        if(m_percentage_SA < self.filterPercentage)
        {
            is_all_Lessthan ++;
//            self.yinTextview_average_SA.backgroundColor = [UIColor yellowColor];
            if([noteString isEqualToString:@"A♯/B♭"] == TRUE)
            {
                is_discard = 1;
            }
        }
        if(m_percentage_B < self.filterPercentage)
        {
            is_all_Lessthan ++;
//            self.yinTextview_average_B.backgroundColor = [UIColor yellowColor];
            if([noteString isEqualToString:@"B"] == TRUE)
            {
                is_discard = 1;
            }
        }
    }
    //如果所有的音都小于35%,则显示当前刚进来的那个音;
//    if(is_all_Lessthan != 12)
//    {
//        //如果当前的不满足35%则不显示;
        if(is_discard == 1)
        {
            return 0;
        }
//    }
    
    //改变控件颜色测试十二平均律过滤;
    {
        NSString *noteName = noteString;
        if(([inoctaveString isEqualToString:@"2"] == TRUE) ||
           ([inoctaveString isEqualToString:@"3"] == TRUE) ||
           ([inoctaveString isEqualToString:@"4"] == TRUE) ||
           ([inoctaveString isEqualToString:@"5"] == TRUE) ||
           ([inoctaveString isEqualToString:@"6"] == TRUE)) //字符串对比;
        {
            return 1;
            /*
            //@"C",@"C♯/D♭",@"D",@"D♯/E♭",@"E",@"F",@"F♯/G♭",@"G",@"G♯/A♭",@"A",@"A♯/B♭",@"B"；
            if([noteString isEqualToString:@"C"] == TRUE)
            {
                noteName = noteString;
//                self.yinTextview_average_C.backgroundColor = [UIColor redColor];
            }
            else if([noteString isEqualToString:@"C♯/D♭"] == TRUE)
            {
                noteName = noteString;
//                self.yinTextview_average_SC.backgroundColor = [UIColor redColor];
            }
            else if([noteString isEqualToString:@"D"] == TRUE)
            {
                noteName = noteString;
//                self.yinTextview_average_D.backgroundColor = [UIColor redColor];
            }
            else if([noteString isEqualToString:@"D♯/E♭"] == TRUE)
            {
                noteName = noteString;
//                self.yinTextview_average_SD.backgroundColor = [UIColor redColor];
            }
            else if([noteString isEqualToString:@"E"] == TRUE)
            {
                noteName = noteString;
//                self.yinTextview_average_E.backgroundColor = [UIColor redColor];
            }
            else if([noteString isEqualToString:@"F"] == TRUE)
            {
                noteName = noteString;
//                self.yinTextview_average_F.backgroundColor = [UIColor redColor];
            }
            else if([noteString isEqualToString:@"F♯/G♭"] == TRUE)
            {
                noteName = noteString;
//                self.yinTextview_average_SF.backgroundColor = [UIColor redColor];
            }
            else if([noteString isEqualToString:@"G"] == TRUE)
            {
                noteName = noteString;
//                self.yinTextview_average_G.backgroundColor = [UIColor redColor];
            }
            else if([noteString isEqualToString:@"G♯/A♭"] == TRUE)
            {
                noteName = noteString;
//                self.yinTextview_average_SG.backgroundColor = [UIColor redColor];
            }
            else if([noteString isEqualToString:@"A"] == TRUE)
            {
                noteName = noteString;
//                self.yinTextview_average_A.backgroundColor = [UIColor redColor];
            }
            else if([noteString isEqualToString:@"A♯/B♭"] == TRUE)
            {
                noteName = noteString;
//                self.yinTextview_average_SA.backgroundColor = [UIColor redColor];
            }
            else if([noteString isEqualToString:@"B"] == TRUE)
            {
                noteName = noteString;
//                self.yinTextview_average_B.backgroundColor = [UIColor redColor];
            }
            else{
                
            }
             */
        }
        else
        {
            return 0;
        }
    }
    
}

//匹配准确度(区分八度);
- (int)change_Accuracy:(int)change_number
string_getHighlightNoteValue_string:(NSString *)stringgetHighlightNoteValue
    string_pyin_string:(NSString *)stringpyin
{
    //@"C",@"C♯/D♭",@"D",@"D♯/E♭",@"E",@"F",@"F♯/G♭",@"G",@"G♯/A♭",@"A",@"A♯/B♭",@"B"；
    
    if(stringgetHighlightNoteValue == NULL ||
       stringpyin == NULL)
    {
        return 0;
    }
    std::string stringgetHighlightNoteValue_string([stringgetHighlightNoteValue UTF8String]);
    
    std::vector<std::string>::iterator iterhigh;
    iterhigh = find(m_ScaleName.begin(), m_ScaleName.end(), stringgetHighlightNoteValue_string);//find函数返回一个指向对应元素的迭代器
    int index = iterhigh - m_ScaleName.begin();//ans即为5在数组中的序号
    
    if (index >= 0)
    {
        std::vector<std::string> names;
        if (index - change_number < 0)
        {
            for (int i = 0; i <= index + change_number; i++)
            {
                names.push_back(m_ScaleName[i]);
            }
        }
        else if (index - change_number >= 0 && index + change_number <= 87)
        {
            for (int i = index - change_number; i <= index + change_number; i++)
            {
                names.push_back(m_ScaleName[i]);
            }
        }
        else if(index + change_number > 87)
        {
            for (int i = index - change_number; i <= 87; i++)
            {
                names.push_back(m_ScaleName[i]);
            }
        }

        //遍历;
        int count = names.size();
        for (int i = 0; i < count;i++)
        {
            std::string stringpyin_string([stringpyin UTF8String]);
            if(names[i] == stringpyin_string)
            {
                return 1;
                break;
            }
        }
    }
    return 0;
}
//匹配准确度白马(不区分八度);
- (int)change_Accuracy_baima:(int)change_number
string_getHighlightNoteValue_string:(NSString *)stringgetHighlightNoteValue
          string_pyin_string:(NSString *)stringpyin
{
    //@"C",@"C♯/D♭",@"D",@"D♯/E♭",@"E",@"F",@"F♯/G♭",@"G",@"G♯/A♭",@"A",@"A♯/B♭",@"B"；
    
    if(stringgetHighlightNoteValue == NULL ||
       stringpyin == NULL)
    {
        return 0;
    }
    std::string stringgetHighlightNoteValue_string([stringgetHighlightNoteValue UTF8String]);
    
    std::vector<std::string>::iterator iterhigh;
    iterhigh = find(m_ScaleName.begin(), m_ScaleName.end(), stringgetHighlightNoteValue_string);//find函数返回一个指向对应元素的迭代器
    int index = iterhigh - m_ScaleName.begin();//ans即为5在数组中的序号
    
    if (index >= 0)
    {
        std::vector<std::string> names;
        if (index - change_number < 0)
        {
            for (int i = 0; i <= index + change_number; i++)
            {
                names.push_back(m_ScaleName[i]);
            }
        }
        else if (index - change_number >= 0 && index + change_number <= 87)
        {
            for (int i = index - change_number; i <= index + change_number; i++)
            {
                names.push_back(m_ScaleName[i]);
            }
        }
        else if(index + change_number > 87)
        {
            for (int i = index - change_number; i <= 87; i++)
            {
                names.push_back(m_ScaleName[i]);
            }
        }

        //遍历;
        int count = names.size();
        for (int i = 0; i < count;i++)
        {
            std::string stringpyin_string([stringpyin UTF8String]);
            
            //不区分八度;
            if((names[i].size() == stringpyin_string.size() &&
                names[i].substr(1) == stringpyin_string.substr(1)))
            {
                return 1;
                break;
            }
        }
    }
    return 0;
}
// MARK: - 录音
- (void)startRecord {
    [self.recorder startRecord];
}
- (void)stopRecord {
    [self.recorder stopRecord];
}
- (void)pauseAudioRecord {
    [self.recorder pauseRecord];
}
- (void)resumeAudioRecord {
    [self.recorder resumeRecord];
}
- (NSString*)getCurrentWavVoiceFilePath {
    return [self.recorder getCurrentWavVoiceFilePath];
}

// MARK: - player
- (void)playToEnd:(XBPCMPlayer *)player {
    self.m_player_outall_data_length = 0;
    if (MSBUnityAudioCaptureInterface.shared.delegate &&
        [MSBUnityAudioCaptureInterface.shared.delegate respondsToSelector:@selector(backgroundMusicPlayEnd)]) {
        [MSBUnityAudioCaptureInterface.shared.delegate backgroundMusicPlayEnd];
    }
    
}
- (void)startProcess {
    _isProcessingData = true;
}
- (void)stopProcess {
    _isProcessingData = false;
}
/// 暂停处理
- (void)pauseAudioProcess {
    _isProcessingData = false;
    //暂停;
    if(self.m_ispause == 0)
    {
        //暂停滚动条;
        //停止滚动条的定时器时长;
//        if(self.m_view_islog_or_change_colour == 1)
//        {
//            if(self.m_rulertimer_shichang != NULL)
//            {
//                dispatch_source_cancel(self.m_rulertimer_shichang);
//            }
//        }
        //暂停播放器;
        if(self.m_palyer_aec != NULL)
        {
            [self.m_palyer_aec pause];
        }
        self.m_ispause = 1;
    }
    //恢复暂停;
    else if(self.m_ispause == 1)
    {
    }
}

- (void)resumeAudioProcess {
    //暂停;
    if(self.m_ispause == 0)
    {
    }
    //恢复暂停;
    else if(self.m_ispause == 1)
    {
        [NSThread sleepForTimeInterval:1];  //这里必须要做sleep防止播放器和录音正在用;
        if (self.voicePreProcess != NULL)
        {
            self.voicePreProcess = NULL;
            self.voicePreProcess = [MSBVoicePreprocess createVoicePreprocess];
            [self.voicePreProcess init:44100 channel:1];
        }
        
        //重新创建清掉缓存;
        if (self.voiceAnalysisProcess != NULL)
        {
            self.voiceAnalysisProcess = NULL;
            self.voiceAnalysisProcess = [MSBVoiceAnalysisProcess createVoiceAnalysisProcess];
            [self.voiceAnalysisProcess init:44100 channel:1];
        }
        
        //恢复滚动条;
        //开始滚动条的定时器时长;
//        if(self.m_view_islog_or_change_colour == 1)
//        {
//            if((int)self.m_rulerprogress_shichang > 0)
//            {
//                if(self.m_rulertimer_shichang != NULL)
//                {
//                    [self.m_rulerView_shichang.progressDict removeAllObjects];
//                    [self ruler_timerfunc_shichang];
//                }
//            }
//        }
        _isProcessingData = true;
        // MARK: - 重播准备完成
        [MSBUnityAudioCaptureInterface.shared.delegate processResumeReadyed];
        //恢复播放器;
        if(self.m_palyer_aec != NULL)
        {
            self.m_palyer_aec.pause;
        }
        self.m_ispause = 0;
    }
}
- (void)getPlayedTime:(NSData*)newData {
    self.m_player_outall_data_length += newData.length;
//    MSBAudioLog(@"m_player_outall_data = %d",self.m_player_outall_data_length);
    float playedTime = float(self.m_player_outall_data_length) / 2 / 44100;
    float totalTime = float(self.m_player_pcm_alldata.length) / 2 / 44100;
//    MSBAudioLog(@"播放时长%f s",playedTime);
    float position = playedTime/totalTime;
//    MSBAudioLog(@"播放进度%f s",position);
    if ([MSBUnityAudioCaptureInterface.shared.delegate respondsToSelector:@selector(playerTime:position:)]) {
        [MSBUnityAudioCaptureInterface.shared.delegate playerTime:playedTime position:position];
    }
    
    
//    MSBAudioLog(@"播放长度比例  %ld:%ld ",self.m_player_outall_data_length,self.m_player_pcm_alldata.length);
}
//MARK: 这里取出来播放背景音数据; 背景音音频流
- (void)playerInputDataParocess:(XBAudioUnitPlayer *)player
                  ioActionFlags:(AudioUnitRenderActionFlags *)ioActionFlags
                    inTimeStamp:(const AudioTimeStamp *)inTimeStamp
                    inBusNumber:(UInt32) inBusNumber
                 inNumberFrames:(UInt32)inNumberFrames
                         ioData:(AudioBufferList *)ioDat
{
    NSTimeInterval recordTime1 = [[NSDate date] timeIntervalSince1970]*1000;
//    MSBAudioLog(@"@@@@1 == %lli",(long long int)recordTime1);

    if(self.m_ispause == 0) {
        //这里是不管你取不取出来回调数据都会输出;
        //得到新数据;
        NSData * data_newout_player = [NSData dataWithBytes:(char *)ioDat->mBuffers[0].mData
                                                     length:ioDat->mBuffers[0].mDataByteSize];
//        MSBAudioLog(@"data_newout_player = %d",data_newout_player.length);

        //nsdata拼接到队列里；
        [self.m_lock_aec_player lock];
        [self.m_palyer_aec_outall_data appendData:data_newout_player];
        
        [self getPlayedTime:data_newout_player];
        [self.m_lock_aec_player unlock];
        
        //写到文件中做测试;
        //[aec_weakSelf_far.m_xbFile_aec_player writeIoData:ioDat inNumberFrames:inNumberFrames];
    } else {//这里一定要清空;
        //用完之后设置为空的方法;
        [self.m_palyer_aec_outall_data resetBytesInRange:NSMakeRange(0, [self.m_palyer_aec_outall_data length])];
        [self.m_palyer_aec_outall_data setLength:0];
    }
}
// MARK: -


/// 开始录音采集
- (void)startCapture {
    [self startAudioCapture];
    
    //这里取出来播放背景音数据; 背景音音频流
    typeof(self) __weak aec_weakSelf_far = self;
    self.m_palyer_aec.player.bl_inputFull = ^(XBAudioUnitPlayer *player,
                                              AudioUnitRenderActionFlags *ioActionFlags,
                                              const AudioTimeStamp *inTimeStamp,
                                              UInt32 inBusNumber,
                                              UInt32 inNumberFrames,
                                              AudioBufferList *ioDat)
    {
        //加这个之后临时变量内存会自动被释放;
        @autoreleasepool {
            [aec_weakSelf_far playerInputDataParocess:player
                                        ioActionFlags:ioActionFlags
                                          inTimeStamp:inTimeStamp
                                          inBusNumber:inBusNumber
                                       inNumberFrames:inNumberFrames
                                               ioData:ioDat];
        }
    };
    //MARK: 音频采集回调 麦克风
    typeof(self) __weak aec_weakSelf_near = self;
    self.m_recorder_aec.bl_outputFull = ^(XBAudioUnitRecorder *player, AudioUnitRenderActionFlags *ioActionFlags,
                                          const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber,
                                          UInt32 inNumberFrames, AudioBufferList *ioData)
    {
        //加这个之后临时变量内存会自动被释放;
        @autoreleasepool {
            [self audioMergeProcess:player ioActionFlags:ioActionFlags inTimeStamp:inTimeStamp
                        inBusNumber:inBusNumber inNumberFrames:inNumberFrames ioData:ioData];
        }
    };
    
    //加这个之后临时变量内存会自动被释放;
    @autoreleasepool {
        //音高检测(要在另一个线程里面处理 否则会影响这个线程的速度导致卡顿问题);
        self.m_aec_AnalysisThread = [[NSThread alloc]initWithTarget:self selector:@selector(Analysis_thread) object:nil];
        //开启线程
        [self.m_aec_AnalysisThread start];
        self.m_Analysis_thread_isruning = 0;
    }
    
    MSBAudioLog(@"aec paly and record ");
}
- (void)stopCapture {
    
}

@end
