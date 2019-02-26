# SmartBlock

## 使用场景：
* 跨多个界面回调，例如：ViewA -> ViewB -> ViewC 点击ViewC 回调给ViewA或者ViewA所在的controller。（解决多级回调等繁琐问题）
* 轻量级的通知模式替代方案。

## Demo演示：

![Demo gif](https://github.com/Lobster-King/SmartBlock/blob/master/SmartDemo.gif)
 
## 使用方式：
* 引入该分类头文件。
* 调用observeCallBackUsingKey方法，传入key和callBack block。
* 在需要处理回调的地方调用callBackUsingKey方法，传入key。

### 跨界面传值

```bash
/*注册*/
__weak typeof(self)weakSelf = self;
    [self observeCallBackUsingKey:@"touchCallBack" callBack:^(NSString *msg) {
        NSLog(@"%s",__func__);
        weakSelf.view.backgroundColor = [UIColor orangeColor];
    } destructionOption:BlockDestructionDefault];
/*发送*/
[self callBackUsingKey:@"touchCallBack",@"msg",nil];
```

### Block执行线程和注册线程一致

```bash
/*注册*/
[NSThread detachNewThreadSelector:@selector(addObserber) toTarget:self withObject:nil];

- (void)addObserber {
    NSLog(@"注册block线程：%@",[NSThread currentThread]);
    __weak typeof(self)weakSelf = self;
    [self observeCallBackUsingKey:@"touchCallBack" callBack:^(NSString *msg) {
        NSLog(@"block执行线程：%@",[NSThread currentThread]);
        dispatch_async(dispatch_get_main_queue(), ^{
           weakSelf.view.backgroundColor = [UIColor orangeColor];
        });
    } destructionOption:BlockDestructionDefault blockRunModeOption:BlockRunModeOnObserverThread];
}
/*发送*/
[self callBackUsingKey:@"touchCallBack",@"msg",nil];
```
 
## 注意事项：
* 提供BlockDestructionDefault和BlockDestructionBlockInvoked两种模式。
* block入参个数与调用时的参数个数确保一致，否则会丢弃block的执行。
* 谨慎使用option BlockDestructionBlockInvoked
 
## 与通知对比：
* 使用通知忘记dealloc移除观察者在iOS9之前会出现崩溃。
* 发送通知和接收通知的处理是同步的。
* 如果要实现发送通知和接收通知在不同线程，系统原生通知实现比较复杂。
 
## TODO List:
* 多线程安全问题。
* 宿主对象清理策略。
* 性能优化。

## Have a problem?

You can contact me in the following ways

* PRs or Issues.
* Email :[zhiwei.geek@gmail.com](mailto:zhiwei.geek@gmail.com)

