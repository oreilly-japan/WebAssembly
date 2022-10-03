#include <stdlib.h>
#include <emscripten.h>

// 戻り値を持たず文字列をパラメータとして受け入れる
// 様々な型のポインタを受け入れるが読み取り可能なメモリ領域を参照する必要がある
EM_JS(void, NoReturnValueWithStringParameter, (const char* string_pointer), {
  console.log("NoReturnValueWithStringParameter called: " +
      Module.UTF8ToString(string_pointer));
});

int main() 
{
  NoReturnValueWithStringParameter("Hello from WebAssembly");
  return 0;
}

