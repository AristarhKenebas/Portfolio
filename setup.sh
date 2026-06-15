#!/bin/bash

set -e

OS=""
PKG_MANAGER=""

detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
      ubuntu|debian|linuxmint) OS="debian"; PKG_MANAGER="apt" ;;
      arch|manjaro|endeavouros) OS="arch"; PKG_MANAGER="pacman" ;;
      fedora) OS="fedora"; PKG_MANAGER="dnf" ;;
      centos|rhel|rocky) OS="rhel"; PKG_MANAGER="dnf" ;;
      opensuse*|sles) OS="suse"; PKG_MANAGER="zypper" ;;
      nixos) OS="nixos" ;;
      *) OS="unknown" ;;
    esac
  elif [ "$(uname)" = "Darwin" ]; then
    OS="macos"
    PKG_MANAGER="brew"
  else
    echo "Unsupported OS"
    exit 1
  fi
}

install_docker() {
  if command -v docker >/dev/null 2>&1; then
    return
  fi

  echo "Installing Docker..."

  case "$OS" in
    debian)
      sudo apt update
      sudo apt install -y ca-certificates curl
      sudo install -m 0755 -d /etc/apt/keyrings
      sudo curl -fsSL https://download.docker.com/linux/$ID/gpg -o /etc/apt/keyrings/docker.asc
      echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$ID $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list
      sudo apt update
      sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
      ;;
    arch)
      sudo pacman -Sy --noconfirm docker docker-compose
      ;;
    fedora|rhel)
      sudo dnf -y install dnf-plugins-core
      sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
      sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
      ;;
    suse)
      sudo zypper install -y docker docker-compose
      ;;
    macos)
      if ! command -v brew >/dev/null 2>&1; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      fi
      brew install --cask docker
      echo "Start Docker Desktop manually, then run this script again"
      exit 0
      ;;
    nixos)
      echo "Add to configuration.nix:"
      echo "  virtualisation.docker.enable = true;"
      echo "  users.users.YOUR_USER.extraGroups = [ \"docker\" ];"
      echo "Then run: sudo nixos-rebuild switch"
      exit 0
      ;;
    *)
      echo "Cannot install Docker automatically. Install manually: https://docs.docker.com/engine/install"
      exit 1
      ;;
  esac

  sudo systemctl enable --now docker
  sudo usermod -aG docker "$USER"
  echo "Docker installed. Log out and back in, then run this script again"
  exit 0
}

install_git() {
  if command -v git >/dev/null 2>&1; then
    return
  fi

  echo "Installing Git..."

  case "$OS" in
    debian) sudo apt install -y git ;;
    arch) sudo pacman -Sy --noconfirm git ;;
    fedora|rhel) sudo dnf install -y git ;;
    suse) sudo zypper install -y git ;;
    macos) brew install git ;;
    *)
      echo "Install Git manually: https://git-scm.com"
      exit 1
      ;;
  esac
}

generate_secret() {
  cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 48 | head -n 1
}

collect_config() {
  echo ""
  echo "Configuration"
  echo "-------------"
  echo "Press Enter to use the default value shown in brackets."
  echo ""

  read -p "GitHub username: " GITHUB_USERNAME
  while [ -z "$GITHUB_USERNAME" ]; do
    read -p "GitHub username (required): " GITHUB_USERNAME
  done

  read -p "GitHub token (optional, for higher API rate limits): " GITHUB_TOKEN

  echo ""
  read -p "Admin username [admin]: " ADMIN_USERNAME
  ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"

  while true; do
    read -s -p "Admin password (min 8 chars): " ADMIN_PASSWORD
    echo ""
    if [ ${#ADMIN_PASSWORD} -ge 8 ]; then
      read -s -p "Confirm password: " ADMIN_PASSWORD_CONFIRM
      echo ""
      if [ "$ADMIN_PASSWORD" = "$ADMIN_PASSWORD_CONFIRM" ]; then
        break
      else
        echo "Passwords do not match, try again"
      fi
    else
      echo "Password must be at least 8 characters"
    fi
  done

  read -p "Database password [auto-generated]: " POSTGRES_PASSWORD
  POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-$(generate_secret)}"

  SESSION_SECRET=$(generate_secret)

  read -p "Site port [3000]: " SITE_PORT
  SITE_PORT="${SITE_PORT:-3000}"

  read -p "API port [3001]: " API_PORT
  API_PORT="${API_PORT:-3001}"

  read -p "Admin port [3002]: " ADMIN_PORT
  ADMIN_PORT="${ADMIN_PORT:-3002}"

  cat > .env << ENVEOF
POSTGRES_USER=portfolio
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_DB=portfolio

SESSION_SECRET=${SESSION_SECRET}
ADMIN_USERNAME=${ADMIN_USERNAME}
ADMIN_PASSWORD=${ADMIN_PASSWORD}

GITHUB_USERNAME=${GITHUB_USERNAME}
GITHUB_TOKEN=${GITHUB_TOKEN}

SITE_PORT=${SITE_PORT}
API_PORT=${API_PORT}
ADMIN_PORT=${ADMIN_PORT}
ENVEOF

  echo ""
  echo ".env created"
}

clone_repos() {
  [ ! -d api ] && git clone https://github.com/AristarhKenebas/portfolio-api.git api
  [ ! -d site ] && git clone https://github.com/AristarhKenebas/portfolio-site.git site
  [ ! -d admin ] && git clone https://github.com/AristarhKenebas/portfolio-admin.git admin
}

detect_os
install_git
install_docker

if [ ! -f .env ]; then
  collect_config
fi

clone_repos

docker compose up -d --build

echo ""
echo "Site:  http://localhost:${SITE_PORT:-3000}"
echo "Admin: http://localhost:${ADMIN_PORT:-3002}"
echo "API:   http://localhost:${API_PORT:-3001}"
