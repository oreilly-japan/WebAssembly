#include <cstdlib>
#include <cstdio>
#include <emscripten.h>

#ifdef __cplusplus
extern "C" { // C++としてビルドする場合にエクスポート関数の名前が変更されてしまうのを防ぐ
#endif

int IsPrime(int value) 
{
  // 2が指定された場合は素数として判別（2は素数で唯一の偶数）
  if (value == 2) { return 1; }

  // 1より小さいまたは2で割り切れる数字は素数ではない
  if (value <= 1 || value % 2 == 0) { return 0; }

  // 素数は1かその数自身でしか割り切れない数であるため1と2は飛ばす
  // 指定された数の平方根までの奇数で割り切れるかを確認する
  for (int i = 3; (i * i) <= value; i += 2) 
  {
    // 指定された数が割り切れた場合は素数ではない
    if (value % i == 0) { return 0; }
  }

  // どの数でも割り切れなかった場合は素数である
  return 1; 
}

// 動的リンクにより呼び出し可能となる関数
EMSCRIPTEN_KEEPALIVE
void FindPrimes(int start, int end)
{
  printf("Prime numbers between %d and %d:\n", start, end);

  // 偶数が素数でないことは明らかであるため奇数のみを判別する
  for (int i = start; i <= end; i += 2)
  {
    // 素数である場合はコンソールに出力する
    if (IsPrime(i))
    {
      printf("%d ", i);
    }
  }
  printf("\n");
}

// メインのWebAssemblyモジュールとして使用する場合のためにmain関数を定義する
int main() 
{
  FindPrimes(3, 100000);

  return 0; 
}

#ifdef __cplusplus
}
#endif