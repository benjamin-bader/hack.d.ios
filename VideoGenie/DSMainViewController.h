//
//  DSMainViewController.h
//  VideoGenie
//
//  Created by Benjamin Bader on 1/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DSMainViewController : UIViewController<UIImagePickerControllerDelegate, UINavigationControllerDelegate>

-(IBAction) chooseVideo;

@property (retain) IBOutlet UIButton *buttonChooseVideo;
@property (retain) IBOutlet UIProgressView *progressView;

@end
