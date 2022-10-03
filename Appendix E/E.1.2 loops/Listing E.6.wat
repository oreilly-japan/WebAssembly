(module
  (type $type0 (func (param i32) (result i32)))

  (memory 1)

  (export "memory" (memory 0))    
  (export "GetStringLength" (func 0))
  
  (func (param $param i32) (result i32)
    (local $count i32)
    (local $position i32)
    
    (local.set $count
      (i32.const 0)
    )
    
    (local.set $position
      (local.get $param)
    )
        
    (block $parent
      (loop $while       
        (br_if $parent
          (i32.eqz
            (i32.load8_s
              (local.get $position)
            )
          ) ;; i32.eqz
        ) ;; br_if
        
        ;; 文字数をインクリメントする
        (local.set $count
          (i32.add
            (local.get $count)
            (i32.const 1)
          )
        )
        
        ;; 位置をインクリメントする
        (local.set $position
          (i32.add
            (local.get $position)
            (i32.const 1)
          )
        )
        
        (br $while)
      ) ;; loop
    ) ;; block
    
    (local.get $count)
  ) 
)