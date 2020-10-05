//
//  FileOutput.m
//  dccmon
//
//  Created by Aiko Pras on 30-06-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "FileOutput.h"

@implementation FileOutputClass

@synthesize topObject = _topObject;
@synthesize outfile = _outfile;
@synthesize intro_is_written = _intro_is_written;


// ***********************************************************************
// ******************************** FILE WRITE ***************************
// ***********************************************************************
- (void)openOutputFile {
  if (_outfile != nil) return; // file is already open
  // Make sure we can access the properties and methods of the APPDelegate Object
  _topObject = ((AppDelegate *) [[NSApplication sharedApplication] delegate]);
  // Initialise the flag that determine the intro is written
  // According to the documentation we should also have a flag to indicate that
  // the output file is ready for writing (this flag should have been set after
  // an NSStreamEventHasSpaceAvailable event), but it turns out that this event
  // is not always reliably flagged. Therefore we just write when the application
  // has data available, and in case the output is not ready we'll have an error
  // event, and close the outfile
  _intro_is_written = 0;
  // Initialise a new fileOutput object with the given path, schedule it in the runloop, and open
  NSString *path = [self CurrentTimeAsString];
  _outfile = [[NSOutputStream alloc] initToFileAtPath:path append:0];
  [_outfile setDelegate:self];
  [_outfile scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  [_outfile open];
}


- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
  switch(eventCode) {
    case NSStreamEventNone:               { break;}
    case NSStreamEventHasBytesAvailable:  { break;}
    case NSStreamEventEndEncountered:     { break;}
    case NSStreamEventHasSpaceAvailable:  { 
      if (_intro_is_written == 0) {
        [self writeIntro];
        _intro_is_written = 1;
      }
      break;
    }
    case NSStreamEventOpenCompleted:      {
      break;
    }
    case NSStreamEventErrorOccurred: {
      [self closeOutputFile]; 
      break;
    }
  }
}


- (void)closeOutputFile{
  if (_outfile != nil) {
    [_outfile close];
    [_outfile removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_outfile release];
    _outfile = nil;
  }
}


- (void)writeIntro{
  uint8_t intro[10];
  NSInteger len = 0;
  intro[0] = 'D';
  intro[1] = 'C';
  intro[2] = 'C';
  intro[3] = 'M';
  intro[4] = 'O';
  intro[5] = 'N';
  intro[6] = ' ';
  intro[7] = '2';
  intro[8] = '.';
  intro[9] = '0';
  len = [_outfile write:intro maxLength:10];
}


- (void)writeFrame: (FrameObject *) frame{
  uint8_t data[24];
  // Start with the 12 byte header. Write all header bytes from the frame variable, which is a struct of type s_frame
  data[0]  = _topObject.frame.retval; 
  data[1]  = _topObject.frame.address;
  data[2]  = _topObject.frame.protocol;
  // Store the time in milliseconds in data[3] and [4]
  data[3]  = _topObject.frame.timeMSec >> 8;
  data[4]  = _topObject.frame.timeMSec;
  // Store time_t as 6 bytes (48 bits). Note that time_t actually represents a long (64 bit signed integer)  data[5] = time_temp >> 40;
  data[5]  = _topObject.frame.time >> 40;
  data[6]  = _topObject.frame.time >> 32;
  data[7]  = _topObject.frame.time >> 24;
  data[8]  = _topObject.frame.time >> 16;
  data[9]  = _topObject.frame.time >> 8;
  data[10] = _topObject.frame.time;
  data[11] = _topObject.frame.length;
  // Continue with the remaining data bytes;
  data[12] = _topObject.frame.byte1;
  data[13] = _topObject.frame.byte2;
  data[14] = _topObject.frame.byte3;
  data[15] = _topObject.frame.byte4;
  data[16] = _topObject.frame.byte5;
  data[17] = _topObject.frame.byte6;
  data[18] = _topObject.frame.byte7;
  data[19] = _topObject.frame.byte8;
  data[20] = _topObject.frame.byte9;
  // Write data to the outfile 
  [_outfile write:data maxLength:(12 + _topObject.frame.length)];
}


// ***********************************************************************
// ******************************** FILE NAME ****************************
// ***********************************************************************
- (NSString *)CurrentTimeAsString {
  // To create a string holding the current date and time
  time_t curentTime = time (NULL);
  NSDate *currentDate = [NSDate dateWithTimeIntervalSince1970:curentTime];
  // from NSDate to a formatted NSString
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"yyyy-MM-dd_HH_mm_ss"];
  NSString *myDate = [formatter stringFromDate:currentDate];
  [formatter release];
  NSString *myString = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultSaveDirectory"];
  myString = [myString stringByAppendingString:myDate];
  myString = [myString stringByAppendingString:@".dcc"];
  return myString;
}


@end

