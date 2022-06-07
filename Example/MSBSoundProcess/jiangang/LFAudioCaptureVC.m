//
//  LFAudioCaptureVC.m
//  MSBSoundProcess_Example
//
//  Created by 范金龙 on 2021/2/14.
//  Copyright © 2021 jinyuyoulong. All rights reserved.
//

#import "LFAudioCaptureVC.h"
#import <SoundProcess/SoundProcess.h>
#import "LFAudioCapture.h"

#define filepath [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"record.pcm"]

@interface LFAudioCaptureVC ()<LFAudioCaptureDelegate>
{
    BOOL isStartRecorder;
    NSTimer *timer;
    int timer_margin;
    
    BOOL istimerloop;
}
@property (nonatomic,strong) MSBVoicePreprocess *voicePreProcess;
@property (nonatomic,strong) MSBVoiceAnalysisProcess *voiceAnalysisProcess;

/// 音频采集
@property (nonatomic, strong) LFAudioCapture *audioCaptureSource;
/// 音频配置
//@property (nonatomic, strong) LFLiveAudioConfiguration *audioConfiguration;

@property(nonatomic, strong)  NSFileHandle *audioFileHandle1;
@property (nonatomic, copy) NSString *audioFilePath1;

@property(nonatomic, strong)  NSFileHandle *audioFileHandle2;
@property (nonatomic, copy) NSString *audioFilePath2;

@property(nonatomic, strong)  NSFileHandle *audioFileHandle3;
@property (nonatomic, copy) NSString *audioFilePath3;

@property (nonatomic, strong) UILabel *textfield;


@end

@implementation LFAudioCaptureVC

- (LFAudioCapture *)audioCaptureSource {
    if (!_audioCaptureSource) {
        _audioCaptureSource = [[LFAudioCapture alloc] init];
        _audioCaptureSource.delegate = self;
    }
    return _audioCaptureSource;
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

//读文件，返回内存指针，记得free
void* ReadFile(const char *path, unsigned int *len)
{
    FILE *f = fopen(path, "rb");
    if (f == NULL)
        return NULL;
    fseek(f, 0, SEEK_END);
    *len = ftell(f);
    fseek(f, 0, SEEK_SET);
    void *buffer = malloc(*len);
    *len = fread(buffer, 1, *len, f);
    fclose(f);
    return buffer;
}
 
//pcm转wav，返回wav内存指针和wav长度
void* pcmToWav(const void *pcm, unsigned int pcmlen, unsigned int *wavlen)
{
    //44字节wav头
    void *wav = malloc(pcmlen + 44);
    //wav文件多了44个字节
    *wavlen = pcmlen + 44;
    //添加wav文件头
    memcpy(wav, "RIFF", 4);
    *(int *)((char*)wav + 4) = pcmlen + 36;
    memcpy(((char*)wav + 8), "WAVEfmt ", 8);
    *(int *)((char*)wav + 16) = 16;
    *(short *)((char*)wav + 20) = 1;
    *(short *)((char*)wav + 22) = 1;
    *(int *)((char*)wav + 24) = 8000;
    *(int *)((char*)wav + 28) = 16000;
    *(short *)((char*)wav + 32) = 16 / 8;
    *(short *)((char*)wav + 34) = 16;
    strcpy((char*)((char*)wav + 36), "data");
    *(int *)((char*)wav + 40) = pcmlen;
 
    //拷贝pcm数据到wav中
    memcpy((char*)wav + 44, pcm, pcmlen);
    return wav;
}

//pcm文件转wav文件，pcmfilePath:pcm文件路劲，wavfilePath:生成的wav路劲
int pcmfileToWavfile(const char *pcmfilePath, const char *wavfilePath)
{
    unsigned int pcmlen;
    //读取文件获得pcm流，也可以从其他方式获得
    void *pcm = ReadFile(pcmfilePath, &pcmlen);
    if (pcm == NULL)
    {
        printf("not found file\n");
        return 1;
    }
 
    //pcm转wav
    unsigned int wavLen;
    void *wav = pcmToWav(pcm, pcmlen, &wavLen);
 
    FILE *fwav = fopen(wavfilePath, "wb");
    fwrite(wav, 1, wavLen, fwav);
    fclose(fwav);
    free(pcm);
    free(wav);
    return 0;
}
 
- (void)captureOutput:(LFAudioCapture *)capture audioData:(NSData *)audioData
{
    if (self.audioFileHandle1 && isStartRecorder) {
        [self.audioFileHandle1 writeData:audioData];
    }
      
    {
        NSData *outputdata = [self.voicePreProcess preProcessAns:audioData inSampleCnt:audioData.length / 2];

        if (outputdata && outputdata.length > 0) {

            if (isStartRecorder) {
                [self.audioFileHandle2 writeData:outputdata];

                int result = pcmfileToWavfile(self.audioFilePath2.UTF8String, self.audioFilePath3.UTF8String);
                if (result) {
                    NSData *output_wavdata = [NSData dataWithContentsOfFile:self.audioFilePath3];
                    [self.audioFileHandle3 writeData:output_wavdata];
                }
            }

            MSBVoiceAnalysisInfo *analysisInfo = [self.voiceAnalysisProcess getVoiceAnalysisInfoRealtime:outputdata inSampleCnt:outputdata.length / 2];

            NSArray<MSBVoiceVadInfo *> * vadResult = analysisInfo.vadResult;
            NSLog(@"vadResult.count:%lu",(unsigned long)vadResult.count);
            for (int i = 0; i < vadResult.count; i++) {
                NSLog(@"i:%d vadResult.time:%d vadResult.vocal:%d",i,vadResult[i].timeMs,vadResult[i].vocal);
            }

            NSArray<MSBVoicePitchInfo *> * pitchSeq = analysisInfo.pitchSeq;
            NSLog(@"pitchSeq.count:%lu ",(unsigned long)pitchSeq.count);
            for (int i = 0; i < pitchSeq.count; i++) {
                NSLog(@"i:%d pitchSeq.startTimeMs:%d pitchSeq.endTimeMs:%d pitchSeq.vocal:%f",i,pitchSeq[i].startTimeMs,pitchSeq[i].endTimeMs,pitchSeq[i].freq);
            }

            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.textfield setText:[NSString stringWithFormat:@"%f",((MSBVoicePitchInfo *)(pitchSeq.lastObject)).freq]];
            });

            NSArray<MSBVoiceNoteInfo *> * noteSeq = analysisInfo.noteSeq;
            NSLog(@"noteSeq.count:%lu",(unsigned long)noteSeq.count);
            for (int i = 0; i < noteSeq.count; i++) {
                NSLog(@"i:%d noteSeq.startTimeMs:%d noteSeq.endTimeMs:%d noteSeq.note:%f",i,noteSeq[i].startTimeMs,noteSeq[i].endTimeMs,noteSeq[i].note);
            }

        }
    }
}

- (void)cameraView_startOrStopRecordVideo
{
       
    if (isStartRecorder) {
        isStartRecorder = NO;
        [self.audioFileHandle1 closeFile];
        [self.audioFileHandle2 closeFile];
        [self.audioFileHandle3 closeFile];
    } else {
        isStartRecorder = YES;
    }
    
}

- (void)timerAction
{

    if (_audioFileHandle1) {

        [_audioFileHandle1 closeFile];
        _audioFileHandle1 = nil;

        NSData *pcm_data = [NSData dataWithContentsOfFile:self.audioFilePath1];

        int result = pcmfileToWavfile(self.audioFilePath1.UTF8String, self.audioFilePath2.UTF8String);
        NSData *input_wavdata = [NSData dataWithContentsOfFile:self.audioFilePath2];

        NSData *outputdata = [self.voicePreProcess preProcessAns:input_wavdata inSampleCnt:input_wavdata.length / 2];

        MSBVoiceAnalysisInfo * analysisInfo = [self.voiceAnalysisProcess getVoiceAnalysisInfoRealtime:outputdata inSampleCnt:outputdata.length / 2];

        NSArray<MSBVoiceVadInfo *> * vadResult = analysisInfo.vadResult;
        NSLog(@"vadResult.count:%lu",(unsigned long)vadResult.count);
        for (int i = 0; i < vadResult.count; i++) {
            NSLog(@"i:%d vadResult.time:%d vadResult.vocal:%d",i,vadResult[i].timeMs,vadResult[i].vocal);
        }

        NSArray<MSBVoicePitchInfo *> * pitchSeq = analysisInfo.pitchSeq;
        NSLog(@"pitchSeq.count:%lu ",(unsigned long)pitchSeq.count);
        for (int i = 0; i < pitchSeq.count; i++) {
            NSLog(@"i:%d pitchSeq.startTimeMs:%d pitchSeq.endTimeMs:%d pitchSeq.vocal:%f",i,pitchSeq[i].startTimeMs,pitchSeq[i].endTimeMs,pitchSeq[i].freq);
        }

        NSArray<MSBVoiceNoteInfo *> * noteSeq = analysisInfo.noteSeq;
        NSLog(@"noteSeq.count:%lu",(unsigned long)noteSeq.count);
        for (int i = 0; i < noteSeq.count; i++) {
            NSLog(@"i:%d noteSeq.startTimeMs:%d noteSeq.endTimeMs:%d noteSeq.note:%f",i,noteSeq[i].startTimeMs,noteSeq[i].endTimeMs,noteSeq[i].note);
        }

        isStartRecorder = !isStartRecorder;

    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(100, 100, 100, 100);
    [btn setBackgroundColor:[UIColor redColor]];
    [btn setTitle:@"record" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(cameraView_startOrStopRecordVideo) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    self.textfield = [[UILabel alloc] init];
    self.textfield.frame = CGRectMake(200, 200, 300, 300);
    [self.textfield setFont:[UIFont systemFontOfSize:15]];
    [self.textfield setTextColor:[UIColor redColor]];
    self.textfield.text = @"text";
    [self.view addSubview:self.textfield];
    
    // 处理前pcm数据
    self.audioFilePath1 = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"record.pcm"];
    if ([NSFileManager.defaultManager fileExistsAtPath:self.audioFilePath1]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.audioFilePath1 error:nil];
    }
    [[NSFileManager defaultManager] createFileAtPath:self.audioFilePath1 contents:nil attributes:nil];
    self.audioFileHandle1 = [NSFileHandle fileHandleForWritingAtPath:self.audioFilePath1];

    // 处理后pcm数据
    self.audioFilePath2 = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"convert.pcm"];
    if ([NSFileManager.defaultManager fileExistsAtPath:self.audioFilePath2]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.audioFilePath2 error:nil];
    }
    [[NSFileManager defaultManager] createFileAtPath:self.audioFilePath2 contents:nil attributes:nil];
    self.audioFileHandle2 = [NSFileHandle fileHandleForWritingAtPath:self.audioFilePath2];
    
    // 处理后wav数据
    self.audioFilePath3 = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"convert.wav"];
    if ([NSFileManager.defaultManager fileExistsAtPath:self.audioFilePath3]) {
        [[NSFileManager defaultManager] removeItemAtPath:self.audioFilePath3 error:nil];
    }
    [[NSFileManager defaultManager] createFileAtPath:self.audioFilePath3 contents:nil attributes:nil];
    self.audioFileHandle3 = [NSFileHandle fileHandleForWritingAtPath:self.audioFilePath3];

    self.audioCaptureSource.running = YES;

//    timer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(timerAction) userInfo:nil repeats:YES];
//    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    
    // data
//    {
//        NSString *assetName = [[NSBundle mainBundle] pathForResource: [NSString stringWithFormat:@"asset_4"] ofType:@"wav"];
//
//        NSData *inputdata = [NSData dataWithContentsOfFile:assetName];
//        [self.audioFileHandle1 writeData:inputdata];
//        [self.audioFileHandle1 closeFile];
//
//        NSData *outputdata = [self.voicePreProcess preProcessAns:inputdata inSampleCnt:inputdata.length / 2];
//        [self.audioFileHandle2 writeData:outputdata];
//        [self.audioFileHandle2 closeFile];
//
//        MSBVoiceAnalysisInfo * analysisInfo = [self.voiceAnalysisProcess getVoiceAnalysisInfoRealtime:outputdata inSampleCnt:outputdata.length / 2];
//
//        NSArray *analysisInfoArray = [[NSArray alloc] init];
//        analysisInfoArray = [analysisInfoArray arrayByAddingObject:analysisInfo];
//        NSLog(@"analysisInfoArray:%@",analysisInfoArray);
//    }
    
    // file
//{
//    NSString *assetName = [[NSBundle mainBundle] pathForResource: [NSString stringWithFormat:@"asset_4"] ofType:@"wav"];
//    MSBVoiceAssetInfo * assetInfo = [MSBVoiceAssetInfo voiceAssetInfoWithAssetId:4 assetName:assetName];
//
//    NSData *inputdata = [NSData dataWithContentsOfFile:assetName];
//    [self.audioFileHandle1 writeData:inputdata];
//    [self.audioFileHandle1 closeFile];
//
//    NSData *outputdata = [self.voicePreProcess preProcessAnsAssetInfo:assetInfo];
//    [self.audioFileHandle2 writeData:outputdata];
//    [self.audioFileHandle2 closeFile];
//
//    MSBVoiceAnalysisInfo * analysisInfo = [self.voiceAnalysisProcess generateVoiceAnalysisInfo:assetInfo];
//    NSArray *analysisInfoArray = [[NSArray alloc] init];
//    analysisInfoArray = [analysisInfoArray arrayByAddingObject:analysisInfo];
//    NSLog(@"analysisInfoArray:%@",analysisInfoArray);
//}
    
//    {
//        NSString *configName = [[NSBundle mainBundle] pathForResource:@"audioconfig" ofType:@"json"];
//        NSString *midiName = [[NSBundle mainBundle] pathForResource:@"iliketoparty" ofType:@"mid"];
//        NSArray *arr = [[NSArray alloc] init];
//        NSArray *analysisInfoArray = [[NSArray alloc] init];
//        for(int i=1;i<=1;i++) {
//
//            NSString *assetName = [[NSBundle mainBundle] pathForResource: [NSString stringWithFormat:@"asset_%d",i+2] ofType:@"wav"];
//            MSBVoiceAssetInfo * assetInfo = [MSBVoiceAssetInfo voiceAssetInfoWithAssetId:i assetName:assetName];
//
//            MSBVoiceAnalysisInfo * analysisInfo =  [[MSBVoiceBeatProcess createVoiceBeatProcess] generateVoiceAnalysisInfo:(assetInfo)];
//            analysisInfoArray = [analysisInfoArray arrayByAddingObject:analysisInfo];
//
//            NSLog(@"analysisInfoArray:%@",analysisInfoArray);
//
//            arr = [arr arrayByAddingObject:assetInfo];
//        }
//
//    //    [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mp4"];
//    //
//    //    MSBVoiceInputInfo *dcVoiceInput = [MSBVoiceInputInfo voiceInputInfoWithMidiFileName:midiName configFileName:configName assetInfos:arr analysisInfos:analysisInfoArray outFileName:[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/make.wav"] ];
//    //
//    //    NSLog(@"paht:%@",[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/make.wav"]);
//    //
//    //    NSDictionary<NSNumber *, NSArray<MSBVoiceTrackInfo *> *> * dict = [[MSBVoiceBeat createVoiceBeat] getVoiceTrackInfo:dcVoiceInput];
//    //
//    //    NSMutableDictionary *destDict = [NSMutableDictionary dictionary];
//    //    NSMutableArray *assetAry = [NSMutableArray array];
//    //    for (NSNumber *assetId in [dict allKeys]) {
//    //        //        NSMutableDictionary *assetDict = [NSMutableDictionary dictionary];
//    //        NSArray<MSBVoiceTrackInfo *> *ary = [dict objectForKey:assetId];
//    //        NSMutableArray *infos = [NSMutableArray array];
//    //        if (ary) {
//    //            for (MSBVoiceTrackInfo *trackInfo in ary) {
//    //                NSMutableArray *voiceInfo = [NSMutableArray array];
//    //                for (MSBVoiceNodeInfo *nodeInfo in trackInfo.voiceInfo) {
//    //                    NSDictionary *nodeInfoDict = @{
//    //                                                   @"inputStartTime": @(nodeInfo.inputStartTime),
//    //                                                   @"inputEndTime": @(nodeInfo.inputEndTime),
//    //                                                   @"outputStartTime": @(nodeInfo.outputStartTime),
//    //                                                   @"outputEndTime": @(nodeInfo.outputEndTime),
//    //                                                   @"scale": @(nodeInfo.scale)
//    //                                                   };
//    //                    [voiceInfo addObject:nodeInfoDict];
//    //                }
//    //                NSDictionary *infoDict = @{
//    //                                           @"trackId": @(trackInfo.trackId),
//    //                                           @"voiceInfo": voiceInfo
//    //                                           };
//    //                [infos addObject:infoDict];
//    //            }
//    //        }
//    //        NSDictionary *assetDict = @{
//    //                                    @"assetId": assetId,
//    //                                    @"tracks": infos
//    //                                    };
//    //        [assetAry addObject:assetDict];
//    //    }
//    //    [destDict setObject:assetAry forKey:@"voiceInfo"];
//    //
//    //    NSString *jsonString = nil;
//    //    NSString * jsonName = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/data.json"];
//    //    if ([NSJSONSerialization isValidJSONObject:destDict])
//    //    {
//    //        NSError *error;
//    //        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:destDict options:NSJSONWritingPrettyPrinted error:&error];
//    //        jsonString =[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//    //        if (error) {
//    //            NSLog(@"Error:%@" , error);
//    //        }
//    //        [jsonString writeToFile:jsonName atomically:YES encoding:NSUTF8StringEncoding error:nil ];
//    //    }
//    }

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
