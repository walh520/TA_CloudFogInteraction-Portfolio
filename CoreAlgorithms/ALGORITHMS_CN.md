# 烘焙、步进与艺术外观的算法连接

## 1. 从可解析频率到保守密度场

`safe_octaves` 用分辨率约束最高频率：第 k 层的特征数为 `BaseCells × Lacunarity^k`，乘最少体素数后不能超过烘焙分辨率。达到限制就停止，而不是把所有请求层数写进低分辨率纹理。例如 BaseCells=8、每特征 4 体素时，32 分辨率只支持一层；256 分辨率支持四层。

`TACloudBuildProfile` 输出 RGBA 形态语法：R 是高度密度曲线，G 是 billow 膨胀权重，B 是侵蚀权重，A 是风暴上部特殊区域。Type 从 0 到 1 连续经过 stratus、cumulus、storm，避免切换云类别时出现硬跳。输入 Height 和 Type 使用 [0,1]。

`TACloudDensityBaseFromFields` 把 Macro.R 的连通骨架与 Macro.G 的正膨胀分开，G 受 Profile.G 限制。Coverage 移动 Macro 等值面，再乘高度曲线。Coverage 为零时，等值面的下边界为 1，饱和 Macro 也不会凭空产生云。

烘焙上界先做 `min(255, Skeleton + Billow)`，因为 Profile.G 不超过 1；高度 Profile.R 不超过 1，后续细节侵蚀只移除密度。`scalar_mips` 用周期半径一 halo 覆盖邻近插值 donor，然后构建 max mip。普通外观过滤使用 mean mip，调用时需设置 `scalar_mips(values, shape, maximum=False, dilate=False)`，避免把占据上界用的 halo 膨胀带入外观平均值。这是单调密度组合下的上界，不能拿平均 mip 当作空区证明。

Python 数组适配要求每轴为二次幂，以保持一致的父子与周期单元对应。原项目还处理资源维度与 mip 选择；这里没有加入未验证的任意尺寸保守遍历。

天气语义函数接收 Coverage、[-1,1] 的 TypeNoise/StormPotential、[0,1] 的 Lifecycle。CloudType 同时受覆盖相关性和低频类型场影响；Storm 经覆盖门限与低频强度调制。噪声生成器作为外部输入，便于单独查看这些通道如何连接。

## 2. 光线步进如何使用烘焙结果

`TACloudDensityFootprintLod` 按步长与最小体素尺寸的比值求 log2。`TACloudDistanceToPeriodicCellBoundary` 把位置映射到周期单元，用方向符号选择下一个单元面，对有效轴取最短正距离。平行轴不限制步长；处于负方向边界时保留极小正距离，避免原地重复采样。

`trace_transmittance` 是项目 `ShaftTraceSun` 实时分支的 CPU 适配：整个已知射线区间按固定数量切段，在中点采样 RGB 消光，逐段乘 `exp(-sigma × ds)`。米与每米消光配对，结果为 RGB 透射率。固定预算覆盖全路径，仍可能漏掉高频薄层，不能据此声称保守精度。

`trace_reference` 保留参考分支的有限步数和失败语义：只有调用方给出保守零密度区间时才跳过；其余区间按细步长采样。预算耗尽、采样密度/空区步长为非有限值，或无法前进时返回黑色透射与 `complete=False`，避免把未完成路径当作全可见。无效的路径长度、细步长或预算参数会抛出 `ValueError`。实际接入时，空区回调必须保证步长不超出其 halo/上界证明覆盖的范围。

`constant_segment` 是为讲解独立写出的均匀介质 Beer–Lambert 小例子：先算段不透明度，再累积 `T_before × albedo × incident × opacity`，随后更新透射。它展示段细分一致性，不是 UE 物理云、多次散射或大气积分器的代码摘录。

## 3. DA 驱动的艺术渲染

原项目由 sky/local 组件共享 `UTAToonCloudArtProfile.Settings`，解析实例乘数和 FeatureMask 后进入同一艺术层。摘录从艺术响应段落开始；物理积分与 ABI 重建由调用方提供。

`TACloudArtInputs` 的 RGB 为线性空间，`PhysicalPremultiplied` 和 `DirectPremultiplied` 已乘覆盖率；`Coverage` 为 [0,1]。调用方应保持 `PhysicalColor = PhysicalPremultiplied / max(Coverage,1e-4)`，`PhysicalLuminance` 为该非预乘颜色的亮度。梯度、天气和 cavity 是 [0,1]，曲率是 [-1,1]，Tau 为非负无量纲光学厚度，DepthKm 为公里。NDotL、MuForward 来自已重建法线及视线/光照方向的点积。

A4 用连续 Wrap 作为调色板坐标，Dark Edge 用背光、边界梯度与厚度响应相乘，衰减平滑限制在 0.85 以内。A5 的 Silver 使用边缘厚度，Powder 使用局部厚度，二者都消耗已有直射光预算。没有有效主光时，这些定向项关闭。

A6 对正负曲率分别求 smoothstep，形成互斥凸/凹掩码；凸面获得小幅亮度/饱和度提升，凹槽获得同亮度冷色与有界衰减。A7 使用 `Pcavity × exp(-kL × TauLight) × (1-exp(-kV × TauView))` 的连续结构响应，颜色仍来自已有直射光预算。

A8 用 Storm 连续放大结构响应，用代表深度平滑降低远处艺术强度，最后把艺术亮度压到 `物理预乘亮度 × max(EnergyLimit,1)`，再与物理颜色混合。因此物理黑场不会变成艺术自发光。Lifecycle 已经参与密度，不再次乘进亮度。

LUT 输入坐标为亮度响应、光学深度响应或归一化高度、CloudType 或 Storm。`TACloudContinuousBaseColorLUTCoordinates` 返回两个切片的 UV 与插值权重；调用方以线性过滤、LOD0 读取两个切片，再传入 `SampledLUTBaseColor`。它保留 texel-centre 边界，避免切片间串色。默认 PreservePhysicalLuminance 模式是 `ColorLUTColorMode=1`；黑色调色板没有可归一化色度时保留物理基线。

这些函数按项目算法整理，显式结构和回调是本次提取的适配接口。完整 UE 材质桥、重建、调度与大气合成不在本目录。
