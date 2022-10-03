#include <emscripten.h>

EMSCRIPTEN_KEEPALIVE
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