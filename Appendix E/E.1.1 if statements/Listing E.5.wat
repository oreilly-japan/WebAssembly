(module
  (type $type0 (func (param i32) (result i32)))
  (export "Test" (func 0))
  
  (func (param $param i32) (result i32)
    (local $result i32)
    
    i32.const 10
    local.set $result

    local.get $param
    i32.const 0
    i32.eq
    if
      block
        i32.const 5
        local.set $result
      end
    end

    local.get $result
  )
)