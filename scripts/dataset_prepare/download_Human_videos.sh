#!/bin/zsh

DATASET_DIR="${1:-/media/lenovo/disk/Dataset}"
DATASET_PATH="${DATASET_DIR}/NaVILA-Dataset/Human"

VIDEO_ID_FILE="${DATASET_PATH}/video_ids_small.txt"
OUTPUT_DIR="${DATASET_PATH}/videos"
LOG_FILE="${DATASET_PATH}/download.log"
FAILED_FILE="${DATASET_PATH}/failed_ids.txt"
ARCHIVE_FILE="${DATASET_PATH}/downloaded.txt"

# ------------------ 环境检查 ------------------
command -v yt-dlp >/dev/null 2>&1 || {
    echo "❌ 请先安装 yt-dlp 工具（例如 pip install -U yt-dlp）"
    exit 1
}

mkdir -p "$OUTPUT_DIR"

# 清空日志文件
:> "${LOG_FILE}"
:> "${FAILED_FILE}"

# 设置下载参数
YTDLP_OPTS=(
  -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"  # 最佳MP4格式
  --no-overwrites                # 跳过已下载文件
  --download-archive "$ARCHIVE_FILE"  # 记录已下载视频
  --concurrent-fragments 5       # 加速下载
  --retries 10                   # 失败重试次数
  --fragment-retries 10          # 分片重试次数
  --console-title                # 显示进度标题
  --progress                     # 显示进度条
  --no-simulate                  # 实际执行下载
  --merge-output-format mp4
)

TOTAL_IDS=$(grep -vcE '^\s*($|#)' "$VIDEO_ID_FILE")

echo "开始批量下载视频 (共 ${TOTAL_IDS} 个))"
echo "日志文件: ${LOG_FILE}"
echo "======================================"

i=0
while IFS= read -r VIDEO_ID || [[ -n "$VIDEO_ID" ]]; do
# 跳过空行和注释行
  if [[ -z "${VIDEO_ID}" ]] || [[ "${VIDEO_ID}" =~ ^# ]]; then
    continue
  fi

  i=$((i+1))
  echo "\n[$(date +'%Y-%m-%d %H:%M:%S')] [$i/$TOTAL_IDS] Downloading ${VIDEO_ID}" | tee -a "${LOG_FILE}"

  if yt-dlp "${YTDLP_OPTS[@]}" \
    -o "${OUTPUT_DIR}/%(id)s.%(ext)s" \
    "https://www.youtube.com/watch?v=${VIDEO_ID}" >> "${LOG_FILE}" 2>&1
  then
    echo "✅ 下载成功: ${VIDEO_ID}" | tee -a "${LOG_FILE}"
  else
    echo "❌ 下载失败: ${VIDEO_ID}" | tee -a "${LOG_FILE}"
    echo "${VIDEO_ID}" >> "${FAILED_FILE}"
  fi
  yt-dlp -f mp4 -o "${OUTPUT_DIR}/${VIDEO_ID}.mp4" "https://www.youtube.com/watch?v=${VIDEO_ID}"

done < "${VIDEO_ID_FILE}"

# 生成摘要报告
SUCCESS_COUNT=$(wc -l < "$ARCHIVE_FILE" 2>/dev/null || echo 0)
FAILED_COUNT=$(wc -l < "$FAILED_FILE" 2>/dev/null || echo 0)

echo "\n======================================"
echo "下载完成!"
echo "成功: ${SUCCESS_COUNT} 个视频"
echo "失败: ${FAILED_COUNT} 个视频 (查看 ${FAILED_FILE})"
echo "日志: ${LOG_FILE}"
echo "视频保存至: ${OUTPUT_DIR}"