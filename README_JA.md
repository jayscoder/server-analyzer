# サーバー分析ツール

<div align="center">
<img src="https://raw.githubusercontent.com/iconic/open-iconic/master/svg/globe.svg" width="80" height="80">
<br>
<strong>サーバー情報を素早く収集し、詳細なレポートを生成します</strong>
</div>

<p align="center">
  <a href="README.md">中文</a> |
  <a href="README_EN.md">English</a> |
  <a href="README_JA.md">日本語</a> |
  <a href="README_ES.md">Español</a>
</p>

## 概要

サーバー分析ツールは、Linux/Unix サーバーのさまざまなシステム情報を素早く収集し、フォーマット化されたレポートを生成する強力な Bash スクリプトです。このツールは、システム管理者、DevOps エンジニア、AI エンジニア向けに設計されており、サーバーの構成と状態を素早く理解するのに役立ちます。

### 主な機能

- **包括的な情報収集**: CPU、メモリ、ストレージ、ネットワーク、GPU などのハードウェア情報を収集
- **ソフトウェア環境の検出**: オペレーティングシステム、インストールされたサービス、Docker コンテナ、プログラミング言語環境を検出
- **セキュリティ状態の分析**: ファイアウォールの状態、SSH 設定、基本的なセキュリティ設定をチェック
- **AI フレームワークのサポート**: Ollama、PyTorch、TensorFlow などの一般的な AI フレームワークを検出
- **マルチフォーマットレポート**: Markdown または HTML 形式の詳細なレポートの生成をサポート
- **ローカル/リモードモード**: ローカルサーバーまたは SSH 経由でリモートサーバーの分析をサポート

## AI モデルのコンテキストとしてレポートを活用

生成されたレポートは形式が整っており情報が豊富であるため、大規模言語モデルのコンテキスト情報として理想的です。以下のことができます：

1. 生成されたレポートを AI モデル（ChatGPT、Claude など）に直接アップロード
2. 実際のサーバー状況に基づいて、AI モデルにカスタマイズされた最適化提案を提供してもらう
3. レポートを使用して、AI によるより正確なサーバー構成、最適化、トラブルシューティングを支援

## インストール方法

### 直接ダウンロード

```bash
curl -o server_analyzer.sh https://raw.githubusercontent.com/ユーザー名/server-analyzer/メインブランチ/server_analyzer.sh
chmod +x server_analyzer.sh
```

### リリースからダウンロード

[リリースページ](https://github.com/ユーザー名/server-analyzer/releases)にアクセスして最新バージョンをダウンロードしてください。

## 使用方法

### 基本的な使用法

ローカルサーバーを分析して markdown レポートを生成します：

```bash
./server_analyzer.sh
```

### コマンドラインオプション

```
オプション:
  -i, --ip IP              リモートサーバーのIPアドレス（提供されていない場合はローカルサーバーを分析）
  -p, --port PORT          SSHポート（デフォルト: 22）
  -u, --user USER          SSHユーザー名
  -o, --output PATH        レポート出力パス（デフォルト: ./server_report.md）
  -f, --format FORMAT      レポート形式: markdown または html（デフォルト: markdown）
  -h, --help               このヘルプ情報を表示
```

### 例

リモートサーバーを分析：

```bash
./server_analyzer.sh -i 192.168.1.100 -p 2222 -u admin -o /tmp/server_report.md
```

HTML 形式のレポートを生成：

```bash
./server_analyzer.sh -f html -o server_report.html
```

## レポート内容

生成されたレポートには、以下の主なセクションが含まれています：

- **基本情報**: ホスト名、IP アドレス、オペレーティングシステム、カーネルバージョンなど
- **ハードウェア構成**: CPU、メモリ、ストレージデバイス、GPU 情報
- **ネットワーク構成**: ネットワークインターフェース、パブリック IP、オープンポートなど
- **ソフトウェアとサービス**: システムサービス、Docker コンテナ、プログラミング言語環境など
- **AI フレームワーク**: Ollama、PyTorch、TensorFlow などの AI フレームワークの検出
- **パフォーマンスとリソース使用量**: システム負荷、リソース使用率が最も高いプロセスなど
- **セキュリティ情報**: ファイアウォールの状態、SSH 構成、SELinux の状態など
- **ユーザー情報**: 現在ログインしているユーザー、管理者権限を持つユーザーなど
- **結論と推奨事項**: 収集された情報に基づく提案

## ライセンス

MIT ライセンス

## 貢献

イシューやプルリクエストは歓迎します！
