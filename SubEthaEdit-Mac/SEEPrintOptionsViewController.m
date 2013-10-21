//
//  SEEPrintOptionsViewController.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 17.10.13.
//  Copyright (c) 2013 TheCodingMonkeys. All rights reserved.
//

#import "SEEPrintOptionsViewController.h"

@interface SEEPrintOptionsViewController ()

@end

@implementation SEEPrintOptionsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:@"PrintOptions" bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

//- (IBAction)changeFontViaPanel:(id)sender {
//    NSDictionary *fontAttributes=[[O_printOptionController content] valueForKeyPath:@"SEEFontAttributes"];
//    NSFont *newFont=[NSFont fontWithName:[fontAttributes objectForKey:NSFontNameAttribute] size:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
//    if (!newFont) newFont=[NSFont userFixedPitchFontOfSize:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
//
//    [[NSFontManager sharedFontManager]
//        setSelectedFont:newFont
//             isMultiple:NO];
//    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
//
//	[[sender window] makeFirstResponder:O_printOptionTextField];
//
//}
//
//- (void)changeFont:(id)aSender
//{
//    NSFont *newFont = [aSender convertFont:I_fonts.plainFont];
//    if (I_printOperationIsRunning) {
//        NSMutableDictionary *dict=[NSMutableDictionary dictionary];
//        [dict setObject:[newFont fontName]
//                 forKey:NSFontNameAttribute];
//        [dict setObject:[NSNumber numberWithFloat:[newFont pointSize]]
//                 forKey:NSFontSizeAttribute];
//        [[O_printOptionController content] setValue:dict forKeyPath:PROPERTY(SEEFontAttributes)];
//    } else {
//        [self setPlainFont:newFont];
//    }
//}

@end
