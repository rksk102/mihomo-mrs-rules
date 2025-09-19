#!/usr/bin/env bash
# 说明：在保留原有“逐行嗅探 TXT 判定 behavior”的基础上，增强进度日志与耗时统计。
# 可用环境变量：
#   PROGRESS_EVERY: 每处理多少个文件打印一次进度，默认 1
#   GROUP_LOG:      是否折叠分组日志（GitHub Actions ::group::），默认 true
#   SHOW_TIMING:    是否显示耗时，默认 true
#   DEBUG_XTRACE:   是否启用 bash -x 调试输出，默认 false
set -euo pipefail

PROGRESS_EVERY="${PROGRESS_EVERY:-1}"
GROUP_LOG="${GROUP_LOG:-true}"
SHOW_TIMING="${SHOW_TIMING:-true}"
DEBUG_XTRACE="${DEBUG_XTRACE:-false}"

if [ "$DEBUG_XTRACE" = "true" ]; then
  set -x
fi

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

# 打印带时间戳的日志
log() {
  printf '[%s] %s\n' "$(date +'%H:%M:%S')" "$*" >&2
}

# 毫秒时间，尽量兼容
now_ms() {
  if date +%s%3N >/dev/null 2>&1; then
    date +%s%3N
  else
    # 退化为秒*1000
    echo $(( $(date +%s) * 1000 ))
  fi
}

# 原有的逐行嗅探 TXT 判定（保持不变）
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
build_start_ms="$(now_ms)"

# 收集文件
mapfile -d '' files < <(find mrs-rules -type f -name '*.mrs' -print0 2>/dev/null || true)
total="${#files[@]}"

log "Start generating README for ${total} .mrs files (ref=${REF}, repo=${REPO})."

# 进度预览
if [ "$total" -gt 0 ]; then
  log "First few entries:"
  for f in "${files[@]:0:5}"; do
    log "  - ${f#mrs-rules/}"
  done
fi

# 构建 README
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

  if [ "$total" -eq 0 ]; then
    echo "当前 mrs-rules/ 目录为空。请先运行构建流程生成 .mrs。"
    # 同时日志提示
    log "No .mrs files found under mrs-rules/. Done."
    exit 0
  fi

  echo "| 相对路径 | 行为 behavior | jsDelivr | raw |"
  echo "| --- | --- | --- | --- |"

  idx=0
  for f in "${files[@]}"; do
    idx=$((idx+1))
    rel="${f#mrs-rules/}"
    path="mrs-rules/${rel}"
    src_txt="rulesets/${rel%.mrs}.txt"

    step_title="[$idx/$total] ${rel}"
    step_start_ms="$(now_ms)"

    # 分组折叠开始
    if [ "$GROUP_LOG" = "true" ]; then
      echo "::group::${step_title}"
    fi

    # 进度行（控制频率）
    if [ $((idx % PROGRESS_EVERY)) -eq 0 ] || [ "$idx" -eq 1 ]; then
      log "${step_title} - deciding behavior..."
    fi

    beh="domain"
    if [ -f "$src_txt" ]; then
      beh="$(decide_behavior "$src_txt")"
    else
      log "  └─ source TXT not found, fallback behavior=domain"
    fi

    if [ $((idx % PROGRESS_EVERY)) -eq 0 ] || [ "$idx" -eq 1 ]; then
      log "  ├─ behavior=${beh}"
    fi

    link_js="$(cdn_url "$path")"
    link_raw="$(raw_url "$path")"
    safe_rel="$(echo "$rel" | sed 's/|/\\|/g')"
    echo "| ${safe_rel} | ${beh} | [jsDelivr](${link_js}) | [raw](${link_raw}) |"

    # 分组折叠结束 + 耗时
    if [ "$SHOW_TIMING" = "true" ]; then
      dur_ms=$(( $(now_ms) - step_start_ms ))
      log "  └─ done in ${dur_ms} ms"
    fi
    if [ "$GROUP_LOG" = "true" ]; then
      echo "::endgroup::"
    fi
  done

  echo
  echo "提示：请选择与你引用文件相匹配的 behavior（domain/ipcidr/classical）。"
} > README.md

total_dur_ms=$(( $(now_ms) - build_start_ms ))
log "All done. Generated README for ${total} files in ${total_dur_ms} ms."

# 将简要统计写入 Job Summary（Actions 运行页面 Summary 选项卡）
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "### README 生成摘要"
    echo
    echo "- 仓库：${REPO}"
    echo "- 分支/标签：${REF}"
    echo "- 文件总数：${total}"
    echo "- 生成耗时：$((total_dur_ms/1000)).$((total_dur_ms%1000)) s"
  } >> "$GITHUB_STEP_SUMMARY"
fi
