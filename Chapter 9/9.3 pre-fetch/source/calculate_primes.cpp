#include <cstdlib>
#include <cstdio>
#include <vector>
#include <chrono>
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

void FindPrimes(int start, int end, std::vector<int>& primes_found)
{
  // 偶数が素数でないことは明らかであるため奇数のみを判別する
  for (int i = start; i <= end; i += 2)
  {
    // 素数である場合はコンソールに出力する
    if (IsPrime(i))
    {
      primes_found.push_back(i);
    }
  }
}

int main() 
{
  int start = 3, end = 1000000;
  printf("Prime numbers between %d and %d:\n", start, end);

  // 「clock_t start = clock()」は各スレッドが使用するCPU時間を含むCPUクロックを返すため使用しない
  // 我々が知りたいのはコードでの処理にかかった時間である
  std::chrono::high_resolution_clock::time_point duration_start = std::chrono::high_resolution_clock::now();

  std::vector<int> primes_found;
  FindPrimes(start, end, primes_found);

  std::chrono::high_resolution_clock::time_point duration_end = std::chrono::high_resolution_clock::now();
  std::chrono::duration<double, std::milli> duration = (duration_end - duration_start);

  printf("FindPrimes took %f milliseconds to execute\n", duration.count());

  printf("The values found:\n");
  for(int n : primes_found) 
  {
    printf("%d ", n);
  }
  printf("\n");

  return 0; 
}

#ifdef __cplusplus
}
#endif