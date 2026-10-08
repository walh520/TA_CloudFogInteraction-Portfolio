# 来源说明

这些摘录来自 NiTong 的 TA_ToonVolumetricLighting 项目目录，保留项目内的函数命名、数据布局和相对路径。

- 雾段累积使用已有的 Beer–Lambert 透射率与前向散射累积形式；透射率辅助函数位于单独依赖文件中
- 代理形状使用既有的四元数旋转，以及球、胶囊、盒的解析距离公式
- 地形部分使用双线性插值、有限差分法线和面向效果的近地风调整
- 交互与环境头文件组织项目的运动历史、时间/修订字段、GPU 数据和参数接口

项目实现与接口适配不改变这些数学方法的归属。Unreal Engine API、类型及另外提供的引擎/插件依赖保留各自的所有权与适用条款。此版本未包含引擎实现或序列化资产，也未提供所缺依赖的授权。

新增 [CoreAlgorithms](CoreAlgorithms/README.md) 收录烘焙、光线步进与艺术 DA 的函数级适配；具体项目入口、独立讲解重写与数学背景见[函数映射](CoreAlgorithms/SOURCE_MAP.md)和[核心数学来源](CoreAlgorithms/ATTRIBUTION.md)。完整 Cloud 与 RealtimeFog 渲染管线仍未随附。

## English

The excerpts preserve project-specific names, data layouts and paths from NiTong's TA_ToonVolumetricLighting project. Optical accumulation, quaternion rotation, analytic distance functions, interpolation and finite differences build on established mathematical methods. Unreal Engine APIs and separately supplied implementations retain their ownership and applicable terms. The CoreAlgorithms directory adds function-level baking, ray-stepping and art-response adaptations with a separate source map. Complete Cloud and RealtimeFog engine integration is not included.
