#!/bin/bash
emcc validate.cpp -s RESERVED_FUNCTION_POINTERS=4 -s "EXPORTED_RUNTIME_METHODS=['ccall','UTF8ToString','addFunction','removeFunction']" -s "EXPORTED_FUNCTIONS=['_malloc','_free']" -o validate.js