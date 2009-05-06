//
//  PictureMeController.m
//  PictureMe
//
//  Created by Jeremy Collins on 3/30/09.
//  Copyright 2009 Jeremy Collins. All rights reserved.
//

#import "PictureMeController.h"
#import "UIImageAdditions.h"

@implementation PictureMeController

@synthesize camera;
@synthesize activity;
@synthesize activityLabel;

- (void)viewDidLoad {
    self.activity.hidden = NO;
    self.activityLabel.hidden = NO;
    
    self.camera = [CameraController instance];
    self.camera.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.camera.delegate = self;
    
    self.activity.hidden = YES;
    //self.activityLabel.text = @"Loading..."; 
}

- (void)viewDidAppear:(BOOL)animated {
    [self presentModalViewController:[CameraController instance] animated:YES];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self presentModalViewController:[CameraController instance] animated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker 
        didFinishPickingImage:(UIImage *)image
                  editingInfo:(NSDictionary *)editingInfo {
    
    self.activity.hidden = NO;
    self.activityLabel.text = @"Saving photograph...";
    self.activityLabel.hidden = NO;
        
    [camera dismissModalViewControllerAnimated:YES];
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(savedImage:didFinishSavingWithError:contextInfo:), nil);
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissModalViewControllerAnimated:YES];
    self.activityLabel.text = @"Tap screen to active camera.";
}

- (void)savedImage:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    [self presentModalViewController:[CameraController instance] animated:YES];
    self.activity.hidden = YES;
    self.activityLabel.text = @"Tap screen to active camera.";    
    self.activityLabel.hidden = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark UINavigationControllerDelegate Methods

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
}

- (void)dealloc {
    [super dealloc];
}

@end
