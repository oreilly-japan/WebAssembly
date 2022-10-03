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
  (import "env" "_GenerateCards" (func $GenerateCards (param i32 i32 i32 i32)))
  (import "env" "_UpdateTriesTotal" (func $UpdateTriesTotal (param i32)))
  (import "env" "_FlipCard" (func $FlipCard (param i32 i32 i32)))
  (import "env" "_RemoveCards" (func $RemoveCards (param i32 i32 i32 i32)))
  (import "env" "_LevelComplete" (func $LevelComplete (param i32 i32 i32)))
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
  (global $tries (mut i32) (i32.const 0))

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
    local.get $level
    i32.const 1
    i32.eq
    if
      i32.const 2
      global.set $rows

      i32.const 2
      global.set $columns
    end

    ;; レベル2の設定
    local.get $level
    i32.const 2
    i32.eq
    if
      i32.const 2
      global.set $rows

      i32.const 3
      global.set $columns
    end

    ;; レベル3の設定
    local.get $level
    i32.const 3
    i32.eq
    if
      i32.const 2
      global.set $rows

      i32.const 4
      global.set $columns
    end
  )

  (func $ResetSelectedCardValues
    ;; 最初にクリックされたカードの値をリセットする
    i32.const -1
    global.set $first_card_row

    i32.const -1
    global.set $first_card_column

    i32.const -1
    global.set $first_card_value

    ;; 2番目にクリックされたカードの値をリセットする
    i32.const -1
    global.set $second_card_row

    i32.const -1
    global.set $second_card_column

    i32.const -1
    global.set $second_card_value
  )

  (func $InitializeCards (param $level i32)
    (local $count i32)

    ;; 要求されたレベルを保存してグローバル変数rowsとcolumnsの値を
    ;; 適切な値に設定する
    local.get $level
    global.set $current_level
    
    local.get $level
    call $InitializeRowsAndColumns
    
    ;; カードの値を確実にリセットする
    call $ResetSelectedCardValues

    ;; レベルに応じてカードの組と数を設定する
    global.get $rows
    global.get $columns
    i32.mul
    local.set $count
    
    local.get $count
    i32.const 2
    i32.div_s
    global.set $matches_remaining

    ;; カードに必要なメモリを割り当ててそのポインタを変数$cardsに設定する
    ;; WebAssemblyではポインタはi32型である
    local.get $count
    i32.const 2
    i32.shl ;; カード1枚につき4バイトのメモリが必要なので2つ左シフトする（つまり4倍）
    call $malloc
    global.set $cards

    ;; 値の組（例えば0, 0, 1, 1, 2, 2）で配列を埋める
    local.get $count
    call $PopulateArray

    ;; 配列をシャッフルする
    local.get $count
    call $ShuffleArray

    global.get 6
    global.set $tries
  )

  (func $PopulateArray (param $array_length i32)
    (local $index i32)
    (local $card_value i32)

    ;; ループ処理に使用する変数を初期化する
    i32.const 0
    local.set $index
    
    i32.const 0
    local.set $card_value
    
    ;; ループ処理で配列を値の組（例えば0, 0, 1, 1, 2, 2）で埋める
    loop $while-populate
      ;; 変数$indexの値を変数$card_valueに設定する
      local.get $index
      call $GetMemoryLocationFromIndex
      local.get $card_value
      i32.store ;; 変数$card_valueの値をメモリに保存する
      
      ;; 次の配列のために変数$indexの値をインクリメントする
      local.get $index
      i32.const 1
      i32.add
      local.set $index
      
      ;; 変数$indexの値を変数$card_valueに設定する
      local.get $index
      call $GetMemoryLocationFromIndex
      local.get $card_value
      i32.store ;; 変数$card_valueの値をメモリに保存する
    
      ;; 次のループ処理のために$card_valueの値をインクリメントする
      local.get $card_value
      i32.const 1
      i32.add
      local.set $card_value
      
      ;; 次のループ処理のために$indexの値をインクリメントする
      local.get $index
      i32.const 1
      i32.add
      local.set $index

      ;; 配列の末尾でなければ次のループ処理を実行する
      local.get $index
      local.get $array_length
      i32.lt_s
      if
        br $while-populate
      end
    end $while-populate
  )

  ;; 変数$cardsに保存されているポインタが指すメモリ領域中でのオフセットを
  ;; 指定されたインデックスに基づき決定して返す
  (func $GetMemoryLocationFromIndex (param $index i32) (result i32)
    ;; 各インデックスの位置は32ビット整数で表現されるため
    ;; 変数$indexの値を2つ左シフトする（つまり4倍）
    local.get $index
    i32.const 2
    i32.shl

    ;; 変数$cardsの値を基準にインデックスの値を調整する
    global.get $cards
    i32.add
  )

  (func $ShuffleArray (param $array_length i32)
    (local $index i32)
    (local $memory_location1 i32)
    (local $memory_location2 i32)
    (local $card_to_swap i32)
    (local $card_value i32)

    call $SeedRandomNumberGenerator

    ;; 以下のループ処理は配列の末尾から先頭に向かって実行する
    local.get $array_length
    i32.const 1
    i32.sub
    local.set $index
    
    ;; Fisher-Yatesのシャッフルを用いてカードをシャッフルする
    ;; https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle
    loop $while-shuffle
      ;; 交換するカードのインデックスをランダムに決定して変数$card_to_swapに保存する
      local.get $index
      i32.const 1
      i32.add
      call $GetRandomNumber
      local.set $card_to_swap
      
      ;; 変数$indexで指定されているカードの値が保存されているメモリの位置を
      ;; 変数$memory_location1に設定する
      local.get $index
      call $GetMemoryLocationFromIndex
      local.set $memory_location1
      
      ;; 変数$card_to_swapで指定されているカードの値が保存されているメモリの位置を
      ;; 変数$memory_location2に設定する
      local.get $card_to_swap
      call $GetMemoryLocationFromIndex
      local.set $memory_location2

      ;; 変数$memory_location1で指定されるメモリの位置から
      ;; カードの値を読み取り変数$card_valueに保存する
      local.get $memory_location1
      i32.load
      local.set $card_value
      
      ;; 変数$card_to_swapで指定されたインデックスのカードの値を
      ;; 変数$memory_location1で指定されるメモリの位置に書き込む
      local.get $memory_location1 ;; 変数$memory_location1には変数$indexで指定されるカードの値が保存されているメモリ領域のアドレスが格納されている
      local.get $memory_location2 ;; 変数$memory_location2には変数$card_to_swapで指定されるカードの値が保存されているメモリ領域のアドレスが格納されている
      i32.load ;; 変数$card_to_swapで指定されたインデックスのカードの値を読み取ってスタックに配置する
      i32.store ;; スタックに配置された変数$card_to_swapの値を変数$memory_location1が示す位置のメモリに書き込む
      
      ;; 変数$card_to_swapで指定されたカードの値が保存されているメモリ領域に
      ;; 変数$indexで指定されたカードの値を書き込む
      local.get $memory_location2
      local.get $card_value
      i32.store

      ;; 次のループ処理のために変数$indexの値をデクリメントする
      local.get $index
      i32.const 1
      i32.sub
      local.set $index

      ;; 変数$indexの値が0でなければ次のループ処理を実行する
      local.get $index
      i32.const 0
      i32.gt_s
      if
        br $while-shuffle
      end 
    end $while-shuffle
  )

  (func $PlayLevel (param $level i32)
    local.get $level
    call $InitializeCards
 
    global.get $rows
    global.get $columns
    local.get $level
    global.get $tries
    call $GenerateCards
  )

  (func $GetCardValue (param $row i32) (param $column i32) (result i32) 
    ;; 次の計算式から得られる配列$cards中のカードのインデックス：
    ;; row * columns + column
    local.get $row
    global.get $columns
    i32.mul ;; 行と列の値を積算する
    local.get $column
    i32.add ;; 列の値を加算する

    i32.const 2
    i32.shl ;; インデックスの値は32ビット整数（4バイト）で表現されるため2つ左シフトする（つまり4倍） 
    global.get $cards
    i32.add ;; 変数$cardsに保存されたポインタの位置を基にインデックスを調整する
    i32.load ;; メモリから値を読み取った値をスタックに残す
  )

  (func $CardSelected (param $row i32) (param $column i32)
    (local $card_value i32)

    ;; 一時停止中はクリックを無視する
    global.get $execution_paused
    i32.const 1
    i32.eq
    if
      return
    end

    ;; 選択されたカードの値を取得する
    local.get $row
    local.get $column
    call $GetCardValue
    local.set $card_value

    ;; UIにカードの表示を指示する
    local.get $row
    local.get $column
    local.get $card_value
    call $FlipCard

    ;; カードがクリックされていない場合の処理
    global.get $first_card_row
    i32.const -1
    i32.eq
    if
      ;; クリックされたカードの情報を保存する
      local.get $row
      global.set $first_card_row
      
      local.get $column
      global.set $first_card_column

      local.get $card_value
      global.set $first_card_value
    else ;; 2番目のカードがクリックされた場合の処理
      ;; 最初にクリックされたカードであるかどうかを確認する
      local.get $row
      local.get $column
      call $IsFirstCard
      if
        return
      end

      ;; 2番目のカードの情報を保存する
      local.get $row
      global.set $second_card_row
      
      local.get $column
      global.set $second_card_column

      local.get $card_value
      global.set $second_card_value
      
      ;; Pause関数の処理が終了するまでクリックを無視する
      i32.const 1
      global.set $execution_paused
      
      ;; クリックされたカードの表を十分な時間だけ表示するために
      ;; Pause関数を呼び出す
      ;; 一定の時間が経過するとUIは指定した関数を呼び出す
      i32.const 5120 ;; 「SecondCardSelectedCallback」という文字列が保存されているメモリの位置
      i32.const 600
      call $Pause
    end
  )

  (func $IsFirstCard (param $row i32) (param $column i32) (result i32)
    (local $rows_equal i32)
    (local $columns_equal i32)

    ;; 最初にクリックされたカードの行番号と一致するか確認する
    global.get $first_card_row
    local.get $row
    i32.eq
    local.set $rows_equal
      
    ;; 最初にクリックされたカードの列番号と一致するか確認する
    global.get $first_card_column
    local.get $column
    i32.eq
    local.set $columns_equal
      
    ;; 値が1（true）である場合は最初にクリックされたカードである
    ;; （i32.and命令はAND演算である）
    local.get $rows_equal
    local.get $columns_equal
    i32.and
  )

  (func $SecondCardSelectedCallback
    (local $is_last_level i32)

    ;; 選択したカードが一致した場合の処理
    global.get $first_card_value
    global.get $second_card_value
    i32.eq
    if
      ;; クリックされたカードを隠すようにJavaScriptのコードに指示する
      global.get $first_card_row
      global.get $first_card_column
      global.get $second_card_row
      global.get $second_card_column
      call $RemoveCards

      ;; 変数$matches_remainingの値をデクリメントする
      global.get $matches_remaining
      i32.const 1
      i32.sub
      global.set $matches_remaining
    else ;; 選択したカードが異なる場合の処理
      ;; カードを裏返しにする
      global.get $first_card_row
      global.get $first_card_column
      i32.const -1
      call $FlipCard
        
      global.get $second_card_row
      global.get $second_card_column
      i32.const -1
      call $FlipCard
    end

    ;; 試行回数をインクリメントする
    global.get $tries
    i32.const 1
    i32.add
    global.set $tries

    ;; JavaScriptのコードにUIの試行回数の表示を更新するよう指示する
    global.get $tries
    call $UpdateTriesTotal

    ;; 選択されたカードを確実に初期化する
    call $ResetSelectedCardValues

    ;; カードが選択できるようにするためにフラグを初期化する
    i32.const 0
    global.set $execution_paused

    ;; カードが残っていない場合は次のレベルに進む
    global.get $matches_remaining
    i32.const 0
    i32.eq
    if
      ;; 使用したメモリを解放する
      global.get $cards
      call $free
      
      ;; レベルが最高レベルであるかを確認する
      global.get $current_level
      global.get $MAX_LEVEL
      i32.lt_s
      local.set $is_last_level
      
      ;; レベルのクリアと次のレベルの有無を知らせる
      global.get $current_level
      global.get $tries
      local.get $is_last_level
      call $LevelComplete
    end
  )

  (func $ReplayLevel
    global.get $current_level
    call $PlayLevel
  )

  (func $PlayNextLevel
    global.get $current_level
    i32.const 1
    i32.add
    call $PlayLevel
  )

  (func $main
    i32.const 1    
    call $PlayLevel 
  )

  ;;==========
  ;; Data
  ;;----------
  (data (i32.const 5120) "SecondCardSelectedCallback")
)