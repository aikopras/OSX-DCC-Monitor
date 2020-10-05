//
//  FileInput.m
//  dccmon
//
//  Created by Aiko Pras on 16-05-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FileInput.h"
#import "FileOutput.h"
#import "AppDelegate.h"
#import "FrameStoreObject.h"
#import "DCCDecode.h"
#import "RSDecode.h"
#import "ValuesToShow.h"


@implementation FileInputClass

@synthesize topObject = _topObject;
@synthesize infile = _infile;
@synthesize dccDecoder = _dccDecoder;
@synthesize rsDecoder =_rsDecoder;
@synthesize intro_is_read = _intro_is_read;


// ***********************************************************************
// ******************************** FILE READ ****************************
// ***********************************************************************
- (void)openFile:(NSString *)path {
  // Make sure we can access the properties and methods of the APPDelegate Object
  _topObject = ((AppDelegate *) [[NSApplication sharedApplication] delegate]);
  // Allocate a new DCC decoder object and initialise it
  _dccDecoder  = [[DccObject alloc] init];
  [_dccDecoder initDecoding];
  // Allocate a new RS decoder object and initialise it
  _rsDecoder  = [[RsObject alloc] init];
  [_rsDecoder initDecoding];
  // check if we should copy all input to an output file
  if (_topObject.saveToFile) [_topObject.fileOutputObject openOutputFile];
  // initialise the control flag _intro_is_read
  _intro_is_read = 0;
  // Initialise a new fileInput object with the given path, schedule it in the runloop, and open
  _infile = [[NSInputStream alloc] initWithFileAtPath:path];
  [_infile setDelegate:self];
  [_infile scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  [_infile open];
  [_topObject dccMonprogressIndicator: 1];
  // Show TCP status line
  NSString *messageText = @"Reading from: ";
  messageText = [messageText stringByAppendingString:path];
  [_topObject.dccMonStatus setObjectValue:messageText];
  messageText = @"";
  [_topObject.lenzStatus setObjectValue:messageText];
}


- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
  // if (stream != _infile) 
  //   NSLog(@"stream is NOT infile ...");  // This sometimes happens. No clue why
  switch(eventCode) {
    case NSStreamEventNone:               { break;}
    case NSStreamEventOpenCompleted:      { break;}
    case NSStreamEventHasSpaceAvailable:  { break;}
    case NSStreamEventErrorOccurred:      { break;}
    case NSStreamEventHasBytesAvailable:  {
      uint8_t intro[10];
      uint8_t header[12];
      uint8_t contents[12];
      NSInteger len = 0;
      int i = 0;
      for(i = 0; i < 10;i++){ intro[i] = 0;} 
      for(i = 0; i < 12;i++){ header[i] = 0;}  
      for(i = 0; i < 12;i++){ contents[i] = 0;}
      if (_intro_is_read == 0) { // Read 10 bytes
        len = [(NSInputStream *)stream read:intro maxLength:10];
        _intro_is_read = 1;
      }
      else {
        // Read one complete packet, as received from the monitoring board
        // Start with the 12 byte header. Assign all header bytes to the frame variable, which is a struct of type s_frame
        len = [(NSInputStream *)stream read:header maxLength:12];
        if ((len !=0) && (len !=12)) NSLog(@"len too small: %ld", len);
        if (len == 12) { 
          _topObject.frame.retval = header[0];   // Should be 0 for a good packet
          _topObject.frame.address = header[1];
          _topObject.frame.protocol = header[2];
          // Read the time in msec
          _topObject.frame.timeMSec = header[3] * 256 + header[4];
          // Read the time in seconds since 1-1-1970. Note that we read 6 bytes from the input file
          _topObject.frame.time = 0;
          for(i = 5; i <= 10; i++) {_topObject.frame.time = _topObject.frame.time * 256 + header[i];}
          _topObject.frame.length = header[11];
          if ((_topObject.frame.length > 0) & (_topObject.frame.length <= 9)) {len = [(NSInputStream *)stream read:contents maxLength:header[11]];}
          // Below seems a bit stupid, but having simple byte Arrays as properties do not work
          if (len > 0) _topObject.frame.byte1 = contents[0];
          if (len > 1) _topObject.frame.byte2 = contents[1];
          if (len > 2) _topObject.frame.byte3 = contents[2];
          if (len > 3) _topObject.frame.byte4 = contents[3];
          if (len > 4) _topObject.frame.byte5 = contents[4];
          if (len > 5) _topObject.frame.byte6 = contents[5];
          if (len > 6) _topObject.frame.byte7 = contents[6];
          if (len > 7) _topObject.frame.byte8 = contents[7];
          if (len > 8) _topObject.frame.byte9 = contents[8];
          // After reading the complete packet, analyze the packet
          if (_topObject.frame.protocol == 1) [_dccDecoder decode_Dcc:_topObject.frame];
          if (_topObject.frame.protocol == 2) [_rsDecoder decode_Rs:_topObject.frame];
          // Save the packet to the output file
          if (_topObject.saveToFile) [_topObject.fileOutputObject writeFrame:_topObject.frame];
        }
      }
      break; }
    case NSStreamEventEndEncountered:
    { 
      [self closeFile];
      break;
    }
  }
}

- (void)closeFile {
  if (_infile != nil) {
    [_infile close];
    [_infile removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_infile release];
    _infile = nil; // stream is ivar, so reinit it
    // reinitialise variables / close writing to output
    _intro_is_read = 0;
    [_topObject.fileOutputObject closeOutputFile];
    // Write some logging info
    [_topObject.valuesToShow showStatistics];
    [_topObject dccMonprogressIndicator: 0]; 
    // Clear TCP status line
    NSString *messageText = @"";
    [_topObject.dccMonStatus setObjectValue:messageText];
  }
}

@end
