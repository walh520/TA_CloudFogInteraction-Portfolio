# 依赖与摘录边界

## Cloud 核心算法

`CoreAlgorithms` 新增函数级 HLSL 数学摘录和 Python CPU 适配。Python 文件只使用标准库；可从仓库根目录运行 `python -B CoreAlgorithms/Tests/check_math.py`。HLSL 输入结构、数组和采样回调已独立整理，但尚未进行 HLSL 编译或与 GPU 输出的逐项比对。

完整集成由调用方提供密度采样、射线有效区间、物理积分结果、重建后的特征及 LUT 采样。DA 对应项目中的 `UTAToonCloudArtProfile`，公开摘录将其参数展开为显式结构，不包含 UE Data Asset 类、资源或反射/编辑器代码。

算法接口、输入单位和适配范围见 [CoreAlgorithms/README.md](CoreAlgorithms/README.md) 与[函数映射](CoreAlgorithms/SOURCE_MAP.md)。

## 原有雾气摘录的目标环境

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

- TA_ToonCloud / TA_ToonCloudEditor 的完整运行时、编辑器、纹理资源创作与渲染管线；新增 CoreAlgorithms 仅提供上述独立数学函数
- 完整 RealtimeFog Renderer、主求解与显示 Shader、Interactor/Effect 组件实现
- WorldInteraction 与 SceneWind 的运行时和其他源码
- Global Fog、LightBeam、原生引擎渲染桥
- 插件入口、Build.cs、.uplugin、完整工程和序列化资产

因此当前目录不能直接安装、编译或运行完整效果，也不表示兼容未修改的 UE 版本。Cloud 的设计阅读说明见 [Docs/Cloud_Architecture.md](Docs/Cloud_Architecture.md)。

## 验证状态

新增核心算法的13项 CPU 边界/不变量检查通过，不能替代 HLSL 编译、GPU 一致性或视觉验证。本次未运行 UBT/UHT、ShaderCompileWorker、UE 自动化、Editor/PIE、视觉检查或性能基准。文件校验仅验证公开内容与清单的一致性。
