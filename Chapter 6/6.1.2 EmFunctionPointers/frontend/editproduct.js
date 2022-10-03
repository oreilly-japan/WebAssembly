const initialData = {
  name: "Women's Mid Rise Skinny Jeans",
  categoryId: "100",
};

const MAXIMUM_NAME_LENGTH = 50;
const VALID_CATEGORY_IDS = [100, 101];

function initializePage() {
  document.getElementById("name").value = initialData.name;

  const category = document.getElementById("category");
  const count = category.length;
  for (let index = 0; index < count; index++) {
    if (category[index].value === initialData.categoryId) {
      category.selectedIndex = index;
      break;
    }
  }
}

function getSelectedCategoryId() {
  const category = document.getElementById("category");
  const index = category.selectedIndex;
  if (index !== -1) { return category[index].value; }

  return "0";
}

function setErrorMessage(error) {
  const errorMessage = document.getElementById("errorMessage");
  errorMessage.innerText = error; 
  errorMessage.style.display = (error === "" ? "none" : "");
}

function onClickSave() {
  // 過去の検証で保存されたエラーメッセージを消去する
  setErrorMessage("");

  const name = document.getElementById("name").value;
  const categoryId = getSelectedCategoryId();

  Promise.all([
    validateName(name),
    validateCategory(categoryId)
  ])
  .then(() => {
    // 検証を通過した場合はデータを保存する
  })
  .catch((error) => {
    setErrorMessage(error);
  });
}

function createPointers(resolve, reject, returnPointers) {
  // Cのコードから無名関数を呼び出す
  const onSuccess = Module.addFunction(function() {
    // 関数ポインタを解放してからPromiseのresolveメソッドを呼び出す
    freePointers(onSuccess, onError);
    resolve();
  }, 'v');

  const onError = Module.addFunction(function(errorMessage) {
    // 関数ポインタを解放してからPromiseのrejectメソッドを呼び出す
    freePointers(onSuccess, onError);
    reject(Module.UTF8ToString(errorMessage));
  }, 'vi');

  // 呼び出す関数の関数ポインタを返す
  returnPointers.onSuccess = onSuccess;
  returnPointers.onError = onError;
}

function freePointers(onSuccess, onError){
  Module.removeFunction(onSuccess);
  Module.removeFunction(onError); 
}

function validateName(name) {
  return new Promise(function(resolve, reject) {

    // 関数ポインタを作成する
    const pointers = { onSuccess: null, onError: null };
    createPointers(resolve, reject, pointers);    

    Module.ccall('ValidateName',
        null, // 戻り値の型をvoidに設定する
        ['string', 'number', 'number', 'number'],
        [name, MAXIMUM_NAME_LENGTH, pointers.onSuccess, pointers.onError]);

  });
}

function validateCategory(categoryId) {
  return new Promise(function(resolve, reject) {

    // 関数ポインタを作成する
    const pointers = { onSuccess: null, onError: null };
    createPointers(resolve, reject, pointers);    

    const arrayLength = VALID_CATEGORY_IDS.length;
    const bytesPerElement = Module.HEAP32.BYTES_PER_ELEMENT;
    const arrayPointer = Module._malloc((arrayLength * bytesPerElement));
    Module.HEAP32.set(VALID_CATEGORY_IDS, (arrayPointer / bytesPerElement));

    Module.ccall('ValidateCategory', 
        null, // 戻り値の型をvoidに設定する
        ['string', 'number', 'number', 'number', 'number'],
        [categoryId, arrayPointer, arrayLength, pointers.onSuccess, pointers.onError]);

    Module._free(arrayPointer);

  });
}