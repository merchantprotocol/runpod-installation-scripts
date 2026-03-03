#!/bin/bash
set -e

echo "=== Starting full setup for Qwen2.5-72B-Instruct-Q4_K_M.gguf ==="

# 1. Install dependencies
apt-get update -qq
apt-get install -y git cmake build-essential python3 python3-pip curl

# 2. Clone llama.cpp (if not already there)
if [ ! -d "/workspace/llama.cpp" ]; then
  echo "Cloning llama.cpp..."
  git clone https://github.com/ggerganov/llama.cpp /workspace/llama.cpp
fi

cd /workspace/llama.cpp

# 3. Build llama.cpp with CUDA
echo "Building llama.cpp with CUDA..."
rm -rf build
cmake -B build -DGGML_CUDA=ON
cmake --build build --config Release -j

# 4. Create models folder and download the exact model
mkdir -p /workspace/models
cd /workspace/models

if [ ! -f "Qwen2.5-72B-Instruct-Q4_K_M.gguf" ]; then
  echo "Downloading Qwen2.5-72B-Instruct-Q4_K_M.gguf (~47 GB)..."
  huggingface-cli download bartowski/Qwen2.5-72B-Instruct-GGUF Qwen2.5-72B-Instruct-Q4_K_M.gguf --local-dir .
fi

# 5. Start the server as daemon
echo "Starting llama-server..."
pkill -f llama-server || true
sleep 2

nohup /workspace/llama.cpp/build/bin/llama-server \
  -m /workspace/models/Qwen2.5-72B-Instruct-Q4_K_M.gguf \
  -c 32768 \
  --host 0.0.0.0 \
  --port 8000 \
  -ngl 99 \
  > /tmp/llama.log 2>&1 &

echo "=== Setup complete! ==="
echo ""
echo "Your API endpoint is:"
echo "https://4l4uga9zmb46l3-8000.proxy.runpod.net/v1"
echo ""
echo "Test it now with:"
echo 'curl -k https://4l4uga9zmb46l3-8000.proxy.runpod.net/v1/chat/completions -H "Content-Type: application/json" -d '\''{"model":"Qwen2.5-72B-Instruct-Q4_K_M","messages":[{"role":"user","content":"Say hello from Sulla!"}],"max_tokens":30}'\'''
echo ""
echo "Check logs anytime with: tail -f /tmp/llama.log"
