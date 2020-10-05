//
//  TCPInputLenz.h
//  dccmon
//
//  Created by Aiko Pras on 15-10-12.
//
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

@interface TCPInputLenzClass : NSObject <NSStreamDelegate>

@property (assign) AppDelegate *topObject;
@property (assign) DccObject *dccDecoder;
@property (assign) RsObject *rsDecoder;
@property (retain) NSInputStream *iStreamLenz;
@property (retain) NSOutputStream *oStreamLenz;
@property (assign) NSString *ipAddressLenz;
@property (assign) NSString *tcpPortLenz;


- (void)openLenzConnection;
- (void)closeLenzConnection;
- (void)checkLenzConnectionStatus;
- (void)handleLenzFrame;


@end
