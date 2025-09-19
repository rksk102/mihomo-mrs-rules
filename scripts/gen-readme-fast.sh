#!/usr/bin/env bash
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-}"
if [ -z "$REPO" ]; then
  REPO="$(git remote get-url origin 2>/dev/null | sed -n 's#.*github.com[:/]\([^/]\+/\([^/.]\+\)\)\(.git\)\{0,1\}$#\1#p')"
fi

REF="${INPUT_REF:-main}"
CDN="${INPUT_CDN:-jsdelivr}"

owner="${REPO%/*}"
repo="${REPO#*/}"

cdn_url() {
  local path="$1"
  echo "https://cdn.jsdelivr.net/gh/${REPO}@${REF}/${path}"
}
raw_url() {
  local path="$1"
  echo "https://raw.githubusercontent.com/${owner}/${repo}/${REF}/${path}"
}

decide_behavior() {
  local f="$1"
  local n_total=0 n_domain=0 n_ip=0 n_classical=0 line
  while IFS= read -r line; do
    line="${line%%#*}"; line="${line%%!*}"
    line="$(echo "$line" | sed 's/^[[:space:]]\+//; s/[[:space:]]\+$//')"
    [ -z "$line" ] && continue
    n_total=$((n_total+1))
    if echo "$line" | grep -Eq '^[A-Z-]+,.*$'; then
      n_classical=$((n_classical+1)); continue
    fi
    if echo "$line" | grep -Eq '^([A-Za-z0-9*-]+\.)+[A-Za-z0-9-]+$|^\+\.[A-Za-z0-9.-]+$|^\*[A-Za-z0-9.-]+$'; then
      n_domain=$((n_domain+1)); continue
    fi
    if echo "$line" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?$|^[0-9A-Fa-f:]+(/[0-9]{1,3})?$'; then
      n_ip=$((n_ip+1)); continue
    fi
  done < "$f"

  if [ "$n_classical" -gt 0 ] && [ "$n_classical" -ge "$n_domain" ] && [ "$n_classical" -ge "$n_ip" ]; then
    echo classical; return
  fi
  if [ "$n_domain" -ge "$n_ip" ]; then
    echo domain; return
  else
    echo ipcidr; return
  fi
}

updated_at="$(date +'%Y-%m-%d %H:%M:%S %Z')"

mapfile -d '' files < <(find mrs-rules -type f -name '*.mrs' -print0 2>/dev/null || true)

{
  echo "# MRS Rule-Providers Index"
  echo
  echo "> 本文件自动生成（仓库B）。最近更新：${updated_at}"
  echo
  echo "本仓库提供将 rulesets 文本规则转换后的 MRS 规则集（mrs-rules/）。下表给出每个 .mrs 的直链。"
  echo
  echo "使用方式示例（behavior 与文件行为一致）："
  echo
  echo '```yaml'
  echo 'rule-providers:'
  echo '  Example-Domain:'
  echo '    type: http'
  echo '    behavior: domain          # 或 ipcidr / classical'
  echo '    format: mrs'
  echo "    url: https://cdn.jsdelivr.net/gh/${REPO}@${REF}/mrs-rules/example/example.mrs"
  echo '    interval: 86400'
  echo '```'
  echo

  if [ "${#files[@]}" -eq 0 ]; then
    echo "当前 mrs-rules/ 目录为空。请先运行构建流程生成 .mrs。"
    exit 0
  fi

  echo "| 相对路径 | 行为 behavior | jsDelivr | raw |"
  echo "| --- | --- | --- | --- |"

  for f in "${files[@]}"; do
    rel="${f#mrs-rules/}"
    path="mrs-rules/${rel}"
    src_txt="rulesets/${rel%.mrs}.txt"
    beh="domain"
    [ -f "$src_txt" ] && beh="$(decide_behavior "$src_txt")"

    link_js="$(cdn_url "$path")"
    link_raw="$(raw_url "$path")"
    safe_rel="$(echo "$rel" | sed 's/|/\\|/g')"
    echo "| ${safe_rel} | ${beh} | [jsDelivr](${link_js}) | [raw](${link_raw}) |"
  done

  echo
  echo "提示：请选择与你引用文件相匹配的 behavior（domain/ipcidr/classical）。"
} > README.md
