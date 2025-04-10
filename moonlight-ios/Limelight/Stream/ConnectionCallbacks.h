//
//  ConnectionCallbacks.h
//  Moonlight
//
//  Created by Cameron Gutman on 11/1/20.
//  Copyright © 2020 Moonlight Game Streaming Project. All rights reserved.
//

typedef void(^LaunchOptionCompletion)(NSInteger);

@protocol ConnectionCallbacks <NSObject>

- (void) connectionStarted;
- (void) connectionTerminated:(int)errorCode;
- (void) stageStarting:(const char*)stageName;
- (void) stageComplete:(const char*)stageName;
- (void) stageFailed:(const char*)stageName withError:(int)errorCode portTestFlags:(int)portTestFlags;
- (void) launchFailed:(NSString*)message errorCode:(NSInteger)code;
- (void) launchFailed:(NSString*)currentApp device:(NSString *)currentDevice errorCode:(NSInteger)code isSameDevice:(BOOL)isSameDevice completion:(LaunchOptionCompletion)Completion;
- (void) rumble:(unsigned short)controllerNumber lowFreqMotor:(unsigned short)lowFreqMotor highFreqMotor:(unsigned short)highFreqMotor;
- (void) connectionStatusUpdate:(int)status;
- (void) setHdrMode:(bool)enabled;
- (void) rumbleTriggers:(uint16_t)controllerNumber leftTrigger:(uint16_t)leftTrigger rightTrigger:(uint16_t)rightTrigger;
- (void) setMotionEventState:(uint16_t)controllerNumber motionType:(uint8_t)motionType reportRateHz:(uint16_t)reportRateHz;
- (void) setControllerLed:(uint16_t)controllerNumber r:(uint8_t)r g:(uint8_t)g b:(uint8_t)b;
- (void) videoContentShown;

@end
