//
//  FileInput.h
//  dccmon
//
//  Created by Aiko Pras on 16-05-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DCCDecode.h"

@interface FileInputClass : NSObject <NSStreamDelegate>

@property (assign) AppDelegate *topObject;
@property (retain) DccObject *dccDecoder;   // 2026: retain instead of assign, since owned by this object
@property (retain) RsObject *rsDecoder;     // 2026: retain instead of assign, since owned by this object
@property (retain) NSInputStream *infile;

@property int intro_is_read;

- (void)openFile:(NSString *)path;
- (void)closeFile;

@end
