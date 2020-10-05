//
//  DCC.m
//  dccmon
//
//  Created by Aiko Pras on 15-05-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DCCDecode.h"
#import "AppDelegate.h"
#import "ValuesToShow.h"

@implementation DccObject
@synthesize topObject = _topObject;
@synthesize LenzCor = _LenzCor;


// *******************************************************************************
// ******************************** MAIN DCC DECODING ****************************
// *******************************************************************************
- (void) initDecoding {
  // Make sure we can access the properties and methods of the APPDelegate and dccDecoder Object
  _topObject = ((AppDelegate *) [[NSApplication sharedApplication] delegate]);
  // Read the preferences file, to determine if the system is from Lenz
  NSString *LenzCorString = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultLenzSystem"];
  if ([LenzCorString rangeOfString:@"1"].location == NSNotFound) _LenzCor = 0;
   else _LenzCor = 1;
}


- (void) decode_Dcc: (FrameObject *) frame {
  [_topObject.valuesToShow newPacket];
  _topObject.valuesToShow.counter_dcc_packets ++;
  // Check parity
  [self check_Parity:frame];
  // Analyse DCC packet
  if (frame.byte1 == 0) [self reset_packet]; 
  else if (frame.byte1 <= 111) [self multi_function_decoder: frame];
  else if (frame.byte1 <= 127) [self service_mode];
  else if (frame.byte1 <= 191) [self accessory_decoder: frame];
  else if (frame.byte1 <= 231) [self multi_function_decoder: frame];
  else if (frame.byte1 <= 254) [self reserved_For_Future_Use:frame];
  else if (frame.byte1 == 255) [self idle_Packet];
}


// *******************************************************************************
// ************************************ GENERAL **********************************
// *******************************************************************************
- (void)check_Parity: (FrameObject *) frame {
  uint8_t parity = 0;
  if (frame.length > 0) parity ^= frame.byte1;
  if (frame.length > 1) parity ^= frame.byte2;
  if (frame.length > 2) parity ^= frame.byte3;
  if (frame.length > 3) parity ^= frame.byte4;
  if (frame.length > 4) parity ^= frame.byte5;
  if (frame.length > 5) parity ^= frame.byte6;
  if (frame.length > 6) parity ^= frame.byte7;
  if (frame.length > 7) parity ^= frame.byte8;
  if (frame.length > 8) parity ^= frame.byte9;
  if (parity) {_topObject.valuesToShow.counter_parityError ++;}
}


- (void)reset_packet { _topObject.valuesToShow.counter_reset ++;}

- (void)service_mode { _topObject.valuesToShow.counter_service_mode ++;}

- (void)idle_Packet { _topObject.valuesToShow.counter_idle ++;}

- (void)reserved_For_Future_Use: (FrameObject *) frame { _topObject.valuesToShow.counter_forFutureUse ++;}


// *******************************************************************************
// ************************* Multi Function (=Loc) Decoders **********************
// *******************************************************************************
- (void)multi_function_decoder: (FrameObject *) frame {
  uint8_t command;
  if (frame.byte1 <= 127) command = frame.byte2;
  else command = frame.byte3;
  switch (command & 0b11100000) {
    case 0b00000000: [self loc_decoder_consist_control:frame]; break; // 000 Decoder and Consist Control Instruction
    case 0b00100000: [self loc_decoder_advanced_operation:frame];break; // 001 Advanced Operation Instructions
    case 0b01000000: [self loc_decoder_speed_and_direction:frame]; break;
    case 0b01100000: [self loc_decoder_speed_and_direction:frame]; break;
    case 0b10000000: [self loc_decoder_function_group_one: frame]; break;
    case 0b10100000: [self loc_decoder_function_group_two: frame]; break;
    case 0b11000000: [self loc_decoder_future_expansion: frame]; break;  // Primarily for F13-F28
    case 0b11100000: [self loc_decoder_cv_access: frame]; break;         // PoM
  }  
}


- (int) locdec_address: (FrameObject *) frame { 
  int address;
  if (frame.byte1 <= 127) address = (frame.byte1 & 0b01111111);
  else address = ((frame.byte1 & 0b00111111) * 256 + frame.byte2);
  return address;
}


// *******************************************************************************
// *             Multi Function (=Loc) Decoders: Speed and direction             *
// *******************************************************************************
- (void)loc_decoder_speed_and_direction: (FrameObject *) frame {
  _topObject.valuesToShow.counter_speed ++;
  int address; uint8_t speed, direction;
  address =   [self locdec_address:frame];
  speed =     [self locdec_speed:frame]; 
  direction = [self locdec_direction:frame]; 
  [_topObject.valuesToShow dccTime: frame.time mSec:frame.timeMSec];
  [_topObject.valuesToShow dccLocAddress: address];
  [_topObject.valuesToShow dccLocSpeed: speed];
  [_topObject.valuesToShow dccLocDirection: direction];
  [_topObject.valuesToShow showPacket];
  // NSLog(@"Address: %d,  Speed: %d,  Direction: %d", address, speed, direction);
}


- (uint8_t)locdec_speed: (FrameObject *) frame {
  uint8_t speed_byte, speed;
  if (frame.byte1 <= 127) speed_byte = frame.byte2;
  else speed_byte = frame.byte3;
  speed = ((speed_byte & 0b00001111) << 1) + ((speed_byte & 0b00010000) >> 4);
  if (speed < 4 ) speed = 0;
  else speed = speed - 3;
  return speed;
}


- (uint8_t)locdec_direction: (FrameObject *) frame {
  uint8_t direction_byte, direction;
  if (frame.byte1 <= 127) direction_byte = frame.byte2;
  else direction_byte = frame.byte3;
  direction = ((direction_byte & 0b00100000) >> 5);
  return direction;
}


// *******************************************************************************
// *        Multi Function (=Loc) Decoders: Function Group Instructions          *
// *******************************************************************************
- (void)loc_decoder_function_group_one: (FrameObject *) frame {
  _topObject.valuesToShow.counter_F0_F12 ++;
  int address; uint8_t F0_F4;
  address = [self locdec_address:frame];
  F0_F4 =   [self locdec_F0_F4:frame]; 
  [_topObject.valuesToShow dccTime: frame.time mSec:frame.timeMSec];
  [_topObject.valuesToShow dccLocAddress: address];
  [_topObject.valuesToShow dccLocFunctions1: F0_F4];
  [_topObject.valuesToShow showPacket];
}

- (void)loc_decoder_function_group_two: (FrameObject *) frame {
  _topObject.valuesToShow.counter_F0_F12 ++;
  int address; uint8_t F5_F12;
  address = [self locdec_address:frame];
  F5_F12 =  [self locdec_F5_F12:frame]; 
  [_topObject.valuesToShow dccTime: frame.time mSec:frame.timeMSec];
  [_topObject.valuesToShow dccLocAddress: address];
  [_topObject.valuesToShow dccLocFunctions2: F5_F12];
  [_topObject.valuesToShow showPacket];
}

- (uint8_t)locdec_F0_F4: (FrameObject *) frame {
  uint8_t databyte;
  if (frame.byte1 <= 127) databyte = frame.byte2;
  else databyte = frame.byte3;
  return (databyte & 0b00011111);
}

- (uint8_t)locdec_F5_F12: (FrameObject *) frame {
  uint8_t databyte;
  if (frame.byte1 <= 127) databyte = frame.byte2;
  else databyte = frame.byte3;
  return databyte;
}

- (uint8_t)locdec_F13_F28: (FrameObject *) frame {
  uint8_t databyte;
  if (frame.byte1 <= 127) databyte = frame.byte3;
  else databyte = frame.byte4;
  return databyte;
}


// *******************************************************************************
// *         Multi Function (=Loc) Decoders: Future Expansion (F13-F28)          *
// *******************************************************************************
- (void)loc_decoder_future_expansion: (FrameObject *) frame {
  uint8_t command;
  if (frame.byte1 <= 127) command = frame.byte2;
  else command = frame.byte3;
  switch (command & 0b00011111) {
    case 0b00000000: break; // Binary State Control Instruction - long form
    case 0b00011101: break; // Binary State Control Instruction - short form
    case 0b00011110: [self loc_decoder_F13_F20:frame]; break;
    case 0b00011111: [self loc_decoder_F20_F28:frame]; break;
    default : break;
  }  
}

- (void)loc_decoder_F13_F20: (FrameObject *) frame {
  _topObject.valuesToShow.counter_F13_F28 ++;
  int address; uint8_t F13_F20;
  address = [self locdec_address:frame];
  F13_F20 = [self locdec_F13_F28:frame]; 
  [_topObject.valuesToShow dccTime: frame.time mSec:frame.timeMSec];
  [_topObject.valuesToShow dccLocAddress: address];
  [_topObject.valuesToShow dccLocFunctions3: F13_F20];
  [_topObject.valuesToShow showPacket];
}

- (void)loc_decoder_F20_F28: (FrameObject *) frame {
  _topObject.valuesToShow.counter_F13_F28 ++;
  int address; uint8_t F21_F28;
  address = [self locdec_address:frame];
  F21_F28 = [self locdec_F13_F28:frame]; 
  [_topObject.valuesToShow dccTime: frame.time mSec:frame.timeMSec];
  [_topObject.valuesToShow dccLocAddress: address];
  [_topObject.valuesToShow dccLocFunctions4: F21_F28];
  [_topObject.valuesToShow showPacket];
}


// *******************************************************************************
// *                  Configuration Variable Access Instruction                  *
// *******************************************************************************
- (void)loc_decoder_cv_access: (FrameObject *) frame {
  _topObject.valuesToShow.counter_CV_Access ++;
  int address; uint8_t command;
  address = [self locdec_address:frame];
  [_topObject.valuesToShow dccTime: frame.time mSec:frame.timeMSec];
  [_topObject.valuesToShow dccLocAddress: address];
  if (frame.byte1 <= 127) {
    command = frame.byte2;
    if (command & 0b00010000) [self loc_dec_cv_short_form:command withValue:frame.byte3];
    else [self loc_dec_cv_long_form:command forCV:frame.byte3 withValue:frame.byte4];  
  }
  else {
    command = frame.byte3;
    if (command & 0b00010000) [self loc_dec_cv_short_form:command withValue:frame.byte4];
    else [self loc_dec_cv_long_form:command forCV:frame.byte4 withValue:frame.byte5];  
  }
}


- (void)loc_dec_cv_short_form:(uint8_t)command withValue:(uint8_t)cvValue {
  int cvNumber;
  switch (command & 0b00001111) {
    case 0b00000000: break; // Not available for use
    case 0b00000010:        // Acceleration Value
    { cvNumber = 23; 
      [_topObject.valuesToShow dccLocCv:cvNumber value:cvValue];
      [_topObject.valuesToShow showPacket];
      break;
    }
    case 0b00000011:
    { cvNumber = 24;        // Deceleration Value
      [_topObject.valuesToShow dccLocCv:cvNumber value:cvValue];
      [_topObject.valuesToShow showPacket];
      break;
    }
    case 0b00001001: break; // See RP-9.2.3, Appendix B???
    default : break;
  }  
}

- (void)loc_dec_cv_long_form:(uint8_t)command forCV:(uint8_t)cvNumberPart withValue:(uint8_t)cvValue {
  int cvNumber;
  cvNumber = (command & 0b00000011);
  cvNumber = cvNumber * 256 + cvNumberPart + 1;
  switch (command & 0b00001100) {
    case 0b00000000: break; // Reserved for future use
    case 0b00000100:        // Verify byte
    { [_topObject.valuesToShow dccLocCvVerify:cvNumber];
      [_topObject.valuesToShow showPacket];
      break; 
    }
    case 0b00001100:        // Write byte
    { [_topObject.valuesToShow dccLocCv:cvNumber value:cvValue]; 
      [_topObject.valuesToShow showPacket];
      break;
    }
    case 0b00001000:        // Bit manipulation
    { [_topObject.valuesToShow dccLocCvBit:cvNumber value:cvValue]; 
      [_topObject.valuesToShow showPacket];
      break;
    }
    default : break;
  }  
}



// *******************************************************************************
// ******************************* Accessory Decoders ****************************
// *******************************************************************************
- (void)accessory_decoder: (FrameObject *) frame {
  _topObject.valuesToShow.counter_accessory ++;
  uint8_t basic_dec    = ((frame.byte2 & 0b10000000));
  if (basic_dec) {
    //uint8_t activate   = ((frame.byte2 & 0b00001000) >> 3);
    uint8_t subAddr      = ((frame.byte2 & 0b00000110) >> 1);
    uint8_t output       = ((frame.byte2 & 0b00000001));
    uint16_t byte2       = ((frame.byte2));
    uint16_t decoderAddr = ((frame.byte1 & 0b00111111) | ((~byte2 & 0b01110000) << 2));
    // It seems the Lenz LZV100 does not send correct addresses. In general, LENZ starts with 1, 
    // instead of 0. In addition, if the received address is exactly 0, 64, 128 or 192, 
    // the address is 64 to low. To compensate this, the foll0wing code should be activated.
    if (_LenzCor == 1) { 
      if (decoderAddr == 0) {decoderAddr = 64;}
      else if (decoderAddr == 64) {decoderAddr = 128;}
      else if (decoderAddr == 128) {decoderAddr = 192;}
      else if (decoderAddr == 192) {decoderAddr = 256;}
      decoderAddr --;
    }
    uint16_t switchAddr = decoderAddr * 4 + subAddr + 1;
    [_topObject.valuesToShow dccTime: frame.time mSec:frame.timeMSec];
    [_topObject.valuesToShow dccSwitch:switchAddr status:output]; 
    [_topObject.valuesToShow showPacket];
  }
  else {
    NSString *messageText = @"Extended Accessory Decoder not implemented";
    [_topObject.dccMonStatus setObjectValue:messageText];
  }
}


// *******************************************************************************
// ******************************** NOT IMPLEMENTED ******************************
// *******************************************************************************
- (void)loc_decoder_consist_control: (FrameObject *) frame {
  NSString *messageText = @"Consist Control not implemented";
  [_topObject.dccMonStatus setObjectValue:messageText];
}

- (void)loc_decoder_advanced_operation: (FrameObject *) frame {
  NSString *messageText = @"Advanced Operation not implemented";
  [_topObject.dccMonStatus setObjectValue:messageText];
}

@end

