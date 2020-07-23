#import "SoundService.h"
#import "AppDelegate.h"

#import <AVFoundation/AVFoundation.h>

// private implementation
//
@interface SoundService (Private)
+ (AVAudioPlayer *)initPlayerWithPath:(NSString *)path;
@end

@implementation SoundService (Private)

+ (AVAudioPlayer *)initPlayerWithPath:(NSString *)path {
  NSURL *url = [NSURL
      fileURLWithPath:[NSString
                          stringWithFormat:@"%@/%@",
                                           [[NSBundle mainBundle] resourcePath],
                                           path]];

  NSError *error;
  AVAudioPlayer *player =
      [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
  if (player == nil) {
  }

  return player;
}

@end

@interface SoundService () {
@private
  AVAudioPlayer *playerRingBackTone;
  AVAudioPlayer *playerRingTone;

  BOOL speakerOn;
}
@end
//
// default implementation
//
@implementation SoundService

- (SoundService *)init {
  if ((self = [super init])) {
  }
  return self;
}

- (void)dealloc {

#define RELEASE_PLAYER(player)                                                 \
  if (player) {                                                                \
    if (player.playing) {                                                      \
      [player stop];                                                           \
    }                                                                          \
  }

  RELEASE_PLAYER(playerRingBackTone);
  RELEASE_PLAYER(playerRingTone);

#undef RELEASE_PLAYER
}

//
// SoundService
//
- (BOOL)speakerEnabled:(BOOL)enabled {
  AVAudioSession *session = [AVAudioSession sharedInstance];
  AVAudioSessionCategoryOptions options = session.categoryOptions;

  if (enabled) {
    options |= AVAudioSessionCategoryOptionDefaultToSpeaker;
  } else {
    options &= ~AVAudioSessionCategoryOptionDefaultToSpeaker;
  }

  NSError *error = nil;
  [session setCategory:AVAudioSessionCategoryPlayAndRecord
           withOptions:options
                 error:&error];
  if (error != nil) {
    return NO;
  }
  return YES;
}

- (BOOL)isSpeakerEnabled {
  return speakerOn;
}

- (BOOL)playRingTone {
  if (!playerRingTone) {
    playerRingTone = [SoundService initPlayerWithPath:@"ringtone.mp3"];
  }
  if (playerRingTone) {
    playerRingTone.numberOfLoops = -1;
    [self speakerEnabled:YES];
    [playerRingTone play];
    return YES;
  }
  return NO;
}

- (BOOL)stopRingTone {
  if (playerRingTone && playerRingTone.playing) {
    [playerRingTone stop];
  }
  return YES;
}

- (BOOL)playRingBackTone {
  if (!playerRingBackTone) {
    playerRingBackTone = [SoundService initPlayerWithPath:@"ringtone.mp3"];
  }
  if (playerRingBackTone) {
    playerRingBackTone.numberOfLoops = -1;
    [self speakerEnabled:NO];
    [playerRingBackTone play];
    return YES;
  }

  return NO;
}

- (BOOL)stopRingBackTone {
  if (playerRingBackTone && playerRingBackTone.playing) {
    [playerRingBackTone stop];
  }
  return YES;
}

@end
