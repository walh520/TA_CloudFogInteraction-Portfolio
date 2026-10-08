# Cloud series architecture / Cloud 系列架构

The Cloud series organizes sky shells, local cloud volumes, fog volumes/layers and landscape fog around Actor/Component configuration, density resources, rendering passes and art controls.

## Data flow

1. Actor/Component configuration describes spatial bounds, density resources, art settings and quality controls
2. Editor density-field workflows create data for cloud and fog volumes
3. Scene registration exposes those resources and parameters to the renderer
4. RDG scheduling organizes light caches, volume tracing, temporal reconstruction, shafts and final shading
5. History and diagnostics support iteration on quality and stability

Density/material authoring and final illustration controls are distinct parts of this design. World interaction and wind provide related scene data, while RealtimeFog maintains a separate simulated concentration/velocity field.

## Public scope

This page is an architecture overview. [CoreAlgorithms](../CoreAlgorithms/README.md) provides selected baking morphology, ray-stepping, transmission and continuous art-response functions with explicit adapters. The complete TA_ToonCloud runtime/editor, material/RDG integration, texture resources and rendering pipeline are separate. The public collection also retains selected fog math, interaction/environment data contracts and terrain sampling; see the [repository overview](../README.md).

当前已公开部分 Cloud 核心数学函数，完整引擎集成与渲染管线尚未随附。本文说明模块职责与数据流，不表示当前仓库能运行完整 Cloud，也不代表已完成构建或效果验证。
