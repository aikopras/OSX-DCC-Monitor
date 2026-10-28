//
//  TCPInputDCCMon.h
//  dccmon
//
//  Created by Aiko Pras on 01-05-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "TCPSocket.h"

// 2026: NSStreamDelegate replaced by TCPSocketDelegate
@interface TCPInputDCCMonClass : NSObject <TCPSocketDelegate>

@property (assign) AppDelegate *topObject;
@property (retain) DccObject *dccDecoder;          // 2026: retain instead of assign, since owned by this object
@property (retain) RsObject *rsDecoder;            // 2026: retain instead of assign, since owned by this object
@property (retain) TCPSocketClass *socketDCC;      // 2026: replaces iStreamDCC and oStreamDCC
@property (assign) NSString *ipAddressDCC;
@property (assign) NSString *tcpPortDCC;


- (void)openDCCMonConnection;
- (void)closeDCCMonConnection;
- (BOOL)isOpen;                                     // 2026: replaces checkDCCMonConnectionStatus and iStreamDCC != nil
- (void)handleDCCMonFrame;

@end
