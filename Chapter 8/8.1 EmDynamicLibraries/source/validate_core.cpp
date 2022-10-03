#include <cstdlib>

#ifdef __EMSCRIPTEN__
  #include <emscripten.h>
#endif

#ifdef __cplusplus
extern "C" { // C++としてビルドする場合にエクスポート関数の名前が変更されてしまうのを防ぐ
#endif

  // JavaScriptのコードからインポートする関数
  extern void UpdateHostAboutError(const char* error_message);

#ifdef __EMSCRIPTEN__
  EMSCRIPTEN_KEEPALIVE
#endif
  int ValidateValueProvided(const char* value, const char* error_message)
  {
    // 値がNULLまたは先頭バイトがNullバイトである場合は空の文字列が入力されたと判別する
    if ((value == NULL) || (value[0] == '\0'))
    {
      UpdateHostAboutError(error_message);
      return 0;
    }

    // 検証の通過を示す戻り値を返す
    return 1;
  }

#ifdef __EMSCRIPTEN__
  EMSCRIPTEN_KEEPALIVE
#endif
  int IsIdInArray(char* selected_id, int* valid_ids, int array_length)
  {
    // 正しいIDが保存された配列に指定したIDが含まれているかを検証する
    int id = atoi(selected_id);
    for (int index = 0; index < array_length; index++)
    {
      // 配列に含まれているIDと指定したIDが一致するかを確認する
      if (valid_ids[index] == id)
      {
        // 指定されたIDが正しいことを示す戻り値を返す
        return 1;
      }
    }

    // 指定されたIDが正しいIDとして登録されていないことを示す戻り値を返す
    return 0;
  }

#ifdef __cplusplus
}
#endif
