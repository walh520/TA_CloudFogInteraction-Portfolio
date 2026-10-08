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

This page is an architecture overview. The TA_ToonCloud runtime/editor implementation, shader transport and density authoring code are not included in this repository version. The public source files cover selected fog math, interaction/environment data contracts and terrain sampling; see the [repository overview](../README.md).

Cloud 集成与渲染核心尚未纳入本次公开源码。本文说明模块职责与数据流，不表示当前仓库能运行 Cloud，也不代表已完成构建或效果验证。
