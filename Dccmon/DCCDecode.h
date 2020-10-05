//
//  DCC.h
//  dccmon
//
//  Created by Aiko Pras on 15-05-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "FrameStoreObject.h"

@interface DccObject : NSObject
@property (assign) AppDelegate *topObject;
@property (assign) uint8_t LenzCor;

- (void) initDecoding;
- (void) decode_Dcc: (FrameObject *) frame;

@end
