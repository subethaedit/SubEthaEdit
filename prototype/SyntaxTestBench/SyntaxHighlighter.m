//
//  SyntaxHighlighter.m
//  Hydra
//
//  Created by Martin Pittenauer on Tue Feb 25 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#define chunkSize              		5000

#import "SyntaxHighlighter.h"
#import "SyntaxManager.h"
#import <regex.h>
#import <time.h>


@interface SyntaxHighlighter (PrivateAdditions) 
// Private
- (regex_t *)regexTPointerForString:(NSString *)aString;
- (void) colorize:(NSMutableAttributedString*)aString;
- (void) colorize:(NSMutableAttributedString*)aString inRange:(NSRange)aRange;
- (void) colorRegEx:(NSString *)aRegex withColor:(NSColor *)aColor inString:(NSMutableAttributedString*)aString lossyCString:(char *)aCString inRange:(NSRange)aRange keyword:(BOOL)isKeyword comment:(BOOL)isComment;
- (NSMutableString *)replaceRegex:(NSString *)aRegEx inString:(NSString *)aString withString:(NSString *)aReplaceString;
- (void) doMultilines:(NSMutableAttributedString*)aString inRange:(NSRange)aRange;

@end

@implementation SyntaxHighlighter

- (id)init{ 		// No Syntax, no Highlight.
    [super dealloc];
    return nil;
}

- (id)initWithFile:(NSString *)synfile {
    self=[super init];
    if (self) {
        regularExpressions=[NSMutableDictionary new];
        definition=[[NSDictionary dictionaryWithContentsOfFile:synfile] retain];
        if (definition==nil) {
            NSLog(@"Hydra: Read error while loading Syntax File: %@",synfile); 
            return nil;
        }
        
        if ([[definition objectForKey:kHeaderKey] objectForKey:kNotKeywordKey])
            notKeyword = [[NSCharacterSet characterSetWithCharactersInString:
                       [[definition objectForKey:kHeaderKey] objectForKey:kNotKeywordKey]] retain];
        multilines = [NSMutableArray new];
        simples = [NSMutableArray new];
        
        NSArray *styles;
        BOOL multiline = NO;
        unsigned int i;
        if (( styles = [definition objectForKey:kStylesKey] )) {
            for(i=0;i<[styles count];i++) {
                     
                    if ([[styles objectAtIndex:i] objectForKey:kMultilineKey]) 
                        multiline = ([[[styles objectAtIndex:i] objectForKey:kMultilineKey] boolValue]);
                    else 
                        multiline = NO;
                        
                    if (multiline) {
                        [multilines addObject:[styles objectAtIndex:i]];
                    } else {
                        [simples addObject:[styles objectAtIndex:i]];
                    }
            }
        }
    }
    return self;
}

- (id)initWithName:(NSString *)aName {
    NSString* synfile;
    if ((synfile=[[SyntaxManager sharedInstance] syntaxDefinitionForName:aName])) {
        return [self initWithFile:synfile];
    } else {
        return nil;
    }
}

- (id)initWithExtension:(NSString *)anExtension{
    NSString* synfile;
    if ((synfile=[[SyntaxManager sharedInstance] syntaxDefinitionForExtension:anExtension])) {
        return [self initWithFile:synfile];
    } else {
        return nil;
    }
}

- (void)dealloc {
    NSEnumerator *values=[regularExpressions objectEnumerator];
    NSValue *value;
    while ((value=[values nextObject])) {
        if ((void *)value!=(void *)[NSNull null]) {
            regex_t *regex=(regex_t *)[value pointerValue];
            regfree(regex);
            free(regex);
        }
    }
    [regularExpressions release];
    [notKeyword release];
    [definition release];
    [multilines release];
    [simples release];
    [super dealloc];
}

- (void) cleanup:(NSMutableAttributedString*)aString {
    [aString removeAttribute:kMultilineAttribute range:NSMakeRange(0,[aString length])];
}

/*"Returns YES if nothing is dirty anymore"*/
- (BOOL) colorizeDirtyRanges:(NSMutableAttributedString*)aString { 

    NSRange textRange=NSMakeRange(0,[aString length]);
    NSRange dirtyRange;
    id dirty;
    id multiline;
    NSRange multilineFreeRange;
    unsigned int position;
    double return_after = 0.2;
    BOOL returnvalue = NO;
    int chunks=0;
    
    clock_t start_time = clock();
    
    [aString beginEditing];
   // [aString removeAttribute:NSBackgroundColorAttributeName range:textRange]; // Debug
    
    position=0;
    while (position<NSMaxRange(textRange)) {
        dirty=[aString attribute:kSyntaxColoringIsDirtyAttribute atIndex:position
                longestEffectiveRange:&dirtyRange inRange:textRange];
        if (dirty) {
            NSRange chunkRange,lineRange;
            // NSLog(@"DirtyRange: %@",NSStringFromRange(dirtyRange));
            while(YES) {
                chunks++;
                chunkRange=dirtyRange;
                if (chunkRange.length>chunkSize) chunkRange.length=chunkSize;
                // NSLog(@"handling Chunk: %@",NSStringFromRange(chunkRange));

                lineRange=[[aString string] lineRangeForRange:chunkRange];
                
                // [aString addAttribute:NSBackgroundColorAttributeName value:[[NSColor redColor] highlightWithLevel:0.3]  range:lineRange]; // Debug
                
                //[self colorize:aString inRange:lineRange];
                [aString removeAttribute:kCommentAttribute range:lineRange];

                [self doMultilines:aString inRange:lineRange];
                
                unsigned int multilinePosition=lineRange.location;
                while (multilinePosition<NSMaxRange(lineRange)) {
                    multiline=[aString attribute:kMultilineAttribute atIndex:multilinePosition 
                                      longestEffectiveRange:&multilineFreeRange inRange:lineRange];
                    if (!multiline) {
                        [self colorize:aString inRange:multilineFreeRange];
                    }
                    multilinePosition=NSMaxRange(multilineFreeRange);
                }  /**/
                
                [aString removeAttribute:kSyntaxColoringIsDirtyAttribute range:lineRange];
                if ((((double)(clock()-start_time))/CLOCKS_PER_SEC) > return_after) break;
                
                // adjust ranges
                unsigned int lastDirty=NSMaxRange(dirtyRange);
                if (NSMaxRange(lineRange)<lastDirty) {
                    dirtyRange.location=NSMaxRange(lineRange);
                    dirtyRange.length=lastDirty-dirtyRange.location;
                } else {
                    break;
                }
            }
            position=NSMaxRange(lineRange);
        } else {
            position=NSMaxRange(dirtyRange);
            if (position>=[aString length]) {
                returnvalue = YES;
                break;
            }
        }
        if ((((double)(clock()-start_time))/CLOCKS_PER_SEC) > return_after) break;
        // adjust Range
        textRange.length=NSMaxRange(textRange);
        textRange.location=position;
        textRange.length  =textRange.length-position;
    }
    
    [aString endEditing];
    return returnvalue;
}

- (void) doMultilines:(NSMutableAttributedString*)aString inRange:(NSRange)aRange {
    NSArray *stored_color;
    NSColor *current_color;
    NSDictionary *current_style;
    NSRange colorRange,foundRange;
    NSString *current_begin,*current_end;
    unsigned int i;
    unsigned multilineStart;
    unsigned aMaxRange = NSMaxRange(aRange);
    NSString *string = [aString string];
    BOOL isComment = NO;
    
   // NSLog(@"---- doMultilines: %@",NSStringFromRange(aRange));

    if ([multilines count] > 0) { 

        [aString removeAttribute:kMultilineAttribute range:aRange];
    
        for(i=0;i<[multilines count];i++) {
            NSRange searchRange=aRange;
            NSString *name = [[multilines objectAtIndex:i] objectForKey:@"Name"];
            current_style = [multilines objectAtIndex:i];
            current_begin = [current_style objectForKey:@"Multiline Begin"];
            current_end = [current_style objectForKey:@"Multiline End"];
            if ([[multilines objectAtIndex:i] objectForKey:@"Comment"]) 
                isComment = [[[multilines objectAtIndex:i] objectForKey:@"Comment"] boolValue];
            else isComment = NO;
            
            stored_color = [current_style objectForKey:kColorKey];
          //  NSLog(@"--- %@ : b:%@ e:%@ ",name, current_begin, current_end);
            current_color = [NSColor colorWithCalibratedRed:[[stored_color objectAtIndex:0]floatValue]
                          green:[[stored_color objectAtIndex:1]floatValue]
                          blue:[[stored_color objectAtIndex:2]floatValue] alpha:1.0];
        
            // Are we in an multiline?
            if (aRange.location > 0)
            if ( [[aString attribute:kMultilineAttribute atIndex:aRange.location-1 effectiveRange:nil] isEqual:name] ) {
                // NSLog(@"Search range now is: %@",NSStringFromRange(searchRange));
                foundRange = [string rangeOfString:current_end options:NSCaseInsensitiveSearch range:searchRange];
                if (foundRange.location==NSNotFound) { // No end found.
                    [aString addAttribute:NSForegroundColorAttributeName value:current_color range:aRange];
                    [aString addAttribute:kMultilineAttribute value:name range:aRange];
                    if (isComment) [aString addAttribute:kCommentAttribute value:name range:aRange];
                    // Not closed. Mark some range after this dirty if it's not a multiline already.
                    if (aMaxRange < [aString length]) // !Last chunk?
                    if (!([[aString attribute:kMultilineAttribute atIndex:aMaxRange effectiveRange:nil] isEqual:name]))  {
                        //NSLog(@"Made dirty %@ %@",NSStringFromRange(NSMakeRange(aMaxRange, MIN(chunkSize,[aString length]-aMaxRange))),name);
                        [aString addAttribute:kSyntaxColoringIsDirtyAttribute value:kSyntaxColoringIsDirtyAttributeValue 
                            range:NSMakeRange(aMaxRange, MIN(aRange.length,[aString length]-aMaxRange))];
                    }
                   // NSLog(@"1: No End, no Begin at: %@",NSStringFromRange(foundRange));
                    continue;
                } else {	// End found.
                    colorRange = NSMakeRange(aRange.location, NSMaxRange(foundRange)-searchRange.location);
                    [aString addAttribute:NSForegroundColorAttributeName value:current_color range:colorRange];
                    [aString addAttribute:kMultilineAttribute value:name range:colorRange];
                    if (isComment) [aString addAttribute:kCommentAttribute value:name range:colorRange];
                    if (NSMaxRange(foundRange) < aMaxRange) {
                        searchRange.location = NSMaxRange(foundRange);
                        searchRange.length   = aMaxRange-searchRange.location;
                    } else 
                        continue;  
                    // NSLog(@"2: End without Begin at: %@",NSStringFromRange(foundRange));
                }
            }
                
            while (YES) {                
                // NSLog(@"Search range now is: %@",NSStringFromRange(searchRange));
                foundRange = [string rangeOfString:current_begin options:NSCaseInsensitiveSearch range:searchRange];
                // No multiline at begin                
                if (foundRange.location==NSNotFound) {
                    // Do nothing
                    // (Closed multiline without open.)
                    if (aMaxRange < [aString length])
                    if (([[aString attribute:kMultilineAttribute atIndex:aMaxRange effectiveRange:nil] isEqual:name])) {
                        [aString addAttribute:kSyntaxColoringIsDirtyAttribute value:kSyntaxColoringIsDirtyAttributeValue 
                            range:NSMakeRange(aMaxRange, MIN(aRange.length,[aString length]-aMaxRange))];
                        }
                    break;
                } else {
                    // NSLog(@"4?: Begin found: %@",NSStringFromRange(foundRange));                    
                    multilineStart=foundRange.location;
                    if (NSMaxRange(foundRange)>=aMaxRange) {
                        [aString addAttribute:NSForegroundColorAttributeName value:current_color range:foundRange];
                        [aString addAttribute:kMultilineAttribute value:name range:foundRange];
                        if (isComment) [aString addAttribute:kCommentAttribute value:name range:foundRange];
                        if (aMaxRange < [aString length]) // !Last chunk?
                        if (!([[aString attribute:kMultilineAttribute atIndex:aMaxRange effectiveRange:nil] isEqual:name])) {
                            //NSLog(@"Made dirty %@ %@",NSStringFromRange(NSMakeRange(aMaxRange, MIN(chunkSize,[aString length]-aMaxRange))),name);
                            [aString addAttribute:kSyntaxColoringIsDirtyAttribute value:kSyntaxColoringIsDirtyAttributeValue 
                                range:NSMakeRange(aMaxRange, MIN(aRange.length,[aString length]-aMaxRange))];
                        }
                        break;
                    }
                    searchRange.location = NSMaxRange(foundRange);
                    searchRange.length   = aMaxRange-searchRange.location;
                   // NSLog(@"Search range now is: %@",NSStringFromRange(searchRange));
                    foundRange = [string rangeOfString:current_end options:0 range:searchRange];
                    if (foundRange.location==NSNotFound) {
                        // Opened multiline, without close.
                        // Color and mark following range dirty
                        colorRange = NSMakeRange(multilineStart,aMaxRange-multilineStart);
                        [aString addAttribute:NSForegroundColorAttributeName value:current_color range:colorRange];
                        [aString addAttribute:kMultilineAttribute value:name range:colorRange];
                        if (isComment) [aString addAttribute:kCommentAttribute value:name range:colorRange];
                        if (aMaxRange < [aString length]) // !Last chunk?
                        if (!([[aString attribute:kMultilineAttribute atIndex:aMaxRange effectiveRange:nil] isEqual:name])) {
                            //NSLog(@"Made dirty %@ %@",NSStringFromRange(NSMakeRange(aMaxRange, MIN(chunkSize,[aString length]-aMaxRange))),name);
                            [aString addAttribute:kSyntaxColoringIsDirtyAttribute value:kSyntaxColoringIsDirtyAttributeValue 
                                range:NSMakeRange(aMaxRange, MIN(aRange.length,[aString length]-aMaxRange))];
                        }
                       // NSLog(@"3: Begin without end at: %@",NSStringFromRange(foundRange));
                        break;
                    } else {
                        // W00t, it's "normal" usecase: found multiline begin and end.
                        colorRange = NSMakeRange(multilineStart, NSMaxRange(foundRange)-multilineStart);
                        [aString addAttribute:NSForegroundColorAttributeName value:current_color range:colorRange];
                        [aString addAttribute:kMultilineAttribute value:name range:colorRange];
                        if (isComment) [aString addAttribute:kCommentAttribute value:name range:colorRange];
                      //  NSLog(@"4: End and Begin at: %@",NSStringFromRange(foundRange));
                        if (NSMaxRange(foundRange) < aMaxRange) {
                            searchRange.location = NSMaxRange(foundRange);
                            searchRange.length   = aMaxRange-searchRange.location;
                        } else 
                            break;
                    }
                }
            }
        }
    }
}

- (void) colorize:(NSMutableAttributedString*)aString {
    [self colorize:aString inRange:NSMakeRange(0, [aString length])];
}

- (void) colorize:(NSMutableAttributedString*)aString inRange:(NSRange)aRange {
    NSArray *styles, *items;
    NSDictionary *current_style;
    NSArray *stored_color;
    NSColor *current_color;
    NSAutoreleasePool *pool, *secondpool;
    BOOL isComment = NO;
    unsigned int i,j;
  
    char *str = (char *)[[[aString string] substringWithRange: aRange] lossyCString];

//    NSArray *foregroundColorArray=[[NSUserDefaults standardUserDefaults] objectForKey:ForegroundColorPreferenceKey];
//    NSColor *foregroundColor=
//    [NSColor colorWithCalibratedRed:[[foregroundColorArray objectAtIndex:0] floatValue] 
//                              green:[[foregroundColorArray objectAtIndex:1] floatValue] 
//                               blue:[[foregroundColorArray objectAtIndex:2] floatValue] alpha:1.];

    NSColor *foregroundColor=[NSColor blackColor];

    
    [aString beginEditing];
    
    [aString addAttribute:NSForegroundColorAttributeName value:foregroundColor range:aRange];
    if (( styles = simples )) {
        for(i=0;i<[styles count];i++) {
            pool = [NSAutoreleasePool new];
            
            current_style = [styles objectAtIndex:i];
            stored_color = [current_style objectForKey:kColorKey];
            current_color = [NSColor colorWithCalibratedRed:[[stored_color objectAtIndex:0]floatValue]
                                     green:[[stored_color objectAtIndex:1]floatValue]
                                     blue:[[stored_color objectAtIndex:2]floatValue] alpha:1.0];
            if ([current_style objectForKey:@"Comment"]) 
                isComment = [[current_style objectForKey:@"Comment"] boolValue];
            else isComment = NO;

            
            
            items = [current_style objectForKey:kRegularExpressionsKey];
            if (nil!=items) {
                for(j=0;j<[items count];j++) {
                    secondpool = [NSAutoreleasePool new];
                    [self colorRegEx:[items objectAtIndex:j] withColor:current_color inString:aString lossyCString:str inRange:aRange keyword:NO comment:isComment];
                    [secondpool release];
                }
            }

            items = [current_style objectForKey:kPlainStringsKey];
            if (nil!=items) {
                for(j=0;j<[items count];j++) {
                    secondpool = [NSAutoreleasePool new];
                    [self colorRegEx:[items objectAtIndex:j] withColor:current_color inString:aString lossyCString:str inRange:aRange keyword:YES comment:isComment];
                    [secondpool release];
                }
            }
            [pool release];
        }
    } 
    [aString endEditing];
    
}

- (regex_t *)regexTPointerForString:(NSString *)aString {
    regex_t *regex=NULL;
    id value;
    if ((value=[regularExpressions objectForKey:aString])) {
        if (value==[NSNull null]) {
            regex=NULL;
        } else {
            regex=[(NSValue *)value pointerValue];
        }
    } else {
        regex=malloc(sizeof(regex_t));
        int result=regcomp(regex,[aString lossyCString],REG_EXTENDED|REG_NEWLINE);
        if (result != 0) {
            [regularExpressions setObject:[NSNull null] forKey:aString];
            char errbuf[255];
            regerror(result, regex, errbuf, 255);
            free(regex);
            [NSException raise: @"RegEx Error"
                        format: @"Couldn't compile regex %@: %s",
                        aString, errbuf];
        } else {
            [regularExpressions setObject:[NSValue valueWithPointer:regex] forKey:aString];
        }
    }
    return regex;
}


- (void) colorRegEx:(NSString *)aRegex withColor:(NSColor *)aColor 
         inString:(NSMutableAttributedString*)aString lossyCString:(char *)aCString inRange:(NSRange)aRange keyword:(BOOL)isKeyword comment:(BOOL)isComment { 
    int result;
    regmatch_t pmatch[2];
    int pos_in_string;
    int length_of_string;
    BOOL do_it = YES;

    regex_t *preg=[self regexTPointerForString:aRegex];
    if (preg==NULL) {
        return;
    }

    // ...and match it
    pos_in_string = 0;
    length_of_string = aRange.length;
    
    while(length_of_string - pos_in_string - 1) {
        unsigned int pos, length;
        NSRange range;
    
        result = regexec(preg, &(aCString[pos_in_string]), 2, pmatch, 0);
    
        if(result == REG_NOMATCH) { // No more matches -> return
            return;
        }
        
        if (!isKeyword && pmatch[1].rm_so!=-1 && pmatch[1].rm_eo!=-1) {
            pos = aRange.location + pos_in_string + pmatch[1].rm_so;
            length = pmatch[1].rm_eo - pmatch[1].rm_so;            
        } else {
            pos = aRange.location + pos_in_string + pmatch[0].rm_so;
            length = pmatch[0].rm_eo - pmatch[0].rm_so;
        }
//        assert(length>=1);
        
        range = NSMakeRange(pos, length);
                      
        if ((isKeyword)&&(notKeyword)&&((pos+length)<[aString length])&&(((int)pos-1)>=0)) {     //If its a keyword there can't be notKeyword char at -1 and +1
            unichar before, after;
            before = [[aString string] characterAtIndex:pos-1];
            after = [[aString string] characterAtIndex:pos+length];
            if (([notKeyword characterIsMember:before])||([notKeyword characterIsMember:after])) {
                do_it = NO;
            } else {
                do_it = YES;
            }
        }

        if (do_it) [aString addAttribute:NSForegroundColorAttributeName value:aColor range:range];
        if (do_it && isComment) [aString addAttribute:kCommentAttribute value:aColor range:range];
        
        pos_in_string = pos_in_string + (pmatch[0].rm_eo>0?pmatch[0].rm_eo:1);
    }
}

- (BOOL) hasSymbols {
        if (([[definition objectForKey:kHeaderKey] objectForKey:kFunctionsRegExKey] )) {
            return YES;
        } else {return NO;}
}


/*"Retuns an NSArray of foundSymbols with entries as NSDictionarys with entries "Name" and "Range" "*/
- (NSArray*)symbolsInAttributedString:(NSAttributedString*)aString {  // NSDict in NSArray
    NSString *function_regex, *replace, *with;
    NSArray *function_modifiers;
    NSMutableArray *result = [[NSMutableArray new] autorelease];
    NSMutableString *name;
    unsigned int i;
    
    regex_t preg;
    char errbuf[255];
    int regresult;
    regmatch_t pmatch;
    char *str;
    int pos_in_string;
    int length_of_string;
    NSRange aRange = NSMakeRange(0, [aString length]);        
    
    if (( function_regex = [[definition objectForKey:kHeaderKey] objectForKey:kFunctionsRegExKey] )) {
    
        // Compile the RegEx
        regresult = regcomp(&preg, [function_regex lossyCString], REG_EXTENDED);
        if(regresult != 0) {
            regerror(regresult, &preg, errbuf, 255);
            [NSException raise: @"RegEx Error"
                        format: @"Couldn't compile regex %@: %s",
                        function_regex, errbuf];
            return nil;
        }
    
        // ...and match it
        str = (char *)[[[aString string] substringWithRange: aRange] lossyCString];
        pos_in_string = 0;
        length_of_string = strlen(str);
        
        while(length_of_string - pos_in_string - 1) {
            int pos, length;
            NSRange range;
        
            regresult = regexec(&preg, &(str[pos_in_string]), 1, &pmatch, 0);
        
            if(regresult == REG_NOMATCH) { // No more matches -> return
                regfree(&preg);
                return result;
            }
        
            pos = aRange.location + pos_in_string + pmatch.rm_so;
            length = pmatch.rm_eo - pmatch.rm_so;
            assert(length>=1);
            
            range = NSMakeRange(pos, length);
                                                    
            name = [NSMutableString stringWithString:[[aString string] substringWithRange:range]];
            [name replaceOccurrencesOfString:@"\n" withString:@"" 
                  options:nil range:NSMakeRange(0, [name length])];
            [name replaceOccurrencesOfString:@"\t" withString:@" " 
                  options:nil range:NSMakeRange(0, [name length])];
            
           
            if (![aString attribute:kCommentAttribute atIndex:range.location effectiveRange:nil]) {
                if (( function_modifiers = [[definition objectForKey:kHeaderKey] 
                      objectForKey:kFunctionsModifersKey] )) {
                    for(i=0;i<[function_modifiers count];i++) {
                        if (((replace = [[function_modifiers objectAtIndex:i] objectForKey:@"Replace"])) &&
                           ((with = [[function_modifiers objectAtIndex:i] objectForKey:@"With"]))) {
                            name = [self replaceRegex:replace inString:name withString:with];
                        }
                    }
                }
                
                [result addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                    name, @"Name", 
                                    [NSValue valueWithRange:range], @"Range",
                                    NULL]];
            }
            pos_in_string = pos_in_string + pmatch.rm_eo;
        }

        regfree(&preg);
        return result;
    }
    return nil;
}

- (NSMutableString *)replaceRegex:(NSString *)aRegEx inString:(NSString *)aString withString:(NSString *)aReplaceString {
    NSMutableString *result = [NSMutableString stringWithString:aString];
    
    regex_t preg;
    char errbuf[255];
    int regresult;
    regmatch_t pmatch;
    char *str;
    int pos_in_string;
    int length_of_string;
    NSRange aRange = NSMakeRange(0, [aString length]);
        
    //regresult = regcomp(&preg, [aRegEx lossyCString], REG_EXTENDED);
    regresult = regcomp(&preg, [aRegEx lossyCString], REG_EXTENDED);
    if(regresult != 0) {
        regerror(regresult, &preg, errbuf, 255);
        [NSException raise: @"RegEx Error"
                    format: @"Couldn't compile regex %@: %s",
                    aRegEx, errbuf];
        return nil;
    }
    
    // ...and match it
    str = (char *)[[aString substringWithRange: aRange] lossyCString];
    pos_in_string = 0;
    length_of_string = strlen(str);
    
    while(length_of_string - pos_in_string - 1) {
        int pos, length;
        NSRange range;
    
        regresult = regexec(&preg, &(str[pos_in_string]), 1, &pmatch, 0);
    
        if(regresult == REG_NOMATCH) { // No more matches -> return
            regfree(&preg);
            return result;
        }
    
        pos = aRange.location + pos_in_string + pmatch.rm_so;
        length = pmatch.rm_eo - pmatch.rm_so;
        assert(length>=1);
        
        range = NSMakeRange(pos-([aString length]-[result length]), length);
        
        [result replaceCharactersInRange:range withString:aReplaceString];
        
        pos_in_string = pos_in_string + pmatch.rm_eo;
    }
    
    regfree(&preg);
    return result;
}

@end
