//
//  UIImageOpenCV.m
//  Whiteboard
//
//  Created by Jeremy Collins on 3/2/09.
//  Copyright 2009 Jeremy Collins. All rights reserved.
//

#import "UIImageOpenCV.h"

@implementation UIImage (OpenCV)

+ (UIImage *)imageWithCVImage:(IplImage *)cvImage {
    
    int x, y;
    int width = cvImage->width;
    int height = cvImage->height;
    int step = cvImage->widthStep;
    int stride = width;
    
    UInt8 *pixelData = (UInt8 *) malloc(width * height);
    UInt8 *cvdata = (UInt8 *) cvImage->imageData;
    
    // Equalize histogram.
    //IplImage *red = cvCreateImage(cvSize(width, height), 8, 1);
    //IplImage *green = cvCreateImage(cvSize(width, height), 8, 1);
    //IplImage *blue = cvCreateImage(cvSize(width, height), 8, 1);
    
    //cvCvtPixToPlane(cvImage, red, green, blue, NULL);
    //cvEqualizeHist(red, red);
    //cvEqualizeHist(green, green);
    //cvEqualizeHist(blue, blue);
    //cvCvtPlaneToPix(red, green, blue, NULL, cvImage);
    
    for(y = 0; y < height; y++) {
        UInt8 *row = (UInt8 *) pixelData + (y * stride);
        UInt8 *row1 = (UInt8 *) cvdata + (y * step);
        for(x = 0; x < width; x++) {
            int offset = x;
            int offset1 = x;
            row[offset]     = row1[offset1];  // R
            //row[offset + 1] = row1[offset1 + 1];  // G
            //row[offset + 2] = row1[offset1 + 0];  // B
            //row[offset + 3] = 255;
        }
    }

    NSData *rawBytes = [NSData dataWithBytesNoCopy:pixelData length:width * height];
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef) rawBytes);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceGray();
    
    CGImageRef imageRef = CGImageCreate(width, height, 
                                        8, 8,
                                        width,
                                        colorspace,
                                        kCGImageAlphaNoneSkipLast,
                                        provider, NULL, 
                                        YES,
                                        kCGRenderingIntentDefault);
    
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorspace);

    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return image;
}

- (CGContextRef)createARGBBitmapContext {
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    void *          bitmapData;
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
    
    // Get image width, height. We'll use the entire image.
    size_t pixelsWide = CGImageGetWidth(self.CGImage);
    size_t pixelsHigh = CGImageGetHeight(self.CGImage);
    
    // Declare the number of bytes per row. Each pixel in the bitmap in this
    // example is represented by 4 bytes; 8 bits each of red, green, blue, and
    // alpha.
    bitmapBytesPerRow   = (pixelsWide * 4);
    bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
    
    // Use the generic RGB color space.
    colorSpace = CGColorSpaceCreateDeviceRGB();
    if (colorSpace == NULL) {
        return NULL;
    }
    // Allocate memory for image data. This is the destination in memory
    // where any drawing to the bitmap context will be rendered.
    bitmapData = malloc(bitmapByteCount);
    if (bitmapData == NULL) {
        CGColorSpaceRelease(colorSpace);
        return NULL;
    }
    // Create the bitmap context. We want pre-multiplied ARGB, 8-bits
    // per component. Regardless of what the source image format is
    // (CMYK, Grayscale, and so on) it will be converted over to the format
    // specified here by CGBitmapContextCreate.
    context = CGBitmapContextCreate (bitmapData,
                                     pixelsWide,
                                     pixelsHigh,
                                     8,      // bits per component
                                     bitmapBytesPerRow,
                                     colorSpace,
                                     kCGImageAlphaPremultipliedFirst);
    if (context == NULL) {
        free (bitmapData);
    }
    // Make sure and release colorspace before returning
    CGColorSpaceRelease( colorSpace );
    return context;
}

- (IplImage *)cvImage {

    IplImage *cvImage = cvCreateImage(cvSize(CGImageGetWidth(self.CGImage), 
                                             CGImageGetHeight(self.CGImage)), 8, 3);
    
    // Create the bitmap context
    CGContextRef context = [self createARGBBitmapContext];
    if (context == NULL) {
        return nil;
    }
    
    int height,width,step,channels;
    uchar *cvdata;
    int x,y;
    height    = cvImage->height;
    width     = cvImage->width;
    step      = cvImage->widthStep;
    channels  = cvImage->nChannels;
    cvdata      = (uchar *)cvImage->imageData;
    
    CGRect rect = {{0,0},{width,height}};
    
    // Draw the image to the bitmap context. Once we draw, the memory
    // allocated for the context for rendering will then contain the
    // raw image data in the specified color space.
    CGContextDrawImage(context, rect, self.CGImage);
    
    // Now we can get a pointer to the image data associated with the bitmap
    // context.
    unsigned char *data = (unsigned char*) CGBitmapContextGetData (context);
    if (data != NULL) {
        for(y=0;y<height;y++) {
            for(x=0;x<width;x++) {
                cvdata[y*step+x*channels+0] = data[(4*y*width)+(4*x)+3];
                cvdata[y*step+x*channels+1] = data[(4*y*width)+(4*x)+2];
                cvdata[y*step+x*channels+2] = data[(4*y*width)+(4*x)+1];
            }
        }
    }
    
    // When finished, release the context
    CGContextRelease(context);
    
    // Free image data memory for the context
    if (data) {
        free(data);
    }
    
    return cvImage;
}

- (IplImage *)cvGrayscaleImage {
    
    IplImage *cvImage = cvCreateImage(cvSize(CGImageGetWidth(self.CGImage), 
                                             CGImageGetHeight(self.CGImage)), 8, 1);
    
    // Create the bitmap context
    CGContextRef context = [self createARGBBitmapContext];
    if (context == NULL) {
        return nil;
    }
    
    int height,width,step,channels;
    uchar *cvdata;
    int x,y;
    height    = cvImage->height;
    width     = cvImage->width;
    step      = cvImage->widthStep;
    channels  = cvImage->nChannels;
    cvdata      = (uchar *)cvImage->imageData;
    
    CGRect rect = {{0,0},{width,height}};
    
    // Draw the image to the bitmap context. Once we draw, the memory
    // allocated for the context for rendering will then contain the
    // raw image data in the specified color space.
    CGContextDrawImage(context, rect, self.CGImage);
    
    // Now we can get a pointer to the image data associated with the bitmap
    // context.
    unsigned char *data = (unsigned char*) CGBitmapContextGetData (context);
    if (data != NULL) {
        for(y=0;y<height;y++) {
            for(x=0;x<width;x++) {
                int intensity = 0.30 * data[(4*y*width)+(4*x)+1] + 
                                0.59 * data[(4*y*width)+(4*x)+2] + 
                                0.11 * data[(4*y*width)+(4*x)+3];
                
                
                cvdata[y*step+x*channels+0] = intensity;
                //cvdata[y*step+x*channels+1] = data[(4*y*width)+(4*x)+2];
                //cvdata[y*step+x*channels+2] = data[(4*y*width)+(4*x)+1];
            }
        }
    }
    
    // When finished, release the context
    CGContextRelease(context);
    
    // Free image data memory for the context
    if (data) {
        free(data);
    }
    
    return cvImage;
}


@end
