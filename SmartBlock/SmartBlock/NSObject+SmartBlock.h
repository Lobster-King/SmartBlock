//
//  NSObject+SmartBlock.h
//  SmartBlock
//
//  Created by lobster on 2019/2/25.
//  Copyright © 2019 lobster. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 使用场景：
 1.跨多个界面回调，例如：ViewA -> ViewB -> ViewC 点击ViewC 回调给ViewA或者ViewA所在的controller。（解决多级回调等繁琐问题）
 2.轻量级的通知模式解决方案。
 
 使用方式：
 1.引入该分类头文件。
 2.调用observeCallBackUsingKey方法，传入key和callBack block。
 3.在需要处理回调的地方调用callBackUsingKey方法，传入key。
 
 注意事项：
 1.提供BlockDestructionDefault和BlockDestructionBlockInvoked两种模式。
 2.block入参个数与调用时的参数个数确保一致，否则会丢弃block的执行。
 3.谨慎使用option BlockDestructionBlockInvoked
 
 与通知对比：
 1.使用通知忘记dealloc移除观察者在iOS9之前会出现崩溃。
 2.发送通知和接收通知的处理是同步的。
 3.如果要实现发送通知和接收通知在不同线程，系统原生通知实现比较复杂。
 
 TODO List:
 1.多线程安全问题。
 2.宿主对象清理策略。
 3.性能优化。
 */

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, BlockDestructionOption) {
    BlockDestructionDefault         = 0,/*当前object，即self释放后进行block清理*/
    BlockDestructionBlockInvoked    = 1,/*block调用后即清理*/
};

typedef NS_OPTIONS(NSUInteger, BlockRunModeOption) {
    BlockRunModeDefault             = 0,/*执行block线程和触发callBackUsingKey线程一致*/
    BlockRunModeOnObserverThread    = 1,/*执行block线程和注册observeCallBackUsingKey线程一致*/
};

@interface NSObject (SmartBlock)

- (void)observeCallBackUsingKey:(NSString *)key callBack:(id)block;
- (void)observeCallBackUsingKey:(NSString *)key callBack:(id)block destructionOption:(BlockDestructionOption)option;
- (void)observeCallBackUsingKey:(NSString *)key callBack:(id)block destructionOption:(BlockDestructionOption)option blockRunModeOption:(BlockRunModeOption)runMode;

- (void)callBackUsingKey:(NSString *)key,...NS_REQUIRES_NIL_TERMINATION;

@end

NS_ASSUME_NONNULL_END
