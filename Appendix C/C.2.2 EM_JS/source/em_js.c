#include <emscripten.h>

// 戻り値を持たずint型とdouble型のパラメータを持つ
EM_JS(void, NoReturnValueWithIntegerAndDoubleParameters, (int integer_value, double double_value), {
  console.log("NoReturnValueWithIntegerAndDoubleParameters called...integer_value: " +
      integer_value.toString() + "  double_value: " + double_value.toString());
});

int main()
{
  NoReturnValueWithIntegerAndDoubleParameters(1, 5.49);
  return 0;
}
