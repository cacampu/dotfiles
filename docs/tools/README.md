# ツール管理

開発ツールは原則 [mise](https://mise.jdx.dev/) で一元管理する。設定は 2 層に分かれる。

| 層 | ファイル | 役割 |
|----|----------|------|
| 宣言 | `.config/mise/config.toml` | どのツールを何バージョン入れるか・環境変数 |
| activation(mise ツール) | `.config/mise/shell-hooks.zsh` | mise で入れたツールが要求する独自シェルフック(opam 等)を集約 |
| activation(全体) | `.config/shell/loaders` | `mise activate` 本体・cargo・starship 等の順序付き activation |

大半のツールは config.toml に一行足すだけで完結する。詳しい追加手順・設計判断・順序ルールは
[adding-tools.md](adding-tools.md) を参照。

## 管理しているツール

| ツール | 用途 | 備考 |
|--------|------|------|
| neovim | メインエディタ | |
| node   | JavaScript ランタイム(Claude Code 依存) | |
| go     | Go 開発 | `GOPATH → ~/.local/share/go` |
| zig    | Zig 開発 | |
| ghc / cabal | Haskell 開発 | |
| nim    | Nim 開発 | `NIMBLE_DIR → ~/.local/share/nimble` |
| julia  | Julia 開発 | |
| java   | Java 開発(Corretto) | |
| opam   | OCaml パッケージマネージャ | [ocaml.md](ocaml.md)。`OPAMROOT → ~/.local/share/opam` |
| zellij | ターミナルマルチプレクサ | |
| ripgrep / fd / bat / eza | CLI ユーティリティ | |

Rust だけは mise ではなく rustup 管理（理由は [adding-tools.md](adding-tools.md) 末尾）。

## ツール別メモ

依存関係や最小限の使い方は `docs/tools/<tool>.md` に置く。

- [ocaml.md](ocaml.md) — OCaml / opam / dune
