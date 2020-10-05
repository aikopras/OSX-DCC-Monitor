//
//  FileMenuController.m
//  dccmon
//
//  Created by Aiko Pras on 22-05-12.
//

#import "AppDelegate.h"
#import "FileMenuController.h"

@implementation FileMenuController

@synthesize topObject = _topObject;

- (IBAction)doOpen:(id)pId; { 
  // Make sure we can access the properties and methods of the APPDelegate and dccDecoder Object
  _topObject = ((AppDelegate *) [[NSApplication sharedApplication] delegate]);
  // Create an "Open" panel, allow only files with extension ".dcc", and open the file
  NSOpenPanel *oPanel = [NSOpenPanel openPanel];
  [oPanel setAllowedFileTypes:[NSArray arrayWithObject:@"dcc"]];
  NSInteger result = [oPanel runModal];
  if (result == NSModalResponseOK) {
//  if (result == NSModalResponseOK) {
    NSArray *fileToOpen = [oPanel URLs];
    NSURL *fileURL = [fileToOpen objectAtIndex:0];
    NSString *fileString =  [fileURL path];
    [_topObject.fileInputObject openFile:fileString];
  }
}


@end
