//
//  TexturedButtonCell.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on Wed May 26 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TexturedButtonCell : NSButtonCell {
    NSImage *I_textureImage;
}
- (void)setTextureImage:(NSImage *)aImage;
@end
