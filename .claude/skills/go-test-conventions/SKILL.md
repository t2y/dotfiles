---
name: go-test-conventions
description: Go のテストコードを書くときの要項。t-wada のテスト哲学（テストはドキュメント）、テーブル駆動テスト、パラメータ数によるテスト関数の分割（<=5 は単一関数、>5 は成功用と TestXXXError に分割）、package_test による公開 API 経由のテスト、t.Parallel、インターフェースを埋め込んだ部分フェイク、非同期テストの待ち合わせに使う testing/synctest、カバーすべきケース、アサーションの書き方を定める。Go のテストを新規に書く、既存テストにケースを足す、テストをレビューするときに使用する。
---

# Go テストコードの規約

Go のテストを書くとき、レビューするときは、以下の規範に従う。
命名やコメントなど、テストに限らない規約は `go-coding-conventions` skill にある。
両方を適用する。

## テストの哲学（t-wada）

### 原則

1. **テストはドキュメント**：テストは振る舞いと仕様を明確に記述するものである。
2. **説明的な名前**：テスト名は、そのコードが何をするかを表す。どう実装されているかは表さない。
3. **1ケース1アサーション**：各テストケースは単一の振る舞いに絞る。
4. **テストでは DRY を優先しない**：重複の削減より可読性を優先する。技巧的であるより明示的であるほうがよい。
5. **実装ではなく振る舞いをテストする**：コードが何をするかに注目し、どう構造化されているかには注目しない。

### テストの構造

- テーブル駆動テストを使い、テストケース名は仕様書のように読める説明的なものにする。
- 関連するテストは `t.Run()` でまとめる。
- `t.Parallel()` は可能な限り使う。実行時間を短縮し、競合状態を検出できる。
- **Arrange-Act-Assert（AAA）パターン**に従う。ただし `// Arrange`、`// Act`、`// Assert` のコメントは書かない。ブロックの区切りは空行で示す。
- 正常系と異常系の両方を含める。
- テストデータはテストロジックの近くに置く。

## カバーすべき範囲

次を網羅する。

- **境界値**：空入力、nil、境界条件
- **エラー**：不正な入力、エラーの返却、panic
- **正常系**：妥当な入力による典型的なユースケース
- **並行性**：goroutine 安全性（該当する場合）。待ち合わせが必要なら `testing/synctest` を使う
- **インターフェース適合**：実装の検証
- **並列実行**：可能な限り、共有状態を持たず並列実行しても安全にする

## コードスタイル

### 命名と構造

- パッケージ名は `_test` サフィックス付きにする（例：`package user_test`）。公開 API 経由でテストするためである。
- テスト関数名は `Test` で始める。
- 変数名は意味のあるものにする。慣用的な短縮を除き、1文字の名前は避ける。
- 必要に応じて `t.Cleanup()` か `defer` で後始末を行う。
- セットアップ、実行、アサーションの各ブロックは空行で区切る。

### アサーション（Power Assert の考え方）

- **単純なほうがよい**：複雑なマッチャーより等値比較を選ぶ。
- **失敗メッセージを明確にする**：デバッグの助けになる情報を出す。
- **expected と actual の順序**：常に同じ順序（expected、actual）で書く。
- `testify` や `cmp.Diff` などのアサーションライブラリは、すでに使われていれば使う。それでも単純なアサーションを優先する。

### テストデータ

- 実際のユースケースを表す現実的なデータを使う。
- 複雑な構造体はフィクスチャにする。
- 値は定数かヘルパーにまとめ、ハードコードを避ける。
- 文字列には Unicode や非 ASCII の文字を含める。

## パターンの選択

テスト関数は正常系と異常系で分割し、テストケースを単純に保つ。
分割するかどうかはパラメータ数で決める。

| パラメータ数 | パターン | 使う場面 |
|---|---|---|
| 5個以下 | 単一関数（パターン1） | テストケースの構造体が単純で、`expectedErr bool` を含められる |
| 6個以上 | 分割（パターン2と3） | パラメータが多すぎるので、成功用とエラー用に分ける |

判断の手順は次のとおり。

1. テストケース構造体のフィールド数を数える（`name` は除く）。
2. 5個以下ならパターン1を使い、1つの関数に両方のシナリオを入れる。
3. 6個以上ならパターン2（成功のみ）とパターン3（エラーのみ）に分ける。

1つの関数にまとめる場合は、正常系のテストケースを先に、異常系（エラー）のテストケースを後に書く。
同種のシナリオが隣り合うので読みやすくなる。

分割する場合の役割は次のとおり。

- `TestFunctionName`：正常系のみ。`expected` だけを持ち、エラーの内容は検証しない。
- `TestFunctionNameError`：異常系のみ。エラーだけを検証し、正常時の戻り値は検証しない。

分割の利点は、パラメータが減ること、意図が明確になること、可読性が上がること、アサーションが単純になることである。

## パターン別の書き方

### パターン1：正常系と異常系を1つの関数に入れる

```go
package user_test

import (
    "testing"

    "github.com/google/go-cmp/cmp"

    "example.com/project/user"
)

func TestUserStore_FindByID(t *testing.T) {
    tests := []struct {
        name        string
        userID      string
        expected    *user.User
        expectedErr bool
    }{
        // normal
        {
            name:     "returns user when valid ID is provided",
            userID:   "user123",
            expected: &user.User{ID: "user123", Name: "Alice"},
        },

        // error
        {
            name:        "returns error when user does not exist",
            userID:      "nonexistent",
            expectedErr: true,
        },
        {
            name:        "returns error when ID is empty",
            userID:      "",
            expectedErr: true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()

            store := user.NewUserStore()

            actual, err := store.FindByID(tt.userID)

            if tt.expectedErr {
                if err == nil {
                    t.Error("Expected an error, but got nil")
                    return
                }
                t.Log(err)
            } else {
                if err != nil {
                    t.Errorf("Unexpected error: %v", err)
                    return
                }
                if diff := cmp.Diff(tt.expected, actual); diff != "" {
                    t.Error(diff)
                }
            }
        })
    }
}
```

### パターン2：正常系のみのテスト関数

```go
package user_test

import (
    "testing"

    "github.com/google/go-cmp/cmp"

    "example.com/project/user"
)

func TestUserStore_FindByID(t *testing.T) {
    tests := []struct {
        name     string
        userID   string
        expected *user.User
    }{
        {
            name:     "returns user when valid ID is provided",
            userID:   "user123",
            expected: &user.User{ID: "user123", Name: "Alice"},
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()

            store := user.NewUserStore()

            actual, err := store.FindByID(tt.userID)

            if err != nil {
                t.Errorf("Unexpected error: %v", err)
                return
            }
            if diff := cmp.Diff(tt.expected, actual); diff != "" {
                t.Error(diff)
            }
        })
    }
}
```

### パターン3：異常系のみのテスト関数

```go
package user_test

import (
    "testing"

    "example.com/project/user"
)

func TestUserStore_FindByIDError(t *testing.T) {
    tests := []struct {
        name   string
        userID string
    }{
        {
            name:   "returns error when user does not exist",
            userID: "nonexistent",
        },
        {
            name:   "returns error when ID is empty",
            userID: "",
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()

            store := user.NewUserStore()

            _, err := store.FindByID(tt.userID)

            if err == nil {
                t.Error("Expected an error, but got nil")
                return
            }
            t.Log(err)
            // May add some code to check the error status/state
        })
    }
}
```

## テストダブル

### 部分フェイクはインターフェースを埋め込んで作る

フェイクは、対象のインターフェースを nil のまま埋め込み、テスト対象が実際に呼ぶメソッドだけを実装する。

```go
// fakeUserStore records saved users so a test can assert what was written; the
// embedded interface supplies the methods the test never calls.
type fakeUserStore struct {
    user.Store
    saved   []user.User
    saveErr error
}

func (s *fakeUserStore) Save(u user.User) error {
    if s.saveErr != nil {
        return s.saveErr
    }
    s.saved = append(s.saved, u)
    return nil
}
```

**Why:** メソッドの多いインターフェースでも、モック生成ツールを持ち込まずにフェイクを書ける。
実装していないメソッドが呼ばれると nil インターフェースの参照で panic するので、テスト対象が想定外の依存を持っていることが露見する。
全メソッドを空実装で埋めると、同じ呼び出しが黙って成功し、依存が隠れてしまう。

**How to apply:**

- 埋め込んだフィールドは nil のままにする。ゼロ値の実装を入れない。
- 各テストが上書きするのは、そのテストで実際に呼ばれるメソッドだけにする。
- 型アサーションを満たせば足りる場合は、メソッドを1つも実装せず埋め込みだけの型にする（例：`type stubUserStore struct{ user.Store }`）。
- 呼ばれたら panic する設計が意図であることを、フェイクの定義かファイルの冒頭に一言書く。読み手が実装漏れと誤解しないようにする。
- パッケージ内の複数のテストが同じフェイクを使うなら、`fake_test.go` のような専用ファイルにまとめる。各フェイクには、何を記録するのか、どの失敗経路を再現するのかを doc comment で書く。

## 個別のケース

### 並行性のテスト

`t.Parallel()` で競合状態を検出する。
goroutine 安全性は明示的にテストし、`-race` フラグの使用を検討する。

```go
func TestConcurrentAccess(t *testing.T) {
    t.Parallel()
    // Test concurrent operations...
}
```

### 待ち合わせが必要なときは testing/synctest を使う

goroutine の処理完了やタイマーの発火を待つ必要があるテストでは、`testing/synctest` を使う。
実時間の `time.Sleep` でのポーリングや、チャネル受信にタイムアウトを付ける方式は使わない。

**Why:** 実時間の待ち合わせは、遅いマシンや負荷の高い CI で flaky になり、待ち時間の分だけテストが実際に遅くなる。
synctest は「bubble 内のすべての goroutine が停止するまで」という決定的な条件で待つので、待ち時間の調整が要らなくなる。

**How to apply:**

- テスト本体を `synctest.Test(t, func(t *testing.T) { ... })` で包む。bubble 内では時刻が仮想化される。
- goroutine が落ち着くのを待つ地点で `synctest.Wait()` を呼ぶ。bubble 内のすべての goroutine が durably blocked になるまで戻らないので、アサーションの直前に置けば競合なく状態を読める。
- 時間の経過を必要とするケース（タイムアウト、リトライ間隔、周期実行）は `time.Sleep()` で仮想時計を進める。実時間は消費しない。
- bubble を抜ける前に、起動したすべての goroutine を終了させる。context を cancel し、ブロックしているハンドラーを解放してから `synctest.Wait()` で見送る。goroutine が残ったまま関数を抜けると bubble が panic する。
- bubble 内では `t.Parallel()` を使わない。
- `synctest.Wait()` の呼び出しには、そこで何が起きるのを待っているのかを行末コメントで一言添える。待ち合わせの意図はコードから読み取れない。
- `testing/synctest` は Go 1.25 以降の正式 API である。1.24 の `synctest.Run` と `GOEXPERIMENT=synctest` は使わない。

```go
func TestWorkerRunFIFO(t *testing.T) {
    synctest.Test(t, func(t *testing.T) {
        ctx, cancel := context.WithCancel(context.Background())
        w := newWorker(queue, handler)
        go w.run(ctx)

        w.enqueue(first)
        w.enqueue(second)

        synctest.Wait() // drain the queue and settle
        assert.Equal(t, []string{"first", "second"}, executed)

        cancel()
        synctest.Wait() // let the worker observe cancellation and exit
    })
}
```

タイムアウトの検証では、仮想時計を期限の先まで進める。
`assertClosed` は `select` の `default` でチャネルの閉鎖を待たずに判定するヘルパーである。

```go
cancel()
waited := make(chan struct{})
go func() {
    w.Wait()
    close(waited)
}()

// Advance the fake clock past the deadline: Wait gives up on the still
// stuck handler instead of blocking forever.
time.Sleep(drainTimeout + time.Millisecond)
synctest.Wait()
assertClosed(t, waited, "Wait must return once the drain deadline elapses")

close(release) // release the stuck handler so the bubble ends without a leaked goroutine
synctest.Wait()
```

### インターフェースのテスト

実装がインターフェースを満たすことをコンパイル時に検証し、すべてのメソッドをテストする。

```go
var _ UserStore = (*InMemoryStore)(nil)  // Compile-time check
```

### エラー経路のテスト

エラーを返す経路は可能な限りすべてテストする。
エラーメッセージが意味のある内容になっているかを確認し、wrap と unwrap も検証する。

```go
if !errors.Is(err, ErrNotFound) {
    t.Errorf("expected ErrNotFound, got %v", err)
}
```

## 手順

1. **プロジェクトの文脈を読む**：プロジェクトの `CLAUDE.md` から、規約、コーディング標準、テストの慣行、固有の要件を把握する。
2. **対象のコードを読む**：関数シグネチャ、型、依存関係、公開と非公開の別、外部依存（データベース、外部サービス）の有無を確認する。
3. **既存のパターンを確認する**：同じパッケージの既存テスト、すでに使われているアサーションライブラリ、プロジェクト固有のテストヘルパーやフィクスチャ、Makefile のテストターゲットを調べる。
4. **テストを書く**：`package_test` 宣言、グループ分けした import（標準、サードパーティ、内部）、パラメータ数に応じたパターン、説明的な名前、適切な位置の `t.Parallel()`。
5. **検証する**：コンパイルが通り、`go test` でそのまま実行できることを確認する。

## チェックリスト

書き終えたら次を確認する。

- [ ] コンパイルが通る
- [ ] テスト関数名が `Test` で始まる
- [ ] パッケージ名が `_test` サフィックス付きである
- [ ] import が正しくグループ分けされている
- [ ] 適切な位置に `t.Parallel()` がある
- [ ] AAA パターンに従い、空行で区切られていて、`// Arrange` `// Act` `// Assert` のコメントがない
- [ ] テストケース名が説明的である
- [ ] 失敗時のメッセージが明確である
- [ ] `t.Cleanup()` で後始末をしている
- [ ] `go test` でそのまま実行できる
- [ ] パターンの選択が正しい（5個以下なら単一関数、6個以上なら分割）
- [ ] 分割した場合、役割が守られている
  - [ ] `TestXXX`：`expected` のみを持ち、エラー検証をしない
  - [ ] `TestXXXError`：エラーのみを検証し、正常時の戻り値を検証しない

## 補足

- コメントは最小限にする。テスト名それ自体が説明になるようにする。
- 既存のテストのパターンに合わせる。
- `package_test` を使い、公開 API 経由のテストを徹底する。
- 複雑なマッチャーより単純なアサーションを選ぶ。
- 正常系と異常系の両方を含める。
