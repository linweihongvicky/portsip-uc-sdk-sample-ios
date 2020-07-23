
#import <Foundation/Foundation.h>
#include <AudioToolbox/AudioToolbox.h>

#import <AVFoundation/AVFoundation.h>

@interface SoundService : NSObject

- (BOOL)speakerEnabled:(BOOL)enabled;
- (BOOL)isSpeakerEnabled;

- (BOOL)playRingTone;
- (BOOL)stopRingTone;

- (BOOL)playRingBackTone;
- (BOOL)stopRingBackTone;

@end
