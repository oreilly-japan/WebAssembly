#include <emscripten.h>

// 素数判定をするis_primeサイドモジュールからの関数
extern int IsPrime(int value);

// ブラウザのコンソールに素数を記録するJavaScriptのコードからの関数
extern void LogPrime(int prime);

// 動的リンクにより呼び出し可能となる関数
EMSCRIPTEN_KEEPALIVE
void FindPrimes(int start, int end)
{
  // 偶数が素数でないことは明らかであるため奇数のみを判別する
  for (int i = start; i <= end; i += 2)
  {
    // 素数である場合はコンソールに出力する
    if (IsPrime(i))
    {
      LogPrime(i);
    }
  }
}