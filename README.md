# Musys Compiler -- 一个简单的 SysY 扩展编译器

Musys 有两个含义:

- Musys 语言:   C 语言的子集, SysY 2022 的扩展语法. 与 SysY 2022 相比, 支持简易的封包等特性.
- Musys 编译器: 类似于 LLVM/Clang 的编译器, 但是使用 Vala 编写. 目前没有任何后端规划.

该项目源于 [MYGL-v](https://gitee.com/mygl-v) 小组的 MYGL-C 编译器，精简了一部分架构，并换用语法更简单的 Vala 实现.

本仓库是 Musys 编译器的底层中间语言 (Musys-IR) 部分. 其他部分参见:

- \[[Musys Lang](https://github.com/medihbt/musys-lang)\] Musys 编译器的前端部分. 为节省开发时间, 该项目使用 Vala 编译器 (libvala) 作为前端, 并根据 SysY 的语法做了大量限制.

## 构建

Musys 使用 meson + ninja 构建系统. 目前所有的构建都只用于测试程序语法的正确性，不能编译出任何可执行的程序.

Musys 项目使用 Vala 语言编写, 目前只能在 Linux 平台编译. 你需要确保你安装了 [Vala](https://vala.dev) 编译器, 以及下面所需的依赖:

- `glib-2.0`
- `gobject-2.0`
- `gee-0.8`

Musys 项目使用 meson 作为构建系统, 因此你还需要额外安装 meson 和 ninja.

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
