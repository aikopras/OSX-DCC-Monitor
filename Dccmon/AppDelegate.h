//
//  AppDelegate.h
//  dccmon-cocao
//
//  Created by Aiko Pras on 17-04-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FrameStoreObject.h"
#import <sys/time.h>


@class DccObject;
@class RsObject;
@class TCPInputDCCMonClass;
@class TCPInputLenzClass;
@class FileInputClass;
@class FileOutputClass;
@class ValuesToShow;
@class PreferencesController;
@class FileMenuController;

@interface AppDelegate : NSObject <NSStreamDelegate>


// Declare properties for objects and controllers
@property (retain) FileInputClass *fileInputObject;
@property (retain) FileOutputClass *fileOutputObject;
@property (retain) TCPInputDCCMonClass *TCPInputDCCMonObject;
@property (retain) TCPInputLenzClass *TCPInputLenzObject;
@property (retain) PreferencesController *preferencesController;
@property (retain) ValuesToShow *valuesToShow;
@property (retain) FrameObject *frame;

// Declare properties for internal use
@property (assign) NSTimer *timerStatus;


// ***************************************************************************************
// ********************************** USER INTERFACE *************************************
// ***************************************************************************************
// General properties to User Interface objects
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTableView *messageWindow;
@property (assign) IBOutlet NSArrayController *messageArray;

// Properties for the status bar
@property (assign) IBOutlet NSTextField *dccMonStatus;
@property (assign) IBOutlet NSTextField *lenzStatus;
@property (assign) IBOutlet NSProgressIndicator *progress;
@property (assign) IBOutlet NSProgressIndicator *lenzProgress;

@property (assign) IBOutlet NSTextField *counterDccPackets;
@property (assign) IBOutlet NSTextField *counterIdle;
@property (assign) IBOutlet NSTextField *counterReset;
@property (assign) IBOutlet NSTextField *counterForFutureUse;
@property (assign) IBOutlet NSTextField *counterLocSpeed;
@property (assign) IBOutlet NSTextField *counterF0F12;
@property (assign) IBOutlet NSTextField *counterF13F28;
@property (assign) IBOutlet NSTextField *counterCvAccess;
@property (assign) IBOutlet NSTextField *counterAccessory;
@property (assign) IBOutlet NSTextField *counterFeedback;
@property (assign) IBOutlet NSTextField *counterServiceMode;
@property (assign) IBOutlet NSTextField *counterRest;
@property (assign) IBOutlet NSTextField *counterParity;

// User Interface properties related to buttons
@property (assign) IBOutlet NSButton *valueLocSpeedButton;
@property (assign) IBOutlet NSButton *valueLocSpeedDetailsButton;
@property (assign) IBOutlet NSButton *valueLocFunctionsButton;
@property (assign) IBOutlet NSButton *valueLocFunctionsDetailsButton;
@property (assign) IBOutlet NSButton *valueLocFunctionsDetails2Button;
@property (assign) IBOutlet NSButton *valueSwitchesButton;
@property (assign) IBOutlet NSButton *valueSwitchesDetailsButton;
@property (assign) IBOutlet NSButton *valueFeedbackButton;
@property (assign) IBOutlet NSButton *valueFeedbackDetailsButton;
@property (assign) IBOutlet NSButton *valuePoMButton;
@property (assign) IBOutlet NSButton *valuePoMDetailsButton;
@property (assign) IBOutlet NSButton *valueSaveButton;
@property (assign) IBOutlet NSButton *valueStartButton;
// Properties to store the setting of these buttons
@property (assign) NSUInteger showLocSpeed;
@property (assign) NSUInteger showLocSpeedDetails;
@property (assign) NSUInteger showLocFunctions;
@property (assign) NSUInteger showLocFunctionsDetails;
@property (assign) NSUInteger showLocFunctionsDetails2;
@property (assign) NSUInteger showSwitches;
@property (assign) NSUInteger showSwitchesDetails;
@property (assign) NSUInteger showFeedback;
@property (assign) NSUInteger showFeedbackDetails;
@property (assign) NSUInteger showPoM;
@property (assign) NSUInteger showPoMDetails;
@property (assign) NSUInteger saveToFile;
// Properties related the "Always show"
@property (assign) IBOutlet NSTextField *textFieldLocAlwaysShow;
@property (assign) IBOutlet NSTextField *textFieldFeedbackAlwaysShow;


// Actions triggered by the User Interface buttons
- (IBAction)buttonLocSpeed:(id)sender;
- (IBAction)buttonLocSpeedDetails:(id)sender;
- (IBAction)buttonLocFunctions:(id)sender;
- (IBAction)buttonLocFunctionsDetails:(id)sender;
- (IBAction)buttonLocFunctionsDetails2:(id)sender;
- (IBAction)buttonSwitches:(id)sender;
- (IBAction)buttonSwitchesDetails:(id)sender;
- (IBAction)buttonFeedback:(id)sender;
- (IBAction)buttonFeedbackDetails:(id)sender;
- (IBAction)buttonPoM:(id)sender;
- (IBAction)buttonPoMDetails:(id)sender;
- (IBAction)buttonSave:(id)sender;
- (IBAction)buttonStart:(id)sender;
- (IBAction)takeLocAlwaysShow:(id)sender;
- (IBAction)takeFeedbackAlwaysShow:(id)sender;


// ***************************************************************************************
// ********************************** GENERAL METHODS ************************************
// ***************************************************************************************
- (IBAction)showPreferences:(id)sender;

- (void)showPacket;
- (void)dccMonprogressIndicator:(BOOL) activity;
- (void)lenzprogressIndicator:(BOOL) activity;
- (void)showStatusLine:(NSString *) statustext;
- (void)initialisePreferences;
- (void)setButtonTitleFor:(NSButton*)button toString:(NSString*)title withColor:(NSColor*)color;


@end
