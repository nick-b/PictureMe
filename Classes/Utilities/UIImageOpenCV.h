//
//  UIImageOpenCV.h
//  Whiteboard
//
//  Created by Jeremy Collins on 3/2/09.
//  Copyright 2009 Jeremy Collins. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cv.h"

@interface UIImage (OpenCV) 

+ (UIImage *)imageWithCVImage:(IplImage *)cvImage;

- (IplImage *)cvImage;

- (IplImage *)cvGrayscaleImage;

@end
