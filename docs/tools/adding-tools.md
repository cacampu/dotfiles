# 開発ツールの追加ワークフローと設計メモ

開発ツールは原則 [mise](https://mise.jdx.dev/) で一元管理する。設定は 2 層に分かれる。

| 層 | ファイル | 役割 |
|----|----------|------|
| 宣言 | `.config/mise/config.toml` | どのツールを何バージョン入れるか・環境変数 |
| activation(mise ツール) | `.config/mise/shell-hooks.zsh` | mise で入れたツールが要求する独自シェルフック(opam 等)を集約 |
| activation(全体) | `.config/shell/loaders` | `mise activate` 本体・cargo・starship 等の順序付き activation |

`eval "$(mise activate zsh)"` や `starship init` は「今動いているシェル自身を書き換える」ものなので、原理的に loaders 側にしか置けない。逆にツールのバージョンや env は config.toml 側に置く。**大半のツールは config.toml に一行足すだけで完結し、loaders も shell-hooks.zsh も触らない。**

`shell/loaders` は `mise activate` の直後に `mise/shell-hooks.zsh` を source する。mise が入れたツール固有のシェルフックは、config.toml と同じ `mise/` に局在させるため後者に書く（`shell/loaders` 自体は増やさない）。

## 標準的な追加手順(mise 管理できるツール)

1. `mise registry <名前>` で mise が扱えるか確認
2. `.config/mise/config.toml` の `[tools]` に一行追加（アルファベット順を維持）
3. ツール固有のデータ置き場を `~` から `~/.local` へ寄せたい場合は `[env]` に環境変数を追加
   （例: `GOPATH`、`NIMBLE_DIR`、`OPAMROOT`。`{{env.HOME}}/.local/share/<tool>` の形）
4. `mise install`
5. loaders は基本いじらない

## シェルフックが必要なツール

以下のどちらかに当てはまるツールだけ、シェル側にフックを一行足す。

- **mise 管理外**: 自前のインストーラを使い、独自の bin ディレクトリを持つもの
  （例: Rust/rustup → `~/.cargo/env`）。mise と無関係なので `shell/loaders` に直接書く。
- **mise の下にもう一段パッケージマネージャがある**: mise が入れるのは「マネージャ本体」までで、
  実際のコマンドはそのマネージャが別の場所に入れるもの（例: OCaml/opam、後述）。
  mise で入れたツールなので `mise/shell-hooks.zsh` に書く。

### 順序ルール

source は逐次実行なので順序に意味がある。原則:

- 土台の `mise activate` を先頭に置く（後続ツールの env・バイナリを供給するため）
- `mise/shell-hooks.zsh` の source はその直後（中身の opam 等が mise の env・バイナリに依存するため）
- mise 非依存の行（cargo・starship）は順不同
- `shell-hooks.zsh` の中では、mise が張った PATH・env（`OPAMROOT` 等）を前提にしてよい

## ケーススタディ: OCaml (opam)

OCaml は他言語と事情が違うので注意。

```
node / go / ghc: mise が「言語本体」を直接入れる → mise activate だけで PATH に載る(1 層)
OCaml:          mise が入れるのは opam(パッケージマネージャ)本体だけ
                → コンパイラ / dune は opam が OPAMROOT/<switch>/bin に入れる
                → そこは mise の管理外なので opam 自身の activation が要る(2 層目)
```

さらに switch はプロジェクトごとに動的なので、静的 PATH では対応できず opam のフックが要る。

**設定内訳:**

- `.config/mise/config.toml`
  - `[tools]` に `opam = "latest"`
  - `[env]` に `OPAMROOT = "{{env.HOME}}/.local/share/opam"`（`~/.opam` を `.local` へ）
- `.config/mise/shell-hooks.zsh`
  - `add-zsh-hook chpwd _opam_env_hook`（中身は `eval "$(opam env --shell=zsh)"`）で、cd のたびに
    「現在ディレクトリの switch」を有効化する。`shell/loaders` が `mise activate` の後にこれを source するので、
    `OPAMROOT`（mise の env）も opam バイナリ（mise 経由）も既に揃っている（mise より前だと空振りする）。
  - opam init が生成する `opam-init/init.zsh` を source する手もあるが、`--no-setup` だと自動追従の実体
    （`env_hook.zsh`）が生成されず無効。そのため**フックは init.zsh に頼らず自前で張る**。

**初期化（一度きり）:**

```bash
mise install                    # opam 本体を導入
opam init --bare --no-setup -y  # OPAMROOT を初期化(rc は触らせない)
opam switch create 5.5.0 -y     # 既定グローバル switch。どこでも ocaml が使え、
                                # プロジェクトを抜けたとき PATH がクリーンに戻る
```

`--no-setup` は rustup の `--no-modify-path` と同じ思想（rc は自前管理する）。既定グローバル switch を
1 本持つと、プロジェクトのローカル switch から抜けたとき既定へクリーンに復帰できる（無いと直前の
switch の PATH が残る）。

**プロジェクト作成:**

```bash
mkdir myproj && cd myproj
opam switch create . 5.5.0 -y   # プロジェクトローカル switch（コンパイラと依存をここに閉じ込める）
eval "$(opam env)"              # 初回だけ手動。以降は shell-hooks の自前フックが cd で自動追従
opam install dune -y
dune init proj myproj .
```

### 検討したが採らなかった案

- **opam の activation を `[env]._.source` で config.toml に寄せる**: 実測で不可。mise は `_.source` を
  `[tools]` の PATH を張る**前**に評価するため（`command -v node` が source 内で `no` を返す）、
  source スクリプトから opam を呼べない。loaders の行は `mise activate` が PATH を張り終えた後に走るので確実。
- **OCaml を mise で直接管理（asdf-ocaml）**: opam と二重管理になり switch と競合するため不可。
- **起動時に `eval "$(opam env)"` を一度だけ**: グローバルのデフォルト switch に固定され、
  プロジェクトローカル switch に cd 追従しないため不採用（chpwd フックで毎回追従させる）。
- **opam 生成の `init.zsh` を source して済ませる**: `--no-setup` では自動追従の実体（`env_hook.zsh`）が
  生成されず効かない。rc を触らせない方針は保ちたいので、フックは自前で張る方を採用。

## 補足: Rust を mise に寄せない理由

mise にも `rust` はあるが実体は rustup のラッパで、`rustup component add rust-analyzer/clippy` や
ターゲット追加といったツールチェーン管理は rustup 直の方が素直。よって Rust だけ rustup 管理のままにし、
`~/.cargo/env` を loaders で source している。
