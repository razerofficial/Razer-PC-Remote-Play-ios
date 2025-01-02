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

#import "RzSwizzling.h"
#import <objc/runtime.h>

@implementation RzSwizzling

+ (void)classTarget:(Class)cls origSel:(SEL)originalSelector swizzleSel:(SEL)swizzledSelector {
    Class class = object_getClass((id)cls);
    
    Method originalMethod = class_getClassMethod(class, originalSelector);
    Method swizzledMethod = class_getClassMethod(class, swizzledSelector);
    
    [self _swizzleClass:class origSel:originalSelector origMethod:originalMethod swizzleSel:swizzledSelector swizzleMethod:swizzledMethod];
}

+ (void)instanceTarget:(id)instance origSel:(SEL)originalSelector swizzleSel:(SEL)swizzledSelector {
    Class class = [instance class];
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    [self _swizzleClass:class origSel:originalSelector origMethod:originalMethod swizzleSel:swizzledSelector swizzleMethod:swizzledMethod];
}

+ (void)_swizzleClass:(Class)class origSel:(SEL)originalSelector origMethod:(Method)originalMethod swizzleSel:(SEL)swizzledSelector swizzleMethod:(Method)swizzledMethod {
    //If the method already exists, it is exchanged directly, otherwise the new method is added to perform the exchange logic
    BOOL isExist = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (isExist) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@end
