#!/bin/bash
emcc calculate_primes.cpp -s SIDE_MODULE=2 -O1 -o calculate_primes.wasm