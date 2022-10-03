const util = require('util');

const clientData = {
  name: "Women's Mid Rise Skinny Jeans",
  categoryId: "100",
};

const MAXIMUM_NAME_LENGTH = 50;
const VALID_CATEGORY_IDS = [100, 101];

let validateOnSuccessNameIndex = -1;
let validateOnSuccessCategoryIndex = -1;
let validateOnErrorNameIndex = -1;
let validateOnErrorCategoryIndex = -1;
let validateNameCallbacks = { resolve: null, reject: null };
let validateCategoryCallbacks = { resolve: null, reject: null };

let moduleMemory = null;
let moduleExports = null;
let moduleTable = null;

const fs = require('fs');
fs.readFile('validate.wasm', function(error, bytes) {
  if (error) { throw error; }

  instantiateWebAssembly(bytes);
});

function instantiateWebAssembly(bytes) {
  const importObject = {    
    wasi_snapshot_preview1 : {
      proc_exit: (value) => {}
    }
  };

  WebAssembly.instantiate(bytes, importObject).then(result => {
    moduleExports = result.instance.exports;
    moduleMemory = moduleExports.memory;
    moduleTable = moduleExports.__indirect_function_table;

    // WebAssemblyモジュールのValdiateName関数とValidateCategory関数から呼び出される
    // Success関数とError関数への関数ポインタのために作成された無名関数を保持する
    validateOnSuccessNameIndex = addToTable(() => { 
      onSuccessCallback(validateNameCallbacks);
    }, 'v');

    validateOnSuccessCategoryIndex = addToTable(() => {
      onSuccessCallback(validateCategoryCallbacks);
    }, 'v');

    validateOnErrorNameIndex = addToTable((errorMessagePointer) => {
      onErrorCallback(validateNameCallbacks, errorMessagePointer);
    }, 'vi');

    validateOnErrorCategoryIndex = addToTable((errorMessagePointer) => {
      onErrorCallback(validateCategoryCallbacks, errorMessagePointer);
    }, 'vi');

    validateData();
  });
}

function addToTable(jsFunction, signature) {
  // 新しいアイテムのインデックスを決定するためにTableオブジェクトの現在のサイズを調べる
  const index = moduleTable.length;

  // 新しい関数をテーブルに追加するためにテーブルのサイズを増やして
  // JavaScriptの関数をWebAssemblyの関数に変換する
  moduleTable.grow(1); 
  moduleTable.set(index, convertJsFunctionToWasm(jsFunction, signature));

  // 登録されたJavaScriptの関数のインデックスを呼び出し元に伝える
  return index;
}

// WebAssembly\Chapter 6\6.1.2 EmFunctionPointers\frontend\validate.jsからのコピー
// 
// 複雑に見えるが指定されたJavaScriptの関数をインポートするWebAssemblyモジュールを作成するだけであり
// 作成されたWebAssemblyモジュールはWebAssembly.Tableオブジェクトに関数をエクスポートする
//
function convertJsFunctionToWasm(func, sig) {
  // 渡された関数シグネチャにより生成されるTypeセクションを除きWebAssemblyモジュールは静的である
  var typeSection = [
    0x01, // id: TypeセクションのID,
    0x00, // length: 0（プレースホルダ）
    0x01, // count: 1
    0x60, // form: func
  ];
  var sigRet = sig.slice(0, 1);
  var sigParam = sig.slice(1);
  var typeCodes = {
    'i': 0x7f, // i32
    'j': 0x7e, // i64
    'f': 0x7d, // f32
    'd': 0x7c, // f64
  };

  // 関数のパラメータの型を示すコードを追加する
  typeSection.push(sigParam.length);
  for (var i = 0; i < sigParam.length; ++i) {
    typeSection.push(typeCodes[sigParam[i]]);
  }

  // 関数の戻り値の型を示すコードを追加する
  // MVP版のWebAssemblyでは複数の型を返さないためvoid（0）かそれ以外（1）である
  if (sigRet == 'v') {
    typeSection.push(0x00);
  } else {
    typeSection = typeSection.concat([0x01, typeCodes[sigRet]]);
  }

  // Typeセクション全体の長さをヘッダ（typeSection）に書き込む
  // （idとlengthの2バイトを除外している）
  typeSection[1] = typeSection.length - 2;

  // WebAssemblyモジュールの残りの部分は静的である
  var bytes = new Uint8Array([
    0x00, 0x61, 0x73, 0x6d, // マジック（"\0asm"）
    0x01, 0x00, 0x00, 0x00, // バージョン：1
  ].concat(typeSection, [
    0x02, 0x07, // Importセクション
      // (import "e" "f" (func 0 (type 0)))
      0x01, 0x01, 0x65, 0x01, 0x66, 0x00, 0x00,
    0x07, 0x05, // Exportセクション
      // (export "f" (func 0 (type 0)))
      0x01, 0x01, 0x66, 0x00, 0x00,
  ]));

  // 非常に小さなWebAssemblyモジュールであるため同期的にコンパイルする
  // エクスポート関数fをe.fとしてインポートする
  var module = new WebAssembly.Module(bytes);
  var instance = new WebAssembly.Instance(module, {
    e: {
      f: func
    }
  });
  var wrappedFunc = instance.exports.f;
  return wrappedFunc;
}

function onSuccessCallback(validateCallbacks) {
  // Promiseのresolveメソッドを呼び出してから関数ポインタを削除する
  validateCallbacks.resolve();
  validateCallbacks.resolve = null;
  validateCallbacks.reject = null;
}

function onErrorCallback(validateCallbacks, errorMessagePointer) {
  // WebAssemblyモジュールのメモリからエラーメッセージを読み取る
  const errorMessage = getStringFromMemory(errorMessagePointer);

  // Promiseのrejectメソッドを呼び出してから関数ポインタを削除する
  validateCallbacks.reject(errorMessage);
  validateCallbacks.resolve = null;
  validateCallbacks.reject = null;
}

function setErrorMessage(error) { console.log(error); }

function validateData() {
  Promise.all([
    validateName(clientData.name),
    validateCategory(clientData.categoryId)
  ])
  .then(() => {
    // 検証を通過した場合はデータを保存する
  })
  .catch((error) => { 
    setErrorMessage(error);
  });
}

function createPointers(isForName, resolve, reject, returnPointers) {
  // Promiseオブジェクトの関数ポインタを適切なオブジェクトに渡す
  if (isForName) {
    validateNameCallbacks.resolve = resolve;
    validateNameCallbacks.reject = reject;

    // 呼び出す関数のインデックスを返す
    returnPointers.onSuccess = validateOnSuccessNameIndex;
    returnPointers.onError = validateOnErrorNameIndex;
  } else {
    validateCategoryCallbacks.resolve = resolve;
    validateCategoryCallbacks.reject = reject;

    // 呼び出す関数のインデックスを返す
    returnPointers.onSuccess = validateOnSuccessCategoryIndex;
    returnPointers.onError = validateOnErrorCategoryIndex;
  }
}

function getStringFromMemory(memoryOffset) {
  let returnValue = "";

  const size = 256;
  const bytes = new Uint8Array(moduleMemory.buffer, memoryOffset, size);
  
  let character = "";
  for (let i = 0; i < size; i++) {
    character = String.fromCharCode(bytes[i]);
    if (character === "\0") { break;}
    
    returnValue += character;
  }

  return returnValue;
}

function copyStringToMemory(value, memoryOffset) {
  const bytes = new Uint8Array(moduleMemory.buffer);
  bytes.set(new util.TextEncoder().encode((value + "\0")), memoryOffset);
}

function validateName(name) {
  return new Promise(function(resolve, reject) {

    // 関数ポインタを作成する
    const pointers = { onSuccess: null, onError: null };
    createPointers(true, resolve, reject, pointers);

    const namePointer = moduleExports.create_buffer((name.length + 1));
    copyStringToMemory(name, namePointer);

    moduleExports.ValidateName(namePointer, MAXIMUM_NAME_LENGTH, pointers.onSuccess, pointers.onError);

    moduleExports.free_buffer(namePointer);
  });
}

function validateCategory(categoryId) {
  return new Promise(function(resolve, reject) {

    // 関数ポインタを作成する
    const pointers = { onSuccess: null, onError: null };
    createPointers(false, resolve, reject, pointers);

    const categoryIdPointer = moduleExports.create_buffer((categoryId.length + 1));
    copyStringToMemory(categoryId, categoryIdPointer);

    const arrayLength = VALID_CATEGORY_IDS.length;
    const bytesPerElement = Int32Array.BYTES_PER_ELEMENT;
    const arrayPointer = moduleExports.create_buffer((arrayLength * bytesPerElement));

    const bytesForArray = new Int32Array(moduleMemory.buffer);
    bytesForArray.set(VALID_CATEGORY_IDS, (arrayPointer / bytesPerElement));

    moduleExports.ValidateCategory(categoryIdPointer, arrayPointer, arrayLength, pointers.onSuccess, pointers.onError);

    moduleExports.free_buffer(arrayPointer);
    moduleExports.free_buffer(categoryIdPointer);
  });
}