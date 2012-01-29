//
//  DSAppDelegate.h
//  VideoGenie
//
//  Created by Benjamin Bader on 1/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DSMainViewController.h"

@interface DSAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (retain) DSMainViewController *controller;

@end
