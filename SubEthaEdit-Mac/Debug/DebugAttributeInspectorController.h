//
//  DebugAttributeInspectorController.h
//  SubEthaEdit
//
//  Created by Dominik Wagner on 04.06.07.
//  Copyright 2007 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DebugAttributeInspectorController : NSWindowController {

    IBOutlet NSArrayController *O_attributesContentController;
    IBOutlet NSArrayController *O_foldingTextStorageAttributesContentController;

}

@end
