BetterXib
=========
在使用`xib`的过程中你是否碰到过这样的情景：你选中一个`Label`，修改它的字体、颜色、大小，然后使用。过了一会儿，在另一个地方你又要使用刚才配置过的`Label`，于是。。过了两秒钟你想起了上次使用它的地方，接着你熟练的搜索，复制，粘贴。又过了一会儿，你又要使用它。。

如何解决？
--------

当第三次我又要使用那个Label的时候，我想："嗯，是时候创建一个“类”来解决这个问题啦！"

我的做法是：建一个以项目命名的`xib`文件，在这个文件中存放这个项目中重复使用的`UI控件`。在需要的时候直接从这个项目文件中复制，粘贴。
生活美好了一些！

接着，在学会儿编写Xcode插件后，我写了`BetterXib`

它很小，但很有用！

现在你只需要按下`Ctrl+G`，那个`Label`就会出现在你的面前！

使用方法
--------
- **插件安装**
  copy BetterXib.xcplugin to ~/Library/Application Support/Developer/Shared/Xcode/Plug-ins/ or build target , after build, Xcode will help you copy the plug-in product to that directory.
Then you should restart Xcode ,let Xcode load the plug-in.

- **使用**
  按`Ctrl+G`会引导生成一个控件模板文件，然后你可以在模板文件中存放项目中经常使用到的`UI控件`
  下次使用的时候，再按`Ctrl+G`，模板文件会被打开，你就可以从里面选择你需要的控件啦。
