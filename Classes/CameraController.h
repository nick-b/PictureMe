//
//  CameraController.h
//  TouchCamera
//
//  Created by Jeremy Collins on 3/11/09.
//  Copyright 2009 Jeremy Collins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIImageAdditions.h"

@interface CameraController : UIImagePickerController {
    NSTimer *faceTimer;
    NSTimer *previewTimer;
        
    CvHaarClassifierCascade *model;
    
    UIView *camera;
    
    BOOL isPreview;
    BOOL isDisplayed;
    
    UIDeviceOrientation o;
}

@property (nonatomic, retain) NSTimer *faceTimer;
@property (nonatomic, retain) NSTimer *previewTimer;
@property (nonatomic, assign) CvHaarClassifierCascade *model;

+ (CameraController *)instance;

@end
