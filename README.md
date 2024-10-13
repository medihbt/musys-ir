# Musys -- 类 LLVM 编译器框架

参考 LLVM 设计、使用 Vala 实现的中间代码框架. 目前 Musys 主要供 [medihbt](https://github.com/medihbt) 学习编译/优化原理使用, 将来可能会成为 [Musys 语言项目](https://github.com/medihbt/musys-lang) 的一部分.

## 项目结构

与 LLVM 所有子项目都放在一个 Git 归档的做法不同, Musys 每一个模块 (前端、中间代码、后端) 都会放在不同的项目归档里. 下面是计划实现的一些子项目, 其中大多数仅仅是规划而已:

- \[Musys-IR]: Musys-IR 自己也是一个子项目, 主要实现中间代码以及一系列优化器.
- [\[Musys-Lang\]](https://github.com/medihbt/musys-lang): Musys 编程语言, 该项目是编译器前端项目
- \[Musys-MIR]: Musys 接近机器一端的中间代码.
- \[Musys-RISCV]: Musys 的 RISC-V 后端

这个项目(Musys-IR)的文件布局如下:

- `src`: 存放项目的 Vala 代码, 所有的实现都在这里.
  - `src/base`: 一些基础的支持类/函数, 例如栈回溯、哈希等 GLib 库没有的.
  - `src/type`: Musys-IR 和 Musys-MIR 的类型系统.
  - `src/ir`: 中间代码指令系统, 实现了值、数据流、指令等. 总体架构和 LLVM 大差不差.
  - `src/ir-util`: 中间代码的外围工具, 包括打印器等.
  - `src/optimize`: 优化算法、优化器
- `csource`: 存放项目的 C 代码. 倘若有一些 Vala 代码存在性能瓶颈或者跨不了平台, 就会换成用 C 实现.
- `include`: C 代码对应的头文件.

## 构建指南

Musys-IR 项目使用 [Vala 语言](https://vala.dev) 编写, 采用 [Meson 构建系统](https://mesonbuild.com/), 主要支持 Linux/GLibC 平台, 能在 Linux 和 Windows 平台上成功编译. 该模块是一个动态库, 因此

Musys 在 Fedora 40 操作系统平台的依赖如下:

- `vala`
- `meson`
- `ninja-build`
- `pkg-config`
- `glib-devel`: Vala 包名 `glib-2.0` `gobject-2.0`
- `libgee-devel`: Vala 包名 `gee-0.8`

在 Windows 平台上请安装 msys2 环境, 并安装以下依赖:

- `mingw-w64-ucrt-x86_64-gcc`
- `mingw-w64-ucrt-x86_64-pkg-config`
- `mingw-w64-ucrt-x86_64-vala`
- `mingw-w64-ucrt-x86_64-meson`
- `mingw-w64-ucrt-x86_64-libgee`

然后可以构建了.

### 作为动态库构建

准备好环境以后, 进入项目所在目录并输入命令:

```bash
meson setup build
cd build && meson compile

# 倘若要安装, 在 root 用户下执行
meson install
```

然后你就能在 `build/src` 目录下看到所需要的 `libmusys.so` `Musys-0.0.1.gir` `musys.h` 和 `musys.vapi` 文件了.

### 作为子项目

倘若你想跳过繁琐的编译流程, 直接引用该项目作为子项目, 那你要确保你的项目也使用 Meson 作为构建系统, 然后按照[这篇说明](https://mesonbuild.com/Subprojects.html)构建即可.

## 补充信息

### Musys 语言

计划开发的编程语言, 语法类似 SysY 的 C 语言子集.

### 项目许可

项目采用 MIT 许可证, 以下是它的内容:

```
MIT License

Copyright (c) 2024 Medi H.B.T.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### 鸣谢

Musys 项目源于 MYGL-C 项目，而 MYGL-C 项目离不开下述组员的贡献:

- CapitalLiu (https://gitee.com/CapitalLiu)
- 杨东炜 (https://gitee.com/yang-dongwei2)
- gypso (https://gitee.com/gyp-so)
