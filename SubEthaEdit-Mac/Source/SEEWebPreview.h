//
//  SEEWebPreview.h
//  SubEthaEdit
//
//  Created by Matthias Bartelmeß on 16.11.19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SEEWebPreview : NSObject

- (instancetype)initWithURL:(NSURL *)url;
- (NSString *)webPreviewForText:(NSString *)text;
@end
