//
//  TCPInputDCCMon.m
//  dccmon
//
//  Created by Aiko Pras on 01-05-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
//  2026: The TCP connection is now handled by TCPSocketClass (Network framework), instead of NSStream.
//  TCPSocketClass reports state changes and received data via the delegate methods below.
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
@synthesize socketDCC = _socketDCC;       // 2026: replaces iStreamDCC and oStreamDCC

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
#define CONNECT_TIMEOUT 3              // Seconds to wait for the DCCMon server before giving up

// ******************************************************************************************
// ************************************** CONNECT METHODS ***********************************
// ******************************************************************************************
- (void)openDCCMonConnection { 
  // Make sure we can access the properties and methods of the APPDelegate Object
  _topObject = ((AppDelegate *) [[NSApplication sharedApplication] delegate]);
  // Allocate a DCC decoder object (2026: only the first time) and initialise it
  if (_dccDecoder == nil) _dccDecoder = [[DccObject alloc] init];
  [_dccDecoder initDecoding];
  // Allocate a RS decoder object (2026: only the first time) and initialise it
  if (_rsDecoder == nil) _rsDecoder = [[RsObject alloc] init];
  [_rsDecoder initDecoding];
  // 2026: Forget the (part of a) frame that may remain from a previous connection
  frameSize = 0;
  // check if we should copy all input to an output file
  if (_topObject.saveToFile) [_topObject.fileOutputObject openOutputFile];
  // Open the TCP connection.
  _ipAddressDCC = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultIpAddressDCCMon"];
  _tcpPortDCC = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultPortDCCMon"];
  // Show the progress indicator
  [_topObject dccMonprogressIndicator: 1];
  // 2026: The connection is now made by TCPSocketClass, which reports back via the delegate methods below.
  // The status line is updated by tcpSocket:didChangeState:reason:
  if (_socketDCC == nil) _socketDCC = [[TCPSocketClass alloc] init];
  [_socketDCC setDelegate:self];
  [_socketDCC openToHost:_ipAddressDCC port:_tcpPortDCC timeout:CONNECT_TIMEOUT];
}


- (void)closeDCCMonConnection {
  // 2026: Closing the socket results in a call of tcpSocket:didChangeState:reason: with TCP_SOCKET_CLOSED,
  // which updates the status line and cleans up (see connectionEnded)
  [_socketDCC close];
}


// 2026: YES while connecting or connected (formerly tested via iStreamDCC != nil)
- (BOOL)isOpen {
  return [_socketDCC isOpen];
}


// 2026: Release the socket. The delegate is cleared first, so the socket does not call back into this object.
// (The socket object itself stays alive until its connection has been cancelled completely.)
- (void)dealloc {
  [_socketDCC setDelegate:nil];
  [_socketDCC close];
  [_socketDCC release];
  [_dccDecoder release];
  [_rsDecoder release];
  [super dealloc];
}


// 2026: Clean up after the connection has been closed, could not be established, or was lost
- (void)connectionEnded {
  // Stop writing to the output file
  [_topObject.fileOutputObject closeOutputFile];
  // Write some logging info
  [_topObject.valuesToShow showStatistics];
  [_topObject dccMonprogressIndicator: 0];
}


// ******************************************************************************************
// ******************************* TCP SOCKET DELEGATE METHODS ******************************
// ******************************************************************************************
// 2026: Called by TCPSocketClass (on the main thread) after every state change of the connection.
// Replaces checkDCCMonConnectionStatus, which was called every second
- (void)tcpSocket:(TCPSocketClass *)socket didChangeState:(tcpSocketState_t)state reason:(NSString *)reason {
  NSString *statusText = @"";
  switch (state) {
    case TCP_SOCKET_CONNECTING: {
      statusText = [@"TCP connect attempt to DCCMon at " stringByAppendingString:_ipAddressDCC];
      break; }
    case TCP_SOCKET_CONNECTED: {
      statusText = @"DCCMon: Connected to server";
      [_topObject dccMonprogressIndicator: 0];
      break; }
    case TCP_SOCKET_FAILED: {
      if ([socket lastErrorCode] == ETIMEDOUT) statusText = @"DCCMon: No response from server";
      else statusText = [NSString stringWithFormat:@"DCCMon: Could not connect to server (%@)", reason];
      [self connectionEnded];
      break; }
    case TCP_SOCKET_LOST: {
      statusText = [NSString stringWithFormat:@"DCCMon: Connection to server lost (%@)", reason];
      [self connectionEnded];
      break; }
    case TCP_SOCKET_CLOSED: {
      if (reason == nil) statusText = @"TCP connection to DCCMon closed";
      else statusText = [NSString stringWithFormat:@"TCP connection to DCCMon closed (%@)", reason];
      [self connectionEnded];
      break; }
  }
  [_topObject.dccMonStatus setObjectValue:statusText];
}


// 2026: Called by TCPSocketClass (on the main thread) for every chunk of data received from the DCCMon server
- (void)tcpSocket:(TCPSocketClass *)socket didReceiveBytes:(const uint8_t *)bytes length:(NSUInteger)length {
  for (NSUInteger i = 0; i < length; i++) {
    if (![_socketDCC isOpen]) break;    // handleDCCMonByte may close the connection
    [self handleDCCMonByte:bytes[i]];
  }
}


// ******************************************************************************************
// *************************************** RECEIVE METHODS **********************************
// ******************************************************************************************
// 2026: Formerly the NSStreamEventHasBytesAvailable part of stream:handleEvent:. The logic is unchanged.
- (void)handleDCCMonByte:(uint8_t)byte
{
  frameByte[0] = byte;
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
