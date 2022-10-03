let compiledModule = null;
let emscriptenModule = null;

// Web Workerを作成しメッセージを待ち受ける
const worker = new Worker("prefetch.worker.js");
worker.onmessage = function(e) {
  // グローバル変数にコンパイルされたWebAssemblyモジュールを保存する
  compiledModule = e.data;

  // EmscriptenのModuleオブジェクトの新しいインスタンスを作成し
  // コールバック関数を指定してWebAssemblyモジュールのインスタンス化を処理する
  Module({ instantiateWasm: onInstantiateWasm }).then((module) => {
    emscriptenModule = module;
  });
}

function onInstantiateWasm(importObject, successCallback) {
  // WebAssemblyモジュールをインスタンス化する
  WebAssembly.instantiate(compiledModule, importObject).then(instance =>
    // インスタンス化されたWebAssemblyモジュールをEmscriptenが生成したJavaScriptのコードに渡す
    successCallback(instance)
  ); 

  // インスタンス化処理は非同期で実行されるため空のオブジェクトを返す
  return {};
}
