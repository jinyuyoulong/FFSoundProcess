# soundprocess_ios

    @property (nonatomic,strong) MSBVoicePreprocess *voicePreProcess;
    @property (nonatomic,strong) MSBVoiceAnalysisProcess *voiceAnalysisProcess;

    //****** 实时处理程序 ******//
    self.voicePreProcess = [MSBVoicePreprocess createVoicePreprocess];
    [self.voicePreProcess init:44100 channel:1];
    
    //****** agc + ans ******//
    NSData *outputdata = [self.voicePreProcess preProcess:inputdata inSampleCnt:inputdata.length / 2];

    //agc;
    NSData *outputdata = [self.voicePreProcess preProcessAgc:inputdata inSampleCnt:inputdata.length / 2];

    //ans;
    NSData *outputdata = [self.voicePreProcess preProcessAns:inputdata inSampleCnt:inputdata.length / 2];
    
    //vod;返回1有声音返回0没声音;
    int ret = [self.voicePreProcess preProcessVod:inputdata inSampleCnt:(int32_t)inputdata.length / 2];
    
    //aec;playerdata;recodedata;ios存储位置路径;aec偏移(毫秒);
    NSData *aec_outputdata = [self.voicePreProcess
                              preProcessAec:inputplayerdata inFarSampleCnt:((int32_t)inputplayerdata.length/2)
                           inNearData:inputrecodedata  inNearSampleCnt:((int32_t)inputrecodedata.length/2)
                              filePath:testdocumentPath InSndCardBuf:self.m_aec_InSndCardBuf];  //这个地址filePath不能填空值，可以填无效的值比如NSString *testdocumentPath_test = "1111";

    //****** voice info ******//
    self.voiceAnalysisProcess = [MSBVoiceAnalysisProcess createVoiceAnalysisProcess];
    [self.voiceAnalysisProcess init:44100 channel:1];
    
    //音高检测;
    MSBVoiceAnalysisPitchAndNoteInfo * m_analysisInfoPitchAndNoteInfo = [self.voiceAnalysisProcess getPitchAndNote:inputdata inSampleCnt:inputdata.length / 2];
    
    @interface MSBVoiceAnalysisPitchAndNoteInfo : NSObject
    //pitch;
    @property (nonatomic, readonly) float mOutpitch;

    //note(后面需要调整);
    @property (nonatomic, readonly) float mOutnote;

    //第几个八度;
    @property (nonatomic, readonly, nonnull) NSString * mOutoctaveString;

    //音调;
    @property (nonatomic, readonly, nonnull) NSString * mOutnoteString;
    @end
