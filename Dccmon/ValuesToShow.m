//
//  ValuesToShow.m
//  dccmon
//
//  Created by Aiko Pras on 17-05-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ValuesToShow.h"
#import "AppDelegate.h"

@implementation ValuesToShow

// Top object
@synthesize topObject = _topObject;
// Normal strings
@synthesize stringTime           = _stringTime;
@synthesize stringLocAddress     = _stringLocAddress;
@synthesize stringLocSpeed       = _stringLocSpeed;
@synthesize stringLocDirection   = _stringLocDirection;
@synthesize stringCvNumber       = _stringCvNumber;
@synthesize stringCvValue        = _stringCvValue;
@synthesize stringRsAddress      = _stringRsAddress;
// Attributed strings
@synthesize aStringLocFunctions  = _aStringLocFunctions;
@synthesize aStringSwitches      = _aStringSwitches;
@synthesize aStringFeedback      = _aStringFeedback;
// Always show ...
@synthesize alwaysShowLoc        = _alwaysShowLoc;
@synthesize alwaysShowFeedback   = _alwaysShowFeedback;

// Counters for total statistics
@synthesize counter_dcc_packets  = _counter_dcc_packets;
@synthesize counter_reset        = _counter_reset;
@synthesize counter_idle         = _counter_idle;
@synthesize counter_service_mode = _counter_service_mode;
@synthesize counter_speed        = _counter_speed;
@synthesize counter_F0_F12       = _counter_F0_F12;
@synthesize counter_F13_F28      = _counter_F13_F28;
@synthesize counter_CV_Access    = _counter_CV_Access;
@synthesize counter_accessory    = _counter_accessory;
@synthesize counter_feedback     = _counter_feedback;
@synthesize counter_forFutureUse = _counter_forFutureUse;
@synthesize counter_parityError  = _counter_parityError;

#define UNDEFINED8 255             // To intialize the next arrays
#define UNDEFINED16 65535          // To intialize the next arrays
#define MAXLOCS 10241              // To intialize the loc arrays
#define MAXSWITCH 2050             // To intialize the switch array
#define MAXRSBUS 130               // To intialize the RS bus arrays

uint8_t historySpeed[MAXLOCS];     // To keep track of previous Loc Speeds
uint8_t historyDirection[MAXLOCS]; // To keep track of previous Loc Directions
uint8_t historyF0_F4[MAXLOCS];     // To keep track of previous Loc Functions F0 - F4
uint8_t historyF5_F8[MAXLOCS];     // To keep track of previous Loc Functions F5 - F8
uint8_t historyF9_F12[MAXLOCS];    // To keep track of previous Loc Functions F9 - F12
uint16_t historyF13_F20[MAXLOCS];  // To keep track of previous Loc Functions F13 - F20
uint16_t historyF21_F28[MAXLOCS];  // To keep track of previous Loc Functions F21 - F28
uint8_t historySwitch[MAXSWITCH];  // To keep track of previous Switch positions
uint8_t rsbit1_4[MAXRSBUS];        // To keep track of previous RS Bus values for bit 1-4
uint8_t rsbit5_8[MAXRSBUS];        // To keep track of previous RS Bus values for bit 5-8

int currentLocAddress;             // Stores the Loc Address of the current DCC packet
int previousCvNumber;              // Holds the CV number used in the previous PoM packet
uint8_t previousCvValue;           // Holds the CV value within the previous PoM packet
uint8_t previousCvVerified;        // Indicates if the CV value has recently been verified
int showDccLoc;
int showSwitch;
int showFeedback;

// ***********************************************************************
// *************************** GENERAL METHODS ***************************
// ***********************************************************************
- (void) initValuesToShow {
  // Make sure we can access the properties and methods of the APPDelegate and dccDecoder Object
  _topObject = ((AppDelegate *) [[NSApplication sharedApplication] delegate]);
  // Initialise the history arrays
  // Note that we do not keep a history array for PoM, since such array would become too big. Instead we remember the last operation.
  for (int i = 0; i < MAXLOCS; i++) {
    historySpeed[i]     = UNDEFINED8;  // 8 bit resolution
    historyDirection[i] = UNDEFINED8;
    historyF0_F4[i]     = UNDEFINED8;
    historyF5_F8[i]     = UNDEFINED8;
    historyF9_F12[i]    = UNDEFINED8;
    historyF13_F20[i]   = UNDEFINED16; // 16 bit resolution
    historyF21_F28[i]   = UNDEFINED16;
  }
  // Initialise the switch array and RS bus arrays
  for (int i = 0; i < MAXSWITCH; i++) {historySwitch[i] = UNDEFINED8;}
  for (int i = 0; i < MAXRSBUS;  i++) {rsbit1_4[i]      = UNDEFINED8;}
  for (int i = 0; i < MAXRSBUS;  i++) {rsbit5_8[i]      = UNDEFINED8;}
  // Initialise the statistics
  _counter_dcc_packets = 0;
  _counter_reset = 0;
  _counter_idle = 0;
  _counter_service_mode = 0;
  _counter_speed = 0;
  _counter_F0_F12 = 0;
  _counter_F13_F28 = 0;
  _counter_CV_Access = 0;
  _counter_accessory = 0;
  _counter_feedback = 0;
  _counter_forFutureUse = 0;
  _counter_parityError = 0;
  // Initialise the "show" variables
  showDccLoc = 0;
  showSwitch = 0;
  showFeedback = 0;
  // Allocate space for the attributed mutable arrays
  _aStringLocFunctions = [[NSMutableAttributedString alloc] initWithString:@"ABCDEFG"];
  _aStringSwitches = [[NSMutableAttributedString alloc] initWithString:@"ABCDEFG"];
  _aStringFeedback = [[NSMutableAttributedString alloc] initWithString:@"ABCDEFG"];
  // initialise the Always Show fields
  // _alwaysShowLoc = 0;
  // _alwaysShowFeedback = 0;
}

- (void) newPacket {
  // Clear all normal string fields
  _stringTime           = @"";
  _stringLocAddress     = @"";
  _stringLocSpeed       = @"";
  _stringLocDirection   = @"";
  _stringCvNumber       = @"";
  _stringCvValue        = @"";
  _stringRsAddress      = @"";
  // Clear the (attributed and mutable) strings for the loc functions and the switches
  NSRange totalRange;
  totalRange.location = 0;
  totalRange.length = [_aStringLocFunctions length];
  [_aStringLocFunctions deleteCharactersInRange: totalRange];
  totalRange.length = [_aStringSwitches length];
  [_aStringSwitches deleteCharactersInRange: totalRange];
  totalRange.length = [_aStringFeedback length];
  [_aStringFeedback deleteCharactersInRange: totalRange];
  // Clear other fields
  showDccLoc = 0;
  showSwitch = 0;
  showFeedback = 0;
}


- (void) showPacket {
  if (showDccLoc)   [_topObject showPacket];
  if (showSwitch)   [_topObject showPacket];
  if (showFeedback) [_topObject showPacket];
}

- (void) showStatistics {
  NSInteger rest;
  rest = _counter_dcc_packets + _counter_feedback;
  rest = rest - _counter_idle - _counter_reset - _counter_forFutureUse;
  rest = rest - _counter_speed - _counter_F0_F12 - _counter_F13_F28 - _counter_CV_Access;
  rest = rest - _counter_accessory - _counter_feedback - _counter_service_mode;
  [_topObject.counterDccPackets   setObjectValue:[NSString stringWithFormat:@"%ld",_counter_dcc_packets]];
  [_topObject.counterIdle         setObjectValue:[NSString stringWithFormat:@"%ld",_counter_idle]];
  [_topObject.counterReset        setObjectValue:[NSString stringWithFormat:@"%ld",_counter_reset]];
  [_topObject.counterForFutureUse setObjectValue:[NSString stringWithFormat:@"%ld",_counter_forFutureUse]];
  [_topObject.counterLocSpeed     setObjectValue:[NSString stringWithFormat:@"%ld",_counter_speed]];
  [_topObject.counterF0F12        setObjectValue:[NSString stringWithFormat:@"%ld",_counter_F0_F12]];
  [_topObject.counterF13F28       setObjectValue:[NSString stringWithFormat:@"%ld",_counter_F13_F28]];
  [_topObject.counterCvAccess     setObjectValue:[NSString stringWithFormat:@"%ld",_counter_CV_Access]];
  [_topObject.counterAccessory    setObjectValue:[NSString stringWithFormat:@"%ld",_counter_accessory]];
  [_topObject.counterFeedback     setObjectValue:[NSString stringWithFormat:@"%ld",_counter_feedback]];
  [_topObject.counterServiceMode  setObjectValue:[NSString stringWithFormat:@"%ld",_counter_service_mode]];
  [_topObject.counterParity       setObjectValue:[NSString stringWithFormat:@"%ld",_counter_parityError]];  
  [_topObject.counterRest         setObjectValue:[NSString stringWithFormat:@"%ld",rest]];
}


// ***********************************************************************
// *************************** DCC LOC METHODS ***************************
// ***********************************************************************
- (NSString *)timeToString: (time_t) timeStamp {
  // Needed to convert a time_t into a string formatted in the way we want
  // from time_t to NSDate
  NSDate *someDate = [NSDate dateWithTimeIntervalSince1970:timeStamp];
  // from NSDate to a formatted NSString
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"HH:mm:ss"];
  NSString *myString = [formatter stringFromDate:someDate];
 [formatter release];
  return myString;
}


- (void)dccTime:(time_t)timeStamp mSec:(uint16_t)timeMSec {
  _stringTime = [self timeToString:timeStamp];
  _stringTime = [_stringTime stringByAppendingString:[NSString stringWithFormat:@".%.3d", timeMSec]];
}


- (void)dccLocAddress: (int) locAddress {
  currentLocAddress = locAddress;
  _stringLocAddress = [_stringLocAddress stringByAppendingString:[NSString stringWithFormat:@"%d", locAddress]];
}


- (void)dccLocSpeed: (uint8_t) speed {
  if ((_topObject.showLocSpeed == 0) && (_alwaysShowLoc != currentLocAddress)) return;
  _stringLocSpeed = [_stringLocSpeed stringByAppendingString:[NSString stringWithFormat:@"%d", speed]];
  if (speed != historySpeed[currentLocAddress]) {showDccLoc = 1;}
  if (_topObject.showLocSpeedDetails == 1) showDccLoc = 1;
  historySpeed[currentLocAddress] = speed;
}


- (void)dccLocDirection: (uint8_t) direction {
  if ((_topObject.showLocSpeed == 0) && (_alwaysShowLoc != currentLocAddress)) return;
  if (direction) {_stringLocDirection = @">";}
  else {_stringLocDirection = @"<";}
  if (direction != historyDirection[currentLocAddress]){showDccLoc = 1;}
  if (_topObject.showLocSpeedDetails == 1) showDccLoc = 1;
  historyDirection[currentLocAddress] = direction;
}


// *******************************************************************************
// *         Multi Function (=Loc) Decoders: Function Group Instructions         *
// *******************************************************************************
- (void) dccNewLocFunctionString: (NSString *) newText {
  // Goal: initialise the _aStringLocFunctions with the newText
  NSRange totalRange;
  // Replace the old string with new Text
  totalRange.location = 0;
  totalRange.length = [_aStringLocFunctions length];
  [_aStringLocFunctions replaceCharactersInRange:totalRange withString:newText];
  // Give the text a default color
  totalRange.length = [_aStringLocFunctions length];  
  [_aStringLocFunctions addAttribute:NSForegroundColorAttributeName value:[NSColor lightGrayColor] range:totalRange];
}

-(void)setColorInSubstring:(uint8_t)stringNumber IfValueOfBit:(uint8_t)bitNumber differsInNew:(uint8_t)data comparedTo:(uint8_t)old_data orIfThisIs:(uint8_t)firstTime{
  // Goal: check if a certain bit has changed in the Function Values
  // If yes change the color of the related substring. Do this also if firstTime is set
  // Note that bitNumber startes (according to the NMRA) with 0. 
  // For symmetrie reasons we'll start stringNumber also with 0.
  uint8_t mask = 0;
  NSColor *functionColor;
  NSRange selectedRange;
  // 1: Check if bitNumber is a value between 0 and 7. If yes, set the mask.
  // Note that the NMRA standards defines the least significant (rightmost) bit as 0)
  if ((bitNumber >=0) && (bitNumber <= 7)) {mask = (0b00000001 << bitNumber);}
  else {NSLog(@"Error in setColorInSubstring: bitNumber out of range"); return;}
  // 2: Check if there is anything to show
  if (((data & mask) != (old_data & mask)) || firstTime) {
    // 3: determine which color to use. Red if the bit is set, otherwise green
    if (data & mask) functionColor = [NSColor redColor];
    else functionColor = [NSColor greenColor];
    // determine the range this color should be applied to
    selectedRange.location = stringNumber * 4;
    selectedRange.length = 3;
    // do the actual editting to change the color
    if ((selectedRange.location + selectedRange.length) <= _aStringLocFunctions.length){
      [_aStringLocFunctions beginEditing];
      [_aStringLocFunctions addAttribute:NSForegroundColorAttributeName value:functionColor range:selectedRange];
      [_aStringLocFunctions endEditing];}
    else NSLog(@"Error in setColorInSubstring: selectedRange exceeds size of _aStringLocFunctions");
  }
}


- (void)dccLocFunctions1: (uint8_t) functions {
  if ((_topObject.showLocFunctions == 0) && (_alwaysShowLoc != currentLocAddress)) return;
  uint8_t old_functions, firstOccurence = 0;
  [self dccNewLocFunctionString: @"F0  F1  F2  F3  F4  "];
  old_functions = historyF0_F4[currentLocAddress];
  historyF0_F4[currentLocAddress] = functions;
  if (old_functions != functions) showDccLoc = 1;
  if (_topObject.showLocFunctionsDetails == 1) showDccLoc = 1;
  if (old_functions == UNDEFINED8) firstOccurence = 1;
  [self setColorInSubstring:0 IfValueOfBit:4 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
  [self setColorInSubstring:1 IfValueOfBit:0 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
  [self setColorInSubstring:2 IfValueOfBit:1 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
  [self setColorInSubstring:3 IfValueOfBit:2 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
  [self setColorInSubstring:4 IfValueOfBit:3 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
}


- (void)dccLocFunctions2: (uint8_t) functions {
  if ((_topObject.showLocFunctions == 0) && (_alwaysShowLoc != currentLocAddress)) return;
  uint8_t old_functions, firstOccurence = 0;
  if (functions & 0b00010000){
    [self dccNewLocFunctionString: @"F5  F6  F7  F8  "];
    old_functions = historyF5_F8[currentLocAddress];
    historyF5_F8[currentLocAddress] = functions; }
  else {
    [self dccNewLocFunctionString: @"F9  F10 F11 F12  "];
    old_functions = historyF9_F12[currentLocAddress];
    historyF9_F12[currentLocAddress] = functions; }
  if (old_functions != functions) showDccLoc = 1;
  if (_topObject.showLocFunctionsDetails == 1) showDccLoc = 1;
  if (old_functions == UNDEFINED8) firstOccurence = 1;
  [self setColorInSubstring:0 IfValueOfBit:0 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
  [self setColorInSubstring:1 IfValueOfBit:1 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
  [self setColorInSubstring:2 IfValueOfBit:2 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
  [self setColorInSubstring:3 IfValueOfBit:3 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
}

- (void)dccLocFunctions3: (uint8_t) functions {
  if ((_topObject.showLocFunctions == 0) && (_alwaysShowLoc != currentLocAddress)) return;
  uint16_t old_functions, firstOccurence = 0;
  [self dccNewLocFunctionString: @"F13 F14 F15 F16 F17 F18 F19 F20 "];
  old_functions = historyF13_F20[currentLocAddress];
  historyF13_F20[currentLocAddress] = functions;
  if (old_functions != functions) showDccLoc = 1;
  if (_topObject.showLocFunctionsDetails2 == 1) showDccLoc = 1;
  if (old_functions == (UNDEFINED16)) firstOccurence = 1;
  [self setColorInSubstring:0 IfValueOfBit:0 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
  [self setColorInSubstring:1 IfValueOfBit:1 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
  [self setColorInSubstring:2 IfValueOfBit:2 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
  [self setColorInSubstring:3 IfValueOfBit:3 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
  [self setColorInSubstring:4 IfValueOfBit:4 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
  [self setColorInSubstring:5 IfValueOfBit:5 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
  [self setColorInSubstring:6 IfValueOfBit:6 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
  [self setColorInSubstring:7 IfValueOfBit:7 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
  }

- (void)dccLocFunctions4: (uint8_t) functions {
  if ((_topObject.showLocFunctions == 0) && (_alwaysShowLoc != currentLocAddress)) return;
  uint16_t old_functions, firstOccurence = 0;
  [self dccNewLocFunctionString: @"F21 F22 F23 F24 F25 F26 F27 F28 "];
  old_functions = historyF21_F28[currentLocAddress];
  historyF21_F28[currentLocAddress] = functions;
  if (old_functions != functions) showDccLoc = 1;
  if (old_functions == (UNDEFINED16)) firstOccurence = 1;
  if (_topObject.showLocFunctionsDetails2 == 1) showDccLoc = 1;
  [self setColorInSubstring:0 IfValueOfBit:0 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
  [self setColorInSubstring:1 IfValueOfBit:1 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
  [self setColorInSubstring:2 IfValueOfBit:2 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
  [self setColorInSubstring:3 IfValueOfBit:3 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
  [self setColorInSubstring:4 IfValueOfBit:4 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
  [self setColorInSubstring:5 IfValueOfBit:5 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
  [self setColorInSubstring:6 IfValueOfBit:6 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
  [self setColorInSubstring:7 IfValueOfBit:7 differsInNew:functions comparedTo:old_functions orIfThisIs:firstOccurence];
}


// *******************************************************************************
// *          Multi Function (=Loc) Decoders: CV Access Commands (PoM)           *
// *******************************************************************************
- (void)dccLocCv: (int)cvNumber value:(uint8_t)cvValue{
//  NSLog(@"PoM: CV:%d is set to value:%d",cvNumber, cvValue);
  if (_topObject.showPoM == 0) return;
  _stringCvNumber = [_stringCvNumber stringByAppendingString:[NSString stringWithFormat:@"%d", cvNumber]];
  _stringCvValue = [_stringCvValue stringByAppendingString:[NSString stringWithFormat:@"%d", cvValue]];
  if ((cvNumber != previousCvNumber) || (cvValue != previousCvValue) || (_topObject.showPoMDetails)) {
    showDccLoc = 1;
    previousCvVerified = 0;
  }
  previousCvNumber = cvNumber;
  previousCvValue = cvValue;
};


- (void)dccLocCvVerify: (int)cvNumber {
  //  NSLog(@"PoM: CV:%d is verified",cvNumber); 
  if (_topObject.showPoM == 0) return;
  _stringCvNumber = [_stringCvNumber stringByAppendingString:[NSString stringWithFormat:@"%d", cvNumber]];
  _stringCvValue = [_stringCvValue stringByAppendingString:[NSString stringWithFormat:@"verify"]];
  if ((cvNumber != previousCvNumber) || !(previousCvVerified) || (_topObject.showPoMDetails)) { 
    showDccLoc = 1; previousCvVerified = 1;} 
  previousCvNumber = cvNumber;
};


- (void)dccLocCvBit: (int)cvNumber value:(uint8_t)cvValue{
  if (_topObject.showPoM == 0) return;
  uint8_t cvBit = (cvValue & 0b00000111) + 1;
  uint8_t cvBitValue = (cvValue & 0b00001000) >> 3;
  uint8_t cvBitCommand = (cvValue & 0b00010000) >> 4;
  _stringCvNumber = [_stringCvNumber stringByAppendingString:[NSString stringWithFormat:@"%d (%d)", cvNumber, cvBit]];
  _stringCvValue = [_stringCvValue stringByAppendingString:[NSString stringWithFormat:@"%d", cvBitValue]];
  if (cvBitCommand == 0) _stringCvValue = [_stringCvValue stringByAppendingString:[NSString stringWithFormat:@"?"]];
  if ((cvNumber != previousCvNumber) || (cvValue != previousCvValue) || (_topObject.showPoMDetails)) {
    showDccLoc = 1;
    previousCvVerified = 0;
  }
  previousCvNumber = cvNumber;
  previousCvValue = cvValue;
  // NSLog(@"PoM: CV:%d - Bit:%d - value:%d - command:%d",cvNumber, cvBit, cvBitValue,cvBitCommand);
};

// *******************************************************************************
// ****************************** DCC SWITCH METHODS *****************************
// *******************************************************************************
- (void)dccSwitch: (int)address status:(uint8_t)status{
  if (_topObject.showSwitches == 0) return;
  NSString *switchText;
  NSColor *switchColor;
  NSRange totalRange;
  // Initialise _aStringSwitches with the switch address plus status
  totalRange.location = 0;
  totalRange.length = [_aStringSwitches length];
  if (status) switchText = [NSString stringWithFormat:@"%d+", address];
    else switchText = [NSString stringWithFormat:@"%d-", address];
  [_aStringSwitches replaceCharactersInRange:totalRange withString:switchText];
  // Determine the color for the switch
  if (status) switchColor = [NSColor redColor];
    else switchColor = [NSColor greenColor];
  // Change the color of _aStringSwitches to the selected color
  totalRange.length = [_aStringSwitches length];
  [_aStringSwitches beginEditing];
  [_aStringSwitches addAttribute:NSForegroundColorAttributeName value:switchColor range:totalRange];
  [_aStringSwitches endEditing];
  // determine whether the (detailed or normal) switch info should be shown
  if (_topObject.showSwitchesDetails) historySwitch[address] = UNDEFINED8;
  if (status != historySwitch[address]){
    showSwitch = 1;}
  // update the history array with switch status
  historySwitch[address] = status;
}


// *******************************************************************************
// *************************** RS-BUS FEEDBACK METHODS ***************************
// *******************************************************************************
- (void)rsFeedback: (uint8_t)address value:(uint8_t)value nibble:(uint8_t)nibble{
  if ((_topObject.showFeedback == 0) && (_alwaysShowFeedback != address)) return;
  // Set the RS bus address string
  _stringRsAddress = [_stringRsAddress stringByAppendingString:[NSString stringWithFormat:@"%d", address]];
  uint8_t old_values, firstOccurence = 0;
  if (nibble){
    [self rsNewValueString: @"5 6 7 8 "];
    old_values = rsbit5_8[address];
    rsbit5_8[address] = value; }
  else {
    [self rsNewValueString: @"1 2 3 4 "];
    old_values = rsbit1_4[address];
    rsbit1_4[address] = value; }
  if (old_values != value) showFeedback = 1;
  if (_topObject.showFeedbackDetails == 1) showFeedback = 1;
  if (old_values == UNDEFINED8) firstOccurence = 1;
  [self setColorInRsSubstring:0 IfValueOfBit:0 differsInNew:value comparedTo:old_values orIfThisIs:firstOccurence];
  [self setColorInRsSubstring:1 IfValueOfBit:1 differsInNew:value comparedTo:old_values orIfThisIs:firstOccurence];
  [self setColorInRsSubstring:2 IfValueOfBit:2 differsInNew:value comparedTo:old_values orIfThisIs:firstOccurence];
  [self setColorInRsSubstring:3 IfValueOfBit:3 differsInNew:value comparedTo:old_values orIfThisIs:firstOccurence];
}


- (void) rsNewValueString: (NSString *) newText {
  // This function is a variant of dccNewLocFunctionString 
  // Goal: initialise the _aStringFeedback with the newText
  NSRange totalRange;
  // Replace the old string with new Text
  totalRange.location = 0;
  totalRange.length = [_aStringLocFunctions length];
  [_aStringFeedback replaceCharactersInRange:totalRange withString:newText];
  // Give the text a default color
  totalRange.length = [_aStringFeedback length];  
  [_aStringFeedback addAttribute:NSForegroundColorAttributeName value:[NSColor lightGrayColor] range:totalRange];
}


-(void)setColorInRsSubstring:(uint8_t)stringNumber IfValueOfBit:(uint8_t)bitNumber differsInNew:(uint8_t)data comparedTo:(uint8_t)old_data orIfThisIs:(uint8_t)firstTime{
  // This function is a variant of setColorInSubstring 
  // Goal: check if a certain bit has changed in the RS bus Values
  // If yes change the color of the related substring. Do this also if firstTime is set
  // Note that bitNumber startes (according to the NMRA) with 0. 
  // For symmetrie reasons we'll start stringNumber also with 0.
  uint8_t mask = 0;
  NSColor *functionColor;
  NSRange selectedRange;
  // 1: Check if bitNumber is a value between 0 and 7. If yes, set the mask.
  // Note that the NMRA standards defines the least significant (rightmost) bit as 0)
  if ((bitNumber >=0) && (bitNumber <= 7)) {mask = (0b00000001 << bitNumber);}
  else {NSLog(@"Error in setColorInRsSubstring: bitNumber out of range"); return;}
  // 2: Check if there is anything to show
  if (((data & mask) != (old_data & mask)) || firstTime) {
    // 3: determine which color to use. Red if the bit is set, otherwise green
    if (data & mask) functionColor = [NSColor redColor];
    else functionColor = [NSColor greenColor];
    // determine the range this color should be applied to
    selectedRange.location = stringNumber * 2;
    selectedRange.length = 1;
    // do the actual editting to change the color
    if ((selectedRange.location + selectedRange.length) <= _aStringFeedback.length){
      [_aStringFeedback beginEditing];
      [_aStringFeedback addAttribute:NSForegroundColorAttributeName value:functionColor range:selectedRange];
      [_aStringFeedback endEditing];}
    else NSLog(@"Error in setColorInRsSubstring: selectedRange exceeds size of _aStringFeedback");
  }
}



@end
