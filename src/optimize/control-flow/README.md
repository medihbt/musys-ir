# `Musys.Optimize.Controlflow` -- 控制流图及控制流优化

本模块实现了控制流相关的数据结构与算法，以及一系列有关控制流的优化器.

该分支采用了主动追踪的 CFG 结构, 因此在实现上会简单一些.

## 实现的数据结构

- [ ] 控制流图: 部分实现(类似于 LLVM use-def 的方式)
- [x] DfsSequence类: DFS 遍历序列 + DFS 树
- [ ] 支配树
  - [ ] Semi-NCA 支配树
  - [ ] Lengauer–Tarjan 支配树

## 实现的算法

## 实现的优化器

- [ ] 分支消除
- [ ] 循环展开