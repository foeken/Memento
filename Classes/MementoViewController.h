//
//  MementoViewController.h
//  Memento
//
//  Created by Andre Foeken on 5/3/09.
//  Copyright Nedap 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MementoViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAccelerometerDelegate> {
	IBOutlet UITableViewCell *defaultCell;
	NSMutableData *responseData;
	NSArray *applications;
}

- (void)showConnectionError;
- (void) getApplicationHealthData;
- (UIImage*) imageForThreshold:(NSString*)threshold;

@end

