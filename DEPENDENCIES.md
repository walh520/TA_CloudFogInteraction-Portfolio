# 依赖与摘录边界

## 目标环境

原项目目标为 Unreal Engine 5.7.4 源码工程。头文件使用 `CoreMinimal.h` 中的 UE 类型；参数文件需包含在有效的 Shader 参数结构中，并由调用方提供 RDG 与 Shader 参数宏。

## 文件依赖

- `TAFogOptics.ush` 包含未随附的 `TAToonVolumetricGeometry.ush`，并调用其中的 `TABeerLambertTransmittance`
- `TAFogTerrain.ush` 包含未随附的 `TAFogSoftBoundary.ush`，同时需要调用方定义网格间距 `H`，提供高度缓冲、环境参数和有效的参数范围
- `TAToonFogEnvironment.h` 依赖已包含的 `TAToonFogInteraction.h`
- `TAToonFogInteraction.h` 声明运动数据采集接口；对应的组件、数据服务和实现未包含
- `TAToonFogEnvironment.h` 声明局部效果数据采集接口；对应实现未包含
- `TAToonFogEnvironmentParameters.inl` 是共享参数声明片段，需要匹配的求解/显示参数结构和资源绑定代码

`TAFogShapeMath.ush` 提供几何辅助函数；调用方负责传入约定的形状编码、尺寸和旋转参数。

## 未包含的部分

- TA_ToonCloud / TA_ToonCloudEditor 的运行时、编辑器、密度场创作和渲染 Shader
- 完整 RealtimeFog Renderer、主求解与显示 Shader、Interactor/Effect 组件实现
- WorldInteraction 与 SceneWind 的运行时和其他源码
- Global Fog、LightBeam、原生引擎渲染桥
- 插件入口、Build.cs、.uplugin、完整工程和序列化资产

因此当前目录不能直接安装、编译或运行完整效果，也不表示兼容未修改的 UE 版本。Cloud 的设计阅读说明见 [Docs/Cloud_Architecture.md](Docs/Cloud_Architecture.md)。

## 验证状态

本次未运行 UBT/UHT、ShaderCompileWorker、UE 自动化、Editor/PIE、视觉检查或性能基准。文件校验仅验证公开内容与清单的一致性。
