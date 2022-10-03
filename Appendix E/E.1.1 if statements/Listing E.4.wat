(module
  (type $type0 (func (param i32) (result i32)))
  (export "Test" (func 0))
  
  (func (param $param i32) (result i32)
    (local $result i32)
    (local.set $result
      (i32.const 10)
    )
  
    (if
      (i32.eq
        (local.get $param)
        (i32.const 0)
      )
      (block
        (local.set $result
          (i32.const 5)
        )
      )
    )

    (local.get $result)
  )
)