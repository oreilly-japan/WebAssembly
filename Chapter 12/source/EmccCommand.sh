#!/bin/bash
emcc main.cpp -s "EXPORTED_FUNCTIONS=['_malloc','_free']" -o main.js