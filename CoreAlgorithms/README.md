# Cloud 核心算法

这组摘录展示云密度烘焙、光线步进和艺术 Data Asset 的连续着色数学。代码来自 TA_ToonCloud 的具体函数与新增艺术响应段落；输入结构、数组容器、采样回调和少量数值检查被整理为独立接口，便于阅读与验证。

| 入口 | 核心内容 |
| --- | --- |
| [CloudMorphology.hlsli](Baking/CloudMorphology.hlsli) | 三类云形态的高度曲线、Coverage 驱动等值面、形态膨胀与天气语义通道 |
| [bake_math.py](Baking/bake_math.py) | 按分辨率限制 octave、Macro 上界、周期 halo 和 max/mean mip |
| [PeriodicStep.hlsli](Raymarch/PeriodicStep.hlsli) | 采样足迹 LOD 与正负方向的周期单元边界距离 |
| [trace_math.py](Raymarch/trace_math.py) | 全路径中点透射、预算受限参考步进、保守空区回调和独立光学讲解例子 |
| [CloudArt.hlsli](Art/CloudArt.hlsli) | A4–A8：Wrap、Dark Edge、Silver、Powder、曲率、Inner Glow、天气/距离响应与最终能量限制 |
| [ContinuousLUT.hlsli](Art/ContinuousLUT.hlsli) | 叠层二维 LUT 的像素中心坐标与连续切片插值 |
| [art_math.py](Art/art_math.py) | 部分艺术响应的 CPU 数学镜像及 LUT/能量检查 |

DA 是项目中的 `UTAToonCloudArtProfile`，继承 UE 的 `UDataAsset`。它提供共享外观参数；摘录把这些参数展开为 `TACloudArtParameters`。FeatureMask 的八位分别控制 Wrap、Dark Edge、Silver、Powder、曲率、Inner Glow、天气和距离响应。

详见[中文算法说明](ALGORITHMS_CN.md)、[源码函数映射](SOURCE_MAP.md)和[数学来源](ATTRIBUTION.md)。运行小规模检查：

```sh
python -B CoreAlgorithms/Tests/check_math.py
```

13 项 CPU 检查通过，覆盖上界、周期层级、均匀介质、步进预算、NaN、曲率互斥、LUT 边界和黑场能量。没有执行 HLSL 编译、UE 构建、视觉或 GPU 测试。

这些文件提供核心数学与明确的输入输出。接回引擎时，调用方需提供密度采样、射线区间、物理积分结果、重建特征和 LUT 采样；原插件的 RDG、材质、引擎私有接口与资产另行集成。未添加许可证授权。
