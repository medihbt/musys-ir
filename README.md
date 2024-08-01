# Musys Compiler -- 一个简单的 SysY 扩展编译器

Musys 有两个含义:

- Musys 语言:   C 语言的子集, SysY 2022 的扩展语法. 与 SysY 2022 相比, 支持简易的封包等特性.
- Musys 编译器: 类似于 LLVM/Clang 的编译器, 但是使用 Vala 编写. 目前没有任何后端规划.

该项目源于 [MYGL-v](https://gitee.com/mygl-v) 小组的 MYGL-C 编译器，精简了一部分架构，并换用语法更简单的 Vala 实现.

## 构建

Musys 使用 meson + ninja 构建系统. 目前所有的构建都只用于测试程序语法的正确性，不能编译出任何可执行的程序.

你需要在项目根目录下执行如下命令:

```sh
meson setup build && cd build
meson compile
```

## 鸣谢

Musys 项目源于 MYGL-C 项目，而 MYGL-C 项目离不开下述组员的贡献:

- CapitalLiu (https://gitee.com/CapitalLiu)
- 杨东炜 (https://gitee.com/yang-dongwei2)
- gypso (https://gitee.com/gyp-so)
