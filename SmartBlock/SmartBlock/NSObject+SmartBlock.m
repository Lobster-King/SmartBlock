//
//  NSObject+SmartBlock.m
//  SmartBlock
//
//  Created by lobster on 2019/2/25.
//  Copyright © 2019 lobster. All rights reserved.
//

#import "NSObject+SmartBlock.h"
#import <objc/runtime.h>

static NSString *kBlockDefaultKey = @"kBlockDefaultKey";

@interface BlockInfo : NSObject

@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, copy) id block;
@property (nonatomic, assign) BlockDestructionOption option;
@property (nonatomic, strong) NSThread *blockThread;
@property (nonatomic, assign) BOOL finished;

@end

@implementation BlockInfo

+ (id)initBlockInfoUsingBlock:(id)block option:(BlockDestructionOption)option {
    NSParameterAssert(block);
    return [BlockInfo initBlockInfoUsingKey:kBlockDefaultKey block:block option:option];
}

+ (id)initBlockInfoUsingKey:(NSString *)key block:(id)block option:(BlockDestructionOption)option {
    return [BlockInfo initBlockInfoUsingKey:key block:block thread:[NSThread currentThread] option:option];
}

+ (id)initBlockInfoUsingKey:(NSString *)key block:(id)block thread:(NSThread *)currentThread option:(BlockDestructionOption)option {
    BlockInfo *info = [[BlockInfo alloc]init];
    info.key        = key;
    info.block      = block;
    info.option     = option;
    info.blockThread= currentThread;
    return info;
}

@end

struct __Block_literal_ {
    void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct Block_descriptor_1 {
        unsigned long int reserved;     // NULL
        unsigned long int size;         // sizeof(struct Block_literal_1)
        // optional helper functions
        // void (*copy_helper)(void *dst, void *src);     // IFF (1<<25)
        // void (*dispose_helper)(void *src);             // IFF (1<<25)
        // required ABI.2010.3.16
        // const char *signature;                         // IFF (1<<30)
        void* rest[1];
    } *descriptor;
    // imported variables
};

static const char *__BlockSignature__(id blockRef)
{
    struct __Block_literal_ *block = (__bridge void *)blockRef;
    struct Block_descriptor_1 *descriptor = block->descriptor;
    int copyDisposeFlag = 1 << 25;
    int signatureFlag = 1 << 30;
    assert(block->flags & signatureFlag);
    int offset = 0;
    if(block->flags & copyDisposeFlag)
        offset += 2;
    return (const char*)(descriptor->rest[offset]);
}
static NSString *associatedObjectKey            = @"smartBlockKey";
static BOOL     initialized                     = NO;
static NSMutableDictionary *globalMap           = nil;
static NSMutableArray *argumentsRef             = nil;
static NSMutableArray *destructionDefaultArray  = nil;
static NSMutableArray *destructionInvokedArray  = nil;

@interface ObserverWatcher : NSObject

@property (nonatomic, copy) NSString *hostAddress;

@end

@implementation ObserverWatcher

- (void)dealloc {
    /*当前宿主对象释放之后，其关联对象随之被清理，在此方法内把全局的Block清理掉*/
    [self destroyBlocks];
}

- (void)destroyBlocks {
#warning 需要考虑多线程问题
    for (NSMutableArray *observers in [globalMap allValues]) {
        NSMutableArray *blocksTemp = [NSMutableArray array];
        for (BlockInfo *blockInfo in observers) {
            if ([blockInfo.address isEqualToString:self.hostAddress]) {
                [blocksTemp addObject:blockInfo];
            }
        }
        [observers removeObjectsInArray:blocksTemp];
    }
}

@end

@implementation NSObject (SmartBlock)

- (void)observeCallBackUsingKey:(NSString *)key callBack:(id)block {
    [self observeCallBackUsingKey:key callBack:block destructionOption:BlockDestructionDefault];
}

- (void)observeCallBackUsingKey:(NSString *)key callBack:(id)block destructionOption:(BlockDestructionOption)option {
    [self observeCallBackUsingKey:key callBack:block destructionOption:option blockRunModeOption:BlockRunModeDefault];
}

- (void)observeCallBackUsingKey:(NSString *)key callBack:(id)block destructionOption:(BlockDestructionOption)option blockRunModeOption:(BlockRunModeOption)runMode {
    NSParameterAssert(key);
    NSParameterAssert(block);
    
    if (!initialized) {
        globalMap = [NSMutableDictionary new];
        initialized = YES;
    }
    
    NSString *address = [NSString stringWithFormat:@"%p",self];
    
    id associatedObj = objc_getAssociatedObject(self, &associatedObjectKey);
    if (!associatedObj) {
        ObserverWatcher *watcher = [ObserverWatcher new];
        watcher.hostAddress = address;
        objc_setAssociatedObject(self, &associatedObjectKey, watcher, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    NSMutableArray *blocks = [globalMap objectForKey:key];
    if (!blocks) {
        blocks = [NSMutableArray array];
    }
    
    BlockInfo *info = [BlockInfo initBlockInfoUsingKey:key block:block option:option];
    info.address = address;
    [blocks addObject:info];
    
    [globalMap setObject:blocks forKey:key];
    
    if ([[NSThread currentThread] isMainThread]) {
        /*主线程单独处理，主线程不需要开启runloop，默认就是开启的*/
        info.blockThread = nil;
    } else if (runMode == BlockRunModeOnObserverThread) {
        /*子线程并且要求block执行在注册blcok线程，需要开启当前线程的runloop*/
        [self startRunLoopUsingBlockInfo:info];
    }
}

- (void)startRunLoopUsingBlockInfo:(BlockInfo *)info {
    [[NSRunLoop currentRunLoop] addPort:[NSPort new] forMode:NSDefaultRunLoopMode];
    while (!info.finished) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
    NSLog(@"over!!!");
}

- (void)callBackUsingKey:(NSString *)key,...NS_REQUIRES_NIL_TERMINATION {
    NSParameterAssert(key);
    
    va_list args;
    va_start(args, key);
    [self invokeMsgWithKey:key arguments:args];
    va_end(args);
}

- (void)invokeMsgWithKey:(NSString *)key arguments:(va_list)args {
    NSMutableArray *argsArray = [NSMutableArray array];
    id param = nil;
    while ((param = va_arg(args, id))) {
        [argsArray addObject:param];
    }
    [self invokeBlockUsingKey:key arguments:argsArray];
}

- (void)invokeBlockUsingKey:(NSString *)key arguments:(NSMutableArray *)args {
    argumentsRef = args;
    NSMutableArray *blocks = [globalMap objectForKey:key];
    destructionDefaultArray = [NSMutableArray array];
    destructionInvokedArray = [NSMutableArray array];
    
    for (id block in blocks) {
        BlockInfo *info = (BlockInfo *)block;
        if (info.blockThread == nil) {
            [self performSelector:@selector(invokeBlockOnDefaultThreadWithInfo:) withObject:info];
        }
        
        if (![info.blockThread isMainThread]) {
            [self performSelector:@selector(invokeBlockOnObserverThreadWithInfo:) onThread:info.blockThread withObject:info waitUntilDone:NO];
        }
        
        if (info.option == BlockDestructionDefault) {
            [destructionDefaultArray addObject:info];
        } else if (info.option == BlockDestructionBlockInvoked) {
            [destructionInvokedArray addObject:info];
        }
    }
    
    [self disposeBlockInfos:blocks];
}

- (void)invokeBlockOnDefaultThreadWithInfo:(BlockInfo *)blockInfo {
    NSMutableArray *args = argumentsRef;
    id block = blockInfo.block;
    NSMethodSignature *blockSignature = [NSMethodSignature signatureWithObjCTypes:__BlockSignature__(block)];
    
    if (argumentsRef.count != ([blockSignature numberOfArguments] - 1)) {
        //        NSAssert(0, @"参数个数不符！");
        /*参数个数不符合，直接丢弃本次block调用*/
        NSLog(@"Smart_Block_参数个数不符！");
        return;
    }
    /*
     1.不做参数具体类型校验
     2.上层业务负责类型校验
     */
    switch (argumentsRef.count) {
        case 0:
        {
            void (^blockRef)(void) = block;
            blockRef();
        }
            break;
        case 1:
        {
            void (^blockRef)(id) = block;
            blockRef(args[0]);
        }
            break;
        case 2:
        {
            void (^blockRef)(id,id) = block;
            blockRef(args[0],args[1]);
        }
            break;
        case 3:
        {
            void (^blockRef)(id,id,id) = block;
            blockRef(args[0],args[1],args[2]);
        }
            break;
        case 4:
        {
            void (^blockRef)(id,id,id,id) = block;
            blockRef(args[0],args[1],args[2],args[3]);
        }
            break;
        case 5:
        {
            void (^blockRef)(id,id,id,id,id) = block;
            blockRef(args[0],args[1],args[2],args[3],args[4]);
        }
            break;
        case 6:
        {
            void (^blockRef)(id,id,id,id,id,id) = block;
            blockRef(args[0],args[1],args[2],args[3],args[4],args[5]);
        }
            break;
        case 7:
        {
            void (^blockRef)(id,id,id,id,id,id,id) = block;
            blockRef(args[0],args[1],args[2],args[3],args[4],args[5],args[6]);
        }
            break;
        case 8:
        {
            void (^blockRef)(id,id,id,id,id,id,id,id) = block;
            blockRef(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7]);
        }
            break;
            
        default:
            break;
    }
}

- (void)invokeBlockOnObserverThreadWithInfo:(BlockInfo *)blockInfo {
    NSMutableArray *args = argumentsRef;
    id block = blockInfo.block;
    NSMethodSignature *blockSignature = [NSMethodSignature signatureWithObjCTypes:__BlockSignature__(block)];
    
    if (argumentsRef.count != ([blockSignature numberOfArguments] - 1)) {
        //        NSAssert(0, @"参数个数不符！");
        /*参数个数不符合，直接丢弃本次block调用*/
        NSLog(@"Smart_Block_参数个数不符！");
        return;
    }
    /*
     1.不做参数具体类型校验
     2.上层业务负责类型校验
     */
    switch (argumentsRef.count) {
        case 0:
        {
            void (^blockRef)(void) = block;
            blockRef();
        }
            break;
        case 1:
        {
            void (^blockRef)(id) = block;
            blockRef(args[0]);
        }
            break;
        case 2:
        {
            void (^blockRef)(id,id) = block;
            blockRef(args[0],args[1]);
        }
            break;
        case 3:
        {
            void (^blockRef)(id,id,id) = block;
            blockRef(args[0],args[1],args[2]);
        }
            break;
        case 4:
        {
            void (^blockRef)(id,id,id,id) = block;
            blockRef(args[0],args[1],args[2],args[3]);
        }
            break;
        case 5:
        {
            void (^blockRef)(id,id,id,id,id) = block;
            blockRef(args[0],args[1],args[2],args[3],args[4]);
        }
            break;
        case 6:
        {
            void (^blockRef)(id,id,id,id,id,id) = block;
            blockRef(args[0],args[1],args[2],args[3],args[4],args[5]);
        }
            break;
        case 7:
        {
            void (^blockRef)(id,id,id,id,id,id,id) = block;
            blockRef(args[0],args[1],args[2],args[3],args[4],args[5],args[6]);
        }
            break;
        case 8:
        {
            void (^blockRef)(id,id,id,id,id,id,id,id) = block;
            blockRef(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7]);
        }
            break;
            
        default:
            break;
    }
    blockInfo.finished = YES;
}

- (void)disposeBlockInfos:(NSMutableArray *)blocks{
    [blocks removeObjectsInArray:destructionInvokedArray];
}

@end
