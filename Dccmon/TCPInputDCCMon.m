//
//  TCPInputDCCMon.m
//  dccmon
//
//  Created by Aiko Pras on 01-05-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TCPInputDCCMon.h"
#import "FileOutput.h"
#import "AppDelegate.h"
#import "FrameStoreObject.h"
#import "DCCDecode.h"
#import "RSDecode.h"
#import "ValuesToShow.h"

@implementation TCPInputDCCMonClass

@synthesize topObject = _topObject;
@synthesize iStreamDCC = _iStreamDCC;
@synthesize oStreamDCC = _oStreamDCC;

@synthesize dccDecoder = _dccDecoder;
@synthesize rsDecoder = _rsDecoder;
@synthesize ipAddressDCC = _ipAddressDCC;
@synthesize tcpPortDCC = _tcpPortDCC;


// ******************************************************************************************
// **************************** Some C type definitions and declarations ********************
// ******************************************************************************************
#define MAX_FRAME_SIZE 12              // A complete frame is never bigger than this many bytes of data
uint8_t frameByte[MAX_FRAME_SIZE];     // Current byte on the TCP stream
uint8_t frameTCP[MAX_FRAME_SIZE + 8];  // To store the frame that we currently receive from the TCP stream
int frameSize = 0;                     // Size (until now) of the frame that we currently receive from TCP
int totalBytes = 0;                    // Total number of bytes we have received thusfar

// ******************************************************************************************
// ************************************** CONNECT METHODS ***********************************
// ******************************************************************************************
- (void)openDCCMonConnection { 
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
  // Open the TCP connection.
  _ipAddressDCC = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultIpAddressDCCMon"];
  NSHost *host = [NSHost hostWithName:_ipAddressDCC];
  _tcpPortDCC = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultPortDCCMon"];
  NSInteger dccPort = [_tcpPortDCC integerValue];
  // Although we only read input data and therefore would not need an output stream, we still have to open an
  // output stream since the TCP connection will only be closed (TCP FIN) in case we call [_oStreamDCC close] 
  // Depricated [NSStream getStreamsToHost:host port:dccPort   inputStream:&(_iStreamDCC) outputStream:&(_oStreamDCC)];
  [NSStream getStreamsToHostWithName:_ipAddressDCC port:dccPort   inputStream:&(_iStreamDCC) outputStream:&(_oStreamDCC)];
  // Show TCP status line
  NSString *messageText = @"TCP connect attempt to DCCMon";
  messageText = [messageText stringByAppendingString:host.address];
  [_topObject.dccMonStatus setObjectValue:messageText];
  // Check for errors
  if (_iStreamDCC == nil) { NSLog(@"Error opening DCCMon TCP input stream."); return;}       
  [_iStreamDCC retain];
  [_iStreamDCC setDelegate:self];
  [_iStreamDCC scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  [_iStreamDCC open];
  if (_oStreamDCC == nil) { NSLog(@"Error opening DCCMon TCP output stream."); return;}
  [_oStreamDCC retain];
  [_oStreamDCC setDelegate:self];
  [_oStreamDCC scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
  [_oStreamDCC open];
  // Show the progress indicator
  [_topObject dccMonprogressIndicator: 1];
}


- (void)checkDCCMonConnectionStatus {
  NSString *statusText;
  if (_iStreamDCC == nil) {statusText = @"Error: No TCP input stream to DCCMon"; return;}
  NSUInteger newStatus = [self.iStreamDCC streamStatus];
  if (newStatus == NSStreamStatusNotOpen) {statusText = @"DCCMon: Not connected to server";}
  if (newStatus == NSStreamStatusOpening) {statusText = @"DCCMon: Connecting to server ...";}
  if (newStatus == NSStreamStatusOpen)    {statusText = @"DCCMon: Connected to server";}
  if (newStatus == NSStreamStatusError)   {statusText = @"DCCMon: Could not connect to server";[self closeDCCMonConnection];}
  if (newStatus == NSStreamStatusReading) {statusText = @"DCCMon: Reading from server";}
  if (newStatus == NSStreamStatusWriting) {statusText = @"DCCMon: Writing to server";}
  if (newStatus == NSStreamStatusAtEnd)   {statusText = @"DCCMon: Connection to server closing";}
  if (newStatus == NSStreamStatusClosed)  {statusText = @"DCCMon: Connection to server closed";}
  [_topObject.dccMonStatus setObjectValue:statusText];
}


// ******************************************************************************************
// *************************************** RECEIVE METHODS **********************************
// ******************************************************************************************

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
  NSInteger len = 0;  // to check if we have read exactly 1 byte from the TCP stream
  switch(eventCode) {
    case NSStreamEventNone:               { break;}
    case NSStreamEventOpenCompleted:      { [_topObject dccMonprogressIndicator: 0]; break;}
    case NSStreamEventHasSpaceAvailable:  { break;}
    case NSStreamEventErrorOccurred:      { break;}
    case NSStreamEventHasBytesAvailable:  { 
      len = [(NSInputStream *)stream read:frameByte maxLength:1];
      if (len == 1) 
      { // We have an input byte (no error reading from stream)
        // NSLog(@"char = %0x", frameByte[0]);  // for testing
        totalBytes++;
        if (frameByte[0] > 127) 
        { // The byte we've received marks the beginning of a new frame
          // handle first the frame we still hold in frame_Build
          [self handleDCCMonFrame];
          frameTCP[0] = frameByte[0];
          frameSize = 1;
        }
        else 
        { // The byte we've received is not the first byte of a frame. Store it (unless frame is too big)
          // However: what we've received need not (yet) be part of a a valid frame. It can be that we just
          // started receiving and we've not yet seen the frame start. In case we see too many errors, close stream.
          if (frameSize < MAX_FRAME_SIZE) {frameTCP[frameSize] = frameByte[0];}
          if (frameSize > (3 * MAX_FRAME_SIZE)) {[self closeDCCMonConnection];} // close stream
          frameSize ++;
        }
      }
      break; }
    case NSStreamEventEndEncountered:
    { 
      [self closeDCCMonConnection];
      break;
    }
  }
}

- (void)closeDCCMonConnection{
  if (_iStreamDCC != nil) {
    // Stop writing to the output file
    [_topObject.fileOutputObject closeOutputFile];
    // Close and remove the TCP input stream
    [_iStreamDCC close]; // Note that this call will NOT close the TCP connection (TCP FIN)
    [_iStreamDCC removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_iStreamDCC release];
    _iStreamDCC = nil; // stream is instance variable, so reinit it
    // Close and remove the TCP output stream
    [_oStreamDCC close]; // Only this call will close the TCP connection (TCP FIN)
    [_oStreamDCC removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_oStreamDCC release];
    _oStreamDCC = nil; // stream is instance variable, so reinit it
    // Update the status line manually, now that the runloop will not call this anymore
    [_topObject.dccMonStatus setObjectValue:@"TCP connection to DCCMon closed"];
    // Write some logging info
    [_topObject.valuesToShow showStatistics];
    [_topObject dccMonprogressIndicator: 0]; 
  }
}


// ************************************************************************************************************
// ******************************************* ANALYSE RECEIVED FRAME *****************************************
// ************************************************************************************************************
- (void)handleDCCMonFrame 
{ uint8_t parity = 0;         // to calculate the frame parity
  uint8_t dataByte = 0;       // the contents of the data byte that is copied from the TCP stream
  uint8_t hiByte = 0;         // the contents of the (next) hiByte
  int ptrHiByte;              // pointer to the byte containing the (next) hi-bits
  int ptrFrom;                // pointer to the data byte in the array FROM which we copy
  int ptrTo;                  // pointer to the data byte in the array TO which we copy
  struct timeval now;         // to calculate the current millisecond
  //
  // We need to check if the received frame is correct
  // If first byte of the frame is not a start byte, do nothing
  if (frameTCP[0] < 128) {frameSize = 0; return;} // 
  // Minimum length for a frame with data is 4 bytes (address/protocol, data, hi_bits, parity)
  if (frameSize < 5) {frameSize = 0; return;} 
  // Maximum length for a frame with data is MAX_FRAME_SIZE
  // NOTE: the currrent usage of MAX_FRAME_SIZE is confusing, since it refers to both TCP and DCC frame
  if (frameSize > MAX_FRAME_SIZE) {frameSize = 0; return;} 
  // Check parity
  parity = (uint8_t) frameTCP[0];
  for (int i = 1; i < frameSize; i++) {parity ^= (uint8_t) frameTCP[i];}
  if (parity & 127) {frameSize = 0; return;} // Parity error
  // Fill in Frame protocol, board address and the current time
  _topObject.frame.protocol = (frameTCP[0] & 15);
  _topObject.frame.address = ((frameTCP[0] & 112) >> 4);
  // Fill in the current time, including the millisecond
  gettimeofday(&now, NULL);
  _topObject.frame.time = now.tv_sec;
  _topObject.frame.timeMSec = now.tv_usec / 1000;
  // Now we deal with the hi-bits. Hi-bytes are found after 7 data bytes, plus at the end (before the parity byte).
  // Some examples (note: the frameSize is given between brackets at the end):
  //     0          1      2      3      4      5      6      7      8       9     10    11       12
  // proto/addr   data   data   data   data   data   data   data  HiByte  data   data   HiByte  Parity (13)
  // proto/addr   data   data   data   data   data   data   data  HiByte  data  HiByte  Parity         (12)
  // proto/addr   data   data   data   data   data   data   data  HiByte  Parity                       (10)
  // proto/addr   data   data   data   data   data   data  HiByte Parity                                (9)
  // proto/addr   data   data   data   data   data  HiByte Parity                                       (8)
  // proto/addr   data   data   data   data  HiByte Parity                                              (7)
  // Everything starts from the first data byte. Initialy 1 (but may later become 9 (or 17, 25))
  ptrFrom = 1;
  ptrTo = 0;
  _topObject.frame.length = 0;
  // Since there may be multiple hiBytes, we have a while loop to take one hiByte at a time
  while (ptrFrom < (frameSize - 2)) {
    // find the hiByte. In principle 7 bytes further, unless we are near the end of the frame
    ptrHiByte = ptrFrom + 7;
    if (ptrHiByte > (frameSize - 2)) ptrHiByte = (frameSize - 2);
    hiByte = frameTCP[ptrHiByte];
    // copy the data bytes from the TCP frame to the frame->data, and set the hi-bits in each data byte 
    for (int i = ptrFrom; i < ptrHiByte; i++) {
      dataByte = frameTCP[i];
      // Set the high bit in the data byte correctly
      if ((hiByte & 1)) { dataByte |= (1 << 7);}
      // Shift hi_bits
      hiByte >>= 1;
      if (ptrTo == 0) _topObject.frame.byte1 = dataByte;
      if (ptrTo == 1) _topObject.frame.byte2 = dataByte;
      if (ptrTo == 2) _topObject.frame.byte3 = dataByte;
      if (ptrTo == 3) _topObject.frame.byte4 = dataByte;
      if (ptrTo == 4) _topObject.frame.byte5 = dataByte;
      if (ptrTo == 5) _topObject.frame.byte6 = dataByte;
      if (ptrTo == 6) _topObject.frame.byte7 = dataByte;
      if (ptrTo == 7) _topObject.frame.byte8 = dataByte;
      if (ptrTo == 8) _topObject.frame.byte9 = dataByte;
      ptrTo++;
      _topObject.frame.length ++;
      totalBytes++;
    }
    ptrFrom = ptrFrom + 8;
  }
  if (_topObject.frame.length > 100) {;}
  totalBytes++;
  // After reading the complete packet, analyze the packet
  if (_topObject.frame.protocol == 1) [_dccDecoder decode_Dcc:_topObject.frame];
  if (_topObject.frame.protocol == 2) [_rsDecoder decode_Rs:_topObject.frame]; 
  // Save the packet to the output file
  if (_topObject.saveToFile) [_topObject.fileOutputObject writeFrame:_topObject.frame];

}

@end
