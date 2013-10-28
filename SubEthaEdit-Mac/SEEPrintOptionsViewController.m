//
//  SEEPrintOptionsViewController.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 17.10.13.
//  Copyright (c) 2013 TheCodingMonkeys. All rights reserved.
//

#import "SEEPrintOptionsViewController.h"
#import "FontForwardingTextField.h"
#import "PlainTextDocument.h"

@interface SEEPrintOptionsViewController ()

@end

@implementation SEEPrintOptionsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:@"PrintOptions" bundle:nibBundleOrNil];
    return self;
}

- (void)loadView {
    [super loadView];
    
    NSView *view = self.view;
    NSString *measurementUnits = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleMeasurementUnits"];
    NSString *labelText = NSLocalizedString(([NSString stringWithFormat:@"Label%@", measurementUnits]), @"Centimeters or Inches, short label string for them");
    int i = 996;
    for (i = 996; i < 1000; i++) {
        [[view viewWithTag:i] setStringValue:labelText];
    }
    [self.printOptionTextFieldOutlet setFontDelegate:self];
    [self.printOptionControllerOutlet setContent:[self.document printOptions]];
}

- (NSArray *)localizedSummaryItems {
    return @[];
}

- (IBAction)changeFontViaPanel:(id)sender {
    NSDictionary *fontAttributes = [[self.printOptionControllerOutlet content] valueForKeyPath:@"SEEFontAttributes"];
    
    NSFont *font = [NSFont fontWithName:[fontAttributes objectForKey:NSFontNameAttribute] size:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
    if (!font) {
        font = [NSFont userFixedPitchFontOfSize:[[fontAttributes objectForKey:NSFontSizeAttribute] floatValue]];
    }
    
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    [fontManager setSelectedFont:font isMultiple:NO];
    [fontManager orderFrontFontPanel:self];
    
    [[sender window] makeFirstResponder:self.printOptionTextFieldOutlet];
}

- (IBAction)changeFont:(id)sender {
    NSFont *newFont = [sender convertFont:[self.document fontWithTrait:0]];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:[newFont fontName]
             forKey:NSFontNameAttribute];
    [dict setObject:[NSNumber numberWithFloat:[newFont pointSize]]
             forKey:NSFontSizeAttribute];
    [self.printOptionControllerOutlet.content setValue:dict forKeyPath:@"SEEFontAttributes"];
}

- (NSSet *)keyPathsForValuesAffectingPreview {
    return [NSSet setWithObjects:
//            @"self.representedObject.leftMargin",
//            @"self.representedObject.rightMargin",
//            @"self.representedObject.topMargin",
//            @"self.representedObject.bottomMargin",
            
            @"self.printOptionControllerOutlet.content.NSLeftMargin",
            @"self.printOptionControllerOutlet.content.NSRightMargin",
            @"self.printOptionControllerOutlet.content.NSTopMargin",
            @"self.printOptionControllerOutlet.content.NSBottomMargin",
            
            @"self.printOptionControllerOutlet.content.SEEAnnotateChangeMarks",
            @"self.printOptionControllerOutlet.content.SEEAnnotateWrittenBy",
            @"self.printOptionControllerOutlet.content.SEEColorizeChangeMarks",
            @"self.printOptionControllerOutlet.content.SEEColorizeWrittenBy",
            @"self.printOptionControllerOutlet.content.SEEHighlightSyntax",
            
            @"self.printOptionControllerOutlet.content.SEEPageHeader",
            @"self.printOptionControllerOutlet.content.SEEPageHeaderCurrentDate",
            @"self.printOptionControllerOutlet.content.SEEPageHeaderFilename",
            
            @"self.printOptionControllerOutlet.content.SEEParticipantImages",
            @"self.printOptionControllerOutlet.content.SEEParticipants",
            @"self.printOptionControllerOutlet.content.SEEParticipantsAIMAndEmail",
            @"self.printOptionControllerOutlet.content.SEEParticipantsVisitors1",

            @"self.printOptionControllerOutlet.content.SEEResizeDocumentFont",
            @"self.printOptionControllerOutlet.content.SEEResizeDocumentFontTo",
            @"self.printOptionControllerOutlet.content.SEEUseCustomFont",
            @"self.printOptionControllerOutlet.content.SEEFontAttributes",
            @"self.printOptionControllerOutlet.content.SEEWhiteBackground",
            nil];
}

@end
