#include <cstdlib>
#include <cstring>

// Emscriptenがこのコードをビルドする場合はemscripten.hをインクルードする
#ifdef __EMSCRIPTEN__
  #include <emscripten.h>
#endif

#ifdef __cplusplus
extern "C" { // C++としてビルドする場合にエクスポート関数の名前が変更されてしまうのを防ぐ
#endif

  int ValidateValueProvided(const char* value, const char* error_message, char* return_error_message)
  {
    // 値がNULLまたは先頭バイトがNullバイトである場合は空の文字列が入力されたと判別する
    if ((value == NULL) || (value[0] == '\0'))
    {
      strcpy(return_error_message, error_message);
      return 0;
    }

    // 検証の通過を示す戻り値を返す
    return 1;
  }

#ifdef __EMSCRIPTEN__
  EMSCRIPTEN_KEEPALIVE
#endif
  int ValidateName(char* name, int maximum_length, char* return_error_message)
  {
    // 検証1：商品名が指定されているか？
    if (ValidateValueProvided(name, "A Product Name must be provided.", return_error_message) == 0)
    {
      return 0;
    }

    // 検証2：商品名の文字列の長さが制限を超えていないか？
    if (strlen(name) > maximum_length)
    {
      strcpy(return_error_message, "The Product Name is too long.");
      return 0;
    }

    // 検証の通過を示す戻り値を返す
    return 1;
  }

  int IsCategoryIdInArray(char* selected_category_id, int* valid_category_ids, int array_length)
  {
    // 正しいカテゴリIDが保存された配列に指定したカテゴリIDが含まれているかを検証する
    int category_id = atoi(selected_category_id);
    for (int index = 0; index < array_length; index++)
    {
      // 配列に含まれているカテゴリIDと指定したカテゴリIDが一致するかを確認する
      if (valid_category_ids[index] == category_id)
      {
        // 指定されたカテゴリIDが正しいことを示す戻り値を返す
        return 1;
      }
    }

    // 指定されたカテゴリIDが正しいカテゴリIDとして登録されていないことを示す戻り値を返す
    return 0;
  }

#ifdef __EMSCRIPTEN__
  EMSCRIPTEN_KEEPALIVE
#endif
  int ValidateCategory(char* category_id, int* valid_category_ids, int array_length, char* return_error_message)
  {
    // 検証1：カテゴリIDが指定されているか？
    if (ValidateValueProvided(category_id, "A Product Category must be selected.", return_error_message) == 0)
    {
      return 0;
    }

    // 検証2：正しいカテゴリIDが保存された配列が指定されているか？
    if ((valid_category_ids == NULL) || (array_length == 0))
    {
      strcpy(return_error_message, "There are no Product Categories available.");
      return 0;
    }

    // 検証3：指定されたカテゴリIDは正しいカテゴリIDか？
    if (IsCategoryIdInArray(category_id, valid_category_ids, array_length) == 0)
    {
      strcpy(return_error_message, "The selected Product Category is not valid.");
      return 0;
    }

    // 検証の通過を示す戻り値を返す
    return 1;
  }

#ifdef __cplusplus
}
#endif
