//
//  FrameObject.h
//  dccmon
//
//  Created by Aiko Pras on 17-05-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
// Note that OS X typedefs time_t as a __darwin_time_t. __darwin_time_t is a long (integer).  
// If you compile with LP64 support (#define __LP_64__), you get a 63-bit long, 
// otherwise you get 31 bits (long is signed). 

@interface FrameObject : NSObject
@property time_t time;        // Time we received the frame. 
@property uint16_t timeMSec;  // The millisecond the frame was received
@property uint8_t retval;     // The return value from the read call (should be zero if OK)
@property uint8_t address;    // Address that sent the frame
@property uint8_t protocol;   // Protocol of data in frame
@property uint8_t length;     // Length of data
@property uint8_t byte1;      // Frame data byte
@property uint8_t byte2;      // Frame data byte
@property uint8_t byte3;      // Frame data byte
@property uint8_t byte4;      // Frame data byte
@property uint8_t byte5;      // Frame data byte
@property uint8_t byte6;      // Frame data byte
@property uint8_t byte7;      // Frame data byte
@property uint8_t byte8;      // Frame data byte
@property uint8_t byte9;      // Frame data byte
@end
