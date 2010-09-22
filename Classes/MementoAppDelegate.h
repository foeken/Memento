//
//  MementoAppDelegate.h
//  Memento
//
//  Created by Andre Foeken on 5/3/09.
//  Copyright Nedap 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MementoViewController;

@interface MementoAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    MementoViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet MementoViewController *viewController;

@end

