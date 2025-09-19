#!/usr/bin/env bash
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-}"
if [ -z "$REPO" ]; then
  REPO="$(git remote get-url origin 2>/dev/null | sed -n 's#.*github.com[:/]\([^/]\+/\([^/.]\+\)\)\(.git\)\{0,1\}$#\1#p')"
fi

REF="${INPUT_REF:-main}"
VALIDATE_MODE="${INPUT_VALIDATE:-both}"    # both/jsdelivr/raw
CHECK_TIMEOUT="${INPUT_CHECK_TIMEOUT:-6}"
CHECK_RETRIES="${INPUT_CHECK_RETRIES:-0}"
PARALLEL="${INPUT_PARALLEL:-8}"
OUTPUT_FILE="${INPUT_OUTPUT_FILE:-LINKS_CHECK.md}"

owner="${REPO%/*}"
repo="${REPO#*/}"

cdn_url() { echo "https://cdn.jsdelivr.net/gh/${REPO}@${REF}/${1}"; }
raw_url() { echo "https://raw.githubusercontent.com/${owner}/${repo}/${REF}/${1}"; }

check_url() {
  local url="$1"
  local code
  code=$(curl -sS -I -o /dev/null --max-time "${CHECK_TIMEOUT}" --retry "${CHECK_RETRIES}" --retry-delay 1 -L -w '%{http_code}' "$url" || echo "000")
  case "$code" in
    2*|3*) echo "ok" ;;
    *)     echo "fail:${code}" ;;
  esac
}

updated_at="$(date +'%Y-%m-%d %H:%M:%S %Z')"

mapfile -d '' files < <(find mrs-rules -type f -name '*.mrs' -print0 2>/dev/null || true)

# 并行检查每个文件
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

one_file() {
  local f="$1"
  local rel="${f#mrs-rules/}"
  local path="mrs-rules/${rel}"
  local js="$(cdn_url "$path")"
  local rw="$(raw_url "$path")"
  local sj="skip" sr="skip"

  case "$VALIDATE_MODE" in
    both)
      sj="$(check_url "$js")"
      sr="$(check_url "$rw")"
      ;;
    jsdelivr)
      sj="$(check_url "$js")"
      ;;
    raw)
      sr="$(check_url "$rw")"
      ;;
  esac

  printf "%s\t%s\t%s\t%s\t%s\n" "$rel" "$js" "$rw" "$sj" "$sr"
}

export -f check_url cdn_url raw_url one_file
export REPO REF CHECK_TIMEOUT CHECK_RETRIES VALIDATE_MODE

if [ "${#files[@]}" -eq 0 ]; then
  echo "# Links Check Report" > "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  echo "> 生成时间：${updated_at}" >> "$OUTPUT_FILE"
  echo "" >> "$OUTPUT_FILE"
  echo "mrs-rules/ 目录为空，未进行检查。" >> "$OUTPUT_FILE"
  exit 0
fi

# 并行
printf "%s\0" "${files[@]}" | xargs -0 -n1 -P "${PARALLEL}" -I{} bash -c 'one_file "$@"' _ {} > "${tmpdir}/rows.tsv"

# 生成报告
{
  echo "# Links Check Report"
  echo
  echo "> 生成时间：${updated_at}"
  echo
  echo "- 分支/标签：${REF}"
  echo "- 检查模式：${VALIDATE_MODE}"
  echo "- 超时/重试：${CHECK_TIMEOUT}s / ${CHECK_RETRIES}"
  echo "- 并行度：${PARALLEL}"
  echo
  echo "| 相对路径 | jsDelivr 状态 | raw 状态 | jsDelivr 链接 | raw 链接 |"
  echo "| --- | --- | --- | --- | --- |"
  while IFS=$'\t' read -r rel js rw sj sr; do
    bj="(未检验)"; br="(未检验)"
    [ "$sj" != "skip" ] && bj=$([ "$sj" = "ok" ] && echo "✅" || echo "❌(${sj#fail:})")
    [ "$sr" != "skip" ] && br=$([ "$sr" = "ok" ] && echo "✅" || echo "❌(${sr#fail:})")
    safe_rel="$(echo "$rel" | sed 's/|/\\|/g')"
    echo "| ${safe_rel} | ${bj} | ${br} | ${js} | ${rw} |"
  done < "${tmpdir}/rows.tsv"
} > "$OUTPUT_FILE"

echo "Report written to ${OUTPUT_FILE}"
