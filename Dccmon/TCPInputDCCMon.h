//
//  TCPInputDCCMon.h
//  dccmon
//
//  Created by Aiko Pras on 01-05-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

@interface TCPInputDCCMonClass : NSObject <NSStreamDelegate>

@property (assign) AppDelegate *topObject;
@property (assign) DccObject *dccDecoder;
@property (assign) RsObject *rsDecoder;
@property (retain) NSInputStream *iStreamDCC;
@property (retain) NSOutputStream *oStreamDCC;
@property (assign) NSString *ipAddressDCC;
@property (assign) NSString *tcpPortDCC;


- (void)openDCCMonConnection;
- (void)closeDCCMonConnection;
- (void)checkDCCMonConnectionStatus;
- (void)handleDCCMonFrame;

@end
