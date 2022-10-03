const initialProductData = {
  name: "Women's Mid Rise Skinny Jeans",
  categoryId: "100",
};

const MAXIMUM_NAME_LENGTH = 50;
const VALID_CATEGORY_IDS = [100, 101];
const VALID_PRODUCT_IDS = [200, 301];

// 動的リンクされるWebAssemblyモジュールのEmscriptenのModuleオブジェクトを保持するインスタンス
let productModule = null;
let orderModule = null;

function initializePage() {
  document.getElementById("name").value = initialProductData.name;

  const category = document.getElementById("category");
  const count = category.length;
  for (let index = 0; index < count; index++) {
    if (category[index].value === initialProductData.categoryId) {
      category.selectedIndex = index;
      break;
    }
  }

  // URIにハッシュ（#EditProductや#PlaceOrder）がありそれが商品注文フォームのものであれば
  // 商品注文フォームがデフォルトで表示されるようにフラグを調整する
  let showEditProduct = true;
  if ((window.location.hash) && (window.location.hash.toLowerCase() === "#placeorder")) {
    showEditProduct = false;
  }

  // 正しいフォームが表示されておりEmscriptenのModuleオブジェクトが作成されているかを確認する
  switchForm(showEditProduct);
}

// 正しいフォームの表示を制御するためのヘルパー関数
function switchForm(showEditProduct) {
  // 過去の検証で保存されたエラーメッセージを消去する
  setErrorMessage("");
  setActiveNavLink(showEditProduct);
  setFormTitle(showEditProduct);

  if (showEditProduct) {
    // 商品編集フォームに使用するEmscriptenのModuleオブジェクトを作成する
    if (productModule === null) {
      Module({ dynamicLibraries: ['validate_product.wasm'] }).then((module) => {
        productModule = module;
      });
    }
 
    // 商品編集フォームを表示する
    showElement("productForm", true);
    showElement("orderForm", false);
  } else {
    // 商品注文フォームに使用するEmscriptenのModuleオブジェクトを作成する
    if (orderModule === null) {
      Module({ dynamicLibraries: ['validate_order.wasm'] }).then((module) => {
        orderModule = module;
      });
    }

    // 商品注文フォームを表示する
    showElement("productForm", false);
    showElement("orderForm", true);
  }
}

// ナビゲーションバーの適切なリンクがアクティブであることを示すためのヘルパー関数
function setActiveNavLink(editProduct) {
  const navEditProduct = document.getElementById("navEditProduct");
  const navPlaceOrder = document.getElementById("navPlaceOrder");
  navEditProduct.classList.remove("active");
  navPlaceOrder.classList.remove("active");

  if (editProduct) { navEditProduct.classList.add("active"); }
  else { navPlaceOrder.classList.add("active"); }
}

function setFormTitle(editProduct) {
  const title = (editProduct ? "Edit Product" : "Place Order");
  document.getElementById("formTitle").innerText = title;
}

function showElement(elementId, show) {
  const element = document.getElementById(elementId);
  element.style.display = (show ? "" : "none");
}

function getSelectedDropdownId(elementId) {
  const dropdown = document.getElementById(elementId);
  const index = dropdown.selectedIndex;
  if (index !== -1) { return dropdown[index].value; }

  return "0";
}

function setErrorMessage(error) {
  const errorMessage = document.getElementById("errorMessage");
  errorMessage.innerText = error; 
  showElement("errorMessage", (error !== ""));
}

//-------------
// 商品の編集に使用する関数
//
function onClickSaveProduct() {
  // 過去の検証で保存されたエラーメッセージを消去する
  setErrorMessage("");

  const name = document.getElementById("name").value;
  const categoryId = getSelectedDropdownId("category");

  if (validateName(name) && validateCategory(categoryId)) {
    // 検証を通過した場合はサーバ側のコードにデータを渡す    
  }
}

function validateName(name) {
  const isValid = productModule.ccall('ValidateName',
      'number',
      ['string', 'number'],
      [name, MAXIMUM_NAME_LENGTH]);

  return (isValid === 1);
}

function validateCategory(categoryId) {
  const arrayLength = VALID_CATEGORY_IDS.length;
  const bytesPerElement = productModule.HEAP32.BYTES_PER_ELEMENT;
  const arrayPointer = productModule._malloc((arrayLength * bytesPerElement));
  productModule.HEAP32.set(VALID_CATEGORY_IDS, (arrayPointer / bytesPerElement));

  const isValid = productModule.ccall('ValidateCategory', 
      'number',
      ['string', 'number', 'number'],
      [categoryId, arrayPointer, arrayLength]);

  productModule._free(arrayPointer);

  return (isValid === 1);
}
//
// 商品の編集に使用する関数の末尾
//-------------

//-------------
// 商品の注文の管理に使用する関数
//
function onClickAddToCart() {
  // 過去の検証で保存されたエラーメッセージを消去する
  setErrorMessage("");

  const productId = getSelectedDropdownId("product");
  const quantity = document.getElementById("quantity").value;

  if (validateProduct(productId) && validateQuantity(quantity)) {
    // 検証を通過した場合はサーバ側のコードにデータを渡す
  }
}

function validateProduct(productId) {
  const arrayLength = VALID_PRODUCT_IDS.length;
  const bytesPerElement = orderModule.HEAP32.BYTES_PER_ELEMENT;
  const arrayPointer = orderModule._malloc((arrayLength * bytesPerElement));
  orderModule.HEAP32.set(VALID_PRODUCT_IDS, (arrayPointer / bytesPerElement));

  const isValid = orderModule.ccall('ValidateProduct',
      'number',
      ['string', 'number', 'number'],
      [productId, arrayPointer, arrayLength]);

  orderModule._free(arrayPointer);

  return (isValid === 1);
}

function validateQuantity(quantity) {
  const isValid = orderModule.ccall('ValidateQuantity',
      'number',
      ['string'],
      [quantity]);

  return (isValid === 1);
}
//
// 商品注文の管理に使用する関数の末尾
//-------------