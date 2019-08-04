//
//  SEEWorkspaceController.h
//  SubEthaEdit
//
//  Created by Matthias Bartelmeß on 03.08.19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SEEWorkspace;

@interface SEEWorkspaceController : NSObject {

    @private
    NSMutableArray <SEEWorkspace *> *workspaces;
}

-(SEEWorkspace *)workspaceForDocument:(NSDocument *)document;

// Creates a new workspace if none exists yet for the provided url
-(SEEWorkspace *)workspaceForURL:(NSURL *)url;

@end
