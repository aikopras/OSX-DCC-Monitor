//
//  RsObject.h
//  dccmon
//
//  Created by Aiko Pras on 23-06-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "FrameStoreObject.h"

@interface RsObject : NSObject
@property (assign) AppDelegate *topObject;

- (void) initDecoding;
- (void) decode_Rs: (FrameObject *) frame;

@end



