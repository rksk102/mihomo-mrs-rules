#!/usr/bin/env bash
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-}"
if [ -z "$REPO" ]; then
  REPO="$(git remote get-url origin 2>/dev/null | sed -n 's#.*github.com[:/]\([^/]\+/\([^/.]\+\)\)\(.git\)\{0,1\}$#\1#p')"
fi

REF="${INPUT_REF:-main}"
CDN="${INPUT_CDN:-jsdelivr}"

VALIDATE_MODE="${INPUT_VALIDATE:-both}"      # both/jsdelivr/raw/none
FAIL_ON_BROKEN="${INPUT_FAIL_ON_BROKEN:-false}"
CHECK_TIMEOUT="${INPUT_CHECK_TIMEOUT:-15}"
CHECK_RETRIES="${INPUT_CHECK_RETRIES:-2}"
PREFER_CDN="${INPUT_PREFER_CDN:-jsdelivr}"   # jsdelivr/raw

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

# 返回 ok 或 fail:HTTP_CODE
check_url() {
  local url="$1"
  local code
  code=$(curl -sS -o /dev/null -m "${CHECK_TIMEOUT}" --retry "${CHECK_RETRIES}" --retry-delay 2 -L -w '%{http_code}' "$url" || echo "000")
  if [ "$code" = "200" ]; then
    echo "ok"
  else
    echo "fail:${code}"
  fi
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
broken_count=0

mapfile -d '' files < <(find mrs-rules -type f -name '*.mrs' -print0 2>/dev/null || true)

{
  echo "# MRS Rule-Providers Index"
  echo
  echo "> 本文件自动生成（仓库B）。最近更新：${updated_at}"
  echo
  echo "本仓库提供将 rulesets 文本规则转换后的 MRS 规则集（mrs-rules/）。下表给出每个 .mrs 的直链，并标注 jsDelivr/raw 的可用性。"
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

  echo "| 相对路径 | 行为 behavior | 推荐链接 | jsDelivr | raw |"
  echo "| --- | --- | --- | --- | --- |"

  for f in "${files[@]}"; do
    rel="${f#mrs-rules/}"
    path="mrs-rules/${rel}"
    src_txt="rulesets/${rel%.mrs}.txt"
    beh="domain"
    [ -f "$src_txt" ] && beh="$(decide_behavior "$src_txt")"

    url_js="$(cdn_url "$path")"
    url_raw="$(raw_url "$path")"

    status_js="skip"
    status_raw="skip"

    case "$VALIDATE_MODE" in
      both)
        status_js="$(check_url "$url_js")"
        status_raw="$(check_url "$url_raw")"
        ;;
      jsdelivr)
        status_js="$(check_url "$url_js")"
        ;;
      raw)
        status_raw="$(check_url "$url_raw")"
        ;;
      none)
        ;;
    esac

    # 生成显示文本
    badge_js="(未检验)"; link_js="[jsDelivr](${url_js})"
    badge_raw="(未检验)"; link_raw="[raw](${url_raw})"

    if [ "$status_js" != "skip" ]; then
      if [ "$status_js" = "ok" ]; then
        badge_js="✅"
      else
        code="${status_js#fail:}"
        badge_js="❌(${code})"
        broken_count=$((broken_count+1))
      fi
    fi

    if [ "$status_raw" != "skip" ]; then
      if [ "$status_raw" = "ok" ]; then
        badge_raw="✅"
      else
        code="${status_raw#fail:}"
        badge_raw="❌(${code})"
        broken_count=$((broken_count+1))
      fi
    fi

    # 推荐链接：优先选择可用的；若均未检验则按偏好；若检验且都失败则给 raw
    recommended="$url_raw"
    if [ "$VALIDATE_MODE" = "none" ]; then
      recommended="$([ "$PREFER_CDN" = "jsdelivr" ] && echo "$url_js" || echo "$url_raw")"
    else
      if [ "$PREFER_CDN" = "jsdelivr" ]; then
        if [ "$status_js" = "ok" ]; then
          recommended="$url_js"
        elif [ "$status_raw" = "ok" ]; then
          recommended="$url_raw"
        else
          recommended="$url_raw"
        fi
      else
        if [ "$status_raw" = "ok" ]; then
          recommended="$url_raw"
        elif [ "$status_js" = "ok" ]; then
          recommended="$url_js"
        else
          recommended="$url_raw"
        fi
      fi
    fi

    safe_rel="$(echo "$rel" | sed 's/|/\\|/g')"
    echo "| ${safe_rel} | ${beh} | ${recommended} | ${badge_js} ${link_js} | ${badge_raw} ${link_raw} |"
  done

  echo
  echo "说明："
  echo "- ✅ 表示链接在生成时可访问；❌(状态码) 表示访问失败的 HTTP 状态码；(未检验) 表示本次未检测该链接。"
  echo "- 如果你更偏好使用 raw 链接，可在客户端替换为 raw；或将本脚本的 PREFER_CDN 设为 raw。"
} > README.md

if [ "$FAIL_ON_BROKEN" = "true" ] && [ "$broken_count" -gt 0 ]; then
  echo "::error::检测到 ${broken_count} 个不可用链接（根据 VALIDATE_MODE）。"
  exit 1
fi
