//
//  SEEWorkspaceDocument.h
//  SubEthaEdit
//
//  Created by Matthias Bartelmeß on 18.08.19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SEEWorkspace.h"



@interface SEEWorkspaceDocument : NSDocument<SEEWorkspaceDocument>

- (void)selectFileWithURL:(NSURL *)url;

@end


