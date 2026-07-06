plugins=(
	z
	fzf
	zsh-syntax-highlighting
)
source $ZSH/oh-my-zsh.sh



HISTSIZE=50000
SAVEHIST=50000
setopt APPEND_HISTORY          # 履歴を追記で保存
setopt SHARE_HISTORY           # 複数のターミナルで履歴を即時共有
setopt HIST_IGNORE_DUPS        # 直前のコマンドと同じ場合は保存しない
setopt HIST_IGNORE_ALL_DUPS    # 過去の履歴と完全一致する場合は保存しない
setopt HIST_VERIFY             # 実行したコマンドを一旦履歴に展開し、編集可能にする
setopt HIST_IGNORE_SPACE       # コマンドの前にスペースを入れると履歴に残さない


bindkey '^P' up-line-or-beginning-search
bindkey '^N' down-line-or-beginning-search

bindkey '^[.' insert-last-word
autoload -U edit-command-line; zle -N edit-command-line
bindkey '^[e' edit-command-line

[ -f "$HOME/.config/shell/aliases" ] && . "$HOME/.config/shell/aliases"
[ -f "$HOME/.config/shell/loaders" ] && . "$HOME/.config/shell/loaders"
