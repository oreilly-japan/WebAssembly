(module
  (type $type0 (func (param i32) (result i32)))

  (memory 1)

  (export "memory" (memory 0))
  (export "GetStringLength" (func 0))
  
  (func (param $param i32) (result i32)
    (local $count i32)
    (local $position i32)

    i32.const 0
    local.set $count
    
    local.get $param
    local.set $position
        
    loop $while
      local.get $position
      i32.load8_s

      i32.const 0
      i32.ne
      if
        local.get $count
        i32.const 1
        i32.add
        local.set $count
    
        local.get $position
        i32.const 1
        i32.add
        local.set $position
    
        br $while
      end
    end
    
    local.get $count
  )
)
