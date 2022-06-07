//
//  MSBViewController.m
//  MSBSoundProcess
//
//  Created by jinyuyoulong on 01/12/2021.
//  Copyright (c) 2021 jinyuyoulong. All rights reserved.
//

#import "MSBViewController.h"
#import "AudioRecorder.h"
#import "FFAudio.h"
#import "XDXAudioQueueCaptureManager.h"
#import <AVFoundation/AVFoundation.h>
#import "AudioPlayer.h"

#import "MSBAudioCaptureVC.h"
#import "LFAudioCaptureVC.h"
#import "MSBSoundProcessHeader.h"
#import "LYPlayer.h"
#import "MSBAudioUnitGraph.h"
#import <MSBSoundProcess/MSBSoundProcessHeader.h>
#include <msbaudioai/msbaudioai.h>
#import "MSBNewTestViewController.h"
//#import "MYDownloadMultiManager.h"

#import <OSAbility/OSAbility-umbrella.h>

@interface MSBViewController ()
<
AudioRecorderDelegate,
LYPlayerDelegate,
MSBAudioUnitGraphDelegate,
MSBAudioKitInterface,
UITableViewDelegate,
UITableViewDataSource
//MYDownloadMultiManagerDelegate
>
{
    BOOL isRunning;
    BOOL isScrollTextView;
}
@property (nonatomic, strong)UITableView *mtableview;
@property (nonatomic, strong)UITextView *textView;

@property (nonatomic, strong)AVAudioPlayer *audioPlayer;
@property (nonatomic, strong)NSMutableArray *audioArray;
@property (nonatomic, strong)AudioRecorder *ar;
@property (nonatomic, strong)MSBAudioCaptureManager *audioCaptureManager;

@property (nonatomic, strong)FFAudio *ffaudiodPlayer;
@property (nonatomic, strong)AudioPlayer *ap;
@property (nonatomic, strong)LYPlayer *lyaudioPlayer;

@property (nonatomic, strong) MSBAudioUnitGraph *audioUnitGraph;
@property (nonatomic, strong) MSBVoicePreprocess *voicePreProcess;
@property (nonatomic, strong) MSBVoiceAnalysisProcess *voiceAnalysisProcess;
@property (nonatomic, strong) MSBVoiceAnalysisInfo *analysisInfo;

@property (nonatomic, strong) MSBAudioAi* audioai;
@end

@implementation MSBViewController
// MARK: - lazy
- (UITableView *)mtableview {
    if (!_mtableview) {
        _mtableview = [[UITableView alloc] initWithFrame:CGRectMake(0, 400, 300, 300)
                                                   style:UITableViewStylePlain];
        [_mtableview registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
        _mtableview.delegate = self;
        _mtableview.dataSource = self;
    }
    return _mtableview;
}
- (UITextView *)textView
{
    if(!_textView)
    {
        _textView = [[UITextView alloc] init];
        CGRect frame = CGRectMake(0, 400, 300, 300);
        _textView.frame = frame;
        isScrollTextView = true;
        _textView.editable = false;
        _textView.backgroundColor = [UIColor lightGrayColor];
    }
    return _textView;
}

- (LYPlayer *)lyaudioPlayer {
    if (!_lyaudioPlayer) {
        _lyaudioPlayer = [[LYPlayer alloc] init];
        _lyaudioPlayer.delegate = self;
    }
    return _lyaudioPlayer;
}
- (MSBAudioCaptureManager *)audioCaptureManager {
    if (!_audioCaptureManager) {
        _audioCaptureManager = [MSBAudioCaptureManager share];
    }
    return  _audioCaptureManager;
}

- (AudioRecorder *)ar {
    if (!_ar) {
        _ar = [AudioRecorder defaultInstance];
        _ar.delegate = self;
    }
    return _ar;
}
- (FFAudio *)ffaudiodPlayer
{
    if(!_ffaudiodPlayer)
    {
        _ffaudiodPlayer = [[FFAudio alloc] init];
    }
    return _ffaudiodPlayer;
}
- (MSBAudioUnitGraph *)audioUnitGraph {
    if (!_audioUnitGraph) {
        _audioUnitGraph = [[MSBAudioUnitGraph alloc] init];
        _audioUnitGraph.delegate = self;
    }
    return _audioUnitGraph;
}
#pragma mark -
- (void)viewDidLoad {
    [super viewDidLoad];
    [self registNotifications];
    [self initFeiZhouGuData];
    // Do any additional setup after loading the view.
//    openAudioCapture(1, 44100, 1);
//    [[XDXAudioQueueCaptureManager getInstance] startAudioCapture];
    
    _ap = [[AudioPlayer alloc] init];
    _audioArray = [[NSMutableArray alloc] init];
    [self makeViews];
    [self getAudioFiles];
    MSBAudioCaptureManager.share.delegate = self;
    MSBUnityAudioCaptureInterface.shared.delegate = self;
//    [self startAudioCapture];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(audioKitNotif:)
                                               name:@"AudioKit" object:nil];
//    [self resetAudioSession];
    [self isBleToothOutput];
}
- (void)audioKitNotif:(NSNotification*)info {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *msg = info.userInfo[@"data"];
        self.textView.text = msg;
    });
    
}
- (void)dealloc {
    [[XDXAudioQueueCaptureManager getInstance] stopAudioCapture];
    [_ar stopRecording];
}

- (void)makeViews {
//        [self.view addSubview:self.mtableview];
        [self.view addSubview:self.textView];
//    UIButton *textViewScrollBtn = [UIButton buttonWithType:UIButtonTypeSystem];
//    [self.view addSubview:textViewScrollBtn];
//    textViewScrollBtn.frame = CGRectMake(0, 500, 50, 50);
//    [textViewScrollBtn addTarget:self action:@selector(setupIsScroll)
//                forControlEvents:UIControlEventTouchUpOutside];
//    [textViewScrollBtn setTitle:@"滚动" forState:UIControlStateNormal];
}
- (void)setupIsScroll {
    isScrollTextView = !isScrollTextView;
}
// MARK: - actions

/// // 开始采集
- (IBAction)startAudioCapture {
    // Pod 音频采集类
//    self.audioCaptureSource.running = YES;
//    [self.audioCaptureManager startAudioCapture];
    
//    startMicrophone();
    
    // 自己的音频采集类
//    self.ar.running = YES;
//    [self.ar startRecording];
    [MSBUnityAudioCaptureInterface.shared startAudioCapture:0];
}
- (IBAction)stopAudioCapture {
    //    self.audioCaptureSource.running = NO;
        
//    [self.audioCaptureManager stopAudioCapture];
    
//    stopMicrophone();
    
    // 自己的音频采集
//    [self.ar stopRecording];
    [self logInfoToScreen:@"停止采集音频"];
    [MSBUnityAudioCaptureInterface.shared stopAudioCapture:0];
}
/// 开始音频处理
- (IBAction)startVoiceProcessAction:(id)sender {
    [MSBUnityAudioCaptureInterface.shared startVoiceProcess];
//    startMicrophone();
//    startVoiceProcess();
}
// stop采集
- (IBAction)stopVoiceProcessAction:(id)sender {
    [MSBUnityAudioCaptureInterface.shared stopVoiceProcess];
//    stopMicrophone();
//    stopVoiceProcess();
}
// 开始录制
- (IBAction)startRecord:(id)sender {

    [MSBUnityAudioCaptureInterface.shared startRecordVoice];
    
//    startMicrophone();
//    startRecordVoice();
    
    
    // 示例的音频采集
//    [[XDXAudioQueueCaptureManager getInstance] startRecordFile];
    
//    [[XDXAudioQueueCaptureManager getInstance] startProcessVoice];
    
}
- (IBAction)stopRecord:(id)sender {
//    self.ar.running = NO;
    
    [MSBUnityAudioCaptureInterface.shared stopRecordVoice];
    
//    stopMicrophone();
//    stopRecordVoice();
    
    
    // 示例的音频采集停止
//    [[XDXAudioQueueCaptureManager getInstance] stopRecordFile];
    // 停止音频解析
    
}
// 播放背景音
- (IBAction)startPlayAudio:(id)sender {
//    _ad.isStartPlay = YES;
//    [self getAudioFiles];
    NSString * path = [[NSBundle mainBundle] pathForResource:@"nixiaoqilaizhenhaokna_44100_1_s16"
                                                      ofType:@"mp3"];
    [MSBUnityAudioCaptureInterface.shared preProcessBgAudioFile: path];
//    [MSBUnityAudioCaptureInterface.shared startCaptureWithBgMusic:path];
    
}
// 停止分析音频
- (IBAction)stopPlayAudio:(id)sender {
//    _ad.isStartPlay = NO;
//    [_ap stop];
    [self stopAudioCapture];
    
}
- (IBAction)costumAction:(id)sender {
//    MSBAudioCaptureVC *vc = [[MSBAudioCaptureVC alloc] init];
//    [self presentViewController:vc animated:YES completion:nil];
//    [self playWAV];

    //    NSString *folder = [[NSBundle mainBundle] pathForResource:@"起风了" ofType:@"mp3"];
//    [self playMP3:folder];
    
//    char* pitchinfo =  voicePitchProcess();
//    NSLog(@"pitchinfo:%s",pitchinfo);
    // storeboard 跳转
//    MSBNewTestViewController *newvc = [[MSBNewTestViewController alloc] initWithNibName:@"MSBNewTestViewController" bundle:[NSBundle mainBundle]];
//    [self.navigationController pushViewController:newvc animated:true];

    [self setAudioSessionToBluetooth];
}

- (IBAction)playAudio:(id)sender {
    [self 测试2];
}
- (IBAction)audioSessionAction:(id)sender {
    NSLog(@"Current Category:%@", AVAudioSession.sharedInstance.category);
    NSLog(@"Current mode:%@", AVAudioSession.sharedInstance.mode);
    NSLog(@"Current categoryOptions:%lx", (unsigned long)AVAudioSession.sharedInstance.categoryOptions);
}
- (void)test2 {
//    [self playWAV];
//    [self playPCM];
}
- (void)测试2 {
//    [self audioUnitGraphCapture];
    [self setAudioSessionDefaultModelA2DP];
}
- (void)playAudioStream {
    
}

- (void)playPCM {
    NSString *folder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"convert.pcm"];
    [self.lyaudioPlayer setupAudioPlayerWithPath:folder];
    
    [self.lyaudioPlayer play];
}
- (void)playWAV {
    NSString *folder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"convert.wav"];
    [self.ap setupAudioPlayerWithPath:folder];
    
    [self.ap playLoundspeaker];
}
- (void)playMP3:(NSString*)path {
//    NSString *folder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"convert.mp3"];
    [self.ap setupAudioPlayerWithPath:path];
    [self.ap playLoundspeaker];
}
- (void)getAudioFiles {
    //获取沙盒路径 作为存储录音文件的路径
    NSArray <NSString *> *files = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSMutableString *strURL = [[NSMutableString alloc] initWithString: [files lastObject]];
    NSString *VoiceDic =  [strURL stringByAppendingPathComponent:@"Voice"];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    NSError *error;
    [fileManager createDirectoryAtPath:VoiceDic withIntermediateDirectories:YES attributes:nil error:nil];
    NSArray * fileArr = [fileManager contentsOfDirectoryAtPath:VoiceDic error:&error];
    if (error) {
        NSLog(@"getAudioFiles:%@",error.localizedDescription);
    }
    for (int i=0; i<fileArr.count; i++) {
        NSString *file = fileArr[i];
        [_audioArray insertObject:file atIndex:0];
    }
    [_mtableview reloadData];
    NSLog(@"getAudioFiles--path= %@",_audioArray);
    
}
- (IBAction)sendertestAudioComposition {
//    NSArray *names = @[@"0100_6009_midi02.mp3",
//                       @"0100_6010_button.mp3",
//                       @"right.mp3",@"0100_6010_button.mp3",@"right.mp3",@"0100_6010_button.mp3",
//                       @"0100_6010_button.mp3",@"right.mp3",@"0100_6010_button.mp3",@"right.mp3",@"0100_6010_button.mp3",
//                       @"right.mp3",@"0100_6010_button.mp3",@"right.mp3",@"0100_6010_button.mp3",@"right.mp3",
//                       @"right.mp3",@"0100_6010_button.mp3",@"right.mp3",@"0100_6010_button.mp3",@"right.mp3",
//                       @"right.mp3",@"0100_6010_button.mp3",@"right.mp3",@"0100_6010_button.mp3",@"right.mp3",
//                       @"0100_6010_button.mp3",@"right.mp3",@"0100_6010_button.mp3",@"0100_6010_button.mp3"
//    ];
    NSArray *names = @[@"0100_6009_midi02.mp3",
                       @"0100_6010_button.mp3",
                       @"right.mp3",@"0100_6010_button.mp3",@"right.mp3",@"0100_6010_button.mp3",
                       @"0100_6010_button.mp3",@"right.mp3",@"0100_6010_button.mp3",@"right.mp3",@"0100_6010_button.mp3",
                       @"right.mp3",@"0100_6010_button.mp3",@"right.mp3",@"0100_6010_button.mp3",@"right.mp3",
                       @"right.mp3",@"0100_6010_button.mp3",@"right.mp3",@"0100_6010_button.mp3",@"right.mp3",
                       @"right.mp3",@"0100_6010_button.mp3",@"right.mp3",@"0100_6010_button.mp3",@"right.mp3",
                       @"0100_6010_button.mp3",@"right.mp3",@"0100_6010_button.mp3",@"0100_6010_button.mp3"
    ];

//    NSArray *names = @[@"train_gu_bg_1.mp3",@"0100_6010_button.ogg",@"4.mp3",@"0100_6010_button.ogg",@"4.mp3",@"0100_6010_button.ogg"];
//    NSArray *names = @[@"1.mp3",@"2.mp3",@"3.mp3",@"4.mp3",@"5.mp3"];
//    NSArray<NSNumber*> *positions = @[@0,
//                                      @300,@1,@2,@3,@4,
//                                      @5,@6,@7,@8,@9,
//                                      @10,@11,@12,@13,@14,
//                                      @15,@16,@17,@18,@19,
//                                      @20,@21,@22,@23,@24,
//                                      @25,@26,@27,@28
//    ];
    NSArray<NSNumber*> *positions = @[@0,
                                      @3,
                                      @1,@2,@3,@4,
                                      @5,@6,@7,@8,@9,
                                      @10,@11,@12,@13,@14,
                                      @15,@16,@17,@18,@19,
                                      @20,@21,@22,@23,@24,
                                      @25,@26,@27,@28
    ];
    NSMutableArray<NSNumber*>*mpositions = [NSMutableArray new];
    for (NSNumber *position in positions) {
        float time = position.floatValue * 1000;
        [mpositions addObject:@(time)];
    }
//    NSDate *startTime = [NSDate now];
//    NSLog(@"start 合成时间: %@",startTime);
    NSMutableArray *pathArray = [NSMutableArray array];
    for (int i = 0; i < names.count; i++) {
        NSInteger index = i;
//        NSString *path = [[NSBundle mainBundle] pathForResource:names[index] ofType:@"mp3"];
        NSString *name = names[index];
        NSArray *items = [name componentsSeparatedByString:@"."];
        NSString *audioNameAndPath = items[0];
        NSString *audioType = items[1];
        NSString *path = [[NSBundle mainBundle] pathForResource:audioNameAndPath ofType:audioType];
        if (path) {
            [pathArray addObject:path];
        }
    }
    NSLog(@"pathArray=%@\npositions=%@",pathArray,positions);
//    [MSBAudioCompositioner mixAudioTreacManage:pathArray
//                         isHaveBackgroundAudio:YES
//                              backgroundVolume:0.3
//                                     positions:mpositions
//                                       handler:^(NSString * _Nonnull outputFilePath) {
////        NSDate *endTime = [NSDate now];
////        NSLog(@"end 合成时间: %@",endTime);
//        NSString * documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
//        NSLog(@"documentPath:%@",documentPath);
//        NSString *fileName = [documentPath stringByAppendingPathComponent:@"audio"];
//        documentPath = [fileName stringByAppendingPathComponent:@"compositionedAudio.mp3"];
//
//        [self playMP3:documentPath];
//    }];
    
//    [MSBAudioCompositioner audioSynthesis:names
//                                positions:positions
//                                  handler:^(NSString * _Nonnull outputFilePath) {
//        NSDate *endTime = [NSDate now];
//        NSLog(@"end 合成时间: %@",endTime);
//        NSString * filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
//        NSLog(@"filepath:%@",filePath);
//        NSString *fileName = [filePath stringByAppendingPathComponent:@"audio"];
//        filePath = [fileName stringByAppendingPathComponent:@"compositionedAudio.mp3"];
//
//        [self playMP3:filePath];
//
//    }];

    //    mp3音频合成
//    [MSBAudioCompositioner audioSynthesis:names
//                          backgroundAudio:@"train_gu_bg_1.mp3"
//                                positions:positions
//                                  handler:^(NSString *outputFilePath) {
//        [self.ap setupAudioPlayerWithPath:outputFilePath];
//        [self.ap playLoundspeaker];
//    }];
    
    [self AudioMarge];
    
}
- (void)AudioMarge {
    // MARK: - 下载oss + 合成
        NSString *jsonStr = @"{\"leftRhythmClipPath\":\"https://xxyy-kczzht.oss-cn-hangzhou.aliyuncs.com/unity3d/Audio/Test/1600_0000_Effect_XiangBan.mp3\",\"rightRhythmClipPath\":\"https://xxyy-kczzht.oss-cn-hangzhou.aliyuncs.com/unity3d/Audio/Test/1600_0000_Effect_XiangBan.mp3\",\"sourceClip\":\"https://xxyy-kczzht.oss-cn-hangzhou.aliyuncs.com/unity3d/Audio/Test/1600_0000_bgm_game.mp3\",\"rhythmAudioDatas\":[{\"pos\":0,\"time\":6000},{\"pos\":0,\"time\":8000},{\"pos\":0,\"time\":9000},{\"pos\":0,\"time\":10000}]}";
    //    NSString *leftpath = [[NSBundle mainBundle] pathForResource:@"0100_6010_button" ofType:@"mp3"];
    //    NSString *rightpath = [[NSBundle mainBundle] pathForResource:@"0100_6009_midi02" ofType:@"mp3"];
    //    NSString *sourcepath = [[NSBundle mainBundle] pathForResource:@"0100_6009_midi02" ofType:@"mp3"];

        NSMutableDictionary *infoDic = [NSMutableDictionary dictionaryWithDictionary: [MSBViewController dictionaryWithJsonString:jsonStr]];
    //    infoDic[@"leftRhythmClipPath"] = leftpath;
    //    infoDic[@"rightRhythmClipPath"] = rightpath;
    //    infoDic[@"sourceClip"] = sourcepath;
        NSLog(@"infoDic%@",infoDic);
        NSURL *lefturl  = [NSURL URLWithString:infoDic[@"leftRhythmClipPath"]];
        NSLog(@"url: host:%@\nport:%@\nuser:%@\npassword:%@\npath:%@\nfragment:%@",lefturl.host,lefturl.port,lefturl.user, lefturl.password,lefturl.path,lefturl.fragment);
        NSString *leftfileName = [lefturl.path componentsSeparatedByString:@"/"].lastObject;
        NSLog(@"fileName:%@",leftfileName);
        
        NSURL *righturl  = [NSURL URLWithString:infoDic[@"rightRhythmClipPath"]];
        NSURL *sourceurl  = [NSURL URLWithString:infoDic[@"sourceClip"]];
        
        NSString *rightfileName = [righturl.path componentsSeparatedByString:@"/"].lastObject;
        NSString *sourcefileName = [sourceurl.path componentsSeparatedByString:@"/"].lastObject;
        
        NSString * documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *leftpath = [documentPath stringByAppendingPathComponent:lefturl.path];
        NSString *rightpath = [documentPath stringByAppendingPathComponent:righturl.path];
        NSString *sourcepath = [documentPath stringByAppendingPathComponent:sourceurl.path];
        
        
        NSDictionary *lefturldic = @{@"url":infoDic[@"leftRhythmClipPath"],
                                     @"fileDirPath":leftpath};
        NSDictionary *righturldic = @{@"url":infoDic[@"rightRhythmClipPath"],
                                      @"fileDirPath":rightpath};
        NSDictionary *sourceurldic = @{@"url":infoDic[@"sourceClip"],
                                       @"fileDirPath":sourcepath};
        NSArray *urls = @[lefturldic,righturldic,sourceurldic];
        NSLog(@"urls===>%@",urls);
//        [MYDownloadMultiManager.sharedManager downloadWithUrlDict:urls andIsBackGround:true progress:^(CGFloat progress, long long downloadedlength, long long totalLength) {
//
//            } state:^(MYDownloadState state) {
//                if (state == MYDownloadStateComplete) {
//                    infoDic[@"leftRhythmClipPath"] = [leftpath stringByAppendingPathComponent:leftfileName];
//                    infoDic[@"rightRhythmClipPath"] = [rightpath stringByAppendingPathComponent:rightfileName];
//                    infoDic[@"sourceClip"] = [sourcepath stringByAppendingPathComponent:sourcefileName];
//                    NSLog(@"infoDic==>%@",infoDic);
//                    [MSBAudioManager audioSynthesisWithDic:infoDic handler:^(NSString * _Nonnull outputFilePath) {
//                //        NSString * filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
////                        NSString * documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
//                        NSLog(@"outputFilePath:%@",outputFilePath);
////                        NSString *fileName = [documentPath stringByAppendingPathComponent:@"audio"];
////                        documentPath = [fileName stringByAppendingPathComponent:@"compositionedAudio.mp3"];
//
//                        [self playMP3:outputFilePath];
//                    }];
//                }
//            }];
//        //
//        [MYDownloadMultiManager sharedManager].downloadDelegate = self;
}
- (NSArray*)makeDownloadURLs:(NSDictionary *)dic {
    NSURL *lefturl  = [NSURL URLWithString:dic[@"leftRhythmClipPath"]];
//    NSLog(@"url: host:%@\nport:%@\nuser:%@\npassword:%@\npath:%@\nfragment:%@",lefturl.host,lefturl.port,lefturl.user, lefturl.password,lefturl.path,lefturl.fragment);
    
    NSURL *righturl  = [NSURL URLWithString:dic[@"rightRhythmClipPath"]];
    NSURL *sourceurl  = [NSURL URLWithString:dic[@"sourceClip"]];
    
    NSString * documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *leftpath = [documentPath stringByAppendingPathComponent:lefturl.path];
    NSString *rightpath = [documentPath stringByAppendingPathComponent:righturl.path];
    NSString *sourcepath = [documentPath stringByAppendingPathComponent:sourceurl.path];
    
    NSDictionary *lefturldic = @{@"url":dic[@"leftRhythmClipPath"],
                                 @"fileDirPath":leftpath};
    NSDictionary *righturldic = @{@"url":dic[@"rightRhythmClipPath"],
                                  @"fileDirPath":rightpath};
    NSDictionary *sourceurldic = @{@"url":dic[@"sourceClip"],
                                   @"fileDirPath":sourcepath};
    NSArray *urls = @[lefturldic,righturldic,sourceurldic];
    return urls;
}
// JSON字符串转化为字典
+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString
{
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err)
    {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

- (void)audioUnitGraphCapture {
    if (!isRunning) {
        [self.audioUnitGraph startaudioUnitRecordAndPlay];
        isRunning = YES;
    }else{
        isRunning = NO;

        [self.audioUnitGraph stopAudioUnitStop];
    }
}
// MARK: - tool functions
- (void)logInfoToScreen:(NSString *)info {
//    NSString *newText = [self.textView.text stringByAppendingString:info];
    self.textView.text = info;
//    if (isScrollTextView) {
//        if (newText.length) {
//            [self.textView scrollRangeToVisible:(NSRange){newText.length-1, 1}];
//        }
//    }
}
#pragma mark - delegate
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
//    cell.textLabel.text = [NSString stringWithFormat:@"%ld",(long)indexPath.row];
    cell.textLabel.text = [_audioArray objectAtIndex:indexPath.row];
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _audioArray.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray <NSString *> *files = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSMutableString *strURL = [NSMutableString stringWithString: [files lastObject]];
    NSString *VoiceDic =  [strURL stringByAppendingPathComponent:@"Voice"];
    NSString *audioPath = [VoiceDic stringByAppendingPathComponent:_audioArray[indexPath.row]];
    NSLog(@"音频路径:%@",audioPath);
//    _ap.audioPath = audioPath;
//    [_ap setupAudioPlayerWithPath:audioPath];
    //    [_ap play];
    [self.lyaudioPlayer setupAudioPlayerWithPath:audioPath];
    [self.lyaudioPlayer play];
    
//    NSError *error;
//    NSData *data = [NSData dataWithContentsOfFile:audioPath options:0 error:&error];
//    if (error) {
//        NSLog(@"dataWithContentsOfFile:%@",error.localizedDescription);
//    }
////    NSLog(@"data:%@",data);
//    [self.audioManager startManager];
//    NSData *processedData =  [self.audioManager preProcess:data];
//    [_ap setupAudioPlayerWithData:processedData];
    

}
// MARK: - MSBAudioKit delegate
- (void)processedAudioData:(MSBVoiceAnalysisPitchAndNoteInfo *)analysisInfo {
    NSLog(@"SDK处理结果%@",analysisInfo);
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *contentText = self.textView.text;
        self.textView.text = [NSString stringWithFormat:@"pitch=%f\n%@\n",analysisInfo.mOutpitch,contentText];
    });
}
- (void)processedAudioWithPitch:(MSBVoiceAnalysisInfo *)analysisInfo {
    MSBVoicePitchInfo *pitchinfo = analysisInfo.pitchSeq.lastObject;
    MSBVoiceVadInfo *vadinfo = analysisInfo.vadResult.lastObject;
    MSBVoiceNoteInfo *noteinfo = analysisInfo.noteSeq.lastObject;
    NSString *pitchStr;
    NSString *vadStr;
    NSString *noteStr;
    if (!analysisInfo ||analysisInfo.pitchSeq.count == 0 || !pitchinfo) {
        pitchStr = @"0,0,0,0,0";
    } else {
        pitchStr = [NSString stringWithFormat:@"startTimeMs:%d,endTimeMs:%d,startFrameIndex:%d,endFrameIndex:%d,freq:%f",
                    pitchinfo.startTimeMs,
                    pitchinfo.endTimeMs,pitchinfo.startFrameIndex,pitchinfo.endFrameIndex,pitchinfo.freq];
    }
    
    if (!analysisInfo || analysisInfo.vadResult.count == 0 || !vadinfo) {
        vadStr = @"0,0";
    } else {
        vadStr = [NSString stringWithFormat:@"%d,%d",vadinfo.timeMs,vadinfo.vocal ? 1: 0];
    }
    if (!analysisInfo || analysisInfo.noteSeq.count == 0 || !noteinfo) {
        noteStr = @"0,0,0,0,0";
    } else {
        noteStr = [NSString stringWithFormat:@"%d,%d,%d,%d,%f",noteinfo.startTimeMs,
                   noteinfo.endTimeMs,noteinfo.startFrameIndex,noteinfo.endFrameIndex,noteinfo.note];
    }
    
    
    NSString *result = [NSString stringWithFormat:@"vad:%@\npitch:%@\nnote:%@",vadStr, pitchStr, noteStr];
    NSLog(@"音频处理结果：%@",result);
    // 歌唱对对碰 音频处理回调
    
//    非洲鼓识别值：
//    是否有声音：1
//    pitch值：
//    中间区域范围：80-100
//    两边区域：170加减10、350加减10、400加减10、500加减10、
    NSString *infoMsg = @"";
    if (vadinfo.vocal) {
        float pitch = pitchinfo.freq;
        if (pitch == 0) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *contentText = self.textView.text;
            self.textView.text = [NSString stringWithFormat:@"pitch=%f\n%@\n",pitch,contentText];
        });
        
        
        if (pitch>=80 && pitch <=100) {
            NSLog(@"非洲鼓中间区域");
            infoMsg = @"B";
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *contentText = self.textView.text;
                self.textView.text = [NSString stringWithFormat:@"infoMsg=%@\n%@\n",infoMsg,contentText];
            });
        }
        if ([self checkNumber:pitch InArea:170 edgeNum:10]
            || [self checkNumber:pitch InArea:350 edgeNum:10]
            || [self checkNumber:pitch InArea:400 edgeNum:10]
            || [self checkNumber:pitch InArea:500 edgeNum:10]) {
            NSLog(@"非洲鼓两边区域");
            infoMsg = @"S";
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *contentText = self.textView.text;
                self.textView.text = [NSString stringWithFormat:@"infoMsg=%@\n%@\n",infoMsg,contentText];
            });
        }
        
    }
    
}
- (void)processedAudioIsHaveVoice:(BOOL)isHaveVad {
//    NSLog(@"%@",isHaveVad? @"有人声" : @"");
}
- (void)processedAudioMatchResult:(int)result {
    NSLog(@"音名比对结果：%d",result);
}
- (BOOL)checkNumber:(float)num InArea:(float)areaNum edgeNum:(float)edgeNum {
    if (num >= (areaNum-edgeNum) && num <=(areaNum+edgeNum)) {
        return true;
    }
    return false;
}
- (void)recordAudioFileFinish:(nonnull NSString *)mp3Path {
    NSLog(@"录音路径： %@",mp3Path);
    [self playMP3:mp3Path];
}
- (void)processResumeReadyed {
    NSLog(@"音频解析准备完成。。。");
}
// MARK: - AudioRecorder delegate
- (void)captureOutput:(nullable AudioRecorder *)capture audioData:(nullable NSData*)audioData {
    //    NSLog(@"MSBViewController-%@",audioData);
    __block  __weak typeof(self) wself = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [wself.ffaudiodPlayer playWithData:audioData];
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_analysisInfo = [self.voiceAnalysisProcess getVoiceAnalysisInfoRealtime:audioData
                                                                          inSampleCnt:(int32_t)audioData.length / 2];
        NSArray<MSBVoicePitchInfo *> * pitchResult = self->_analysisInfo.pitchSeq;
        NSArray<MSBVoiceVadInfo *> * vadresult = self->_analysisInfo.vadResult;
        NSArray<MSBVoiceNoteInfo *> * noteResult = self->_analysisInfo.noteSeq;
        int midiValue = [MSBAudioMIDITool snapFreqToMIDI:pitchResult.lastObject.freq];
        NSString *noteName = [MSBAudioMIDITool midiToString:midiValue];
        
        NSString *showInfo = [NSString stringWithFormat:@"pitch count: %lu\n pitch:%f\n midi:%d\n 音名:%@\n vad: %@\n note:%f\n",
                              (unsigned long)pitchResult.count,
                              pitchResult.lastObject.freq,
                              midiValue,
                              noteName,
                              (vadresult.firstObject.vocal ? @"有人" : @"无人"),
                              noteResult.lastObject.note];
        
        [self logInfoToScreen:showInfo];
    });
}
static float referenceA = 440.0;
- (int) snapFreqToMIDI:(float) frequencyy {
    
    int midiNote = (12*(log10(frequencyy/referenceA)/log10(2)) + 57) + 0.5;
    return midiNote;
}
- (NSString*) midiToString: (int) midiNote {
    if (midiNote < 0) {
        return @"";
    }
    NSArray *noteStrings = [[NSArray alloc] initWithObjects:@"C", @"C#", @"D", @"D#", @"E", @"F",
                            @"F#", @"G", @"G#", @"A", @"A#", @"B", nil];
    return [noteStrings objectAtIndex:midiNote%12];
}

// MARK: - LYPlayer delegate
- (void)onPlayToEnd:(LYPlayer *)lyPlayer {
    
    lyPlayer = nil;
}

- (void)registNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioSessionRouteChanged:)
                                                 name:OSAudioSessionManager.routeChangeNoti
                                               object:nil];
}
// MARK: - 通知回调
- (void)audioSessionRouteChanged:(NSNotification *)notification {
    
    //    AVAudioSession *session = [ AVAudioSession sharedInstance];
    NSString *seccReason = @"";
    NSInteger reason = [[[notification userInfo] objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (reason) {
            
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            seccReason = @"当前Category下没有合适的设备";
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            seccReason = @"从睡眠状态呼醒";
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            seccReason = @"App重置了输出设置";
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            seccReason = @"类别改变了";
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            seccReason = @"老设备不可用";
            break;
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            seccReason = @"有新设备可用";
            break;
        case AVAudioSessionRouteChangeReasonRouteConfigurationChange:
            seccReason = @"Rotuer的配置改变了";
            break;
        case AVAudioSessionRouteChangeReasonUnknown:
        default:
            seccReason = @"未知原因";
            break;
    }
    NSLog(@"audio session notification userinfo-%@", notification.userInfo);
    NSLog(@"audio session 改变原因-%@", seccReason);
}
- (MSBVoicePreprocess *)voicePreProcess {
    if (!_voicePreProcess) {
        _voicePreProcess = [MSBVoicePreprocess createVoicePreprocess];
        [_voicePreProcess init:kMSBAudioSampleRate channel:kMSBAudioChannelNumber];
    }
    return _voicePreProcess;
}

- (MSBVoiceAnalysisProcess *)voiceAnalysisProcess {
    if (!_voiceAnalysisProcess) {
        _voiceAnalysisProcess = [MSBVoiceAnalysisProcess createVoiceAnalysisProcess];
        [_voiceAnalysisProcess init:kMSBAudioSampleRate channel:kMSBAudioChannelNumber];
    }
    return _voiceAnalysisProcess;
}
// MARK: - MSBAudioUnitGraphDelegate
- (void)audioCaptureGetDataCallback:(const MSBAudioUnitGraph *)auGraph
                          audioData:(NSData *)data {
    //    NSData *outputdata = [self.voicePreProcess preProcessAns:data
    //                                                 inSampleCnt:(int32_t)data.length / 2];
    //    if (outputdata && outputdata.length > 0) {
    //        dispatch_async(dispatch_get_main_queue(), ^{
    //            self->_analysisInfo = [self.voiceAnalysisProcess getVoiceAnalysisInfoRealtime:outputdata
    //                                                                        inSampleCnt:(int32_t)outputdata.length / 2];
    //
    //        });
    //        NSArray<MSBVoicePitchInfo *> * pitchResult = _analysisInfo.pitchSeq;
    //        NSLog(@"pitchResult.count:%lu",(unsigned long)pitchResult.count);
    //        for (int i = 0; i < pitchResult.count; i++) {
    //            NSLog(@"pitchResult.vocal:%f",pitchResult[i].freq);
    //        }
    //    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_analysisInfo = [self.voiceAnalysisProcess getVoiceAnalysisInfoRealtime:data
                                                                          inSampleCnt:(int32_t)data.length / 2];
        
    });
    
    NSArray<MSBVoicePitchInfo *> * pitchResult = _analysisInfo.pitchSeq;
    NSLog(@"pitchResult.count:%lu",(unsigned long)pitchResult.count);
    for (int i = 0; i < pitchResult.count; i++) {
        NSLog(@"pitchResult.vocal:%f",pitchResult[i].freq);
    }
}

// MARK: - 非洲鼓深度识别方案
- (NSString *)applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (IBAction)feizhouguPlay:(UIButton *)sender {
//    [_audioai msbplay];
    [MSBUnityAudioCaptureInterface.shared pauseAudioRecord];
}

- (IBAction)feizhouguPause:(UIButton *)sender {
//    [_audioai msbpause];
    [MSBUnityAudioCaptureInterface.shared resumeAudioRecord];
}
- (void)initFeiZhouGuData {
    _audioai = [MSBAudioAi alloc];
    __block  __weak typeof(self) wself = self;
    _audioai.block = ^(int resultid) {
        if (resultid == -100){
            return;
        }
//        0=B 1=S 100=不确定
        NSLog(@"resultid:%d",resultid);
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *resStr = @"";
            if (resultid == 0) {
                resStr = @"B";
            } else if (resultid == 1) {
                resStr = @"S";
            } else {
                resStr = @"不确定";
            }
            NSString *result = [NSString  stringWithFormat:@"%@\n%@\n",resStr,wself.textView.text];
            wself.textView.text = result;
        });
    };
    
    
    NSString *tflitefilepath = [[NSBundle mainBundle] pathForResource:@"drumbeat_model" ofType:@"tflite"];
    
    NSLog(@"tflitefilepath：%@",tflitefilepath);
    
    NSString *recordfilepath = [[self applicationDocumentsDirectory] stringByAppendingString:@"/record.wav"];
    NSLog(@"recordfilepath:%@",recordfilepath);
    
    NSString *logfilepath = [[self applicationDocumentsDirectory] stringByAppendingString:@"/log.txt"];
    NSLog(@"logfilepath:%@",logfilepath);
    
    [_audioai msbinitaudioai:tflitefilepath andRecordPath:recordfilepath andLogPath:logfilepath];
}
#pragma mark - MYDownloadMultiManagerDelegate
//- (void)receiveAllFilesState:(MYDownloadState)state anddownload:(NSDictionary *)dic {
//    
//    switch (state) {
//        case MYDownloadStateDownloading: {
////                [MSBHUDManager showHUDWithInfo:@"开始下载" maxDelay:2.0];
//        }
//            break;
//        case MYDownloadStateComplete: {
//            NSLog(@"下载成功");
//        }
//            break;
//        case MYDownloadStateError: {
//            NSLog(@"下载失败");
//        }
//            break;
//        case MYDownloadStateSuspend: {
//            NSLog(@"下载暂停");
//        }
//            break;
//        case MYDownloadStateCancel: {
//            NSLog(@"下载取消");
//        }
//            break;
//        default:
//            break;
//    }
//    
//    NSLog(@"%@",dic);
//}
// MARK: - AVAudioSession 相关
/**
 检测是否连接蓝牙
 @return 是否为蓝牙音频输出
 */
-(BOOL)isBleToothOutput
{
    
    AVAudioSessionRouteDescription *currentRount = [AVAudioSession sharedInstance].currentRoute;
    AVAudioSessionPortDescription *outputPortDesc = currentRount.outputs[0];
    if([outputPortDesc.portType isEqualToString:@"BluetoothA2DPOutput"]){
        NSLog(@"BleTooth 当前输出的线路是蓝牙输出，并且已连接");
        return YES;
    }else{
        NSLog(@"BleTooth 当前是spearKer输出");
        return NO;
    }
}

/// 设置外设麦克风话筒
- (void) setAudioSessionDefaultModelA2DP {
    [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayAndRecord
                                          mode:AVAudioSessionModeDefault
                                       options:AVAudioSessionCategoryOptionAllowBluetoothA2DP
     | AVAudioSessionCategoryOptionAllowBluetooth
     | AVAudioSessionCategoryOptionAllowAirPlay
//     | AVAudioSessionCategoryOptionDuckOthers
                                         error:nil];
}
- (void) resetAudioSession {
    NSError *error = nil;
    AVAudioSession* session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord
             withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
                   error:&error];
    [session setActive:YES error:nil];
}

- (void)setAudioSessionToBluetooth {
    [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayAndRecord
                                          mode:AVAudioSessionModeDefault
                                       options:AVAudioSessionCategoryOptionAllowBluetoothA2DP
                                         error:nil];
//    [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayAndRecord
//                                          mode:AVAudioSessionModeDefault
//                                       options:AVAudioSessionCategoryOptionAllowBluetooth
//                                         error:nil];// 无用
//    [AVAudioSession.sharedInstance setMode:AVAudioSessionModeDefault error:nil];// 无用

//    [AVAudioSession.sharedInstance setActive:true error:nil];
}
// MARK: -
@end
