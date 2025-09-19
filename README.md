# MRS Rule-Providers Index

> 本文件自动生成（仓库B）。最近更新：2025-09-19 12:24:47 CST

本仓库提供将 rulesets 文本规则转换后的 MRS 规则集（mrs-rules/）。下表给出每个 .mrs 的直链。

使用方式示例（behavior 与文件行为一致）：

```yaml
rule-providers:
  Example-Domain:
    type: http
    behavior: domain          # 或 ipcidr / classical
    format: mrs
    url: https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/example/example.mrs
    interval: 86400
```

| 相对路径 | 行为 behavior | jsDelivr | raw |
| --- | --- | --- | --- |
| all-adblock.mrs | domain | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/all-adblock.mrs) | [raw](https://raw.githubusercontent.com/rksk102/mihomo-mrs-rules/main/mrs-rules/all-adblock.mrs) |
| all-proxy.mrs | domain | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/all-proxy.mrs) | [raw](https://raw.githubusercontent.com/rksk102/mihomo-mrs-rules/main/mrs-rules/all-proxy.mrs) |
| block/domain/Loyalsoldier/reject.mrs | domain | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/block/domain/Loyalsoldier/reject.mrs) | [raw](https://raw.githubusercontent.com/rksk102/mihomo-mrs-rules/main/mrs-rules/block/domain/Loyalsoldier/reject.mrs) |
| block/domain/Loyalsoldier/win-extra.mrs | domain | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/block/domain/Loyalsoldier/win-extra.mrs) | [raw](https://raw.githubusercontent.com/rksk102/mihomo-mrs-rules/main/mrs-rules/block/domain/Loyalsoldier/win-extra.mrs) |
| block/domain/Loyalsoldier/win-spy.mrs | domain | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/block/domain/Loyalsoldier/win-spy.mrs) | [raw](https://raw.githubusercontent.com/rksk102/mihomo-mrs-rules/main/mrs-rules/block/domain/Loyalsoldier/win-spy.mrs) |
| cnip.mrs | ipcidr | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/cnip.mrs) | [raw](https://raw.githubusercontent.com/rksk102/mihomo-mrs-rules/main/mrs-rules/cnip.mrs) |
| direct/domain/Loyalsoldier/apple-cn.mrs | domain | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/direct/domain/Loyalsoldier/apple-cn.mrs) | [raw](https://raw.githubusercontent.com/rksk102/mihomo-mrs-rules/main/mrs-rules/direct/domain/Loyalsoldier/apple-cn.mrs) |
| direct/domain/Loyalsoldier/china-list.mrs | domain | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/direct/domain/Loyalsoldier/china-list.mrs) | [raw](https://raw.githubusercontent.com/rksk102/mihomo-mrs-rules/main/mrs-rules/direct/domain/Loyalsoldier/china-list.mrs) |
| direct/domain/Loyalsoldier/direct-list.mrs | domain | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/direct/domain/Loyalsoldier/direct-list.mrs) | [raw](https://raw.githubusercontent.com/rksk102/mihomo-mrs-rules/main/mrs-rules/direct/domain/Loyalsoldier/direct-list.mrs) |
| direct/domain/Loyalsoldier/private.mrs | domain | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/direct/domain/Loyalsoldier/private.mrs) | [raw](https://raw.githubusercontent.com/rksk102/mihomo-mrs-rules/main/mrs-rules/direct/domain/Loyalsoldier/private.mrs) |
| direct/domain/MetaCubeX/geolocation-cn.mrs | domain | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/direct/domain/MetaCubeX/geolocation-cn.mrs) | [raw](https://raw.githubusercontent.com/rksk102/mihomo-mrs-rules/main/mrs-rules/direct/domain/MetaCubeX/geolocation-cn.mrs) |
| direct/domain/github.com/microsoft-cn.mrs | domain | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/direct/domain/github.com/microsoft-cn.mrs) | [raw](https://raw.githubusercontent.com/rksk102/mihomo-mrs-rules/main/mrs-rules/direct/domain/github.com/microsoft-cn.mrs) |
| direct/ipcidr/Loyalsoldier/lancidr.mrs | ipcidr | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/direct/ipcidr/Loyalsoldier/lancidr.mrs) | [raw](https://raw.githubusercontent.com/rksk102/mihomo-mrs-rules/main/mrs-rules/direct/ipcidr/Loyalsoldier/lancidr.mrs) |
| proxy/domain/Loyalsoldier/gfw.mrs | domain | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/proxy/domain/Loyalsoldier/gfw.mrs) | [raw](https://raw.githubusercontent.com/rksk102/mihomo-mrs-rules/main/mrs-rules/proxy/domain/Loyalsoldier/gfw.mrs) |
| proxy/domain/Loyalsoldier/telegramcidr.mrs | ipcidr | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/proxy/domain/Loyalsoldier/telegramcidr.mrs) | [raw](https://raw.githubusercontent.com/rksk102/mihomo-mrs-rules/main/mrs-rules/proxy/domain/Loyalsoldier/telegramcidr.mrs) |
| proxy/domain/Loyalsoldier/tld-not-cn.mrs | domain | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/proxy/domain/Loyalsoldier/tld-not-cn.mrs) | [raw](https://raw.githubusercontent.com/rksk102/mihomo-mrs-rules/main/mrs-rules/proxy/domain/Loyalsoldier/tld-not-cn.mrs) |
| proxy/domain/gh-proxy.com/category-ai-!cn.mrs | domain | [jsDelivr](https://cdn.jsdelivr.net/gh/rksk102/mihomo-mrs-rules@main/mrs-rules/proxy/domain/gh-proxy.com/category-ai-!cn.mrs) | [raw](https://raw.githubusercontent.com/rksk102/mihomo-mrs-rules/main/mrs-rules/proxy/domain/gh-proxy.com/category-ai-!cn.mrs) |

提示：请选择与你引用文件相匹配的 behavior（domain/ipcidr/classical）。
