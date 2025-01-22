/*
 * Copyright (C) 2024 Razer Inc.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "HttpResponse+Neuron.h"
#import "RzSwizzling.h"
#import "TemporaryApp.h"
#import <libxml2/libxml/xmlreader.h>

@implementation HttpResponse (Neuron)
+ (void)load {
    [self methodSwizzling];
}

+ (void)methodSwizzling {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RzSwizzling instanceTarget:[HttpResponse new] origSel:@selector(parseData) swizzleSel:@selector(rz_parseData)];
    });
}

- (void) rz_parseData {
    
    Ivar ivar = class_getInstanceVariable([HttpResponse class], "_elements");
    if (!ivar) {
        NSLog(@"Cannot find instance variable _elements.");
        return;
    }
    
    NSMutableDictionary *_elements = object_getIvar(self, ivar);
    if (!_elements) {
        _elements = [NSMutableDictionary dictionary];
    }
    
    _elements = [[NSMutableDictionary alloc] init];
    xmlDocPtr docPtr = xmlParseMemory([self.data bytes], (int)[self.data length]);
    if (docPtr == NULL) {
        Log(LOG_W, @"An error occurred trying to parse xml.");
        return;
    }
    
    xmlNodePtr node = xmlDocGetRootElement(docPtr);
    if (node == NULL) {
        Log(LOG_W, @"No root XML element.");
        xmlFreeDoc(docPtr);
        return;
    }
    
    xmlChar* statusStr = xmlGetProp(node, (const xmlChar*)[TAG_STATUS_CODE UTF8String]);
    if (statusStr != NULL) {
        int status = (int)[[NSString stringWithUTF8String:(const char*)statusStr] longLongValue];
        xmlFree(statusStr);
        self.statusCode = status;
    }
    
    xmlChar* statusMsgXml = xmlGetProp(node, (const xmlChar*)[TAG_STATUS_MESSAGE UTF8String]);
    if (statusMsgXml != NULL) {
        self.statusMessage = [NSString stringWithUTF8String:(const char*)statusMsgXml];
        xmlFree(statusMsgXml);
    } else {
        self.statusMessage = @"Server Error";
    }
    
    if (self.statusCode == -1 && [self.statusMessage isEqualToString:@"Invalid"]) {
        self.statusCode = 418;
        self.statusMessage = Localized(@"Missing audio capture device. Reinstalling Razer Cortex should resolve this error.");
    }
    
    // 递归解析多层 XML
    [self parseNode:node intoDictionary:_elements];
    
    xmlFreeDoc(docPtr);
    Log(LOG_D, @"Parsed XML data: %@", _elements);
    object_setIvar(self, ivar, _elements[@"root"]);
}

- (void) parseNode:(xmlNodePtr)node intoDictionary:(NSMutableDictionary *)dict {
    while (node != NULL) {
        NSString *key = [[NSString alloc] initWithCString:(const char*)node->name encoding:NSUTF8StringEncoding];
        if (key.length == 0) {
            node = node->next;
            continue;
        }

        xmlChar *nodeValue = xmlNodeListGetString(node->doc, node->xmlChildrenNode, 1);
        if (nodeValue) {
            NSString *value = [[NSString alloc] initWithCString:(const char*)nodeValue encoding:NSUTF8StringEncoding];
            xmlFree(nodeValue);
            dict[key] = value;
        }

        if (node->children) {
            NSMutableDictionary *childDict = [NSMutableDictionary dictionary];
            [self parseNode:node->children intoDictionary:childDict];
            if (childDict.count > 0) {
                dict[key] = childDict;
            }
        }

        node = node->next;
    }
}
@end
