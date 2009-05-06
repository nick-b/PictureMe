//
//  PictureMeController.h
//  PictureMe
//
//  Created by Jeremy Collins on 3/30/09.
//  Copyright 2009 Jeremy Collins. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CameraController.h"

@interface PictureMeController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    CameraController *camera;
    
    UIActivityIndicatorView *activity;
    UILabel *activityLabel;
}

@property (nonatomic, retain) CameraController *camera;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activity;
@property (nonatomic, retain) IBOutlet UILabel *activityLabel;

- (void)savedImage:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;

@end
