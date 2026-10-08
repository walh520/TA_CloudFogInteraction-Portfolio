# TA Cloud, Fog & Interaction

UE 云雾系列：云密度烘焙、光线步进、艺术 DA 渲染与雾气交互数学

这组作品围绕云、实时雾和场景交互展开。[Cloud 核心算法](CoreAlgorithms/README.md) 展示密度烘焙、周期单元步进、完整路径透射以及共享艺术 Data Asset 的 A4–A8 连续渲染数学；原有六份雾气与交互摘录继续保留。

## Cloud 核心算法

| 入口 | 内容 |
| --- | --- |
| [密度形态](CoreAlgorithms/Baking/CloudMorphology.hlsli) / [烘焙数学](CoreAlgorithms/Baking/bake_math.py) | 云类型高度曲线、Coverage 等值面、形态膨胀、频率约束、周期 halo 与 max/mean mip |
| [周期步进](CoreAlgorithms/Raymarch/PeriodicStep.hlsli) / [透射求积](CoreAlgorithms/Raymarch/trace_math.py) | 单元面距离、完整路径中点采样、参考预算与失败处理 |
| [艺术 DA 数学](CoreAlgorithms/Art/CloudArt.hlsli) / [连续 LUT](CoreAlgorithms/Art/ContinuousLUT.hlsli) | Wrap、暗边、银边、Powder、曲率、Inner Glow、天气/距离响应及能量限制 |

[中文算法说明](CoreAlgorithms/ALGORITHMS_CN.md) · [函数映射](CoreAlgorithms/SOURCE_MAP.md) · [数学来源](CoreAlgorithms/ATTRIBUTION.md)

## 雾气与交互源码入口

| 文件 | 内容 |
| --- | --- |
| [TAFogOptics.ush](Plugins/TA_ToonVolumetricLighting/Shaders/Private/TAFogOptics.ush) | 雾段散射与透射率累积，调用外部 Beer–Lambert 透射率函数 |
| [TAFogShapeMath.ush](Plugins/TA_ToonVolumetricLighting/Shaders/Private/TAFogShapeMath.ush) | 四元数旋转，以及球、胶囊、盒代理的距离计算 |
| [TAToonFogInteraction.h](Plugins/TA_ToonVolumetricLighting/Source/TA_ToonVolumetricLighting/Private/TAToonFogInteraction.h) | 运动记录、修订/时间区间、CPU/GPU 交互数据布局和采集函数声明 |
| [TAToonFogEnvironment.h](Plugins/TA_ToonVolumetricLighting/Source/TA_ToonVolumetricLighting/Private/TAToonFogEnvironment.h) | 地形快照、环境参数、局部效果记录和数据包 |
| [TAToonFogEnvironmentParameters.inl](Plugins/TA_ToonVolumetricLighting/Source/TA_ToonVolumetricLighting/Private/TAToonFogEnvironmentParameters.inl) | 求解与显示共享的 RDG Shader 参数声明 |
| [TAFogTerrain.ush](Plugins/TA_ToonVolumetricLighting/Shaders/Private/TAFogTerrain.ush) | 双线性高度采样、地面距离/法线、地形判定和近地风向调整 |

这些文件保留项目相对目录，展示数据如何在场景、渲染请求与 Shader 之间组织。参数布局和适配代码属于 NiTong 的项目实现；基础数学见[来源说明](ATTRIBUTION.md)。Cloud 系列完整结构另见[架构说明](Docs/Cloud_Architecture.md)。

## 范围与依赖

Cloud 新增部分按函数整理，采用显式参数、数组与采样回调。接回完整渲染管线时，需要密度采样、射线区间、物理积分结果、重建特征和 LUT 采样；原插件的运行时、Editor、材质/RDG 集成与资产另行接入。

原有雾气文件依赖 UE 5.7.4 类型、RDG/Shader 参数宏和项目辅助函数，见 [DEPENDENCIES.md](DEPENDENCIES.md)。完整 RealtimeFog 求解/显示、Interactor/Effect、WorldInteraction 和 SceneWind 运行时仍为独立依赖。

## 验证

新增核心算法的 13 项 CPU 数学检查通过，覆盖密度上界、周期层级、步进预算、均匀介质、曲率、LUT 和能量边界。未执行 UE 构建、Shader 编译、Editor/PIE、视觉或 GPU 性能测试。

- [新增核心文件清单](CoreAlgorithms/FILE_MANIFEST.csv) / [校验值](CoreAlgorithms/SHA256SUMS.txt)
- [全仓库文件清单](FILE_MANIFEST.csv) / [校验值](SHA256SUMS.txt)

## English

The Cloud core algorithms cover baking morphology, periodic ray stepping, full-path transmission and Data Asset driven continuous art responses. The existing six C++ / HLSL fog and interaction excerpts remain available. Extracted functions use explicit adapters and have CPU mathematical checks; engine integration and assets are supplied separately.
