#include <cstdlib>
#include <cstdio>

#ifdef __EMSCRIPTEN__
  #include <emscripten.h>
#endif

#ifdef __cplusplus
extern "C" { // C++としてビルドする場合にエクスポート関数の名前が変更されてしまうのを防ぐ
#endif

  // JavaScriptのコードで作成される関数シグネチャを定義する
  extern int IsOnline();

int main()
{
  printf("Are we online? %s\n", (IsOnline() == 1 ? "Yes" : "No"));  

  return 0;
}

#ifdef __cplusplus
}
#endif