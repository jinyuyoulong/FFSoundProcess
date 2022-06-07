//
//  pcm_wav.h
//  Test
//
//  Created by Jiangang Yang on 2021/2/8.
//  Copyright © 2021 msb. All rights reserved.
//

#ifndef pcm_wav_h
#define pcm_wav_h

#include <stdio.h>
int convertPcm2Wav(char *src_file, char *dst_file, int channels, int sample_rate);
#endif /* pcm_wav_h */
