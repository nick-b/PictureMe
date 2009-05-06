//
//  UIImageResizing.m
//  Whiteboard
//
//  Created by Jeremy Collins on 2/24/09.
//  Copyright 2009 Jeremy Collins. All rights reserved.
//

#import "UIImageResizing.h"

@implementation UIImage (Resizing)

- (UIImage*)scaleToSize:(CGSize)size {
	UIGraphicsBeginImageContext(size);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, 0.0, size.height);
	CGContextScaleCTM(context, 1.0, -1.0);
	
	CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, size.width, size.height), self.CGImage);
	
	UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return scaledImage;
}

- (UIImage *)scaleAndRotate:(CGRect)rect {
    
	CGImageRef imgRef = self.CGImage;
    
	CGFloat width = CGImageGetWidth(imgRef);
	CGFloat height = CGImageGetHeight(imgRef);
    
	CGAffineTransform transform = CGAffineTransformIdentity;
	CGRect bounds = CGRectMake(0, 0, width, height);
	if (width > rect.size.width || height > rect.size.height) {
		CGFloat ratio = width / height;
		if (ratio > 1) {
			bounds.size.width = rect.size.height;
			bounds.size.height = bounds.size.width / ratio;
		} else {
			bounds.size.height = rect.size.width;
			bounds.size.width = bounds.size.height * ratio;
		}
	}
	
	CGFloat scaleRatio = bounds.size.width / width;
	CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
	CGFloat boundHeight;
	switch(self.imageOrientation) {
			
		case UIImageOrientationUp: //EXIF = 1
			transform = CGAffineTransformIdentity;
			break;
			
		case UIImageOrientationUpMirrored: //EXIF = 2
			transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			break;
			
		case UIImageOrientationDown: //EXIF = 3
			transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
			transform = CGAffineTransformRotate(transform, M_PI);
			break;
			
		case UIImageOrientationDownMirrored: //EXIF = 4
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
			transform = CGAffineTransformScale(transform, 1.0, -1.0);
			break;
			
		case UIImageOrientationLeftMirrored: //EXIF = 5
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
			break;
			
		case UIImageOrientationLeft: //EXIF = 6
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
			break;
			
		case UIImageOrientationRightMirrored: //EXIF = 7
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeScale(-1.0, 1.0);
			transform = CGAffineTransformRotate(transform, M_PI / 2.0);
			break;
			
		case UIImageOrientationRight: //EXIF = 8
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
			transform = CGAffineTransformRotate(transform, M_PI / 2.0);
			break;
			
		default:
			[NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
			
	}
	
	UIGraphicsBeginImageContext(bounds.size);
    
	CGContextRef context = UIGraphicsGetCurrentContext();
    
	if (self.imageOrientation == UIImageOrientationRight || self.imageOrientation == UIImageOrientationLeft) {
		CGContextScaleCTM(context, -scaleRatio, scaleRatio);
		CGContextTranslateCTM(context, -height, 0);
	}
	else {
		CGContextScaleCTM(context, scaleRatio, -scaleRatio);
		CGContextTranslateCTM(context, 0, -height);
	}
	
	CGContextConcatCTM(context, transform);
	
	CGContextDrawImage(context, CGRectMake(0, 0, width, height), imgRef);
	UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return imageCopy;
}

- (UIImage *)scaleImage:(CGRect)rect {
    
	CGImageRef imgRef = self.CGImage;
    
	CGFloat width = CGImageGetWidth(imgRef);
	CGFloat height = CGImageGetHeight(imgRef);
    
	CGRect bounds = CGRectMake(0, 0, width, height);
	if (width > rect.size.width || height > rect.size.height) {
		CGFloat ratio = width/height;
		if (ratio > 1) {
			bounds.size.width = rect.size.height;
			bounds.size.height = round(bounds.size.width / ratio);
		} else {
			bounds.size.height = rect.size.width;
			bounds.size.width = round(bounds.size.height * ratio);
		}
	}
	
	CGFloat scaleRatio = bounds.size.width / width;
	    
    UInt8 *pixelData = (UInt8 *) malloc(bounds.size.width * bounds.size.height * 4);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixelData,
                                                 bounds.size.width, 
                                                 bounds.size.height, 8, 
                                                 bounds.size.width * 4,
                                                 colorspace,
                                                 kCGImageAlphaNoneSkipLast);        
    
    CGContextScaleCTM(context, scaleRatio, scaleRatio);
    //CGContextTranslateCTM(context, 0, -height);
        
	CGContextDrawImage(context, CGRectMake(0, 0, width, height), imgRef);
	CGImageRef imageRef = CGBitmapContextCreateImage(context);

    CGContextRelease(context);
    CGColorSpaceRelease(colorspace);
    free(pixelData);
    
	UIImage *imageCopy = [[UIImage alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);
    [imageCopy autorelease];
    
	return imageCopy;
}

- (UIImage*)imageByCropping:(CGRect)rect {
    
    //create a context to do our clipping in
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    
    //create a rect with the size we want to crop the image to
    //the X and Y here are zero so we start at the beginning of our
    //newly created context
    CGContextClipToRect(currentContext, rect);
    
    //create a rect equivalent to the full size of the image
    //offset the rect by the X and Y we want to start the crop
    //from in order to cut off anything before them
    CGRect drawRect = CGRectMake(0,
                                 0,
                                 self.size.width,
                                 self.size.height + rect.origin.y);
    
    //draw the image to our clipped context using our offset rect
    CGContextDrawImage(currentContext, rect, self.CGImage);
    
    //pull the image from our cropped context
    UIImage *cropped = UIGraphicsGetImageFromCurrentImageContext();
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    
    //Note: this is autoreleased
    return cropped;
}

- (UIImage *)grayscale {
    
    int w = self.size.width;
    int h = self.size.height;
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray();
    
    // Create a color bitmap context and write image into it.  This enables
    // access to the raw pixel data in RGBA format.
    UInt8 *pixelData = (UInt8 *) malloc(w * h);
    CGContextRef context = CGBitmapContextCreate(pixelData,
                                                 w, h, 8, w,
                                                 colorspace,
                                                 kCGImageAlphaNone);
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), self.CGImage);
    
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorspace);
    free(pixelData);
    
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return image;
}

@end