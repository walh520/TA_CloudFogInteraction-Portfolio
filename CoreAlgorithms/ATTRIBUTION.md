# 数学来源

NiTong 的 TA_ToonCloud 项目组织了烘焙形态语法、密度通道、采样上界和连续艺术响应。本目录按具体算法提取，并用显式输入和 CPU 数组/回调接口展示这些实现。

密度分层沿用项目的 Weather/Macro/Detail 思路，背景方法包括 Andrew Schneider 的 *The Real-Time Volumetric Cloudscapes of Horizon Zero Dawn*。本次未附带其纹理、课件或外部噪声实现。

连续体积插画的背景来自 Ebert 与 Rheingans 的 *Volume Illustration: Nonphotorealistic Rendering of Volume Models*（IEEE TVCG, 2000），暖冷色映射可参见 Gooch 等人的非真实感技术插画照明方法。A4–A8 的组合、特征契约和有界响应按项目具体实现提取；不把基础方法声明为项目首创。

透射与均匀介质讲解使用通用 Beer–Lambert 定律和常系数解析积分；周期单元面遍历、max 层级、smoothstep 与插值为标准数学/采样操作。`constant_segment` 是独立编写的数学讲解例子。

原项目的太阳光束研究还参考了 volumetric shadow-map / three-good-godrays 的空间组织思路。本目录包含项目完整路径数值求积与失败处理的函数适配；不包含外部实现、缓存纹理或其资源组织代码。

没有新增 LICENSE，也没有授予原引擎、第三方代码或资产的使用权。
