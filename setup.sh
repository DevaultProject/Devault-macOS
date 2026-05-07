#!/bin/bash
set -e

echo "=== Devault macOS - Dev Environment Setup ==="

# 1. mise 설치 확인 및 설치
if ! command -v mise &> /dev/null; then
  echo "[mise] Installing mise..."
  curl https://mise.run | sh

  # 쉘 환경에 mise 활성화
  SHELL_NAME=$(basename "$SHELL")
  case "$SHELL_NAME" in
    zsh)
      echo 'eval "$(~/.local/bin/mise activate zsh)"' >> ~/.zshrc
      eval "$(~/.local/bin/mise activate zsh)"
      ;;
    bash)
      echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
      eval "$(~/.local/bin/mise activate bash)"
      ;;
    *)
      echo "[mise] Please manually add mise activation to your shell profile."
      echo "  See: https://mise.jdx.dev/getting-started.html"
      ;;
  esac
else
  echo "[mise] Already installed: $(mise --version)"
fi

# 2. .mise.toml에 정의된 Tuist 버전 설치
echo "[tuist] Installing pinned version from .mise.toml..."
mise install

# 3. 설치된 Tuist 버전 확인
TUIST_VERSION=$(mise exec -- tuist version)
echo "[tuist] Active version: $TUIST_VERSION"

# 4. Tuist fetch (SPM 패키지 등 의존성 설치)
if [ -f "Tuist/Package.swift" ] || [ -f "Package.swift" ]; then
  echo "[tuist] Running 'tuist install'..."
  mise exec -- tuist install
fi

echo ""
echo "Setup complete!"
echo "Run tuist commands with: mise exec -- tuist <command>"
echo "Or add 'mise activate' to your shell profile to use 'tuist' directly."
