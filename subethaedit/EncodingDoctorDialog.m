//
//  EncodingDoctorDialog.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on 11.09.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "EncodingDoctorDialog.h"


@implementation EncodingDoctorDialog

- (NSString *)mainNibName {
    return @"EncodingDoctor";
}

- (IBAction)cancel:(id)aSender {
    [(id)[[O_mainView window] windowController] setDocumentDialog:nil];
}

@end
