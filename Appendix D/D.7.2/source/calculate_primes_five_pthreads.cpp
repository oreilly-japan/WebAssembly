#include <cstdlib>
#include <cstdio>
#include <vector>
#include <chrono>
#include <pthread.h>
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
  // 偶数が入力された場合はインクリメントして奇数にする
  if (start % 2 == 0) { start++; }

  // 偶数が素数でないことは明らかであるため奇数のみを判別する
  for (int i = start; i <= end; i += 2)
  {
    // 素数である場合はブラウザのコンソールに出力する
    if (IsPrime(i))
    {
      primes_found.push_back(i);
    }
  }
}

struct thread_args 
{
  int start;
  int end;
  std::vector<int> primes_found;
};

void* thread_func(void* arg) 
{
   struct thread_args* args = (struct thread_args*)arg;

   FindPrimes(args->start, args->end, args->primes_found);

   return arg;
}

int main() 
{
  int start = 0, end = 1000000;
  printf("Prime numbers between %d and %d:\n", start, end);

  // 「clock_t start = clock()」は各スレッドが使用するCPU時間を含むCPUクロックを返すため使用しない
  // 我々が知りたいのはコードでの処理にかかった時間である
  std::chrono::high_resolution_clock::time_point duration_start = std::chrono::high_resolution_clock::now();


  // スレッドを処理しやすくするためにスレッドのIDを保存するための配列を作成する
  // 各スレッドに渡す引数の配列も作成する
  // （メインスレッドでも計算処理をするためスレッド数である4よりも1大きい値を指定する）
  pthread_t thread_ids[5];
  struct thread_args args[5];

  int args_start = 0;

  // 各スレッドを起動する
  for (int i = 0; i < 5; i++) {
    // スレッドで処理する数値の範囲を設定する
    args[i].start = args_start;
    args[i].end = (args_start + 199999);

    // スレッドを開始する
    if (pthread_create(&thread_ids[i], NULL, thread_func, &args[i]))
    {
      perror("Thread create failed");
      return 1;
    }

    // 次のスレッドのために変数の値を増加させる
    args_start += 200000;
  }

  // 全てのスレッドが終了するまで待機する
  for (int j = 0; j < 5; j++)
  {
    pthread_join(thread_ids[j], NULL);
  }


  std::chrono::high_resolution_clock::time_point duration_end = std::chrono::high_resolution_clock::now();
  std::chrono::duration<double, std::milli> duration = (duration_end - duration_start);

  printf("FindPrimes took %f milliseconds to execute\n", duration.count());

  // 変数kの値が5未満の間はループ処理を実行し、検出した素数を出力する
  printf("The values found:\n");
  for (int k = 0; k < 5; k++)
  {
    for(int n : args[k].primes_found) 
    {
      printf("%d ", n);
    }
  }
  printf("\n");

  return 0; 
}

#ifdef __cplusplus
}
#endif