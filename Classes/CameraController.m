//
//  CameraController.m
//  TouchCamera
//
//  Created by Jeremy Collins on 3/11/09.
//  Copyright 2009 Jeremy Collins. All rights reserved.
//

#import "CameraController.h"
#import <QuartzCore/QuartzCore.h> 
#import "AudioToolbox/AudioServices.h"
#import "UIDeviceAdditions.h"

#define FREE_MEMORY [UIDevice currentDevice].availableMemory

#define OPAQUE_HEXCOLOR(c) [UIColor colorWithRed:((c>>16)&0xFF)/255.0 \
                                           green:((c>>8)&0xFF)/255.0 \
                                            blue:(c&0xFF)/255.0 \
                                           alpha:1.0]

extern CGImageRef UIGetScreenImage();

static CvMemStorage *storage = 0;

@implementation CameraController

@synthesize faceTimer;
@synthesize previewTimer;
@synthesize model;

static CameraController *instance = nil;

+ (CameraController *)instance {
	@synchronized(self) {
        if (instance == nil) {
            instance = [[self alloc] init];
            
            [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];  
            [[NSNotificationCenter defaultCenter] addObserver:instance
                                                     selector:@selector(deviceOrientationDidChange:)
                                                         name:@"UIDeviceOrientationDidChangeNotification"
                                                       object:nil]; 
        }
    }
    return instance;
}

-(void)setFaceTimer:(NSTimer *)timer {
	if (faceTimer != timer) {
		[faceTimer invalidate];
		[faceTimer release];
		faceTimer = [timer retain];
	}
}

-(void)setPreviewTimer:(NSTimer *)timer {
    if (previewTimer != timer) {
        [previewTimer invalidate];
        [previewTimer release];
        previewTimer = [timer retain];
    }
}

- (void)deviceOrientationDidChange:(id)ignore {
    UIDevice *device = [UIDevice currentDevice];
    o = device.orientation;
}

-(NSString *)stringPad:(int)numPad {
	NSMutableString *pad = [NSMutableString stringWithCapacity:1024];
	for (int i=0; i<numPad; i++) {
		[pad appendString:@"  "];
	}
	return pad; 
}

-(void)inspectView: (UIView *)theView depth:(int)depth path:(NSString *)path {
	
	if (depth==0) {
		NSLog(@"-------------------- <view hierarchy> -------------------");
	}
	
	NSString *pad = [self stringPad:depth];
	
	// print some information about the current view
	//
	NSLog([NSString stringWithFormat:@"%@.description: %@",pad,[theView description]]);
	if ([theView isKindOfClass:[UIImageView class]]) {
		NSLog([NSString stringWithFormat:@"%@.class: UIImageView",pad]);
	} else if ([theView isKindOfClass:[UILabel class]]) {
		NSLog([NSString stringWithFormat:@"%@.class: UILabel",pad]);
		NSLog([NSString stringWithFormat:@"%@.text: ",pad,[(UILabel *)theView text]]);		
	} else if ([theView isKindOfClass:[UIButton class]]) {
		NSLog([NSString stringWithFormat:@"%@.class: UIButton",pad]);
		NSLog([NSString stringWithFormat:@"%@.title: ",pad,[(UIButton *)theView titleForState:UIControlStateNormal]]);		
	}
	NSLog([NSString stringWithFormat:@"%@.frame: %.0f, %.0f, %.0f, %.0f", pad, theView.frame.origin.x, theView.frame.origin.y,
		   theView.frame.size.width, theView.frame.size.height]);
	NSLog([NSString stringWithFormat:@"%@.subviews: %d",pad, [theView.subviews count]]);
	NSLog(@" ");
	
	// gotta love recursion: call this method for all subviews
	//
	for (int i=0; i<[theView.subviews count]; i++) {
		NSString *subPath = [NSString stringWithFormat:@"%@/%d",path,i];
		NSLog([NSString stringWithFormat:@"%@--subview-- %@",pad,subPath]);		
		[self inspectView:[theView.subviews objectAtIndex:i]  depth:depth+1 path:subPath];
	}
	
	if (depth==0) {
		NSLog(@"-------------------- </view hierarchy> -------------------");
	}
	
}

- (void)detectFaceThread {
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [self retain];
    
    //NSLog(@"Face Detection starting: %f", FREE_MEMORY);
    
    self.faceTimer = nil;
    
    if(self.model == nil) {
        NSString *file = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_alt2.xml" ofType:@"gz"];
        self.model = (CvHaarClassifierCascade *) cvLoad([file cStringUsingEncoding:NSASCIIStringEncoding], 0, 0, 0);
    }
    
#if !TARGET_IPHONE_SIMULATOR
        
    CGImageRef screen = UIGetScreenImage();
    UIImage *viewImage = [UIImage imageWithCGImage:screen];
    CGImageRelease(screen);
    CGRect scaled;
    scaled.size = viewImage.size;
    scaled.size.width *= .5;
    scaled.size.height *= .5;
    viewImage = [viewImage scaleImage:scaled];
    //[UIImage imageWithCGImage:(CGImageRef)cameraView.layer.contents];
    
    IplImage *snapshot = [viewImage cvGrayscaleImage];
    IplImage *snapshotRotated = cvCloneImage(snapshot);
    cvEqualizeHist(snapshot, snapshot);
    
    float angle = 0;
    if(o == UIDeviceOrientationLandscapeLeft) {
        angle = 90;
    } else if(o == UIDeviceOrientationLandscapeRight) {
        angle = -90;
    } 
    
    if(angle != 0) {
        CvPoint2D32f center;
        CvMat *translate = cvCreateMat(2, 3, CV_32FC1);
        cvSetZero(translate);
        center.x = viewImage.size.width / 2;
        center.y = viewImage.size.height / 2;
        cv2DRotationMatrix(center, angle, 1.0, translate);
        cvWarpAffine(snapshot, snapshotRotated, translate, CV_INTER_LINEAR + CV_WARP_FILL_OUTLIERS, cvScalarAll(0));
        cvReleaseMat(&translate);   
    }
    
    storage = cvCreateMemStorage(0);
    
    double t = (double)cvGetTickCount();
    CvSeq* faces = cvHaarDetectObjects(snapshotRotated, self.model, storage,
                                       1.1, 2, CV_HAAR_DO_CANNY_PRUNING,
                                       cvSize(30, 30));
    t = (double)cvGetTickCount() - t;
    
    NSLog(@"Face detection time %gms FOUND(%d)", t/((double)cvGetTickFrequency()*1000), faces->total);
        
    if(faces->total > 0) {
        
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        
        //[NSThread sleepForTimeInterval:.25f];
        
        UIButton *button = [[[[[[[[[[[[self.view subviews] objectAtIndex:0]
                                                 subviews] objectAtIndex:0]
                                                 subviews] objectAtIndex:0]
                                                 subviews] objectAtIndex:3]
                                                 subviews] objectAtIndex:2]
                                                 subviews] objectAtIndex:1];
        
        [button sendActionsForControlEvents:UIControlEventTouchUpInside];  
    } else {
        [self performSelectorOnMainThread:@selector(reschedule) withObject:nil waitUntilDone:NO];
    }
    
    cvReleaseImage(&snapshot);
    cvReleaseImage(&snapshotRotated);
    cvReleaseMemStorage(&storage);
    
#endif
 
    [pool release];
    [self release];
}

-(void)vibrate {
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

-(void)reschedule {
    if(!isPreview && isDisplayed) {
        self.faceTimer = [NSTimer scheduledTimerWithTimeInterval:.10 
                                                          target:self 
                                                        selector:@selector(detectFace) 
                                                        userInfo:nil repeats:YES];    
    }
}

-(void)detectFace {
    self.faceTimer = nil;
    [self performSelectorInBackground:@selector(detectFaceThread) withObject:nil];    
}

-(void)previewCheck {
    
    UIView *preview = [[[[[[[[self.view subviews] objectAtIndex:0]
                            subviews] objectAtIndex: 0]
                          subviews] objectAtIndex: 0]
                        subviews] objectAtIndex: 2];
    
    // preview view path is /0/0/0/2, by default without a subview
    // if it has a subview, preview image is showing, so fix transform
    //
    if ([preview.subviews count] != 0 && !isPreview) {
        isPreview = YES;
    }
}

- (void)viewDidAppear: (BOOL)animated {
	[super viewDidAppear:animated];
    
    isPreview = NO;
    isDisplayed = YES;
    
    self.faceTimer = [NSTimer scheduledTimerWithTimeInterval:.25 
														 target:self 
                                                       selector:@selector(detectFace) 
                                                       userInfo:nil repeats:YES];

    self.previewTimer = [NSTimer scheduledTimerWithTimeInterval:.25
                                                         target:self
                                                       selector:@selector(previewCheck)
                                                       userInfo:nil repeats:YES];    
    
#if !TARGET_IPHONE_SIMULATOR
  
    [self inspectView:self.view depth:0 path:@""];
    
//#if 0
    if(self.sourceType == UIImagePickerControllerSourceTypeCamera) {
        UIImageView *overlay = [[[[[[[[[[self.view subviews] objectAtIndex:0]
                                       subviews] objectAtIndex:0]
                                     subviews] objectAtIndex:0]
                                  subviews] objectAtIndex:3]
                                subviews] objectAtIndex:0];  
        
        UILabel *label = [[[[[[[[[[self.view subviews] objectAtIndex:0]
                                subviews] objectAtIndex:0]
                              subviews] objectAtIndex:0]
                            subviews] objectAtIndex:3]
                          subviews] objectAtIndex:1];
                
        UIButton *button = [[[[[[[[[[[[self.view subviews] objectAtIndex:0]
                                     subviews] objectAtIndex:0]
                                   subviews] objectAtIndex:0]
                                 subviews] objectAtIndex:3]
                               subviews] objectAtIndex:2]
                             subviews] objectAtIndex:0];
        
        [button addTarget:self action:@selector(cancelButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *captureButton = [[[[[[[[[[[[self.view subviews] objectAtIndex:0]
                                     subviews] objectAtIndex:0]
                                   subviews] objectAtIndex:0]
                                 subviews] objectAtIndex:3]
                               subviews] objectAtIndex:2]
                             subviews] objectAtIndex:1];
        
        [captureButton addTarget:self action:@selector(captureButtonAction:) forControlEvents:UIControlEventTouchUpInside];        
                    
        label.hidden = YES;
        overlay.hidden = YES;        
    }
#endif
	
}

- (void)captureButtonAction:(id)sender {
    self.faceTimer = nil;

}

- (void)cancelButtonAction:(id)sender {
    
	if (isPreview) {
        isPreview = NO;
        [self performSelectorOnMainThread:@selector(reschedule) withObject:nil waitUntilDone:YES];        
    } else {
        self.faceTimer = nil;
        [self dismissModalViewControllerAnimated:YES];        
    }
    
}

- (void)viewDidDisappear:(BOOL)animated {
    self.faceTimer = nil;
    self.previewTimer = nil;
    isDisplayed = NO;
	
	[super viewDidDisappear:animated];
}

-(void) dealloc {
    self.faceTimer = nil;
    self.previewTimer = nil;
    
	[super dealloc];
}

@end
