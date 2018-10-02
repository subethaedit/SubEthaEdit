//  SEEPrintOptionsViewController.m
//  SubEthaEdit
//
//  Created by Michael Ehrmann on 17.10.13.

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
    for (NSInteger viewTag = 996; viewTag < 1000; viewTag++) {
        [[view viewWithTag:viewTag] setStringValue:labelText];
    }
    
    [self.printOptionTextFieldOutlet setFontDelegate:self];
    [self.printOptionControllerOutlet setContent:[self.document printOptions]];
}

#pragma mark - Font panel

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


#pragma mark - NSPrintPanelAccessorizing

- (NSArray *)localizedSummaryItems {
    
    BOOL showPageHeader = [[[[self document] printOptions] objectForKey:@"SEEPageHeader"] boolValue];
    return @[@{NSPrintPanelAccessorySummaryItemNameKey:
                   NSLocalizedStringFromTable(@"Header and Footer", @"PrintAccessory", @"Print panel summary item title for whether header and footer (page number, date, document title) should be printed"),
               NSPrintPanelAccessorySummaryItemDescriptionKey:
                   showPageHeader ? NSLocalizedStringFromTable(@"On", @"PrintAccessory", @"Print panel summary value for feature that is enabled") : NSLocalizedStringFromTable(@"Off", @"PrintAccessory", @"Print panel summary value for feature that is disabled")}];
}

- (NSSet *)keyPathsForValuesAffectingPreview {
    return [NSSet setWithObjects:
            @"self.printOptionControllerOutlet.content.SEEFacingPages",
            @"self.printOptionControllerOutlet.content.NSLeftMargin",
            @"self.printOptionControllerOutlet.content.NSRightMargin",
            @"self.printOptionControllerOutlet.content.NSTopMargin",
            @"self.printOptionControllerOutlet.content.NSBottomMargin",
            
            @"self.printOptionControllerOutlet.content.SEEAnnotateChangeMarks",
            @"self.printOptionControllerOutlet.content.SEEColorizeChangeMarks",

            @"self.printOptionControllerOutlet.content.SEEAnnotateWrittenBy",
            @"self.printOptionControllerOutlet.content.SEEColorizeWrittenBy",
            
            @"self.printOptionControllerOutlet.content.SEEHighlightSyntax",
            
            @"self.printOptionControllerOutlet.content.SEEPageHeader",
            @"self.printOptionControllerOutlet.content.SEEPageHeaderCurrentDate",
            @"self.printOptionControllerOutlet.content.SEEPageHeaderFilename",
            @"self.printOptionControllerOutlet.content.SEEPageHeaderFullPath",
            
            @"self.printOptionControllerOutlet.content.SEEParticipants",
            @"self.printOptionControllerOutlet.content.SEEParticipantsVisitors",
            @"self.printOptionControllerOutlet.content.SEEParticipantImages",
            @"self.printOptionControllerOutlet.content.SEEParticipantsAIMAndEmail",

            @"self.printOptionControllerOutlet.content.SEEResizeDocumentFont",
            @"self.printOptionControllerOutlet.content.SEEResizeDocumentFontTo",
            
            @"self.printOptionControllerOutlet.content.SEEUseCustomFont",
            @"self.printOptionControllerOutlet.content.SEEFontAttributes",
            
            @"self.printOptionControllerOutlet.content.SEEWhiteBackground",
            
            @"self.printOptionControllerOutlet.content.SEEHighlightSyntax",
            @"self.printOptionControllerOutlet.content.SEELineNumbers",
            @"self.printOptionControllerOutlet.content.SEEWhiteBackground",
            nil];
}

@end
