//
//  NSSavePanelTCMAdditions.h
//  SubEthaEdit
//
//  Created by Martin Ott on 2/20/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSSavePanel (AppleInternalAdditions)
- (id)_navView;
@end


@interface NSSavePanel (NSSavePanelTCMAdditions)

- (void)TCM_selectFilenameWithoutExtension;

@end
