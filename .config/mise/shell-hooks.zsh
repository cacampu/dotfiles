# mise で導入したツールのうち、自前のシェル統合が必要なもののフックを集約する。
# shell/loaders から mise activate の直後に source される(mise が PATH・env を張った後でないと動かない)。
# 追加ルールは docs/tools/adding-tools.md を参照。

# opam (OCaml): mise が入れるのは opam 本体まで。コンパイラ/dune は switch ごとの prefix に入るので、
# cd するたびに「現在ディレクトリの switch」を有効化する。opam env が出力する PATH 等を eval で適用。
# (opam init が生成する env_hook.zsh は --no-setup では作られないため、フックは自前で張る)
if command -v opam >/dev/null 2>&1; then
  autoload -Uz add-zsh-hook
  _opam_env_hook() { eval "$(opam env --shell=zsh 2>/dev/null)"; }
  add-zsh-hook chpwd _opam_env_hook
  _opam_env_hook   # 起動時にカレントディレクトリ分を反映
fi
