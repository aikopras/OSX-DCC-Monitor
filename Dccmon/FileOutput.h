//
//  FileOutput.h
//  dccmon
//
//  Created by Aiko Pras on 30-06-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

@interface FileOutputClass : NSObject <NSStreamDelegate>

@property (assign) AppDelegate *topObject;
@property (retain) NSOutputStream *outfile;
@property int intro_is_written;

- (void)openOutputFile;
- (void)closeOutputFile;
- (void)writeFrame: (FrameObject *) frame;

@end
