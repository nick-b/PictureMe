//
//  TouchCameraAppDelegate.m
//  TouchCamera
//
//  Created by Jeremy Collins on 3/11/09.
//  Copyright Jeremy Collins 2009. All rights reserved.
//

#import "TouchCameraAppDelegate.h"

@implementation TouchCameraAppDelegate

@synthesize window;
@synthesize main;

- (void)applicationDidFinishLaunching:(UIApplication *)application {    

    // Override point for customization after application launch
    [window addSubview:[main view]];
    [window makeKeyAndVisible];
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

- (void)dealloc {
    [window release];
    [super dealloc];
}


@end
