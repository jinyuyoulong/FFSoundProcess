//
//  PCM2Wav.h
//  Test
//
//  Created by Jiangang Yang on 2021/2/8.
//  Copyright © 2021 msb. All rights reserved.
//

#ifndef PCM2Wav_h
#define PCM2Wav_h

#include <stdio.h>

#include <string.h>
 

typedef unsigned long       DWORD;
typedef unsigned char       BYTE;
typedef unsigned short      WORD;
 
int a_law_pcm_to_wav(const char *pcm_file, const char *wav);

#endif /* PCM2Wav_h */
