//
//  ValuesToShow.h
//  dccmon
//
//  Created by Aiko Pras on 17-05-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

@interface ValuesToShow : NSObject

@property (assign) AppDelegate *topObject;

@property (assign) NSString *stringTime;
@property (assign) NSString *stringLocAddress;
@property (assign) NSString *stringLocSpeed;
@property (assign) NSString *stringLocDirection;
@property (assign) NSString *stringCvNumber;
@property (assign) NSString *stringCvValue;
@property (assign) NSString *stringRsAddress;
@property (assign) NSMutableAttributedString *aStringLocFunctions;
@property (assign) NSMutableAttributedString *aStringSwitches;
@property (assign) NSMutableAttributedString *aStringFeedback;

@property NSInteger alwaysShowLoc;
@property NSInteger alwaysShowFeedback;

@property NSInteger counter_dcc_packets;
@property NSInteger counter_reset;
@property NSInteger counter_idle;
@property NSInteger counter_service_mode;
@property NSInteger counter_speed;
@property NSInteger counter_F0_F12;
@property NSInteger counter_F13_F28;
@property NSInteger counter_CV_Access;
@property NSInteger counter_accessory;
@property NSInteger counter_feedback;
@property NSInteger counter_forFutureUse;
@property NSInteger counter_parityError;


- (void)dccTime: (time_t) timeStamp mSec:(uint16_t)timeMSec;
- (void)dccLocAddress: (int) locAddress;
- (void)dccLocSpeed: (uint8_t) speed;
- (void)dccLocDirection: (uint8_t) direction;
- (void)dccLocFunctions1: (uint8_t) functions;
- (void)dccLocFunctions2: (uint8_t) functions;
- (void)dccLocFunctions3: (uint8_t) functions;
- (void)dccLocFunctions4: (uint8_t) functions;
- (void)dccLocCv:         (int)cvNumber value:(uint8_t)status;
- (void)dccLocCvBit:      (int)cvNumber value:(uint8_t)status;
- (void)dccLocCvVerify:   (int)cvNumber;
- (void)dccSwitch:        (int)address status:(uint8_t)status;
- (void)rsFeedback:       (uint8_t)address value:(uint8_t)value nibble:(uint8_t)nibble;

- (void)initValuesToShow;
- (void)newPacket;
- (void)showPacket;
- (void)showStatistics;

@end
