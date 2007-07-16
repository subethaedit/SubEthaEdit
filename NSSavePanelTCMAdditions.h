//
//  NSSavePanelTCMAdditions.h
//  SubEthaEdit
//
//  Created by Martin Ott on 2/20/06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSObject (AppleInternalAdditions)
- (void)setShowsHiddenFiles:(BOOL)flag;
@end


@interface NSSavePanel (AppleInternalAdditions)
- (id)_navView;
@end


@interface NSSavePanel (NSSavePanelTCMAdditions)

- (BOOL)canShowHiddenFiles;
- (void)setInternalShowsHiddenFiles:(BOOL)flag;
- (void)TCM_selectFilenameWithoutExtension;

@end
