//
//  TCPInputLenz.h
//  dccmon
//
//  Created by Aiko Pras on 15-10-12.
//
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"
#import "TCPSocket.h"

// 2026: NSStreamDelegate replaced by TCPSocketDelegate
@interface TCPInputLenzClass : NSObject <TCPSocketDelegate>

@property (assign) AppDelegate *topObject;
@property (assign) DccObject *dccDecoder;
@property (retain) RsObject *rsDecoder;            // 2026: retain instead of assign, since owned by this object
@property (retain) TCPSocketClass *socketLenz;     // 2026: replaces iStreamLenz and oStreamLenz
@property (assign) NSString *ipAddressLenz;
@property (assign) NSString *tcpPortLenz;
@property (assign) NSTimer *keepAliveTimer;        // 2026: sends the XpressNet Interface Status command


- (void)openLenzConnection;
- (void)closeLenzConnection;
- (BOOL)isOpen;                                     // 2026: replaces checkLenzConnectionStatus
- (void)handleLenzFrame;


@end
