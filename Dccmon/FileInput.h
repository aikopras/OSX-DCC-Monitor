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
@property (assign) DccObject *dccDecoder;
@property (assign) RsObject *rsDecoder;
@property (retain) NSInputStream *infile;

@property int intro_is_read;

- (void)openFile:(NSString *)path;
- (void)closeFile;

@end
