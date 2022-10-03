#include <cstdlib>

#ifdef __EMSCRIPTEN__
  #include <emscripten.h>
#endif

#ifdef __cplusplus
extern "C" { // C++としてビルドする場合にエクスポート関数の名前が変更されてしまうのを防ぐ
#endif

  // validate_core.cppに定義されている関数：
  extern int ValidateValueProvided(const char* value, const char* error_message);
  extern int IsIdInArray(char* selected_id, int* valid_ids, int array_length);

  // JavaScriptのコードからインポートする関数
  extern void UpdateHostAboutError(const char* error_message);

#ifdef __EMSCRIPTEN__
  EMSCRIPTEN_KEEPALIVE
#endif
  int ValidateProduct(char* product_id, int* valid_product_ids, int array_length) 
  {
    // 検証1：商品IDが指定されているか？
    if (ValidateValueProvided(product_id, "A Product must be selected.") == 0) 
    {
      return 0;
    }

    // 検証2：正しい商品IDが保存された配列が指定されているか？
    if ((valid_product_ids == NULL) || (array_length == 0))
    {
      UpdateHostAboutError("There are no Products available.");
      return 0;
    }

    // 検証3：指定された商品IDは正しいカテゴリIDか？
    if (IsIdInArray(product_id, valid_product_ids, array_length) == 0)
    {
      UpdateHostAboutError("The selected Product is not valid.");
      return 0;
    }

    // 検証の通過を示す戻り値を返す
    return 1;
  }

#ifdef __EMSCRIPTEN__
  EMSCRIPTEN_KEEPALIVE
#endif
  int ValidateQuantity(char* quantity)
  {
    // 検証1：数量が指定されているか？
    if (ValidateValueProvided(quantity, "A quantity must be provided.") == 0)
    {
      return 0;
    }

    // 検証2：数量が0よりも大きい数値か？
    if (atoi(quantity) <= 0)
    {
      UpdateHostAboutError("Please enter a valid quantity.");
      return 0;
    }

    // 検証の通過を示す戻り値を返す
    return 1;
  }

#ifdef __cplusplus
}
#endif
