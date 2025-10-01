# MRS Rule-Providers Index

> 本文件自动生成。用于 mihomo 的 rule-providers（format: mrs）。

概览

- 仓库：rksk102/mihomo-mrs-rules
- 分支/标签：main
- 最近更新：2025-10-02 06:59:18 CST
- 文件总数：14（domain=12，ipcidr=2，classical=0）

快速引用模板

```yaml
rule-providers:
  Example-Domain:
    type: http
    behavior: domain          # 或 ipcidr / classical
    format: mrs
    url: https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/example/example.mrs
    interval: 86400
```

规则文件一览

| 名称 | 行为 | 策略 | 所属 | 相对路径 | jsDelivr | raw |
| --- | --- | --- | --- | --- | --- | --- |
| reject | domain | block | Loyalsoldier | block/domain/Loyalsoldier/reject.mrs | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/block/domain/Loyalsoldier/reject.mrs) | [raw](https://raw.githubusercontent.com/Loyalsoldier/mihomo-mrs-rules/main/mrs-rules/block/domain/Loyalsoldier/reject.mrs) |
| win-extra | domain | block | Loyalsoldier | block/domain/Loyalsoldier/win-extra.mrs | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/block/domain/Loyalsoldier/win-extra.mrs) | [raw](https://raw.githubusercontent.com/Loyalsoldier/mihomo-mrs-rules/main/mrs-rules/block/domain/Loyalsoldier/win-extra.mrs) |
| win-spy | domain | block | Loyalsoldier | block/domain/Loyalsoldier/win-spy.mrs | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/block/domain/Loyalsoldier/win-spy.mrs) | [raw](https://raw.githubusercontent.com/Loyalsoldier/mihomo-mrs-rules/main/mrs-rules/block/domain/Loyalsoldier/win-spy.mrs) |
| all-adblock | domain | block | rksk102 | block/domain/rksk102/all-adblock.mrs | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/block/domain/rksk102/all-adblock.mrs) | [raw](https://raw.githubusercontent.com/rksk102/mihomo-mrs-rules/main/mrs-rules/block/domain/rksk102/all-adblock.mrs) |
| apple-cn | domain | direct | Loyalsoldier | direct/domain/Loyalsoldier/apple-cn.mrs | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/direct/domain/Loyalsoldier/apple-cn.mrs) | [raw](https://raw.githubusercontent.com/Loyalsoldier/mihomo-mrs-rules/main/mrs-rules/direct/domain/Loyalsoldier/apple-cn.mrs) |
| direct-list | domain | direct | Loyalsoldier | direct/domain/Loyalsoldier/direct-list.mrs | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/direct/domain/Loyalsoldier/direct-list.mrs) | [raw](https://raw.githubusercontent.com/Loyalsoldier/mihomo-mrs-rules/main/mrs-rules/direct/domain/Loyalsoldier/direct-list.mrs) |
| private | domain | direct | Loyalsoldier | direct/domain/Loyalsoldier/private.mrs | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/direct/domain/Loyalsoldier/private.mrs) | [raw](https://raw.githubusercontent.com/Loyalsoldier/mihomo-mrs-rules/main/mrs-rules/direct/domain/Loyalsoldier/private.mrs) |
| geolocation-cn | domain | direct | MetaCubeX | direct/domain/MetaCubeX/geolocation-cn.mrs | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/direct/domain/MetaCubeX/geolocation-cn.mrs) | [raw](https://raw.githubusercontent.com/MetaCubeX/mihomo-mrs-rules/main/mrs-rules/direct/domain/MetaCubeX/geolocation-cn.mrs) |
| microsoft-cn | domain | direct | github.com | direct/domain/github.com/microsoft-cn.mrs | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/direct/domain/github.com/microsoft-cn.mrs) | [raw](https://raw.githubusercontent.com/github.com/mihomo-mrs-rules/main/mrs-rules/direct/domain/github.com/microsoft-cn.mrs) |
| lancidr | ipcidr | direct | Loyalsoldier | direct/ipcidr/Loyalsoldier/lancidr.mrs | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/direct/ipcidr/Loyalsoldier/lancidr.mrs) | [raw](https://raw.githubusercontent.com/Loyalsoldier/mihomo-mrs-rules/main/mrs-rules/direct/ipcidr/Loyalsoldier/lancidr.mrs) |
| all-cnip | ipcidr | direct | rksk102 | direct/ipcidr/rksk102/all-cnip.mrs | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/direct/ipcidr/rksk102/all-cnip.mrs) | [raw](https://raw.githubusercontent.com/rksk102/mihomo-mrs-rules/main/mrs-rules/direct/ipcidr/rksk102/all-cnip.mrs) |
| gfw | domain | proxy | Loyalsoldier | proxy/domain/Loyalsoldier/gfw.mrs | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/proxy/domain/Loyalsoldier/gfw.mrs) | [raw](https://raw.githubusercontent.com/Loyalsoldier/mihomo-mrs-rules/main/mrs-rules/proxy/domain/Loyalsoldier/gfw.mrs) |
| category-ai-!cn | domain | proxy | gh-proxy.com | proxy/domain/gh-proxy.com/category-ai-!cn.mrs | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/proxy/domain/gh-proxy.com/category-ai-!cn.mrs) | [raw](https://raw.githubusercontent.com/gh-proxy.com/mihomo-mrs-rules/main/mrs-rules/proxy/domain/gh-proxy.com/category-ai-!cn.mrs) |
| all-proxy | domain | proxy | rksk102 | proxy/domain/rksk102/all-proxy.mrs | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/proxy/domain/rksk102/all-proxy.mrs) | [raw](https://raw.githubusercontent.com/rksk102/mihomo-mrs-rules/main/mrs-rules/proxy/domain/rksk102/all-proxy.mrs) |

提示

- 请在客户端选择与文件相匹配的 behavior（domain/ipcidr/classical）。
- jsDelivr/raw 链接未在本流程中联机校验。如需检测，请运行手动的链接检查工作流。
