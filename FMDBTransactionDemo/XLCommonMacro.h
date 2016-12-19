//
//  XLCommonMacro.h
//  FMDBTransactionDemo
//
//  Created by xiaoL on 16/12/19.
//  Copyright © 2016年 xiaolin. All rights reserved.
//

#ifndef XLCommonMacro_h
#define XLCommonMacro_h

#define SINGLETON_DEFINE(className) \
\
+ (className *)sharedInstance; \


#define SINGLETON_IMPLEMENT(className) \
\
+ (className *)sharedInstance { \
static className *shared##className = nil; \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
shared##className = [[self alloc] init]; \
}); \
return shared##className; \
}


#endif /* XLCommonMacro_h */
