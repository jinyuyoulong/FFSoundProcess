//
//  MSBAudioMIDITool.m
//  MSBSoundProcess
//
//  Created by 范金龙 on 2021/5/20.
//

#import "MSBAudioMIDITool.h"

@implementation MSBAudioMIDITool
static float referenceA = 440.0;

/// 频率转midi值
/// @param frequency 频率
+ (int) snapFreqToMIDI:(float) frequency {

    int midiNote = (12*(log10(frequency/referenceA)/log10(2)) + 57) + 0.5;
    return midiNote;
}
+ (NSString*) midiToString: (int) midiNote {
    if (midiNote < 0) {
        return @"";
    }
    NSArray *noteStrings = [[NSArray alloc] initWithObjects:@"C", @"C#", @"D", @"D#", @"E", @"F", @"F#", @"G", @"G#", @"A", @"A#", @"B", nil];
    return [noteStrings objectAtIndex:midiNote%12];
}
@end
