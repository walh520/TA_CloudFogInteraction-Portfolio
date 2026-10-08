# 函数映射与适配说明

项目原模块为 `Plugins/TA_ToonCloud`。表中路径均相对于该模块；行号对应提取时快照。公开文件只包含指定数学函数/段落，输入接口已有整理。

| 公开实现 | 项目入口 | 适配 |
| --- | --- | --- |
| CloudMorphology | `Shaders/Private/TAToonCloudDensityBuild.usf::TACloudBuildProfile` (186–222) | 保留高度/类型形态公式 |
| 天气语义 | 同文件 `TACloudBuildSemanticWeather` (120–140) | 以预采样噪声为输入，构建参数显式传入 |
| 密度等值面/膨胀 | `Shaders/Private/TAToonCloudDensityField.ush::TACloudDensityRemap` (95–99), `TACloudDensityBaseFromCombinedField/Fields` (287–315) | 四个全局阈值改为函数参数 |
| safe_octaves | `Source/TA_ToonCloudEditor/Private/TAToonCloudDensityFieldBuilder.cpp::ResolveSafeOctaves` (127–148) | Python 容器/数值适配 |
| scalar_mips | 同文件 `BuildScalarMips` (394–475) | Python 扁平数组，明确限制二次幂尺寸 |
| combined_macro_upper_bound | 同文件 `BuildCombinedMacroUpperBound` (547–560) | 去除 UE 容器，保留 UNorm8 饱和和 |
| PeriodicStep | `Shaders/Private/TAToonCloudDensityField.ush::TACloudDensityFootprintLod` (282–285), `TACloudDistanceToPeriodicCellBoundary` (392–422) | HLSL 数学函数保留；另有 CPU 镜像 |
| 透射步进 | `Shaders/Private/TAToonCloudShaftTrace.ush::ShaftTraceSun` (90–146) | 去除球壳/UE 纹理绑定；输入已求出的区间、密度和空区回调；距离统一为米 |
| CloudArt | `Shaders/Private/TAToonCloudFinalShade.usf::FinalShadePS` 艺术段 (436–726), `TACloudArtMatchLuminance/TintDirectBudget` (119–136) | 仅提取 A4–A8；去除 ABI 构建、legacy 材质 tint 与 UE 输出桥；明确输入、参数和 Rec.709 亮度辅助函数 |
| ContinuousLUT | 同文件 `TACloudSampleContinuousBaseColorLUT` (140–177) | 返回 UV0/UV1/权重，纹理采样交给调用方 |
| art_math | 上述艺术响应/能量/LUT 段 | 部分公式的 CPU 镜像；structural_responses 的系数为讲解示例，不代表 DA 默认值 |
| constant_segment | 通用 Beer–Lambert 与均匀介质解析积分 | 独立讲解重写；不映射到 UE 派生物理积分器 |

本次摘录没有引入原文件的材质桥、RDG、蓝噪声寻址、SH、大气查询或 UE 物理积分表达，也没有改变原工程。代码沿用项目函数名以保留映射；数学方法的来源见 [ATTRIBUTION.md](ATTRIBUTION.md)。
