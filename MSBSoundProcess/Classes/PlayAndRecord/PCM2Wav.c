//
//  PCM2Wav.c
//  Test
//
//  Created by Jiangang Yang on 2021/2/8.
//  Copyright © 2021 msb. All rights reserved.
//

#include "PCM2Wav.h"

struct tagHXD_WAVFLIEHEAD
{
    char RIFFNAME[4];
    DWORD nRIFFLength;
    char WAVNAME[4];
    char FMTNAME[4];
    DWORD nFMTLength;
    WORD nAudioFormat;
    
    WORD nChannleNumber;
    DWORD nSampleRate;
    DWORD nBytesPerSecond;
    WORD nBytesPerSample;
    WORD    nBitsPerSample;
    char    DATANAME[4];
    DWORD   nDataLength;
};
typedef struct tagHXD_WAVFLIEHEAD HXD_WAVFLIEHEAD;
 
int a_law_pcm_to_wav(const char *pcm_file, const char *wav)
{
    // 开始准备WAV的文件头
    HXD_WAVFLIEHEAD DestionFileHeader;
    DestionFileHeader.RIFFNAME[0] = 'R';
    DestionFileHeader.RIFFNAME[1] = 'I';
    DestionFileHeader.RIFFNAME[2] = 'F';
    DestionFileHeader.RIFFNAME[3] = 'F';
    
    DestionFileHeader.WAVNAME[0] = 'W';
    DestionFileHeader.WAVNAME[1] = 'A';
    DestionFileHeader.WAVNAME[2] = 'V';
    DestionFileHeader.WAVNAME[3] = 'E';
    
    DestionFileHeader.FMTNAME[0] = 'f';
    DestionFileHeader.FMTNAME[1] = 'm';
    DestionFileHeader.FMTNAME[2] = 't';
    DestionFileHeader.FMTNAME[3] = 0x20;
    DestionFileHeader.nFMTLength = 16;  //  表示 FMT 的长度
    DestionFileHeader.nAudioFormat = 6; //这个表示a law PCM
    
    DestionFileHeader.DATANAME[0] = 'd';
    DestionFileHeader.DATANAME[1] = 'a';
    DestionFileHeader.DATANAME[2] = 't';
    DestionFileHeader.DATANAME[3] = 'a';
    DestionFileHeader.nBitsPerSample = 8;
    DestionFileHeader.nBytesPerSample = 1;    //
    DestionFileHeader.nSampleRate = 8000;    //
    DestionFileHeader.nBytesPerSecond = 8000;
    DestionFileHeader.nChannleNumber = 1;
    
    // 文件头的基本部分
    int nFileLen = 0;
    int nSize = sizeof(DestionFileHeader);
    
    FILE *fp_s = NULL;
    FILE *fp_d = NULL;
    
    fp_s = fopen(pcm_file, "rb");
    if (fp_s == NULL)
        return -1;
    
    fp_d = fopen(wav, "wb+");
    if (fp_d == NULL)
        return -2;
    
    
    int nWrite = fwrite(&DestionFileHeader, 1, nSize, fp_d);     //将文件头写入wav文件
    if (nWrite != nSize)
    {
        fclose(fp_s);
        fclose(fp_d);
        return -3;
    }
    
    while( !feof(fp_s))
    {
        char readBuf[4096];
        int nRead = fread(readBuf, 1, 4096, fp_s);    //将pcm文件读到readBuf
        if (nRead > 0)
        {
            fwrite(readBuf, 1, nRead, fp_d);      //将readBuf文件的数据写到wav文件
        }
        
        nFileLen += nRead;
    }
    fseek(fp_d, 0L, SEEK_SET);   //将读写位置移动到文件开头
    
    DestionFileHeader.nRIFFLength = nFileLen - 8 + nSize;
    DestionFileHeader.nDataLength = nFileLen;
    nWrite = fwrite(&DestionFileHeader, 1, nSize, fp_d);   //重新将文件头写入到wav文件
    if (nWrite != nSize)
    {
        fclose(fp_s);
        fclose(fp_d);
        return -4;
    }
    
    fclose(fp_s);
    fclose(fp_d);
    
    return nFileLen;
}
