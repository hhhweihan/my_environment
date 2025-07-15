# 安装zsh
sudo apt update && sudo apt install -y zsh

# 将Zsh设为默认shell
chsh -s $(which zsh)

# 安装Oh My Zsh框架
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 命令自动建议（输入时会显示灰色建议）
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

# 语法高亮（正确命令绿色，错误命令红色）
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# 强大的主题（可选但推荐）
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# 配置~/.zshrc
## 设置主题（二选一）
ZSH_THEME="robbyrussell"  # Oh My Zsh默认主题
## 或使用powerlevel10k
ZSH_THEME="powerlevel10k/powerlevel10k"

## 添加插件（在plugins行修改）
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  sudo
  extract
  history
)

# 应用配置
source ~/.zshrc

# 配置Powerlevel10k主题
p10k configure

# 验证安装
## 检查当前shell
echo $SHELL

## 检查zsh版本
zsh --version

## 检查插件是否生效（应有高亮显示）
echo "This should be green"  # 正确命令应为绿色
ech "This should be red"     # 错误命令应为红色


