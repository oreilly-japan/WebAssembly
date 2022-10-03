(module
  ;;==========
  ;; Types
  ;;----------
  ;; WebAssemblyに定義する関数とインポート関数の関数シグネチャ
  (type $FUNCSIG$v (func))
  (type $FUNCSIG$vi (func (param i32)))
  (type $FUNCSIG$vii (func (param i32 i32))) 
  (type $FUNCSIG$viii (func (param i32 i32 i32))) 
  (type $FUNCSIG$viiii (func (param i32 i32 i32 i32))) 
  (type $FUNCSIG$ii (func (param i32) (result i32)))
  (type $FUNCSIG$iii (func (param i32 i32) (result i32))) 

  ;;==========
  ;; Imports
  ;;----------
  ;; JavaScriptのコードからインポートされる関数
  (import "env" "_GenerateCards" (func $GenerateCards (param i32 i32 i32)))
  (import "env" "_FlipCard" (func $FlipCard (param i32 i32 i32)))
  (import "env" "_RemoveCards" (func $RemoveCards (param i32 i32 i32 i32)))
  (import "env" "_LevelComplete" (func $LevelComplete (param i32 i32)))
  (import "env" "_Pause" (func $Pause (param i32 i32)))

  ;; メモリの設定とEmscriptenが生成するWebAssemblyモジュールからインポートする関数の定義
  (import "env" "memory" (memory $memory 256))
  (import "env" "_SeedRandomNumberGenerator" (func $SeedRandomNumberGenerator))
  (import "env" "_GetRandomNumber" (func $GetRandomNumber (param i32) (result i32)))
  (import "env" "_malloc" (func $malloc (param i32) (result i32)))
  (import "env" "_free" (func $free (param i32)))

  ;;==========
  ;; Globals
  ;;----------
  ;; レベルは6まで作成できるがInitializeRowsAndColumns関数の実装を
  ;; 簡単にするために3とする
  (global $MAX_LEVEL i32 (i32.const 3))

  ;; 各カードの値を表す配列
  (global $cards (mut i32) (i32.const 0))

  ;; ゲームのレベルの情報
  (global $current_level (mut i32) (i32.const 0))
  (global $rows (mut i32) (i32.const 0))
  (global $columns (mut i32) (i32.const 0))
  (global $matches_remaining (mut i32) (i32.const 0))

  ;; クリックしたカードの情報
  (global $first_card_row (mut i32) (i32.const 0))
  (global $first_card_column (mut i32) (i32.const 0))
  (global $first_card_value (mut i32) (i32.const 0))
  (global $second_card_row (mut i32) (i32.const 0))
  (global $second_card_column (mut i32) (i32.const 0))
  (global $second_card_value (mut i32) (i32.const 0))

  ;; 2枚目のカードを開いた後にカードを消したり裏返しにしたりするまでに
  ;; プレイヤがカードの内容を確認できるように一時停止する
  ;; 一時停止中はカードをクリックできないようにする 
  ;; 1がtrueで0がfalseである
  (global $execution_paused (mut i32) (i32.const 0))

  ;;==========
  ;; Exports
  ;;----------
  (export "_CardSelected" (func $CardSelected))
  (export "_SecondCardSelectedCallback" (func $SecondCardSelectedCallback))
  (export "_ReplayLevel" (func $ReplayLevel))
  (export "_PlayNextLevel" (func $PlayNextLevel))

  ;;==========
  ;; Start
  ;;----------
  (start $main)

  ;;==========
  ;; Code
  ;;----------
  ;; WebAssemblyのテキスト形式では関数の宣言と本体の定義を一つにまとめる

  (func $InitializeRowsAndColumns (param $level i32)
    ;; レベル1の設定
    (if
      (i32.eq
        (local.get $level)
        (i32.const 1)
      )
      (then
        (global.set $rows (i32.const 2))
        (global.set $columns (i32.const 2))
      )
    )

    ;; レベル2の設定
    (if
      (i32.eq
        (local.get $level)
        (i32.const 2)
      )
      (then
        (global.set $rows (i32.const 2))
        (global.set $columns (i32.const 3))
      )
    )

    ;; レベル3の設定
    (if
      (i32.eq
        (local.get $level)
        (i32.const 3)
      )
      (then
        (global.set $rows (i32.const 2))
        (global.set $columns (i32.const 4))
      )
    )
  )

  (func $ResetSelectedCardValues
    ;; 最初にクリックされたカードの値をリセットする
    (global.set $first_card_row
      (i32.const -1)
    )
    (global.set $first_card_column
      (i32.const -1)
    )
    (global.set $first_card_value
      (i32.const -1)
    )

    ;; 2番目にクリックされたカードの値をリセットする
    (global.set $second_card_row
      (i32.const -1)
    )
    (global.set $second_card_column
      (i32.const -1)
    )
    (global.set $second_card_value
      (i32.const -1)
    )
  )

  (func $InitializeCards (param $level i32)
    (local $count i32)

    ;; 要求されたレベルを保存してグローバル変数rowsとcolumnsの値を
    ;; 適切な値に設定する
    (global.set $current_level
      (local.get $level)
    )
    (call $InitializeRowsAndColumns
      (local.get $level)
    )

    ;; カードの値を確実にリセットする
    (call $ResetSelectedCardValues)

    ;; レベルに応じてカードの組と数を設定する
    (local.set $count
      (i32.mul
        (global.get $rows)
        (global.get $columns)
      )
    )

    (global.set $matches_remaining
      (i32.div_s
        (local.get $count)
        (i32.const 2)
      )
    )

    ;; カードに必要なメモリを割り当ててそのポインタを変数$cardsに設定する
    ;; WebAssemblyではポインタはi32型である
    (global.set $cards
      (call $malloc
        (i32.shl ;; カード1枚につき4バイトのメモリが必要なので2つ左シフトする（つまり4倍）
          (local.get $count)
          (i32.const 2)
        )
      )
    )

    ;; 値の組（例えば0, 0, 1, 1, 2, 2）で配列を埋める
    (call $PopulateArray
      (local.get $count)
    )

    ;; 配列をシャッフルする
    (call $ShuffleArray
      (local.get $count)
    )
  )

  (func $PopulateArray (param $array_length i32)
    (local $index i32)
    (local $card_value i32)

    (local.set $index
      (i32.const 0)
    )
    (local.set $card_value
      (i32.const 0)
    )

    ;; ループ処理で配列を値の組（例えば0, 0, 1, 1, 2, 2）で埋める
    (loop $while-populate
      ;; 変数$indexの値を変数$card_valueに設定する
      (i32.store
        (call $GetMemoryLocationFromIndex
          (local.get $index)
        )
        (local.get $card_value)
      )

      ;; 次の配列のために変数$indexの値をインクリメントする
      (local.set $index
        (i32.add
          (local.get $index)
          (i32.const 1)
        )
      )

      ;; 変数$indexの値を変数$card_valueに設定する
      (i32.store
        (call $GetMemoryLocationFromIndex
          (local.get $index)
        )
        (local.get $card_value)
      )
    
      ;; 次のループ処理のために$card_valueの値をインクリメントする
      (local.set $card_value
        (i32.add
          (local.get $card_value)
          (i32.const 1)
        )
      )

      ;; 次のループ処理のために$indexの値をインクリメントする
      (local.set $index
        (i32.add
          (local.get $index)
          (i32.const 1)
        )
      )

      ;; 配列の末尾でなければ次のループ処理を実行する
      (if
        (i32.lt_s
          (local.get $index)
          (local.get $array_length)
        )
        (then
          (br $while-populate)
        )
      )
    )
  )

  ;; 変数$cardsに保存されているポインタが指すメモリ領域中でのオフセットを
  ;; 指定されたインデックスに基づき決定して返す
  (func $GetMemoryLocationFromIndex (param $index i32) (result i32)
    ;; 変数$cardsに保存されているポインタを基準にインデックスの値を調整する
    (i32.add
      (global.get $cards)
      ;; 各インデックスの位置は32ビット整数で表現されるため
      ;; 変数$indexの値を2つ左シフトする（つまり4倍）
      (i32.shl
        (local.get $index)
        (i32.const 2)
      )
    )
  )

  (func $ShuffleArray (param $array_length i32)
    (local $index i32)
    (local $memory_location1 i32)
    (local $memory_location2 i32)
    (local $card_to_swap i32)
    (local $card_value i32)

    (call $SeedRandomNumberGenerator)

    ;; 以下のループ処理は配列の末尾から先頭に向かって実行する
    (local.set $index
      (i32.sub
        (local.get $array_length)
        (i32.const 1)
      )
    )

    ;; Fisher-Yatesのシャッフルを用いてカードをシャッフルする
    ;; https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle
    (loop $while-shuffle
      ;; 交換するカードのインデックスをランダムに決定して変数$card_to_swapに保存する
      (local.set $card_to_swap
        (call $GetRandomNumber
          (i32.add
            (local.get $index)
            (i32.const 1)
          )
        )
      )

      ;; 変数$index指定されているカードの値が保存されているメモリの位置を
      ;; 変数$memory_location1に設定する
      (local.set $memory_location1
        (call $GetMemoryLocationFromIndex
          (local.get $index)
        )
      )

      ;; 変数$card_to_swapで指定されているカードの値が保存されているメモリの位置を
      ;; 変数$memory_location2に設定する
      (local.set $memory_location2
        (call $GetMemoryLocationFromIndex
          (local.get $card_to_swap)
        )
      )

      ;; 変数$memory_location1で指定されるメモリの位置から
      ;; カードの値を読み取り変数$card_valueに保存する
      (local.set $card_value
        (i32.load
          (local.get $memory_location1)
        )
      )

      ;; 変数$card_to_swapに指定されたインデックスのカードの値を
      ;; 変数$memory_location1で指定されるメモリの位置に書き込む
      (i32.store
        (local.get $memory_location1)
        (i32.load
          (local.get $memory_location2)
        )
      )

      ;; 変数$card_to_swapで指定されたカードの値が保存されているメモリ領域に
      ;; 変数$indexで指定されたカードの値を書き込む
      (i32.store
        (local.get $memory_location2)
        (local.get $card_value)
      )

      ;; 次のループ処理のために変数$indexの値をデクリメントする
      (local.set $index
        (i32.sub
          (local.get $index)
          (i32.const 1)
        )
      )

      ;; 変数$indexの値が0でなければ次のループ処理を実行する
      (if
        (i32.gt_s
          (local.get $index)
          (i32.const 0)
        )
        (then
          (br $while-shuffle)
        )
      ) 
    )
  )

  (func $PlayLevel (param $level i32)
    (call $InitializeCards
      (local.get $level)
    )

    (call $GenerateCards
      (global.get $rows)
      (global.get $columns)
      (local.get $level)
    )
  )

  (func $GetCardValue (param $row i32) (param $column i32) (result i32)
    (local $index i32)
    (local $value i32)

    ;; 次の計算式から得られる配列$cards中のカードのインデックス：
    ;; row * columns + column
    (local.set $index
      (i32.mul
        (local.get $row)
        (global.get $columns)
      )
    )
    (local.set $index
      (i32.add
        (local.get $index)
        (local.get $column)
      )
    )

    ;; カードの値は32ビット整数で表現されるポインタが指すメモリのインデックスである
    ;; そのインデックスはカードの配列内を指している
    ;; インデックスの位置をカードの配列が保存されているメモリ領域の位置に基づき調整する必要がある
    (local.set $index
      (i32.add
        (i32.shl ;; 変数$indexの値を2つ左シフトする（つまり4倍）
          (local.get $index)
          (i32.const 2)
        )
        (global.get $cards)
      )
    )

    ;; メモリからカードの値を読み取る
    (local.set $value
      (i32.load
        (local.get $index)
      )
    )

    ;; 読み取ったカードの値を戻り値としてスタックに残す
    (local.get $value)
  )

  (func $CardSelected (param $row i32) (param $column i32)
    (local $card_value i32)

    ;; 一時停止中はクリックを無視する
    (if
      (i32.eq
        (global.get $execution_paused)
        (i32.const 1)
      )
      (then
        (return)
      )
    )

    ;; UIにカードの表示を指示する
    (local.set $card_value
      (call $GetCardValue
        (local.get $row)
        (local.get $column)
      )
    )
    (call $FlipCard
      (local.get $row)
      (local.get $column)
      (local.get $card_value)
    )

    ;; カードがクリックされていない場合の処理
    (if
      (i32.eq
        (global.get $first_card_row)
        (i32.const -1)
      )
      (then
        ;; クリックされたカードの情報を保存する
        (global.set $first_card_row
          (local.get $row)
        )
        (global.set $first_card_column
          (local.get $column)
        )
        (global.set $first_card_value
          (local.get $card_value)
        )
      )
      (else ;; 2番目のカードがクリックされた場合の処理
        ;; 最初にクリックされたカードであるかどうかを確認する
        (if
          (call $IsFirstCard
            (local.get $row)
            (local.get $column)
          )
          (then
            (return)
          )
        )

        ;; 2番目のカードの情報を保存する
        (global.set $second_card_row
          (local.get $row)
        )
        (global.set $second_card_column
          (local.get $column)
        )
        (global.set $second_card_value
          (local.get $card_value)
        )

        ;; Pause関数の処理が終了するまでクリックを無視する
        (global.set $execution_paused
          (i32.const 1)
        )

        ;; クリックされたカードの表を十分な時間だけ表示するために
        ;; Pause関数を呼び出す
        ;; 一定の時間が経過するとUIは指定した関数を呼び出す
        (call $Pause
          (i32.const 5120) ;; 「SecondCardSelectedCallback」という文字列が保存されているメモリの位置
          (i32.const 600)
        )
      )
    )
  )

  (func $IsFirstCard (param $row i32) (param $column i32) (result i32)
    (local $rows_equal i32)
    (local $columns_equal i32)

    ;; 最初にクリックされたカードの行番号と一致するか確認する
    (local.set $rows_equal
      (i32.eq
        (global.get $first_card_row)
        (local.get $row)
      )
    )

    ;; 最初にクリックされたカードの列番号と一致するか確認する
    (local.set $columns_equal
      (i32.eq
        (global.get $first_card_column)
        (local.get $column)
      )
    )

    (i32.and
      (local.get $rows_equal)
      (local.get $columns_equal)
    )
  )

  (func $SecondCardSelectedCallback
    (local $is_last_level i32)

    ;; 選択したカードが一致した場合の処理
    (if
      (i32.eq
        (global.get $first_card_value)
        (global.get $second_card_value)
      )
      (then
        (call $RemoveCards
          (global.get $first_card_row)
          (global.get $first_card_column)
          (global.get $second_card_row)
          (global.get $second_card_column)
        )

        ;; 変数$matches_remainingの値をデクリメントする
        (global.set $matches_remaining
          (i32.sub
            (global.get $matches_remaining)
            (i32.const 1)
          )
        )
      )
      (else
        ;; カードを裏返しにする
        (call $FlipCard
          (global.get $first_card_row)
          (global.get $first_card_column)
          (i32.const -1)
        )
        (call $FlipCard
          (global.get $second_card_row)
          (global.get $second_card_column)
          (i32.const -1)
        )
      )
    )

    ;; 選択されたカードを確実に初期化する
    (call $ResetSelectedCardValues)

    ;; カードが選択できるようにするためにフラグを初期化する
    (global.set $execution_paused
      (i32.const 0)
    )

    ;; カードが残っていない場合は次のレベルに進む
    (if
      (i32.eq
        (global.get $matches_remaining)
        (i32.const 0)
      )
      (then
        ;; 使用したメモリを解放する
        (call $free
          (global.get $cards)
        )

        ;; レベルが最高レベルであるかを確認する
        (local.set $is_last_level
          (i32.lt_s
            (global.get $current_level)
            (global.get $MAX_LEVEL)
          )
        )

        ;; レベルのクリアと次のレベルの有無を知らせる
        (call $LevelComplete
          (global.get $current_level)
          (local.get $is_last_level)
        )
      )
    )
  )

  (func $ReplayLevel
    (call $PlayLevel
      (global.get $current_level)
    )
  )

  (func $PlayNextLevel
    (call $PlayLevel
      (i32.add
        (global.get $current_level)
        (i32.const 1)
      )
    )
  )

  (func $main
    (call $PlayLevel 
      (i32.const 1)
    )
  )

  ;;==========
  ;; Data
  ;;----------
  (data (i32.const 5120) "SecondCardSelectedCallback")
)