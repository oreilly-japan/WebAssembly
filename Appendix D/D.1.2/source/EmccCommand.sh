#!/bin/bash
emcc side_module.c --no-entry -O1 -s "EXPORTED_FUNCTIONS=['_Increment','_Decrement']" -o side_module.wasm