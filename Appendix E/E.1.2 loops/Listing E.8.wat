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

    (loop $while
      (if
        (i32.ne
          (i32.load8_s
            (local.get $position)
          )
          (i32.const 0)
        ) ;; i32.ne
        (then
          (local.set $count
            (i32.add
              (local.get $count)
              (i32.const 1)
            )
          )
    
          (local.set $position
            (i32.add
              (local.get $position)
              (i32.const 1)
            )
          )
    
          (br $while)
        ) ;; then
      ) ;; if
    ) ;; loop
    
    (local.get $count)
  )
)
