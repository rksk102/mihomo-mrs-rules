#!/usr/bin/env bash
# 逐行判定行为（不减功能），用单次 AWK 扫描提速；可并行；可打印计数；可开启旧法对照校验
set -euo pipefail

# 可调参数
MRS_JOBS="${MRS_JOBS:-2}"                      # 并发文件数
SNIFF_MAX="${SNIFF_MAX:-0}"                    # 0=读完整个 TXT；>0=仅读前 N 行
SHORTCIRCUIT_BY_PATH="${SHORTCIRCUIT_BY_PATH:-false}"  # true 时路径段包含 type 则直接信任
PROGRESS_EVERY="${PROGRESS_EVERY:-5}"          # 总体进度打印频率
VERBOSE_PROGRESS="${VERBOSE_PROGRESS:-true}"   # 每个文件一行 DONE 日志
DEBUG_BEHAVIOR_COUNTS="${DEBUG_BEHAVIOR_COUNTS:-true}" # 打印每文件计数和扫描模式
VALIDATE_WITH_SLOW="${VALIDATE_WITH_SLOW:-false}"       # 用旧慢方法对照校验
VALIDATE_FAIL_ON_MISMATCH="${VALIDATE_FAIL_ON_MISMATCH:-false}"

# 基本信息
REPO="${GITHUB_REPOSITORY:-}"
if [ -z "$REPO" ]; then
  REPO="$(git remote get-url origin 2>/dev/null | sed -n 's#.*github.com[:/]\([^/]\+/\([^/.]\+\)\)\(.git\)\{0,1\}$#\1#p')"
fi

REF="${INPUT_REF:-main}"
CDN="${INPUT_CDN:-jsdelivr}"

owner="${REPO%/*}"
repo="${REPO#*/}"

# 链接生成
cdn_url() { echo "https://cdn.jsdelivr.net/gh/${REPO}@${REF}/${1}"; }
raw_url() { echo "https://raw.githubusercontent.com/${owner}/${repo}/${REF}/${1}"; }

# 日志
ts() { date +'%H:%M:%S'; }
log() { printf '[%s] %s\n' "$(ts)" "$*" >&2; }

updated_at="$(date +'%Y-%m-%d %H:%M:%S %Z')"

# 1) 路径推断：mrs-rules/<policy>/<type>/...
behavior_from_path() {
  local rel="$1"
  IFS='/' read -r seg1 seg2 _ <<< "$rel" || true
  case "$seg2" in
    domain|ipcidr|classical) echo "$seg2"; return 0 ;;
  esac
  echo ""
}

# 2) 新法：AWK 单次扫描逐行判定（仍逐行），可限行数；可打印统计到 stderr
decide_behavior_awk() {
  local txt="$1"
  local max="${2:-0}"  # 0=全文件；>0=最多读前 max 行
  local debug="${3:-false}"  # 打印计数
  [ -f "$txt" ] || {
    # 找不到源 TXT：回落 domain（与早先逻辑一致）
    if [ "$debug" = "true" ]; then
      echo "[AWK] source missing -> behavior=domain (scan=none)" >&2
    fi
    echo "domain"
    return 0
  }

  awk -v MAX="$max" -v DEBUG="$debug" '
    function trim(s){ sub(/^[[:space:]]+/,"",s); sub(/[[:space:]]+$/,"",s); return s }
    BEGIN{ n_domain=0; n_ip=0; n_classic=0; n=0 }
    {
      line=$0
      sub(/#.*/,"",line)         # 去 # 注释
      sub(/!.*/, "", line)       # 去 ! 注释
      line=trim(line)
      if (line=="") next
      n++
      if (line ~ /^[A-Z-]+,.+$/)                    { n_classic++; next }
      if (line ~ /^([A-Za-z0-9*-]+\.)+[A-Za-z0-9-]+$/ || line ~ /^\+\.[A-Za-z0-9.-]+$/ || line ~ /^\*[A-Za-z0-9.-]+$/) { n_domain++;  next }
      if (line ~ /^([0-9]{1,3}\.){3}[0-9]{1,3}(\/[0-9]{1,2})?$/ || line ~ /^[0-9A-Fa-f:]+(\/[0-9]{1,3})?$/)            { n_ip++;      next }
      if (MAX>0 && n>=MAX) exit
    }
    END{
      beh="domain"
      if (n_classic>0 && n_classic>=n_domain && n_classic>=n_ip)      beh="classical"
      else if (n_domain>=n_ip)                                         beh="domain"
      else                                                             beh="ipcidr"
      if (DEBUG=="true") {
        scan = (MAX>0 ? sprintf("head:%d", MAX) : "full")
        # 打印到 stderr，便于你在日志看到计数
        printf("[AWK] scan=%s counts: classical=%d, domain=%d, ip=%d -> behavior=%s\n", scan, n_classic, n_domain, n_ip, beh) > "/dev/stderr"
      }
      print beh
    }
  ' "$txt"
}

# 3) 旧法：慢速逐行 + 多次 grep 的对照校验（可选）
decide_behavior_slow() {
  local f="$1"
  local n_total=0 n_domain=0 n_ip=0 n_classical=0 line
  [ -f "$f" ] || { echo "domain"; return 0; }
  # 逐行处理，和你之前的慢逻辑一致
  while IFS= read -r line; do
    line="${line%%#*}"; line="${line%%!*}"
    # 去掉首尾空白
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

# 收集 .mrs 文件
mapfile -d '' files < <(find mrs-rules -type f -name '*.mrs' -print0 2>/dev/null || true)
total="${#files[@]}"

log "Start generating README for ${total} .mrs files (ref=${REF}, repo=${REPO})."
if [ "$total" -gt 0 ]; then
  log "First entries preview:"
  for f in "${files[@]:0:5}"; do
    echo "  - ${f#mrs-rules/}" >&2
  done
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
rows="${tmpdir}/rows.tsv"
: > "$rows"

# 单文件工作（输出一行 TSV：rel<TAB>behavior）
work_one() {
  local f="$1"
  local rel="${f#mrs-rules/}"
  local beh=""
  local src="rulesets/${rel%.mrs}.txt"
  local from="txt"

  if [ "$SHORTCIRCUIT_BY_PATH" = "true" ]; then
    beh="$(behavior_from_path "$rel")"
    if [ -n "$beh" ]; then
      from="path"
    fi
  fi

  if [ -z "$beh" ]; then
    beh="$(decide_behavior_awk "$src" "$SNIFF_MAX" "$DEBUG_BEHAVIOR_COUNTS")"
    from="txt"
    # 可选：旧法对照校验
    if [ "$VALIDATE_WITH_SLOW" = "true" ] && [ -f "$src" ]; then
      slow="$(decide_behavior_slow "$src")"
      if [ "$slow" != "$beh" ]; then
        echo "[VALIDATE] MISMATCH ${rel}: awk=${beh}, slow=${slow}" >&2
        if [ "$VALIDATE_FAIL_ON_MISMATCH" = "true" ]; then
          exit 99
        fi
      else
        echo "[VALIDATE] OK ${rel}: ${beh}" >&2
      fi
    fi
  fi

  printf "%s\t%s\n" "$rel" "$beh"

  if [ "$VERBOSE_PROGRESS" = "true" ]; then
    local mode="full"
    if [ "$SNIFF_MAX" != "0" ]; then mode="head:${SNIFF_MAX}"; fi
    echo "[DONE] ${rel} -> behavior=${beh} (by ${from}, scan=${mode})" >&2
  fi
}

export -f behavior_from_path decide_behavior_awk decide_behavior_slow work_one
export SHORTCIRCUIT_BY_PATH SNIFF_MAX VERBOSE_PROGRESS DEBUG_BEHAVIOR_COUNTS VALIDATE_WITH_SLOW VALIDATE_FAIL_ON_MISMATCH

# 并行执行，并后台记录进度
if [ "$total" -gt 0 ]; then
  printf "%s\0" "${files[@]}" | xargs -0 -n1 -P "${MRS_JOBS}" -I{} bash -c '
    work_one "$1"
  ' _ {} > "$rows" 2> "${tmpdir}/workers.log" &

  worker_pid=$!

  # 轮询总体进度
  while kill -0 "$worker_pid" 2>/dev/null; do
    done_count="$( { wc -l <"$rows" 2>/dev/null; } || echo 0 )"
    if [ $((done_count % PROGRESS_EVERY)) -eq 0 ] && [ "$done_count" -gt 0 ]; then
      log "Progress: ${done_count}/${total} files classified..."
    fi
    sleep 1
  done

  wait "$worker_pid" || true
fi

# 生成 README.md（保持原格式与输出）
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
  else
    echo "| 相对路径 | 行为 behavior | jsDelivr | raw |"
    echo "| --- | --- | --- | --- |"

    # 稳定输出顺序
    sort -t$'\t' -k1,1 "$rows" | while IFS=$'\t' read -r rel beh; do
      path="mrs-rules/${rel}"
      link_js="$(cdn_url "$path")"
      link_raw="$(raw_url "$path")"
      safe_rel="$(echo "$rel" | sed 's/|/\\|/g')"
      echo "| ${safe_rel} | ${beh} | [jsDelivr](${link_js}) | [raw](${link_raw}) |"
    done
  fi

  echo
  echo "提示：请选择与你引用文件相匹配的 behavior（domain/ipcidr/classical）。"
} > README.md

log "All done. Generated README for ${total} files."
if [ -s "${tmpdir}/workers.log" ]; then
  log "Worker notes (stderr from workers) are available above."
fi

# 可选：写入 GitHub Actions Summary（存在才写）
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "### README 生成摘要"
    echo
    echo "- 仓库：${REPO}"
    echo "- 分支/标签：${REF}"
    echo "- 文件总数：${total}"
    echo "- 并发：${MRS_JOBS}"
    echo "- 判定模式：逐行 AWK（SNIFF_MAX=${SNIFF_MAX}；路径短路=${SHORTCIRCUIT_BY_PATH})"
    echo "- 调试：DEBUG_BEHAVIOR_COUNTS=${DEBUG_BEHAVIOR_COUNTS}；VALIDATE_WITH_SLOW=${VALIDATE_WITH_SLOW}"
  } >> "$GITHUB_STEP_SUMMARY"
fi
