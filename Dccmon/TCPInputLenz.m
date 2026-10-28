//
//  TCPInputLenz.m
//  dccmon
//
//  Created by Aiko Pras on 15-10-12.
//
//  2026: The TCP connection is now handled by TCPSocketClass (Network framework), instead of NSStream.
//  TCPSocketClass reports state changes and received data via the delegate methods below.
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
@synthesize socketLenz = _socketLenz;     // 2026: replaces iStreamLenz and oStreamLenz
@synthesize ipAddressLenz = _ipAddressLenz;
@synthesize tcpPortLenz = _tcpPortLenz;
@synthesize keepAliveTimer = _keepAliveTimer;


// ******************************************************************************************
// **************************** Some C type definitions and declarations ********************
// ******************************************************************************************
#define MAX_INBUFFER 32             // max. TCP input buffer size for the LENZ interface
uint8_t lenzInBuffer[MAX_INBUFFER]; // LENZ frame buffer holding (parts of) single frame 
int lenzInputBufferSize = 0;        // Size (until now) of the LENZ frame buffer
int totalLenzBytes = 0;             // Total number of bytes we have received thusfar
int lenzSynchronized = 0;           // Indicates if we know the beginning of the frames
#define CONNECT_TIMEOUT 3           // Seconds to wait for the Lenz interface before giving up
// 2026: XpressNet LAN keep-alive (Lenz specification 23151, section 2.1 "Interface Status Befehl").
// The interface stops sending broadcasts to a LAN device it has not received anything from for some time.
#define KEEPALIVE_INTERVAL 10       // Seconds between two Interface Status commands
#define STATUS_ANSWER_TIMEOUT 5.0   // Seconds to wait for the answer (normal command timeout of the interface)
const uint8_t interfaceStatusCommand[] = {0xFF, 0xFE, 0xF1, 0x01, 0xF0};

// ******************************************************************************************
// ************************************** CONNECT METHODS ***********************************
// ******************************************************************************************
- (void)openLenzConnection{
  // Make sure we can access the properties and methods of the APPDelegate Object
  _topObject = ((AppDelegate *) [[NSApplication sharedApplication] delegate]);
  // Allocate a RS decoder object (2026: only the first time) and initialise it
  if (_rsDecoder == nil) _rsDecoder = [[RsObject alloc] init];
  [_rsDecoder initDecoding];
  // 2026: Forget the (part of a) frame that may remain from a previous connection
  lenzSynchronized = 0;
  lenzInputBufferSize = 0;
  // check if we should copy all input to an output file
  if (_topObject.saveToFile) [_topObject.fileOutputObject openOutputFile];
  // Open the TCP connection.
  _ipAddressLenz = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultIpAddressLenz"];
  _tcpPortLenz = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultPortLenz"];
  // Show the progress indicator
  [_topObject lenzprogressIndicator: 1];
  // 2026: The connection is now made by TCPSocketClass, which reports back via the delegate methods below.
  // The status line is updated by tcpSocket:didChangeState:reason:
  if (_socketLenz == nil) _socketLenz = [[TCPSocketClass alloc] init];
  [_socketLenz setDelegate:self];
  [_socketLenz openToHost:_ipAddressLenz port:_tcpPortLenz timeout:CONNECT_TIMEOUT];
}


- (void)closeLenzConnection{
  // 2026: Closing the socket results in a call of tcpSocket:didChangeState:reason: with TCP_SOCKET_CLOSED,
  // which updates the status line and cleans up (see connectionEnded)
  [_socketLenz close];
}


// 2026: YES while connecting or connected
- (BOOL)isOpen {
  return [_socketLenz isOpen];
}


// 2026: Release the socket. The delegate is cleared first, so the socket does not call back into this object.
// (The socket object itself stays alive until its connection has been cancelled completely.)
- (void)dealloc {
  [_socketLenz setDelegate:nil];
  [_socketLenz close];
  [_socketLenz release];
  [_rsDecoder release];
  [super dealloc];
}


// 2026: Clean up after the connection has been closed, could not be established, or was lost
- (void)connectionEnded {
  [_topObject lenzprogressIndicator: 0];
  [self stopKeepAlive];
}


// ******************************************************************************************
// ******************************* TCP SOCKET DELEGATE METHODS ******************************
// ******************************************************************************************
// 2026: Called by TCPSocketClass (on the main thread) after every state change of the connection.
// Replaces checkLenzConnectionStatus, which was called every second
- (void)tcpSocket:(TCPSocketClass *)socket didChangeState:(tcpSocketState_t)state reason:(NSString *)reason {
  NSString *statusText = @"";
  switch (state) {
    case TCP_SOCKET_CONNECTING: {
      statusText = [@"TCP connect attempt to Lenz interface at " stringByAppendingString:_ipAddressLenz];
      break; }
    case TCP_SOCKET_CONNECTED: {
      statusText = @"Lenz: Connected to interface";
      [_topObject lenzprogressIndicator: 0];
      [self startKeepAlive];
      break; }
    case TCP_SOCKET_FAILED: {
      if ([socket lastErrorCode] == ETIMEDOUT) statusText = @"Lenz: No response from interface";
      else statusText = [NSString stringWithFormat:@"Lenz: Could not connect to interface (%@)", reason];
      [self connectionEnded];
      break; }
    case TCP_SOCKET_LOST: {
      statusText = [NSString stringWithFormat:@"Lenz: Connection to interface lost (%@)", reason];
      [self connectionEnded];
      break; }
    case TCP_SOCKET_CLOSED: {
      if (reason == nil) statusText = @"TCP connection to Lenz interface closed";
      else statusText = [NSString stringWithFormat:@"TCP connection to Lenz interface closed (%@)", reason];
      [self connectionEnded];
      break; }
  }
  [_topObject.lenzStatus setObjectValue:statusText];
}


// 2026: Called by TCPSocketClass (on the main thread) for every chunk of data received from the Lenz interface
- (void)tcpSocket:(TCPSocketClass *)socket didReceiveBytes:(const uint8_t *)bytes length:(NSUInteger)length {
  for (NSUInteger i = 0; i < length; i++) {
    if (![_socketLenz isOpen]) break;
    [self handleLenzByte:bytes[i]];
  }
}


// ******************************************************************************************
// ****************************** XPRESSNET LAN KEEP-ALIVE (2026) ***************************
// ******************************************************************************************
// See Lenz specification "XpressNet und LAN/USB Interface 23151", section 2.1 "Interface Status Befehl".
// Command:  0xFF 0xFE 0xF1 0x01 0xF0
// Answer:   0xFF 0xFE 0xF2 0x01 Data2 X-OR, with Data2 bit 0 (A) = 1: interface receives data from the command station
// Besides keeping the connection alive, the answer tells whether the command station is active.
// Only one command may be unanswered (section 1.3): the interval (10 s) is longer than the answer timeout (5 s).
// Note: NSTimer and performSelector:afterDelay: retain this object until the timer is invalidated or has fired.
- (void)startKeepAlive {
  [self stopKeepAlive];
  _keepAliveTimer = [NSTimer scheduledTimerWithTimeInterval:KEEPALIVE_INTERVAL target:self
                                                   selector:@selector(sendInterfaceStatusCommand:) userInfo:nil repeats:YES];
  [self sendInterfaceStatusCommand:nil];   // Ask immediately, so the state of the command station is known at once
}


- (void)stopKeepAlive {
  [_keepAliveTimer invalidate];
  _keepAliveTimer = nil;
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(interfaceStatusTimeout) object:nil];
}


- (void)sendInterfaceStatusCommand:(NSTimer *)timer {
  [_socketLenz sendBytes:interfaceStatusCommand length:sizeof(interfaceStatusCommand)];
  // Wait for the answer. A previous waiting time is cancelled first, so there is never more than one
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(interfaceStatusTimeout) object:nil];
  [self performSelector:@selector(interfaceStatusTimeout) withObject:nil afterDelay:STATUS_ANSWER_TIMEOUT];
}


// No answer to the Interface Status command: the interface is no longer reachable
- (void)interfaceStatusTimeout {
  [self closeLenzConnection];                                             // Shows "TCP connection ... closed"
  [_topObject.lenzStatus setObjectValue:@"Lenz: Interface not responding"]; // Replace that by the actual reason
}


// Handles the answers of the interface and the messages about the command station.
// Returns YES if the frame was such a message, NO if it should be handled by handleLenzFrame.
// Frames have already been checked by currentFrameComplete (start 0xFF 0xFD or 0xFF 0xFE, and complete).
- (BOOL)handleLenzInterfaceFrame {
  // Answers to commands always have header 0xFF 0xFE (specification section 1.3). Since dccmon sends no other
  // commands, every answer belongs to the Interface Status command, and shows that the interface is alive
  if (lenzInBuffer[1] == 0xFE) {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(interfaceStatusTimeout) object:nil];
    // Answer to the Interface Status command: 0xFF 0xFE 0xF2 0x01 Data2 X-OR
    if ((lenzInBuffer[2] == 0xF2) && (lenzInBuffer[3] == 0x01) &&
        ((lenzInBuffer[2] ^ lenzInBuffer[3] ^ lenzInBuffer[4]) == lenzInBuffer[5])) {
      if (lenzInBuffer[4] & 0x01) [_topObject.lenzStatus setObjectValue:@"Lenz: Connected (command station active)"];
      else [_topObject.lenzStatus setObjectValue:@"Lenz: Connected (command station not active)"];
    }
    return YES;
  }
  // Unrequested messages about the command station (specification section 1.5):
  // 0xFF 0xFD 0x01 0x05 0x04: command station no longer addresses the interface
  // 0xFF 0xFD 0x01 0x07 0x06: command station addresses the interface again
  if ((lenzInBuffer[1] == 0xFD) && (lenzInBuffer[2] == 0x01)) {
    if ((lenzInBuffer[2] ^ lenzInBuffer[3]) != lenzInBuffer[4]) return YES;   // Parity error: ignore
    if (lenzInBuffer[3] == 0x05) [_topObject.lenzStatus setObjectValue:@"Lenz: Connected (command station not active)"];
    if (lenzInBuffer[3] == 0x07) [_topObject.lenzStatus setObjectValue:@"Lenz: Connected (command station active)"];
    return YES;
  }
  return NO;
}


// ******************************************************************************************
// *************************************** RECEIVE METHODS **********************************
// ******************************************************************************************
// 2026: Formerly the NSStreamEventHasBytesAvailable part of stream:handleEvent:. The logic is unchanged.
- (void)handleLenzByte:(uint8_t)byte {
  // NSLog(@"char = %0x", byte);  // for testing
  totalLenzBytes++;
  if (lenzSynchronized) {
    lenzInBuffer[lenzInputBufferSize] = byte;
    lenzInputBufferSize ++;
    if ([self currentFrameComplete]) {
      // 2026: first check for messages about the interface / command station, then for feedback messages
      if (![self handleLenzInterfaceFrame]) [self handleLenzFrame];
      lenzInputBufferSize = 0;
    }
  }
  else // we are not sychronized yet. Ignore stream input, unless it has value 0xFF
    if (byte == 0xFF) {
    // this is likely the start of a new frame, although it may be a valid data value as well. Lets try ...
    lenzSynchronized = 1;
    lenzInBuffer[0] = 0xFF;
    lenzInputBufferSize = 1;
  }
}


// 2026: The following test code was part of checkLenzConnectionStatus, which no longer exists

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
