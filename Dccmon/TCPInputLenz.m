//
//  TCPInputLenz.m
//  dccmon
//
//  Created by Aiko Pras on 15-10-12.
//
//

#import "TCPInputLenz.h"
#import "FileOutput.h"
#import "AppDelegate.h"
#import "FrameStoreObject.h"
#import "DCCDecode.h"
#import "RSDecode.h"
#import "ValuesToShow.h"

@implementation TCPInputLenzClass


@synthesize topObject = _topObject;
@synthesize dccDecoder = _dccDecoder;
@synthesize rsDecoder =_rsDecoder;
@synthesize iStreamLenz = _iStreamLenz;
@synthesize oStreamLenz = _oStreamLenz;
@synthesize ipAddressLenz = _ipAddressLenz;
@synthesize tcpPortLenz = _tcpPortLenz;


// ******************************************************************************************
// **************************** Some C type definitions and declarations ********************
// ******************************************************************************************
#define MAX_INSTREAM 1              // size TCP input stream from the LENZ interface
#define MAX_INBUFFER 32             // max. TCP input buffer size for the LENZ interface
uint8_t lenzInStream[MAX_INSTREAM]; // TCP input stream buffer for the LENZ interface
uint8_t lenzInBuffer[MAX_INBUFFER]; // LENZ frame buffer holding (parts of) single frame 
int lenzInputBufferSize = 0;        // Size (until now) of the LENZ frame buffer
int totalLenzBytes = 0;             // Total number of bytes we have received thusfar
int lenzSynchronized = 0;           // Indicates if we know the beginning of the frames

// ******************************************************************************************
// ************************************** CONNECT METHODS ***********************************
// ******************************************************************************************
- (void)openLenzConnection{
  // Make sure we can access the properties and methods of the APPDelegate Object
  _topObject = ((AppDelegate *) [[NSApplication sharedApplication] delegate]);
  // Allocate a new RS decoder object and initialise it
  _rsDecoder  = [[RsObject alloc] init];
  [_rsDecoder initDecoding];
  // check if we should copy all input to an output file
  if (_topObject.saveToFile) [_topObject.fileOutputObject openOutputFile];
  // Open the TCP connection.
  _ipAddressLenz = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultIpAddressLenz"];
  NSHost *host = [NSHost hostWithName:_ipAddressLenz];
  _tcpPortLenz = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultPortLenz"];
  NSInteger dccPort = [_tcpPortLenz integerValue];
  // Depricated [NSStream getStreamsToHost:host port:dccPort   inputStream:&(_iStreamLenz) outputStream:&(_oStreamLenz)];
  [NSStream getStreamsToHostWithName:_ipAddressLenz port:dccPort   inputStream:&(_iStreamLenz) outputStream:&(_oStreamLenz)];
  // Show TCP status line
  NSString *messageText = @"TCP connect attempt to Lenz interface at ";
  messageText = [messageText stringByAppendingString:host.address];
  [_topObject.lenzStatus setObjectValue:messageText];
  // Check for errors
  if (_iStreamLenz == nil) { NSLog(@"Error opening Lenz TCP input stream."); return;}
  [_iStreamLenz retain];
  [_iStreamLenz setDelegate:self];
  [_iStreamLenz scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  [_iStreamLenz open];
  if (_oStreamLenz == nil) { NSLog(@"Error opening Lenz TCP output stream."); return;}
  [_oStreamLenz retain];
  [_oStreamLenz setDelegate:self];
  [_oStreamLenz scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  [_oStreamLenz open];
  // Show the progress indicator
  [_topObject lenzprogressIndicator: 1];
}


- (void)checkLenzConnectionStatus{
  NSString *statusText;
  if (_iStreamLenz == nil) {statusText = @"Error: No TCP input stream to Lenz interface"; return;}
  NSUInteger newStatus = [self.iStreamLenz streamStatus];
  if (newStatus == NSStreamStatusNotOpen) {statusText = @"Lenz: Not connected to interface";}
  if (newStatus == NSStreamStatusOpening) {statusText = @"Lenz: Connecting to interface ...";}
  if (newStatus == NSStreamStatusOpen)    {statusText = @"Lenz: Connected to interface";}
  if (newStatus == NSStreamStatusError)   {statusText = @"Lenz: Could not connect to interface";[self closeLenzConnection];}
  if (newStatus == NSStreamStatusReading) {statusText = @"Lenz: Reading from interface";}
  if (newStatus == NSStreamStatusWriting) {statusText = @"Lenz: Writing to interface";}
  if (newStatus == NSStreamStatusAtEnd)   {statusText = @"Lenz: Connection to interface closing";}
  if (newStatus == NSStreamStatusClosed)  {statusText = @"Lenz: Connection to interface closed";}
  [_topObject.lenzStatus setObjectValue:statusText];
  /*
  // TEST
  lenzInputBufferSize = 18;
  lenzInBuffer[0] = 0xFF;
  lenzInBuffer[1] = 0xFD;
  lenzInBuffer[2] = 0x4E;
  lenzInBuffer[3] = 0x19;
  lenzInBuffer[4] = 0x32;
  lenzInBuffer[5] = 0x19;
  lenzInBuffer[6] = 0x31;
  lenzInBuffer[7] = 0x19;
  lenzInBuffer[8] = 0x32;
  lenzInBuffer[9] = 0x19;
  lenzInBuffer[10] = 0x31;
  lenzInBuffer[11] = 0x19;
  lenzInBuffer[12] = 0x32;
  lenzInBuffer[13] = 0x19;
  lenzInBuffer[14] = 0x31;
  lenzInBuffer[15] = 0x19;
  lenzInBuffer[16] = 0x32;
  lenzInBuffer[17] = 0x32;
  [self currentFrameComplete];
  if ([self currentFrameComplete]) {
    [self handleLenzFrame];
    lenzInputBufferSize = 0;
  }
 */
}

// ******************************************************************************************
// *************************************** RECEIVE METHODS **********************************
// ******************************************************************************************

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
  NSInteger len = 0;  // to check if we have read exactly 1 byte from the TCP stream
  switch(eventCode) {
    case NSStreamEventNone:               { break;}
    case NSStreamEventOpenCompleted:      { [_topObject lenzprogressIndicator: 0]; break;}
    case NSStreamEventHasSpaceAvailable:  { break;}
    case NSStreamEventErrorOccurred:      { break;}
    case NSStreamEventHasBytesAvailable:  {
      len = [(NSInputStream *)stream read:lenzInStream maxLength:1];
      if (len == 1) {
        // We have an input byte (no error reading from stream)
        // NSLog(@"char = %0x", lenzInStream[0]);  // for testing
        totalLenzBytes++;
        if (lenzSynchronized) {
          lenzInBuffer[lenzInputBufferSize] = lenzInStream[0];
          lenzInputBufferSize ++;
          if ([self currentFrameComplete]) {
            [self handleLenzFrame];
            lenzInputBufferSize = 0;
          }
        }
        else // we are not sychronized yet. Ignore stream input, unless it has value 0xFF
          if (lenzInStream[0] == 0xFF) {
          // this is likely the start of a new frame, although it may be a valid data value as well. Lets try ...
          lenzSynchronized = 1;
          lenzInBuffer[0] = 0xFF;
          lenzInputBufferSize = 1;
        }
      }
      break; }
    case NSStreamEventEndEncountered:
    {
      [self closeLenzConnection];
      break;
    }
  }
}

- (void)closeLenzConnection{
  if (_iStreamLenz != nil) {
    // Close and remove the TCP input stream
    [_iStreamLenz close]; // Note that this call will NOT close the TCP connection (TCP FIN)
    [_iStreamLenz removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_iStreamLenz release];
    _iStreamLenz = nil; // stream is instance variable, so reinit it
    // Close and remove the TCP output stream
    [_oStreamLenz close]; // Only this call will close the TCP connection (TCP FIN)
    [_oStreamLenz removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_oStreamLenz release];
    _oStreamLenz = nil; // stream is instance variable, so reinit it
    // Update the status line manually, now that the runloop will not call this anymore
    [_topObject.lenzStatus setObjectValue:@"TCP connection to Lenz interface closed"];
    // Write some logging info
    [_topObject lenzprogressIndicator: 0];
  }
}


- (uint8_t)currentFrameComplete {
  if (lenzInputBufferSize < 3) return 0;  // can happen during initialisation
  // calculate what the expected frame size should be
  int command_length = (lenzInBuffer[2] & 0b00001111) + 4;
  // check if frame start is what we expect
  if ((lenzInBuffer[0] == 0xFF) && ((lenzInBuffer[1] == 0xFD) || (lenzInBuffer[1] == 0xFE))) {
    if (command_length == lenzInputBufferSize) return 1; // Yes, current frame complete
    if (command_length >  lenzInputBufferSize) return 0; // Command not yet complete, continue to receive more bytes
  }
  // frame start is not what we expect, so an error. Stop analysing this frame and start from scratch
  lenzSynchronized = 0;
  lenzInputBufferSize = 0;
  return 0;
}


- (void)handleLenzFrame {
  uint8_t parity = 0;         // to calculate the parity
  int xor_length;             // determines the number of bytes included in the parity (X-OR) check
  int broadcast_command;      // stores which Xpressbus broadcast command has been received
  struct timeval now;         // to calculate the current millisecond
  // Note we don't need to check if header of the received frame is correct: was done by currentFrameComplete
  // We do check, however, if this is a braodcast packet. If not, don't process input frame
  if (lenzInBuffer[1] != 0xFD) {lenzInputBufferSize = 0; return;};
  // Next check if this is a feedback packet. If not, don't process input frame
  broadcast_command = (lenzInBuffer[2] & 0b11110000);
  if (broadcast_command != 0x40) {lenzInputBufferSize = 0; return;};
  // So we have a boroadcast feedback packet. 
  // Check parity
  parity = (uint8_t) lenzInBuffer[2];
  xor_length = (lenzInBuffer[2] & 0b00001111) + 4;
  for (int i = 3; i < xor_length; i++) {parity ^= (uint8_t) lenzInBuffer[i];}
  if (parity) {lenzInputBufferSize = 0; return;} // Parity error
  // Fill in Frame protocol, board address and the current time
  _topObject.frame.protocol = 2; // RS-bus feedback
  _topObject.frame.address = 129; // Let's use this value for the Lenz Ethernet interface
  _topObject.frame.length = 2;
  // Fill in the current time, including the millisecond
  gettimeofday(&now, NULL);
  _topObject.frame.time = now.tv_sec;
  _topObject.frame.timeMSec = now.tv_usec / 1000;
  // Fill in the RS-bus fields. Note that a single xpressbus feedback packet may include upto 7 feedback messages
  // We'll handle them one by one, in a relative simple way
  // Message 1
  _topObject.frame.byte1 = lenzInBuffer[3];
  _topObject.frame.byte2 = lenzInBuffer[4];
  [_rsDecoder decode_Rs:_topObject.frame];
  if (_topObject.saveToFile) [_topObject.fileOutputObject writeFrame:_topObject.frame];
  // Message 2
  if (lenzInputBufferSize < 7) {lenzInputBufferSize = 0; return;};
  _topObject.frame.byte1 = lenzInBuffer[5];
  _topObject.frame.byte2 = lenzInBuffer[6];
  [_rsDecoder decode_Rs:_topObject.frame];
  if (_topObject.saveToFile) [_topObject.fileOutputObject writeFrame:_topObject.frame];
  // Message 3
  if (lenzInputBufferSize < 9) {lenzInputBufferSize = 0; return;};
  _topObject.frame.byte1 = lenzInBuffer[7];
  _topObject.frame.byte2 = lenzInBuffer[8];
  [_rsDecoder decode_Rs:_topObject.frame];
  if (_topObject.saveToFile) [_topObject.fileOutputObject writeFrame:_topObject.frame];
  // Message 4
  if (lenzInputBufferSize < 11) {lenzInputBufferSize = 0; return;};
  _topObject.frame.byte1 = lenzInBuffer[9];
  _topObject.frame.byte2 = lenzInBuffer[10];
  [_rsDecoder decode_Rs:_topObject.frame];
  if (_topObject.saveToFile) [_topObject.fileOutputObject writeFrame:_topObject.frame];
  // Message 5
  if (lenzInputBufferSize < 13) {lenzInputBufferSize = 0; return;};
  _topObject.frame.byte1 = lenzInBuffer[11];
  _topObject.frame.byte2 = lenzInBuffer[12];
  [_rsDecoder decode_Rs:_topObject.frame];
  if (_topObject.saveToFile) [_topObject.fileOutputObject writeFrame:_topObject.frame];
  // Message 6
  if (lenzInputBufferSize < 15) {lenzInputBufferSize = 0; return;};
  _topObject.frame.byte1 = lenzInBuffer[13];
  _topObject.frame.byte2 = lenzInBuffer[14];
  [_rsDecoder decode_Rs:_topObject.frame];
  if (_topObject.saveToFile) [_topObject.fileOutputObject writeFrame:_topObject.frame];
  // Message 7
  if (lenzInputBufferSize < 17) {lenzInputBufferSize = 0; return;};
  _topObject.frame.byte1 = lenzInBuffer[15];
  _topObject.frame.byte2 = lenzInBuffer[16];
  [_rsDecoder decode_Rs:_topObject.frame];
  if (_topObject.saveToFile) [_topObject.fileOutputObject writeFrame:_topObject.frame];
  lenzInputBufferSize = 0;
}

@end
