# TA Cloud, Fog & Interaction

UE 云雾系列：雾气数学、交互数据契约与地形采样摘录

这组作品围绕云、实时雾和场景交互展开。当前公开版本提供 6 份小型 C++ / HLSL 文件，展示雾段光学累积、运动代理形状、交互/环境数据布局和地形高度采样；Cloud 系列另附[架构说明](Docs/Cloud_Architecture.md)。

## 公开源码入口

| 文件 | 内容 |
| --- | --- |
| [TAFogOptics.ush](Plugins/TA_ToonVolumetricLighting/Shaders/Private/TAFogOptics.ush) | 雾段散射与透射率累积，调用外部 Beer–Lambert 透射率函数 |
| [TAFogShapeMath.ush](Plugins/TA_ToonVolumetricLighting/Shaders/Private/TAFogShapeMath.ush) | 四元数旋转，以及球、胶囊、盒代理的距离计算 |
| [TAToonFogInteraction.h](Plugins/TA_ToonVolumetricLighting/Source/TA_ToonVolumetricLighting/Private/TAToonFogInteraction.h) | 运动记录、修订/时间区间、CPU/GPU 交互数据布局和采集函数声明 |
| [TAToonFogEnvironment.h](Plugins/TA_ToonVolumetricLighting/Source/TA_ToonVolumetricLighting/Private/TAToonFogEnvironment.h) | 地形快照、环境参数、局部效果记录和数据包 |
| [TAToonFogEnvironmentParameters.inl](Plugins/TA_ToonVolumetricLighting/Source/TA_ToonVolumetricLighting/Private/TAToonFogEnvironmentParameters.inl) | 求解与显示共享的 RDG Shader 参数声明 |
| [TAFogTerrain.ush](Plugins/TA_ToonVolumetricLighting/Shaders/Private/TAFogTerrain.ush) | 双线性高度采样、地面距离/法线、地形判定和近地风向调整 |

这些文件保留项目相对目录，可用于阅读数据如何在场景、渲染请求与 Shader 之间组织。参数布局和适配代码属于 NiTong 的项目实现；光学、插值、四元数和解析距离计算采用已有数学方法，见[来源说明](ATTRIBUTION.md)。

## 范围与依赖

当前版本是局部源码摘录，不能独立安装或运行。完整 RealtimeFog Renderer、主求解/显示 Shader、Interactor/Effect 实现，以及 WorldInteraction、SceneWind 运行时不包含在内。Cloud 的运行时、Editor 集成和渲染核心也未公开在此版本中。

原项目目标为 UE 5.7.4 源码工程。摘录依赖 Unreal Engine 类型、RDG/Shader 参数宏和未随附的项目 Shader 辅助函数；具体见 [DEPENDENCIES.md](DEPENDENCIES.md)。声明的采集函数不等于已提供对应实现。

## 验证

文件内容与清单哈希已核对。未执行 UE 构建、Shader 编译、Editor/PIE、视觉或 GPU 性能测试。

- [文件清单](FILE_MANIFEST.csv)
- [SHA-256 校验值](SHA256SUMS.txt)

## English

This public selection contains six C++ / HLSL excerpts for fog segment accumulation, proxy geometry, interaction/environment data contracts and terrain sampling. It is a small source-reading collection, not a complete realtime fog or cloud renderer. The full runtime, solver/display shaders, dependency plugins and engine integration are separate. The [Cloud architecture page](Docs/Cloud_Architecture.md) is descriptive only.
