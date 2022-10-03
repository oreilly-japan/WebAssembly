#include <emscripten.h>

// 戻り値とパラメータを持たない
EM_JS(void, NoReturnValueWithNoParameters, (), {
  console.log("NoReturnValueWithNoParameters called");
});

int main()
{
  NoReturnValueWithNoParameters();
  return 0;
}