//
//  AppListResponse.m
//  Moonlight
//
//  Created by Diego Waxemberg on 2/1/15.
//  Copyright (c) 2015 Moonlight Stream. All rights reserved.
//

#import "AppListResponse.h"
#import "TemporaryApp.h"
#import "DataManager.h"
#import <libxml2/libxml/parser.h>
#import <libxml2/libxml/xmlerror.h>
#import <libxml2/libxml/xmlreader.h>

@implementation AppListResponse {
    NSMutableSet* _appList;
}
@synthesize data, statusCode, statusMessage;

static const char* TAG_APP = "App";
static const char* TAG_APP_TITLE = "AppTitle";
static const char* TAG_APP_ID = "ID";
static const char* TAG_HDR_SUPPORTED = "IsHdrSupported";
static const char* TAG_APP_INSTALL_PATH = "AppInstallPath";
static const int APP_LIST_STRICT_PARSE_OPTIONS = XML_PARSE_NONET | XML_PARSE_BIG_LINES;
static const int APP_LIST_RECOVER_PARSE_OPTIONS = XML_PARSE_RECOVER | XML_PARSE_NONET | XML_PARSE_NOERROR | XML_PARSE_NOWARNING | XML_PARSE_BIG_LINES;
static const NSUInteger APP_LIST_BODY_CHUNK_SIZE = 1500;
static const NSUInteger APP_LIST_HEX_WINDOW_SIZE = 128;
static const NSUInteger APP_LIST_HEX_WINDOW_RADIUS = 64;
static const NSUInteger APP_LIST_SNIPPET_RADIUS = 80;
static const NSUInteger APP_LIST_SNIPPET_CONTEXT_LINES = 4;
static NSString* const APP_LIST_STATUS_CODE_PATTERN = @"status_code\\s*=\\s*[\"'](\\d+)[\"']";
static NSString* const APP_LIST_STATUS_MESSAGE_PATTERN = @"status_message\\s*=\\s*[\"']([^\"']*)[\"']";

- (void)populateWithData:(NSData *)xml {
    self.data = xml;
    _appList = [[NSMutableSet alloc] init];
    [self parseData];
}

- (void) parseData {
#if DEBUG
    // ---- XML parse failure injection (for testing only) ----
    // Change the value below to simulate different failure scenarios:
    //   0 = disabled (normal behaviour)
    //   1 = completely invalid bytes  → both strict + recovery fail, salvage runs
    //   2 = truncated XML             → both strict + recovery fail, salvage may recover apps
    //   3 = minor syntax error        → strict fails, recovery parse succeeds
    static const int kInjectXmlFailure = 0;
    if (kInjectXmlFailure == 1) {
        self.data = [@"NOT XML AT ALL <<<!!!" dataUsingEncoding:NSUTF8StringEncoding];
    } else if (kInjectXmlFailure == 2) {
        // Keep only first 40 bytes so closing tags are missing
        NSUInteger truncLen = MIN(self.data.length, 40);
        self.data = [self.data subdataWithRange:NSMakeRange(0, truncLen)];
    } else if (kInjectXmlFailure == 3) {
        // Make status_code attribute unquoted – strict rejects it, recovery tolerates it.
        // Original app list data is preserved so Desktop etc. still appear.
        NSString* original = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
        if (original.length > 0) {
            NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"status_code=\"(\\d+)\""
                                                                                   options:0 error:nil];
            NSString* broken = [regex stringByReplacingMatchesInString:original
                                                               options:0
                                                                 range:NSMakeRange(0, MIN(original.length, 200))
                                                          withTemplate:@"status_code=$1"];
            self.data = [broken dataUsingEncoding:NSUTF8StringEncoding] ?: self.data;
        }
    }
    // --------------------------------------------------------
#endif
    xmlError strictParseError;
    memset(&strictParseError, 0, sizeof(strictParseError));
    
    xmlDocPtr docPtr = [self newXmlDocumentWithOptions:APP_LIST_STRICT_PARSE_OPTIONS parseError:&strictParseError];
    if (docPtr == NULL) {
        docPtr = [self newXmlDocumentWithOptions:APP_LIST_RECOVER_PARSE_OPTIONS parseError:NULL];
        if (docPtr != NULL) {
            Log(LOG_E, @"AppListResponse: strict XML parse failed but recovery parse succeeded. code=%d line=%d column=%d message=%@",
                strictParseError.code,
                strictParseError.line,
                strictParseError.int2,
                [self trimmedXmlErrorMessage:&strictParseError]);
            NSString* errorSnippet = [self errorSnippetForString:[self bestEffortXmlString]
                                                            line:strictParseError.line
                                                          column:strictParseError.int2];
            if (errorSnippet.length > 0) {
                Log(LOG_E, @"AppListResponse: error snippet\n%@", errorSnippet);
            }
        } else {
            [self logMalformedXmlDiagnosticsWithError:&strictParseError];
            NSUInteger salvagedCount = [self salvageAppsFromMalformedXml];
            Log(LOG_E, @"AppListResponse: XML recovery parse failed. Salvaged %lu apps from malformed response.", (unsigned long)salvagedCount);
            xmlResetError(&strictParseError);
            return;
        }
    }
    
    [self populateFromDocument:docPtr];
    xmlFreeDoc(docPtr);
    
    if (_appList.count == 0) {
        NSUInteger salvagedCount = [self salvageAppsFromMalformedXml];
        if (salvagedCount > 0) {
            Log(LOG_W, @"AppListResponse: parsed XML but app list was empty. Salvaged %lu apps from response body.", (unsigned long)salvagedCount);
        }
    }
    
#ifdef ENABLE_APP_STORE_RESTRICTIONS
    [self applyAppStoreRestrictions];
#endif
    
    xmlResetError(&strictParseError);
}

- (xmlDocPtr)newXmlDocumentWithOptions:(int)options parseError:(xmlError *)parseError {
    if (self.data.length == 0) {
        return NULL;
    }
    
    if (parseError != NULL) {
        memset(parseError, 0, sizeof(xmlError));
    }
    
    xmlParserCtxtPtr parserContext = xmlNewParserCtxt();
    if (parserContext == NULL) {
        return NULL;
    }
    
    xmlResetLastError();
    xmlDocPtr docPtr = xmlCtxtReadMemory(parserContext,
                                         (const char *)[self.data bytes],
                                         (int)[self.data length],
                                         NULL,
                                         NULL,
                                         options);
    
    if (parseError != NULL) {
        xmlErrorPtr lastError = xmlCtxtGetLastError(parserContext);
        if (lastError != NULL) {
            xmlCopyError(lastError, parseError);
        }
    }
    
    xmlFreeParserCtxt(parserContext);
    xmlResetLastError();
    return docPtr;
}

- (void)populateFromDocument:(xmlDocPtr)docPtr {
    xmlNodePtr node = xmlDocGetRootElement(docPtr);
    if (node == NULL) {
        Log(LOG_E, @"AppListResponse: No root XML element.");
        return;
    }
    
    xmlChar* statusStr = xmlGetProp(node, (const xmlChar*)[TAG_STATUS_CODE UTF8String]);
    if (statusStr != NULL) {
        int status = (int)[[NSString stringWithUTF8String:(const char*)statusStr] longLongValue];
        xmlFree(statusStr);
        self.statusCode = status;
    }
    
    xmlChar* statusMsgXml = xmlGetProp(node, (const xmlChar*)[TAG_STATUS_MESSAGE UTF8String]);
    NSString* statusMsg;
    if (statusMsgXml != NULL) {
        statusMsg = [NSString stringWithUTF8String:(const char*)statusMsgXml];
        xmlFree(statusMsgXml);
    }
    else {
        statusMsg = Localized(@"Server Error");
    }
    self.statusMessage = statusMsg;
    
    node = node->children;
    
    while (node != NULL) {
        //Log(LOG_D, @"node: %s", node->name);
        if (!xmlStrcmp(node->name, (xmlChar*)TAG_APP)) {
            xmlNodePtr appInfoNode = node->xmlChildrenNode;
            NSString* appName = @"";
            NSString* appId = nil;
            NSString* hdrSupported = @"0";
            NSString* appInstallPath = nil;
            while (appInfoNode != NULL) {
                if (!xmlStrcmp(appInfoNode->name, (xmlChar*)TAG_APP_TITLE)) {
                    xmlChar* nodeVal = xmlNodeListGetString(docPtr, appInfoNode->xmlChildrenNode, 1);
                    if (nodeVal != NULL) {
                        appName = [[NSString alloc] initWithCString:(const char*)nodeVal encoding:NSUTF8StringEncoding];
                        xmlFree(nodeVal);
                    }else {
                        Log(LOG_E, @"AppListResponse: App title parse error with nodeVal: %s", nodeVal);
                    }
                } else if (!xmlStrcmp(appInfoNode->name, (xmlChar*)TAG_APP_ID)) {
                    xmlChar* nodeVal = xmlNodeListGetString(docPtr, appInfoNode->xmlChildrenNode, 1);
                    if (nodeVal != NULL) {
                        appId = [[NSString alloc] initWithCString:(const char*)nodeVal encoding:NSUTF8StringEncoding];
                        xmlFree(nodeVal);
                    }
                    else {
                        Log(LOG_E, @"AppListResponse: App id parse error with nodeVal: %s", nodeVal);
                    }
                } else if (!xmlStrcmp(appInfoNode->name, (xmlChar*)TAG_HDR_SUPPORTED)) {
                    xmlChar* nodeVal = xmlNodeListGetString(docPtr, appInfoNode->xmlChildrenNode, 1);
                    if (nodeVal != NULL) {
                        hdrSupported = [[NSString alloc] initWithCString:(const char*)nodeVal encoding:NSUTF8StringEncoding];
                        xmlFree(nodeVal);
                    }else {
                        Log(LOG_E, @"AppListResponse: App hdr supported parse error with nodeVal: %s", nodeVal);
                    }
                } else if (!xmlStrcmp(appInfoNode->name, (xmlChar*)TAG_APP_INSTALL_PATH)) {
                    xmlChar* nodeVal = xmlNodeListGetString(docPtr, appInfoNode->xmlChildrenNode, 1);
                    if (nodeVal != NULL) {
                        appInstallPath = [[NSString alloc] initWithCString:(const char*)nodeVal encoding:NSUTF8StringEncoding];
                        xmlFree(nodeVal);
                    }else {
                        Log(LOG_E, @"AppListResponse: App install path parse error with nodeVal: %s", nodeVal);
                    }
                }

                appInfoNode = appInfoNode->next;
            }
            if (appId != nil) {
                TemporaryApp* app = [[TemporaryApp alloc] init];
                app.name = appName;
                app.id = appId;
                app.hdrSupported = [hdrSupported intValue] != 0;
                app.installPath = appInstallPath;
                [_appList addObject:app];
            }
        }
        node = node->next;
    }
}

#ifdef ENABLE_APP_STORE_RESTRICTIONS
- (void)applyAppStoreRestrictions {
    // APP STORE REVIEW COMPLIANCE
    //
    // Remove default Steam entry from the app list to comply with Apple App Store Guideline 4.2.7d:
    //
    // The UI appearing on the client does not resemble an iOS or App Store view, does not provide a store-like interface,
    // or include the ability to browse, select, or purchase software not already owned or licensed by the user.
    //
    // However, if the user manually adds Steam themselves, then we will display it.
    TemporaryApp* officialSteamApp = nil;
    TemporaryApp* manuallyAddedSteamApp = nil;
    for (TemporaryApp* app in _appList) {
        if (app.installPath != nil && [[app.installPath lowercaseString] hasSuffix:@"\\steam\\"]) {
            // The official Steam app is marked as HDR supported, while manually added ones are not.
            if ([app.name isEqualToString:@"Steam"] && app.hdrSupported) {
                officialSteamApp = app;
            }
            else {
                manuallyAddedSteamApp = app;
            }
        }
    }
    
    // To be safe, don't do anything if we didn't find an HDR-enabled Steam app.
    if (officialSteamApp != nil) {
        // If we didn't find a manually added Steam app, remove the official one to
        // comply with the App Store guidelines.
        if (manuallyAddedSteamApp == nil) {
            [_appList removeObject:officialSteamApp];
        }
        else {
            [_appList removeObject:manuallyAddedSteamApp];
        }
    }
}
#endif

- (void)logMalformedXmlDiagnosticsWithError:(const xmlError *)parseError {
    BOOL utf8Decoded = [self isUtf8Decoded];
    NSString* bestEffortXml = [self bestEffortXmlString];
    
    Log(LOG_W, @"AppListResponse: XML parse failed. bytes=%lu utf8Decoded=%@ code=%d line=%d column=%d message=%@",
        (unsigned long)self.data.length,
        utf8Decoded ? @"YES" : @"NO",
        parseError != NULL ? parseError->code : 0,
        parseError != NULL ? parseError->line : 0,
        parseError != NULL ? parseError->int2 : 0,
        [self trimmedXmlErrorMessage:parseError]);
    
    NSString* errorSnippet = [self errorSnippetForString:bestEffortXml
                                                    line:parseError != NULL ? parseError->line : 0
                                                  column:parseError != NULL ? parseError->int2 : 0];
    if (errorSnippet.length > 0) {
        Log(LOG_W, @"AppListResponse: error snippet\n%@", errorSnippet);
    }
    
    if (!utf8Decoded) {
        [self logHexWindowAroundParseError:parseError bestEffortXml:bestEffortXml];
    }
    
    [self logChunkedXmlBody:bestEffortXml];
}

- (NSUInteger)salvageAppsFromMalformedXml {
    NSString* xmlString = [self bestEffortXmlString];
    if (xmlString.length == 0) {
        return 0;
    }
    
    [self populateResponseMetadataFromMalformedXml:xmlString];
    
    NSArray<NSTextCheckingResult*>* appMatches = [self matchesForPattern:@"<App(?:\\s[^>]*)?>" inString:xmlString];
    if (appMatches.count == 0) {
        return 0;
    }
    
    NSUInteger initialCount = _appList.count;
    for (NSUInteger idx = 0; idx < appMatches.count; idx++) {
        NSRange startRange = appMatches[idx].range;
        NSUInteger nextLocation = idx + 1 < appMatches.count ? appMatches[idx + 1].range.location : xmlString.length;
        if (nextLocation <= startRange.location) {
            continue;
        }
        
        NSRange blockRange = NSMakeRange(startRange.location, nextLocation - startRange.location);
        NSString* appBlock = [xmlString substringWithRange:blockRange];
        NSString* appId = [self extractTagValue:@"ID" fromXmlFragment:appBlock];
        if (appId.length == 0) {
            continue;
        }
        
        NSString* appName = [self extractTagValue:@"AppTitle" fromXmlFragment:appBlock] ?: @"";
        NSString* hdrSupported = [self extractTagValue:@"IsHdrSupported" fromXmlFragment:appBlock] ?: @"0";
        NSString* appInstallPath = [self extractTagValue:@"AppInstallPath" fromXmlFragment:appBlock];
        TemporaryApp* app = [[TemporaryApp alloc] init];
        app.name = appName;
        app.id = appId;
        app.hdrSupported = [hdrSupported intValue] != 0;
        app.installPath = appInstallPath;
        [_appList addObject:app];
        
        Log(LOG_W, @"AppListResponse: salvaged app entry name=%@ id=%@ hdr=%@ path=%@",
            appName.length > 0 ? appName : @"<empty>",
            appId,
            hdrSupported,
            appInstallPath.length > 0 ? appInstallPath : @"<empty>");
    }
    
    return _appList.count - initialCount;
}

- (void)populateResponseMetadataFromMalformedXml:(NSString *)xmlString {
    NSString* statusCodeString = [self firstCaptureForPattern:APP_LIST_STATUS_CODE_PATTERN inString:xmlString];
    if (self.statusCode == 0 && statusCodeString.length > 0) {
        self.statusCode = (int)[statusCodeString integerValue];
    }
    
    NSString* statusMessage = [self firstCaptureForPattern:APP_LIST_STATUS_MESSAGE_PATTERN inString:xmlString];
    if (self.statusMessage.length == 0 && statusMessage.length > 0) {
        self.statusMessage = statusMessage;
    } else if (self.statusMessage.length == 0) {
        self.statusMessage = @"Malformed applist XML";
    }
}

- (NSString *)bestEffortXmlString {
    if (self.data.length == 0) {
        return @"";
    }
    
    NSString* xmlString = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
    if (xmlString != nil) {
        return xmlString;
    }
    
    xmlString = [[NSString alloc] initWithData:self.data encoding:NSISOLatin1StringEncoding];
    if (xmlString != nil) {
        return xmlString;
    }
    
    xmlString = [[NSString alloc] initWithData:self.data encoding:NSASCIIStringEncoding];
    return xmlString ?: @"";
}

- (BOOL)isUtf8Decoded {
    if (self.data.length == 0) {
        return NO;
    }
    
    return [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding] != nil;
}

- (NSString *)trimmedXmlErrorMessage:(const xmlError *)parseError {
    if (parseError == NULL || parseError->message == NULL) {
        return @"Unknown parser error";
    }
    
    NSString* message = [NSString stringWithUTF8String:parseError->message];
    if (message.length == 0) {
        return @"Unknown parser error";
    }
    
    return [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)errorSnippetForString:(NSString *)string line:(int)line column:(int)column {
    if (string.length == 0 || line <= 0) {
        return nil;
    }
    
    NSString* targetLine = [self lineTextAtNumber:(NSUInteger)line inString:string];
    if (targetLine == nil) {
        return nil;
    }
    
    // Blank prefix aligned to "line N | " for the caret row
    NSString* linePrefix = [NSString stringWithFormat:@"line %d | ", line];
    NSString* blankPrefix = [@"" stringByPaddingToLength:linePrefix.length withString:@" " startingAtIndex:0];
    
    NSMutableString* result = [NSMutableString string];
    
    // Context lines before the error
    for (NSInteger ctx = (NSInteger)APP_LIST_SNIPPET_CONTEXT_LINES; ctx >= 1; ctx--) {
        NSInteger ctxLineNum = (NSInteger)line - ctx;
        if (ctxLineNum >= 1) {
            NSString* ctxLine = [self lineTextAtNumber:(NSUInteger)ctxLineNum inString:string] ?: @"";
            [result appendFormat:@"line %ld | %@\n", (long)ctxLineNum, ctxLine];
        }
    }
    
    // Error line with caret
    NSUInteger caretColumn = column > 0 ? (NSUInteger)column - 1 : 0;
    NSUInteger boundedCaretColumn = MIN(caretColumn, targetLine.length);
    NSUInteger start = boundedCaretColumn > APP_LIST_SNIPPET_RADIUS ? boundedCaretColumn - APP_LIST_SNIPPET_RADIUS : 0;
    NSUInteger maxLength = APP_LIST_SNIPPET_RADIUS * 2;
    NSUInteger visibleLength = start < targetLine.length ? MIN(targetLine.length - start, maxLength) : 0;
    NSString* excerpt = visibleLength > 0 ? [targetLine substringWithRange:NSMakeRange(start, visibleLength)] : @"";
    
    if (start > 0) {
        excerpt = [@"..." stringByAppendingString:excerpt];
    }
    if (start + visibleLength < targetLine.length) {
        excerpt = [excerpt stringByAppendingString:@"..."];
    }
    
    NSUInteger caretIndent = boundedCaretColumn >= start ? boundedCaretColumn - start : 0;
    if (start > 0) {
        caretIndent += 3;
    }
    
    [result appendFormat:@"%@%@\n", linePrefix, excerpt];
    [result appendFormat:@"%@%@^", blankPrefix, [@"" stringByPaddingToLength:caretIndent withString:@" " startingAtIndex:0]];
    
    // Context lines after the error
    for (NSUInteger ctx = 1; ctx <= APP_LIST_SNIPPET_CONTEXT_LINES; ctx++) {
        NSUInteger ctxLineNum = (NSUInteger)line + ctx;
        NSString* ctxLine = [self lineTextAtNumber:ctxLineNum inString:string];
        if (ctxLine == nil) {
            break;
        }
        [result appendFormat:@"\nline %lu | %@", (unsigned long)ctxLineNum, ctxLine];
    }
    
    return result;
}

- (NSString *)lineTextAtNumber:(NSUInteger)targetLine inString:(NSString *)string {
    if (targetLine == 0 || string.length == 0) {
        return nil;
    }
    
    __block NSString* matchedLine = nil;
    __block NSUInteger currentLine = 0;
    [string enumerateSubstringsInRange:NSMakeRange(0, string.length)
                               options:NSStringEnumerationByLines
                            usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        currentLine++;
        if (currentLine == targetLine) {
            matchedLine = substring ?: @"";
            *stop = YES;
        }
    }];
    
    return matchedLine;
}

- (void)logHexWindowAroundParseError:(const xmlError *)parseError bestEffortXml:(NSString *)bestEffortXml {
    if (self.data.length == 0) {
        return;
    }
    
    NSUInteger offset = 0;
    if (bestEffortXml.length > 0 && parseError != NULL && parseError->line > 0) {
        NSUInteger location = [self characterIndexForLine:parseError->line column:parseError->int2 inString:bestEffortXml];
        if (location != NSNotFound) {
            offset = MIN(location, self.data.length - 1);
        }
    }
    
    NSUInteger start = offset > APP_LIST_HEX_WINDOW_RADIUS ? offset - APP_LIST_HEX_WINDOW_RADIUS : 0;
    NSUInteger end = MIN(self.data.length, offset + APP_LIST_HEX_WINDOW_RADIUS);
    if (end <= start) {
        end = MIN(self.data.length, start + APP_LIST_HEX_WINDOW_SIZE);
    }
    
    NSData* windowData = [self.data subdataWithRange:NSMakeRange(start, end - start)];
    Log(LOG_W, @"AppListResponse: error hex window bytes[%lu..%lu]=%@",
        (unsigned long)start,
        (unsigned long)(end > 0 ? end - 1 : 0),
        [self hexPreviewForData:windowData maxBytes:windowData.length]);
}

- (NSUInteger)characterIndexForLine:(int)targetLine column:(int)targetColumn inString:(NSString *)string {
    if (string.length == 0 || targetLine <= 0) {
        return NSNotFound;
    }
    
    NSUInteger desiredColumn = targetColumn > 0 ? (NSUInteger)targetColumn : 1;
    NSUInteger line = 1;
    NSUInteger column = 1;
    
    for (NSUInteger idx = 0; idx <= string.length; idx++) {
        if (line == (NSUInteger)targetLine && column >= desiredColumn) {
            return MIN(idx, string.length);
        }
        
        if (idx == string.length) {
            break;
        }
        
        unichar character = [string characterAtIndex:idx];
        if (character == '\r') {
            if (idx + 1 < string.length && [string characterAtIndex:idx + 1] == '\n') {
                idx++;
            }
            line++;
            column = 1;
            continue;
        }
        
        if (character == '\n') {
            line++;
            column = 1;
            continue;
        }
        
        column++;
    }
    
    return NSNotFound;
}

- (void)logChunkedXmlBody:(NSString *)xmlString {
    if (xmlString.length == 0) {
        return;
    }
    
    NSUInteger totalChunks = (xmlString.length + APP_LIST_BODY_CHUNK_SIZE - 1) / APP_LIST_BODY_CHUNK_SIZE;
    for (NSUInteger idx = 0; idx < totalChunks; idx++) {
        NSUInteger location = idx * APP_LIST_BODY_CHUNK_SIZE;
        NSUInteger length = MIN(APP_LIST_BODY_CHUNK_SIZE, xmlString.length - location);
        NSString* chunk = [xmlString substringWithRange:NSMakeRange(location, length)];
        Log(LOG_W, @"AppListResponse: raw XML chunk %lu/%lu: %@",
            (unsigned long)(idx + 1),
            (unsigned long)totalChunks,
            chunk);
    }
}

- (NSArray<NSTextCheckingResult*>*)matchesForPattern:(NSString *)pattern inString:(NSString *)string {
    NSError* error = nil;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
                                                                             error:&error];
    if (regex == nil) {
        Log(LOG_W, @"AppListResponse: failed to create regex %@ error=%@", pattern, error.localizedDescription);
        return @[];
    }
    
    return [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
}

- (NSString *)firstCaptureForPattern:(NSString *)pattern inString:(NSString *)string {
    NSError* error = nil;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators
                                                                             error:&error];
    if (regex == nil) {
        Log(LOG_W, @"AppListResponse: failed to create regex %@ error=%@", pattern, error.localizedDescription);
        return nil;
    }
    
    NSTextCheckingResult* match = [regex firstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
    if (match == nil || match.numberOfRanges < 2) {
        return nil;
    }
    
    return [self decodedXmlEntities:[[string substringWithRange:[match rangeAtIndex:1]]
                                     stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
}

- (NSString *)extractTagValue:(NSString *)tagName fromXmlFragment:(NSString *)xmlFragment {
    NSString* fullPattern = [NSString stringWithFormat:@"<%@(?:\\s[^>]*)?>(.*?)</%@>", tagName, tagName];
    NSString* value = [self firstCaptureForPattern:fullPattern inString:xmlFragment];
    if (value.length > 0) {
        return value;
    }
    
    NSString* partialPattern = [NSString stringWithFormat:@"<%@(?:\\s[^>]*)?>([^<]*)", tagName];
    return [self firstCaptureForPattern:partialPattern inString:xmlFragment];
}

- (NSString *)decodedXmlEntities:(NSString *)string {
    if (string.length == 0) {
        return string;
    }
    
    NSString* decoded = [string stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    decoded = [decoded stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    decoded = [decoded stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    decoded = [decoded stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
    decoded = [decoded stringByReplacingOccurrencesOfString:@"&apos;" withString:@"'"];
    return decoded;
}

- (NSString *)hexPreviewForData:(NSData *)data maxBytes:(NSUInteger)maxBytes {
    if (data.length == 0) {
        return @"";
    }
    
    NSUInteger previewLength = MIN(data.length, maxBytes);
    NSMutableString* preview = [NSMutableString stringWithCapacity:previewLength * 3];
    const unsigned char* bytes = data.bytes;
    for (NSUInteger idx = 0; idx < previewLength; idx++) {
        [preview appendFormat:@"%02x", bytes[idx]];
        if (idx + 1 < previewLength) {
            [preview appendString:@" "];
        }
    }
    
    if (previewLength < data.length) {
        [preview appendString:@" ..."];
    }
    
    return preview;
}

- (NSSet*) getAppList {
    return _appList;
}

- (BOOL) isStatusOk {
    return self.statusCode == 200;
}

@end
