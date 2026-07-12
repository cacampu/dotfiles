# OCaml (opam / dune)

## 依存関係

mise が入れるのは **opam（パッケージマネージャ）本体まで**。コンパイラ・dune・ライブラリは
opam が switch ごとの prefix に入れる。

```
mise ─▶ opam ─▶ OCaml コンパイラ + dune + ライブラリ
        OPAMROOT = ~/.local/share/opam
```

シェルで `ocaml` / `dune` を使うための activation は `.config/mise/shell-hooks.zsh` の `chpwd` フック
（`eval "$(opam env)"`）が担い、cd するたびに現在ディレクトリの switch を有効化する。仕組みの詳細は
[adding-tools.md](adding-tools.md) を参照。

## 初期セットアップ（マシンごとに一度）

```bash
mise install                    # opam 本体
opam init --bare --no-setup -y  # OPAMROOT を初期化(rc は触らせない)
opam switch create 5.5.0 -y     # 既定グローバル switch(どこでも ocaml/utop が使える)
```

## プロジェクトのセットアップ

プロジェクトごとに `_opam` にローカル switch を作り、コンパイラとバージョンをそのプロジェクトに固定する
（ローカル switch が無い場所では既定グローバル switch が使われる）。

```bash
mkdir -p ~/dev/sandbox/myproj && cd $_
opam switch create . 5.5.0 -y   # ./_opam にこのプロジェクト用の switch
eval "$(opam env)"              # 初回だけ手動。以降は cd で自動追従
opam install dune -y            # dune を入れる
dune init proj myproj .         # 雛形生成
dune build && dune exec myproj  # ビルド & 実行
echo '_opam/' >> .gitignore
```

別バージョンにしたいプロジェクトは `opam switch create . 5.4.0` のようにバージョンを変えるだけ。

## よく使うコマンド

| コマンド | 意味 |
|---|---|
| `dune build` | ビルド |
| `dune exec <name>` | ビルドして実行 |
| `dune runtest` | テスト |
| `dune fmt` | 整形(要 ocamlformat) |
| `utop` | REPL(要 utop) |
| `opam install <pkg>` | 現在の switch にライブラリ追加 |
| `opam switch list` | switch 一覧と現在の switch |

## エディタ（補完 / LSP）

```bash
opam install ocaml-lsp-server ocamlformat utop -y
```

switch ごとに独立しているので、既定グローバルと各ローカル switch の**両方に入れる**。ローカル switch の
プロジェクトはそのディレクトリでエディタを起動して `_opam` を検出させる。
