const clientData = {
  isProduct: true,
  name: "Women's Mid Rise Skinny Jeans",
  categoryId: "100",
  productId: "301",
  quantity: "10",
};

const MAXIMUM_NAME_LENGTH = 50;
const VALID_CATEGORY_IDS = [100, 101];
const VALID_PRODUCT_IDS = [200, 301];

// ProductページまたはOrderページで使用するWebAssemblyモジュールのインスタンスを保持する
// 1度に1つのWebページしか処理しないためインスタンスは1つで十分である
let validationModule = null;

const Module = require('./validate_core.js');

function initializePage() {
  const moduleName = (clientData.isProduct ? 'validate_product.wasm' : 'validate_order.wasm');

  Module({
    dynamicLibraries: [moduleName],
  }).then((module) => {
    validationModule = module;
    runtimeInitialized();
  });
}

function runtimeInitialized() {
  if (clientData.isProduct) {
    if (validateName(clientData.name) && validateCategory(clientData.categoryId)) {
      // 検証を通過した場合はサーバ側のコードにデータを渡す
    }
  }
  else { // 注文フォームの処理
    if (validateProduct(clientData.productId) && validateQuantity(clientData.quantity)) {
      // 検証を通過した場合はサーバ側のコードにデータを渡す
    }
  }
}

global.setErrorMessage = function(error) { console.log(error); }

//-------------
// 商品の編集に使用する関数
//
function validateName(name) {
  const isValid = validationModule.ccall('ValidateName',
      'number',
      ['string', 'number'],
      [name, MAXIMUM_NAME_LENGTH]);

  return (isValid === 1);
}

function validateCategory(categoryId) {
  const arrayLength = VALID_CATEGORY_IDS.length;
  const bytesPerElement = validationModule.HEAP32.BYTES_PER_ELEMENT;
  const arrayPointer = validationModule._malloc((arrayLength * bytesPerElement));
  validationModule.HEAP32.set(VALID_CATEGORY_IDS, (arrayPointer / bytesPerElement));

  const isValid = validationModule.ccall('ValidateCategory', 
      'number',
      ['string', 'number', 'number'],
      [categoryId, arrayPointer, arrayLength]);

  validationModule._free(arrayPointer);

  return (isValid === 1);
}
//
// 商品の編集に使用する関数の末尾
//-------------

//-------------
// 商品の注文の管理に使用する関数
//
function validateProduct(productId) {
  const arrayLength = VALID_PRODUCT_IDS.length;
  const bytesPerElement = validationModule.HEAP32.BYTES_PER_ELEMENT;
  const arrayPointer = validationModule._malloc((arrayLength * bytesPerElement));
  validationModule.HEAP32.set(VALID_PRODUCT_IDS, (arrayPointer / bytesPerElement));

  const isValid = validationModule.ccall('ValidateProduct',
      'number',
      ['string', 'number', 'number'],
      [productId, arrayPointer, arrayLength]);

  validationModule._free(arrayPointer);

  return (isValid === 1);
}

function validateQuantity(quantity) {
  const isValid = validationModule.ccall('ValidateQuantity',
      'number',
      ['string'],
      [quantity]);

  return (isValid === 1);
}
//
// 商品の注文の管理に使用する関数の末尾
//-------------

// 全てのコードの読み込みが完了したら関数を呼び出す
initializePage();