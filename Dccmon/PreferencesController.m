//
//  PreferencesController.m
//  Simple CV Editor
//
//  Created by Aiko Pras on 26-02-12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PreferencesController.h"

@implementation PreferencesController

/*
- (id)initWithWindow:(NSWindow *)window
{
    NSLog(@"initWithWindow 1");
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
        NSLog(@"initWithWindow 2");
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    NSLog(@"windowDidLoad");
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}
*/


- (void)windowDidLoad
{
  [super windowDidLoad];
  // Use the light gray window background of the classic macOS design (sRGB 235), so input fields stand out
  [[self window] setBackgroundColor:[NSColor colorWithSRGBRed:235/255.0 green:235/255.0 blue:235/255.0 alpha:1.0]];
}


@end
