#!/usr/bin/env bash
set -euo pipefail

if [[ $# -gt 0 ]]; then
  cat <<'EOF'
This script does not accept command line arguments.
Run it directly and input git info during execution:
  bash install.sh
EOF
  exit 1
fi

GIT_NAME=""
GIT_EMAIL=""

SUDO=""
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    echo "sudo is required when running as non-root user."
    exit 1
  fi
fi

install_packages() {
  if command -v apt-get >/dev/null 2>&1; then
    $SUDO apt-get update
    $SUDO apt-get install -y git zsh tmux curl nodejs npm
    return
  fi

  if command -v dnf >/dev/null 2>&1; then
    $SUDO dnf install -y git zsh tmux curl nodejs npm
    return
  fi

  if command -v yum >/dev/null 2>&1; then
    $SUDO yum install -y git zsh tmux curl nodejs npm
    return
  fi

  if command -v pacman >/dev/null 2>&1; then
    $SUDO pacman -Sy --noconfirm git zsh tmux curl nodejs npm
    return
  fi

  if command -v zypper >/dev/null 2>&1; then
    $SUDO zypper --non-interactive install git zsh tmux curl nodejs npm
    return
  fi

  echo "Unsupported package manager. Please install git, zsh, tmux, curl, nodejs, and npm manually."
  exit 1
}

backup_if_exists() {
  local target="$1"
  if [[ -f "$target" ]]; then
    local ts
    ts="$(date +%Y%m%d%H%M%S)"
    cp "$target" "${target}.bak.${ts}"
  fi
}

install_oh_my_zsh() {
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
}

install_zsh_plugins() {
  local custom_dir
  custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  if [[ ! -d "$custom_dir/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$custom_dir/plugins/zsh-autosuggestions"
  fi

  if [[ ! -d "$custom_dir/plugins/zsh-syntax-highlighting" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$custom_dir/plugins/zsh-syntax-highlighting"
  fi
}

write_zshrc() {
  backup_if_exists "$HOME/.zshrc"
  cat > "$HOME/.zshrc" <<'EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting sudo extract history)
source $ZSH/oh-my-zsh.sh

alias ll='ls -alF'
EOF
}

write_tmux_conf() {
  backup_if_exists "$HOME/.tmux.conf"
  cat > "$HOME/.tmux.conf" <<'EOF'
set -g mouse on
set -g history-limit 10000
set -g base-index 1
setw -g pane-base-index 1
EOF
}

set_git_config() {
  git config --global user.name "$GIT_NAME"
  git config --global user.email "$GIT_EMAIL"
}

prompt_yes_no() {
  local prompt="$1"
  local answer
  read -r -p "$prompt [y/N]: " answer
  [[ "$answer" =~ ^[Yy]$ ]]
}

configure_git() {
  if ! prompt_yes_no "Configure git user.name and user.email"; then
    echo "Skip git configuration."
    return
  fi

  read -r -p "Input git user.name: " GIT_NAME
  read -r -p "Input git user.email: " GIT_EMAIL

  if [[ -z "$GIT_NAME" || -z "$GIT_EMAIL" ]]; then
    echo "git user.name and user.email cannot be empty when git configuration is enabled."
    exit 1
  fi

  set_git_config
}

install_npm_package_if_missing() {
  local check_cmd_primary="$1"
  local check_cmd_secondary="$2"
  local package_name="$3"
  local display_name="$4"

  if command -v "$check_cmd_primary" >/dev/null 2>&1; then
    echo "$display_name is already installed."
    return
  fi

  if [[ -n "$check_cmd_secondary" ]] && command -v "$check_cmd_secondary" >/dev/null 2>&1; then
    echo "$display_name is already installed."
    return
  fi

  echo "$display_name is not installed."
  if ! prompt_yes_no "Install $display_name now via npm"; then
    return
  fi

  if ! command -v npm >/dev/null 2>&1; then
    echo "npm is not available. Skip installing $display_name."
    return
  fi

  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    npm install -g "$package_name"
  else
    $SUDO npm install -g "$package_name"
  fi
}

ensure_ai_tools() {
  # Common package name and binary mapping for CLI tools.
  install_npm_package_if_missing "claude" "claude-code" "@anthropic-ai/claude-code" "claude-code"
  install_npm_package_if_missing "opencode" "" "opencode-ai" "opencode"
}

append_env_if_missing() {
  local file_path="$1"
  local key="$2"
  local value="$3"

  # Remove old key definitions first to avoid duplicates.
  if [[ -f "$file_path" ]]; then
    sed -i "/^export ${key}=.*/d" "$file_path"
  fi

  printf "export %s=%q\n" "$key" "$value" >> "$file_path"
}

configure_api_keys() {
  local anthropic_key=""
  local opencode_key=""

  if prompt_yes_no "Configure ANTHROPIC_API_KEY for claude-code"; then
    read -r -p "Input ANTHROPIC_API_KEY: " anthropic_key
    if [[ -n "$anthropic_key" ]]; then
      append_env_if_missing "$HOME/.zshrc" "ANTHROPIC_API_KEY" "$anthropic_key"
    fi
  fi

  if prompt_yes_no "Configure OPENCODE_API_KEY for opencode"; then
    read -r -p "Input OPENCODE_API_KEY: " opencode_key
    if [[ -n "$opencode_key" ]]; then
      append_env_if_missing "$HOME/.zshrc" "OPENCODE_API_KEY" "$opencode_key"
    fi
  fi
}

set_default_shell() {
  local zsh_path
  local current_user
  zsh_path="$(command -v zsh)"
  current_user="${USER:-$(id -un)}"

  if [[ "${SHELL:-}" != "$zsh_path" ]]; then
    if chsh -s "$zsh_path" "$current_user"; then
      echo "Default shell changed to zsh."
    else
      echo "Failed to change default shell automatically. Please run: chsh -s $zsh_path"
    fi
  fi
}

echo "[1/8] Installing packages..."
install_packages

echo "[2/8] Configuring git..."
configure_git

echo "[3/8] Installing Oh My Zsh..."
install_oh_my_zsh

echo "[4/8] Installing zsh plugins..."
install_zsh_plugins

echo "[5/8] Writing shell and tmux config..."
write_zshrc
write_tmux_conf

echo "[6/8] Checking AI CLI tools..."
ensure_ai_tools

echo "[7/8] Configuring API keys..."
configure_api_keys

echo "[8/8] Setting default shell..."
set_default_shell

echo "Done. Reopen terminal or run: exec zsh"
