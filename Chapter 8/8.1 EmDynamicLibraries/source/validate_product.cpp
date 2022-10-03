#include <cstdlib>
#include <cstring>

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
  int ValidateName(char* name, int maximum_length)
  {
    // 検証1：商品名が指定されているか？
    if (ValidateValueProvided(name, "A Product Name must be provided.") == 0)
    {
      return 0;
    }

    // 検証2：商品名の文字列の長さが制限を超えていないか？
    if (strlen(name) > maximum_length)
    {
      UpdateHostAboutError("The Product Name is too long.");
      return 0;
    }

    // 検証の通過を示す戻り値を返す
    return 1;
  }

#ifdef __EMSCRIPTEN__
  EMSCRIPTEN_KEEPALIVE
#endif
  int ValidateCategory(char* category_id, int* valid_category_ids, int array_length)
  {
    // 検証1：カテゴリIDが指定されているか？
    if (ValidateValueProvided(category_id, "A Product Category must be selected.") == 0)
    {
      return 0;
    }

    // 検証2：正しいカテゴリIDが保存された配列が指定されているか？
    if ((valid_category_ids == NULL) || (array_length == 0))
    {
      UpdateHostAboutError("There are no Product Categories available.");
      return 0;
    }

    // 検証3：指定されたカテゴリIDは正しいカテゴリIDか？
    if (IsIdInArray(category_id, valid_category_ids, array_length) == 0)
    {
      UpdateHostAboutError("The selected Product Category is not valid.");
      return 0;
    }

    // 検証の通過を示す戻り値を返す
    return 1;
  }

#ifdef __cplusplus
}
#endif
