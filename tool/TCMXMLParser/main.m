#import <Foundation/Foundation.h>
#import "TCMXMLParser.h"
#import "ParserDelegate.h"

char Buff[8];

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    ParserDelegate *parserDelegate = [[ParserDelegate new] autorelease];
    TCMXMLParser *parser = [TCMXMLParser XMLParser];
    [parser setDelegate:parserDelegate];
    
    for (;;) {
        int done;
        int len;
        fgets(Buff, sizeof(Buff), stdin);
        len = strlen(Buff);
        if (ferror(stdin)) {
            NSLog(@"Read error\n");
            break;
        }
        done = feof(stdin);
        if (![parser parseData:[NSData dataWithBytes:&Buff length:len] moreComing:YES]) {
        //if (! XML_Parse(p, Buff, len, done)) {
            NSLog(@"Parse error at line %d:\n%@\n",
                  [parser lineNumber],
                  [parser errorString]);
            break;
        }
        
        if (done)
            break;
    }
    NSLog(@"\n");
    
    [pool release];
    return 0;
}
