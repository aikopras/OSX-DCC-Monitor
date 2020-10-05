//
//  RsObject.m
//  dccmon
//
//  Created by Aiko Pras on 23-06-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
//  The RS bus feedback packet consists of two bytes: Address_byte  Data_byte
//  The address byte should be incremented with 1 to obtain the real TS bus address (which is in the range 1..128)
//  Structure of the Data_byte:
//  P T1 T0 N D3 D2 D1 D0  where:
//  - P      Bit parity, odd
//  - T1 TO  Responder type:
//     0  0     Switching receiver, no responder
//     0  1     Switching receiver with responder
//     1  0     Stand-alone responder
//     1  1     Reserved
//  - N      Nibble bit: 0 = lower nibble, 1 = higher nibble
//  - D3..D0 Input pin state, 0 = passive, 1 = active
//

#import "RSDecode.h"
#import "DCCDecode.h"
#import "AppDelegate.h"
#import "ValuesToShow.h"

@implementation RsObject
@synthesize topObject = _topObject;


// *******************************************************************************
// ******************************** MAIN RS DECODING *****************************
// *******************************************************************************
- (void) initDecoding {
  // Make sure we can access the properties and methods of the APPDelegate Object
  _topObject = ((AppDelegate *) [[NSApplication sharedApplication] delegate]);
}

- (void) decode_Rs: (FrameObject *) frame {
  uint8_t address = frame.byte1 + 1;
  uint8_t value   = (frame.byte2 & 0b00001111);
  uint8_t nibble  = (frame.byte2 & 0b00010000) >> 4;
  [_topObject.valuesToShow newPacket];
  _topObject.valuesToShow.counter_feedback ++;
  [_topObject.valuesToShow dccTime: frame.time mSec:frame.timeMSec];
  [_topObject.valuesToShow rsFeedback:address value:value nibble:nibble];
  [_topObject.valuesToShow showPacket];
}


@end
