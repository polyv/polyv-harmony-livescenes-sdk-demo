polyv-harmony-livescenes-sdk-demo
===

[![build passing](https://img.shields.io/badge/build-passing-brightgreen.svg)](#)
[![GitHub release](https://img.shields.io/badge/release-1.3.0-blue.svg)](https://github.com/polyv/polyv-harmony-livescenes-sdk-demo/releases/tag/1.3.0)

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [1 简介](#1-%E7%AE%80%E4%BB%8B)
- [2 下载安装](#2-%E4%B8%8B%E8%BD%BD%E5%AE%89%E8%A3%85)
- [3 文档](#3-%E6%96%87%E6%A1%A3)
  - [3.1 集成文档](#31-%E9%9B%86%E6%88%90%E6%96%87%E6%A1%A3)
  - [3.2 接口文档](#32-%E6%8E%A5%E5%8F%A3%E6%96%87%E6%A1%A3)
  - [3.3 版本更新记录](#33-%E7%89%88%E6%9C%AC%E6%9B%B4%E6%96%B0%E8%AE%B0%E5%BD%95)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

### 1 简介
此项目是保利威鸿蒙多场景 Demo。

此项目支持视频播放、在线聊天、打赏、商品、互动等功能（具体见[多场景支持的功能特性](https://github.com/polyv/polyv-harmony-livescenes-sdk-demo/blob/master/publish/docs/支持的功能特性.md)）

多场景项目的文件目录结构如下：

```
|-- entry
|   |-- ability
|   |   `-- PLVEntryAbility (SDK初始化)
|   |-- pages
|   |   `-- PLVLoginPage (登录页)
|   `-- startup (播放器初始化)
|-- scenes_live (直播带货场景模块)
|   |-- pages (观看页)
|   `-- components (功能组件)
`-- scenes_liveWatch (观看端场景模块)
    |-- common (场景内通用组件)
    |-- components (功能组件)
    `-- pages (观看页)
```

### 2 下载安装

```shell
ohpm install @polyvharmony/live-scenes-sdk
```

### 3 文档
#### 3.1 集成文档
[集成文档](https://github.com/polyv/polyv-harmony-livescenes-sdk-demo/tree/master/publish/docs)
#### 3.2 接口文档
[v1.3.0 接口文档](https://repo.polyv.net/harmony/documents/livescenes_sdk/1.3.0/index.html)
#### 3.3 版本更新记录
[全版本更新记录](https://github.com/polyv/polyv-harmony-livescenes-sdk-demo/blob/master/CHANGELOG.md)
