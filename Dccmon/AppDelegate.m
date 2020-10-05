//
//  AppDelegate.m
//
//  Created by Aiko Pras on April - May 2012
//
//  MAC OSX program for receiving and displaying data received from the DCC Monitor board.
//  Runs on MAC OSX 10.6 and above
//
//  An initial program for analysing the frames received for the DCC Monitor board has been 
//  written in 2007-2008 by Peter Lebbing <peter@digitalbrains.com>
//  The current program is a complete rewrite for Cocoa / Objective C
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//  The program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details <http://www.gnu.org/licenses/>.
//

#import "AppDelegate.h"
#import "FileInput.h"
#import "FileOutput.h"
#import "TCPInputDCCMon.h"
#import "TCPInputLenz.h"
#import "PreferencesController.h"
#import "ValuesToShow.h"


// *****************************************************************************************************
// ******************************************** AppDelegate ********************************************
// *****************************************************************************************************
@implementation AppDelegate 
@synthesize valuesToShow = _valuesToShow;

@synthesize fileInputObject = _fileInputObject;
@synthesize fileOutputObject = _fileOutputObject;
@synthesize TCPInputDCCMonObject = _TCPInputDCCMonObject;
@synthesize TCPInputLenzObject = _TCPInputLenzObject;
@synthesize frame = _frame;
@synthesize preferencesController = _preferencesController;
@synthesize window = _window;
@synthesize messageWindow = _messageWindow;
@synthesize messageArray = _messageArray;
@synthesize dccMonStatus = _dccMonStatus;
@synthesize lenzStatus = _lenzStatus;
@synthesize progress = _progress;
@synthesize lenzProgress = _lenzProgress;
@synthesize timerStatus = _timerStatus;
// display statistics
@synthesize counterDccPackets = _counterDccPackets;
@synthesize counterIdle = _counterIdle;
@synthesize counterReset = _counterReset;
@synthesize counterForFutureUse = _counterForFutureUse;
@synthesize counterLocSpeed = _counterLocSpeed;
@synthesize counterF0F12 = _counterF0F12;
@synthesize counterF13F28 = _counterF13F28;
@synthesize counterCvAccess = _counterCvAccess;
@synthesize counterAccessory = _counterAccessory;
@synthesize counterFeedback = _counterFeedback;
@synthesize counterServiceMode = _counterServiceMode;
@synthesize counterRest = _counterRest;
@synthesize counterParity = _counterParity;
// button values
@synthesize valueLocSpeedButton = _valueLocSpeedButton;
@synthesize valueLocSpeedDetailsButton = _valueLocSpeedDetailsButton;
@synthesize valueLocFunctionsButton = _valueLocFunctionsButton;
@synthesize valueLocFunctionsDetailsButton = _valueLocFunctionsDetailsButton;
@synthesize valueLocFunctionsDetails2Button = _valueLocFunctionsDetails2Button;
@synthesize valueSwitchesButton = _valueSwitchesButton;
@synthesize valueSwitchesDetailsButton = _valueSwitchesDetailsButton;
@synthesize valueFeedbackButton = _valueFeedbackButton;
@synthesize valueFeedbackDetailsButton = _valueFeedbackDetailsButton;
@synthesize valuePoMButton = _valuePoMButton;
@synthesize valuePoMDetailsButton = _valuePoMDetailsButton;
@synthesize valueSaveButton = _valueSaveButton;
@synthesize valueStartButton = _valueStartButton;
// Always show
@synthesize textFieldLocAlwaysShow = _textFieldLocAlwaysShow;
@synthesize textFieldFeedbackAlwaysShow = _textFieldFeedbackAlwaysShow;

// Booleans to be used outside AppDelegate 
@synthesize showLocSpeed = _showLocSpeed;
@synthesize showLocSpeedDetails = _showLocSpeedDetails;
@synthesize showLocFunctions = _showLocFunctions;
@synthesize showLocFunctionsDetails = _showLocFunctionsDetails;
@synthesize showLocFunctionsDetails2 = _showLocFunctionsDetails2;
@synthesize showSwitches = _showSwitches;
@synthesize showSwitchesDetails = _showSwitchesDetails;
@synthesize showFeedback = _showFeedback;
@synthesize showFeedbackDetails = _showFeedbackDetails;
@synthesize showPoM = _showPoM;
@synthesize showPoMDetails = _showPoMDetails;
@synthesize saveToFile = _saveToFile;


// ***********************************************************************
// *************************** GENERAL METHODS ***************************
// ***********************************************************************
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  // Initialise the frame object to store the data we'll read from file / TCP
  _frame = [[FrameObject alloc] init];
  // Allocate memory for a new instance of the fileInput class and initialise it
  _fileInputObject = [[FileInputClass alloc] init];
  // Allocate memory for a new instance of the fileOutput class and initialise it
  _fileOutputObject = [[FileOutputClass alloc] init];
  // Allocate memory for a new instance of the ValuesToShow class and initialise it
  _valuesToShow = [[ValuesToShow alloc] init];
  [_valuesToShow initValuesToShow];
  [self updateAlwaysShowFields];
  [_progress setDisplayedWhenStopped: NO];
  [_lenzProgress setDisplayedWhenStopped: NO];
  // Check if the preferences file exists
  [self checkPreferences];
  // Initialise what is shown by default 
  [self buttonLocSpeed:self];
  [self buttonLocSpeedDetails:self];
  [self buttonLocFunctions:self];
  [self buttonLocFunctionsDetails:self];
  [self buttonLocFunctionsDetails2:self];
  [self buttonSwitches:self];
  [self buttonSwitchesDetails:self];;
  [self buttonFeedback:self];
  [self buttonFeedbackDetails:self];
  [self buttonPoM:self];
  [self buttonPoMDetails:self];
  [self buttonSave:self];
  // Run a 1 second timer to update the status lines and counters
  _timerStatus = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateStatusInfo:) userInfo:nil repeats:YES];
}

- (void)dealloc {[super dealloc];}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {return YES;}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
  [_TCPInputDCCMonObject closeDCCMonConnection];
  [_TCPInputLenzObject closeLenzConnection];
  [_fileInputObject closeFile];
  [_fileOutputObject closeOutputFile];
  return NSTerminateNow;
}

// ***********************************************************************
// *********************** SELECT OPERATION MODE *************************
// ***********************************************************************
- (IBAction)buttonStart:(id)sender {
  if ([_valueStartButton state]) {   
    // Initialise all values (again)
    [_valuesToShow initValuesToShow];
    // Allocate memory and initialise the _TCPInputDCCMonObject 
    _TCPInputDCCMonObject = [[TCPInputDCCMonClass alloc] init];
    // Allocate memory and initialise the _TCPInputLenzObject
    _TCPInputLenzObject = [[TCPInputLenzClass alloc] init];
    // Now open the TCP connections for the DCCMon and Lenz interface
    [_TCPInputDCCMonObject openDCCMonConnection];
    [_TCPInputLenzObject openLenzConnection];
    [self setButtonTitleFor:_valueStartButton toString:@"RECEIVING" withColor:[NSColor redColor]];
  }
  else {
    // close the TCP connections
    [_TCPInputDCCMonObject closeDCCMonConnection];
    [_TCPInputLenzObject closeLenzConnection];
    [self setButtonTitleFor:_valueStartButton toString:@"START" withColor:[NSColor blackColor]];
  }  
}


// ***********************************************************************
// *********************** SET DISPLAY OPTIONS ***************************
// ***********************************************************************
- (IBAction)buttonLocSpeed:(id)sender{
  if ([_valueLocSpeedButton state]) _showLocSpeed = 1;
  else _showLocSpeed = 0;   
}

- (IBAction)buttonLocSpeedDetails:(id)sender{
  if ([_valueLocSpeedDetailsButton state]) _showLocSpeedDetails = 1;
  else _showLocSpeedDetails = 0;   
}

- (IBAction)buttonLocFunctions:(id)sender {
  if ([_valueLocFunctionsButton state]) _showLocFunctions = 1;
  else _showLocFunctions = 0;   
}

- (IBAction)buttonLocFunctionsDetails:(id)sender {
  if ([_valueLocFunctionsDetailsButton state]) _showLocFunctionsDetails = 1;
  else _showLocFunctionsDetails = 0;   
}

- (IBAction)buttonLocFunctionsDetails2:(id)sender {
  if ([_valueLocFunctionsDetails2Button state]) _showLocFunctionsDetails2 = 1;
  else _showLocFunctionsDetails2 = 0;   
}

- (IBAction)buttonSwitches:(id)sender{
  if ([_valueSwitchesButton state]) _showSwitches = 1;
  else _showSwitches = 0;   
}

- (IBAction)buttonSwitchesDetails:(id)sender{
  if ([_valueSwitchesDetailsButton state]) _showSwitchesDetails = 1;
  else _showSwitchesDetails = 0;   
}

- (IBAction)buttonFeedback:(id)sender{
  if ([_valueFeedbackButton state]) _showFeedback = 1;
  else _showFeedback = 0;   
}

- (IBAction)buttonFeedbackDetails:(id)sender{
  if ([_valueFeedbackDetailsButton state]) _showFeedbackDetails = 1;
  else _showFeedbackDetails = 0;   
}

- (IBAction)buttonPoM:(id)sender{
  if ([_valuePoMButton state]) _showPoM = 1;
  else _showPoM = 0;   
}

- (IBAction)buttonPoMDetails:(id)sender{
  if ([_valuePoMDetailsButton state]) _showPoMDetails = 1;
  else _showPoMDetails = 0;   
}


- (IBAction)buttonSave:(id)sender {
  if ([_valueSaveButton state]) {
    _saveToFile = 1;
    if (_fileInputObject.infile != nil) [_fileOutputObject openOutputFile];
    if (_TCPInputDCCMonObject.iStreamDCC != nil) [_fileOutputObject openOutputFile];
  }
  else {
    [_fileOutputObject closeOutputFile];
    _saveToFile = 0; 
  }
}


// ***********************************************************************
// ********************* ALWAYS SHOW LOC / FEEDBACK **********************
// ***********************************************************************
- (void)updateAlwaysShowFields {
  [_textFieldLocAlwaysShow setFloatValue:[_valuesToShow alwaysShowLoc]];
  [_textFieldFeedbackAlwaysShow setFloatValue:[_valuesToShow alwaysShowFeedback]];
}

- (IBAction)takeLocAlwaysShow:(id)sender {
  int newValue = [sender intValue];  
  [_valuesToShow setAlwaysShowLoc:newValue];
}

- (IBAction)takeFeedbackAlwaysShow:(id)sender {
  int newValue = [sender intValue];  
  [_valuesToShow setAlwaysShowFeedback:newValue];
}


// ************************************************************************************************************
// ************************************ METHODS TO SHOW THE PACKET CONTENTS ***********************************
// ************************************************************************************************************
- (void)showPacket {
  // We have to copy the _valuesToShow.aStringLocFunctions to a new string instance, to avoid that later changes would change he output.
  NSMutableAttributedString *newStringForFunctions = [[NSMutableAttributedString alloc] initWithString:@"XYZ"];
  [newStringForFunctions setAttributedString: _valuesToShow.aStringLocFunctions];
  // Same for _valuesToShow.aStringSwitches
  NSMutableAttributedString *newStringForSwitches = [[NSMutableAttributedString alloc] initWithString:@"XYZ"];
  [newStringForSwitches setAttributedString: _valuesToShow.aStringSwitches];
  // Same for _valuesToShow.aStringFeedback
  NSMutableAttributedString *newStringForFeedback = [[NSMutableAttributedString alloc] initWithString:@"XYZ"];
  [newStringForFeedback setAttributedString: _valuesToShow.aStringFeedback];
  
  
  
  NSDictionary *dict =[NSDictionary dictionaryWithObjectsAndKeys:
                       _valuesToShow.stringTime,          @"TimeField",
                       _valuesToShow.stringLocAddress,    @"LocAddress",
                       _valuesToShow.stringLocSpeed,      @"Speed",
                       _valuesToShow.stringLocDirection,  @"Direction",
                       _valuesToShow.stringCvNumber,      @"PomCv",
                       _valuesToShow.stringCvValue,       @"PomValue",
                       _valuesToShow.stringRsAddress,     @"RsAddress",
                       newStringForFunctions,             @"Functions",
                       newStringForSwitches,              @"SwitchAddress",
                       newStringForFeedback,              @"RsValue",
                       nil];
  // Add it to the arrayController
  [self.messageArray addObject:dict];
  [self.messageWindow reloadData];
  // Show last line of the scroll window
  NSInteger numberOfRows = [self.messageWindow numberOfRows];
  if (numberOfRows > 0) [self.messageWindow scrollRowToVisible:numberOfRows - 1];
  // Release the temporary strings
  [newStringForFunctions release];
  [newStringForSwitches release];
  [newStringForFeedback release];
}


// ************************************************************************************************************
// **************************************** METHODS TO COLOR BUTTONS ******************************************
// ************************************************************************************************************
- (void)setButtonTitleFor:(NSButton*)button toString:(NSString*)title withColor:(NSColor*)color {
  NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
  [style setAlignment:NSTextAlignmentCenter];
  NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   color, NSForegroundColorAttributeName, style, NSParagraphStyleAttributeName, nil];
  NSAttributedString *attrString = [[NSAttributedString alloc]
                                    initWithString:title attributes:attrsDictionary];
  [button setAttributedTitle:attrString];
  [style release];
  [attrString release]; 
}


// ************************************************************************************************************
// ************************** METHODS FOR STATUS LINE AND PROGRESS INDICATOR **********************************
// ************************************************************************************************************
- (void)updateStatusInfo:(NSTimer *) timer {
  [_TCPInputDCCMonObject checkDCCMonConnectionStatus];
  [_TCPInputLenzObject checkLenzConnectionStatus];
  [_valuesToShow showStatistics];
}

- (void)showStatusLine:(NSString *) statustext {
  [self.dccMonStatus setObjectValue:statustext];
}

- (void)dccMonprogressIndicator:(BOOL) activity {
  if (activity == YES) [self.progress startAnimation: self];
  if (activity == NO)  [self.progress stopAnimation: self];
}

- (void)lenzprogressIndicator:(BOOL) activity {
  if (activity == YES) [self.lenzProgress startAnimation: self];
  if (activity == NO)  [self.lenzProgress stopAnimation: self];
}


// ************************************************************************************************************
// ********************************************* PREFERENCES **************************************************
// ************************************************************************************************************
-(IBAction)showPreferences:(id)sender { 
  if (self.preferencesController == nil)
    self.preferencesController = [[PreferencesController alloc] initWithWindowNibName:@"PreferencesController"];
  [self.preferencesController showWindow:self]; 
}


- (void)checkPreferences{
  // Test if we can read the Preferences
  NSString *test1 = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultIpAddressDCCMon"];
  NSString *test2 = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultIpAddressLenz"];
  NSString *test3 = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultPortDCCMon"];
  NSString *test4 = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultPortLenz"];
  NSString *test5 = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultSaveDirectory"];
  NSString *test6 = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultLenzSystem"];
  // Check if all preferences exist
  if ((test1 == nil) || (test2 == nil) ||(test3 == nil) ||(test4 == nil) ||(test5 == nil) ||(test6 == nil)) [self initialisePreferences];
}


- (void)initialisePreferences{
  // Create a new preferences file
  [[NSUserDefaults standardUserDefaults] setObject:@"192.168.24.210"        forKey:@"defaultIpAddressDCCMon"];
  [[NSUserDefaults standardUserDefaults] setObject:@"192.168.24.213"        forKey:@"defaultIpAddressLenz"];
  [[NSUserDefaults standardUserDefaults] setObject:@"5970"                 forKey:@"defaultPortDCCMon"];
  [[NSUserDefaults standardUserDefaults] setObject:@"5550"                 forKey:@"defaultPortLenz"];
  [[NSUserDefaults standardUserDefaults] setObject:@"/"                    forKey:@"defaultSaveDirectory"];
  [[NSUserDefaults standardUserDefaults] setObject:@"1"                    forKey:@"defaultLenzSystem"];
}



@end


