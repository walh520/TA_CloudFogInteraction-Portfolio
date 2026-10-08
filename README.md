# TA Cloud, Fog & Interaction

UE 5.7.4 云、实时雾与交互源码摘录 / Cloud, realtime fog and interaction source excerpts

NiTong 的云雾系列将云层与局部体积、密度场创作、艺术化光照、实时浓度/速度场和运动代理组织为项目级 UE 插件。这里提供当前 C++、USF/USH 和 GPU 数据契约的可阅核心，便于沿入口理解模块职责与数据流。

| 系统 / System | 当前模块 / Modules | 阅读入口 / Entry |
| --- | --- | --- |
| 天空云与局部云、烘焙雾 / Sky and local clouds, baked fog | TA_ToonCloud + TA_ToonCloudEditor | TAToonCloudActor / TAToonCloudVolumeActor / TAToonFogVolumeActor; density builders; TAToonCloudRenderer |
| 实时雾 / Realtime fog | TA_ToonVolumetricLighting | TAToonRealtimeFogActor / Component / Renderer; TARealtimeFog.usf |
| 运动代理和局部效果 / Moving proxies and local effects | TA_ToonVolumetricLighting | TAToonRealtimeFogInteractorComponent; TAToonRealtimeFogEffectComponent; TAFogInteraction.ush |
| 世界分区、表面查询 / World partitions and surface queries | TAWorldInteractionRuntime excerpts | TAWorldInteractionPartition; TAWorldSurfaceHeight |
| 风场与植被历史 / Wind field and foliage history | SceneWind shader excerpts | SceneWindField.usf; SceneWindFoliageHistoryUpdate.usf |

NiTong 的实现贡献包括插件生命周期、Actor/Component 与反射属性、密度场编辑器工具、RDG 调度、缓存与历史资源管理、解析交互代理、诊断接口和 Shader 数据布局。体积传输、噪声、平流、压力投影及插值采用已有数学方法与 UE API；方法来源见 [ATTRIBUTION.md](ATTRIBUTION.md)。

本仓库为核心摘录，保留原相对目录。部分云传输 Shader、SceneWind/WorldInteraction 核心和引擎接口实现未随包提供，因此不能直接作为完整插件构建。Realtime Fog 有自己的浓度/速度场；Global Fog 则需要定制原生 Froxel 接口。具体依赖、缺失文件与集成边界见 [DEPENDENCIES.md](DEPENDENCIES.md)。

This collection presents project-specific C++, shaders and data contracts for cloud rendering, realtime fog and interaction. It is a source excerpt for reading and integration study. The complete runtime, dependency plugins, custom engine bridge and serialized assets must be supplied separately. Build, shader, Editor/PIE, visual and GPU performance validation were not run for this package.

Start with the [core source guide](Docs/Core_Source_Guide.md). See [architecture](Docs/Architecture_CN_EN.md), [dependencies](DEPENDENCIES.md) and [file manifest](FILE_MANIFEST.csv).
