//
//  MementoAppDelegate.m
//  Memento
//
//  Created by Andre Foeken on 5/3/09.
//  Copyright Nedap 2009. All rights reserved.
//

#import "MementoAppDelegate.h"
#import "MementoViewController.h"

@implementation MementoAppDelegate

@synthesize window;
@synthesize viewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    
    // Override point for customization after app launch    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
	[viewController getApplicationHealthData];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url { 
	BOOL flag = NO;
	if([[url resourceSpecifier] length] == 42) { 
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];		
		[defaults setValue:[[url resourceSpecifier] substringFromIndex:2] forKey:@"license_key"];
		[defaults synchronize];
		flag = YES;
		[viewController getApplicationHealthData];
	}
	return flag; 
} 


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
