//
//  UIImageResizing.h
//  Whiteboard
//
//  Created by Jeremy Collins on 2/24/09.
//  Copyright 2009 Jeremy Collins. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIImage (Resize)
- (UIImage*)scaleToSize:(CGSize)size;

- (UIImage *)scaleAndRotate:(CGRect)rect;

- (UIImage *)scaleImage:(CGRect)rect;

- (UIImage*)imageByCropping:(CGRect)rect;

- (UIImage *)grayscale;

@end