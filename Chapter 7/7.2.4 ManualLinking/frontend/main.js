// find_primes.wasmの_FindPrimesメソッドにより呼び出される関数
function logPrime(prime) {
  console.log(prime.toString());
}

const isPrimeImportObject = { };

// まずはサイドモジュールis_prime.wasmを読み込む
WebAssembly.instantiateStreaming(fetch("is_prime.wasm"), isPrimeImportObject)
.then(module => {
  // 続けてサイドモジュールfind_primes.wasmを読み込みis_primeモジュールからIsPrimeメソッドを渡す
  const findPrimesImportObject = {
    env: {
      IsPrime: module.instance.exports.IsPrime,
      LogPrime: logPrime,
    }
  };

  return WebAssembly.instantiateStreaming(fetch("find_primes.wasm"), findPrimesImportObject);

})
.then(module => {
  module.instance.exports.FindPrimes(3, 100);
});
