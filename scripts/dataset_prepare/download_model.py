import os
import argparse
# need: pip install modelscope
from modelscope import snapshot_download

# Hugging Face 和 ModelScope 的环境变量设置
os.environ["HF_ENDPOINT"] = "https://hf-mirror.com"
os.environ["HF_HUB_ENABLE_HF_TRANSFER"] = "0"


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="微调和评估视觉语言模型。")
    parser.add_argument('--dataset_dir', type=str, default="/media/lenovo/disk/Dataset", help='data folder')
    parser.add_argument('--model_id', type=str, default="google/siglip-so400m-patch14-384", help='Hugging Face 或 ModelScope 上的基础模型ID。')  # SmolVLM2-500M-Video-Instruct

    args = parser.parse_args()

    model_name = args.model_id.split("/")[-1]
    args.local_model_path = os.path.join(args.dataset_dir, "models", model_name)

    # 下载预训练模型
    if not os.path.exists(args.local_model_path):
        print(f"本地模型不存在，从 ModelScope 下载 {args.model_id} 到 {args.local_model_path}...")
        snapshot_download(args.model_id, local_dir=args.local_model_path)  # 下载所有文件
    else:
        print(f"模型已存在于 {args.local_model_path}，跳过下载")