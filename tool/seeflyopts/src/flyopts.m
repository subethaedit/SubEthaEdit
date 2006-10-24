#import "flyopts.h"

@implementation flyopts

+ (void) load {
	[self performSelector:@selector(install:) withObject:nil afterDelay:0.0];
}


+ (void)install:(id)sender {
    
    NSMenu *mainMenu    = nil;
    NSString *bundleId  = [[NSBundle mainBundle] bundleIdentifier];
        
    if ((mainMenu = [NSApp mainMenu]) != nil) {
		
        NSMenuItem *editMenu = [mainMenu itemWithTitle:@"Edit"];
        NSMenuItem *sep = [NSMenuItem separatorItem];
        [[editMenu submenu] addItem: sep];
        
		if (![@"de.codingmonkeys.SubEthaEdit" isEqualToString:bundleId]) {
            NSMenuItem *bbeditCommand = [[editMenu submenu] addItemWithTitle:@"Edit in SubEthaEdit" action:@selector(flyoptsODBEdit:) keyEquivalent:@"j"];
            [bbeditCommand setKeyEquivalentModifierMask: NSControlKeyMask | NSCommandKeyMask];
        }
    }    
}

@end

