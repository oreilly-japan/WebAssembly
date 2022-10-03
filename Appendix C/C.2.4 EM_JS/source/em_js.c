#include <stdlib.h>
#include <stdio.h>
#include <emscripten.h>

// 戻り値とパラメータを持たない
EM_JS(char*, StringReturnValueWithNoParameters, (), {
  const greetings = "Hello from StringReturnValueWithNoParameters";

  // 文字列の長さを調べて終端文字として追加するNULLバイトのために1を足す
  const byteCount = (Module.lengthBytesUTF8(greetings) + 1);

  // メモリを確保して文字列を保存する 
  const greetingsPointer = Module._malloc(byteCount);
  Module.stringToUTF8(greetings, greetingsPointer, byteCount);

  // ポインタを返す
  return greetingsPointer;
});

int main() 
{
  char* greetingsPointer = StringReturnValueWithNoParameters();

  printf("StringReturnValueWithNoParameters was called and it returned the following result: %s\n", greetingsPointer);

  // malloc関数を使用して確保したメモリは確実にfree関数で解放すること
  free(greetingsPointer);

  return 0;
}

