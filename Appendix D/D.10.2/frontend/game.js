let moduleMemory = null;
let moduleExports = null;

var Module = {
  instantiateWasm: function(importObject, successCallback) {
    let mainInstance = null;

    // WebAssemblyモジュールをインスタンス化する
    WebAssembly.instantiateStreaming(fetch("main.wasm"), importObject)
    .then(result => {
      mainInstance = result.instance;
      moduleMemory = mainInstance.exports.memory;
      
      const sideImportObject = {    
        env: {
          memory: moduleMemory,
          _malloc: mainInstance.exports.malloc,
          _free: mainInstance.exports.free,
          _SeedRandomNumberGenerator: mainInstance.exports.SeedRandomNumberGenerator,
          _GetRandomNumber: mainInstance.exports.GetRandomNumber,
          _GenerateCards: generateCards,
          _UpdateTriesTotal: updateTriesTotal,
          _FlipCard: flipCard,
          _RemoveCards: removeCards,
          _LevelComplete: levelComplete,
          _Pause: pause,
          _Log: log,
        }
      };

      return WebAssembly.instantiateStreaming(fetch("cards.wasm"), sideImportObject)   

    }).then(sideInstanceResult => {
       moduleExports = sideInstanceResult.instance.exports;

      // メインモジュールのインスタンスをEmscriptenに渡す    
      successCallback(mainInstance);
    });

    // インスタンス化は非同期で実行されるので空のJavaScriptオブジェクトを返す
    return {}; 
  }
};

// UIにカードの表示を指示するWebAssemblyモジュールから呼び出される関数
function generateCards(rows, columns, level, tries) {
  document.getElementById("currentLevel").innerText = level;
  updateTriesTotal(tries);

  let html = "";
  for (let row = 0; row < rows; row++) { 
    // divタグで行の開始を示す
    html += "<div>";

    // 列の数だけカードを表示するHTMLのコードを作成する処理をする
    for (let column = 0; column < columns; column++) {
      html += "<div id=\"" + getCardId(row, column) + "\" class=\"CardBack\" onclick=\"onClickCard(" + row + "," + column + ");\"><span></span></div>";
    }

    // 行の末尾を指定するdivタグ
    html += "</div>";
  }

  document.getElementById("cardContainer").innerHTML = html;
}

// WebAssemblyモジュールから呼び出される試行回数を更新する関数
function updateTriesTotal(tries) {
  document.getElementById("tries").innerText = tries;
}

// 行と列の値を用いて各カードに名前をつけるためのヘルパー関数
function getCardId(row, column) { return ("card_" + row + "_" + column); }

// カードがクリックされた際にWebAssemblyモジュールから呼び出される関数
function flipCard(row, column, cardValue) {
  const card = getCard(row, column);
  card.className = "CardBack";

  // カードが選択された場合の処理
  if (cardValue !== -1) {
    card.className = ("CardFace " + getClassForCardValue(cardValue));
  }
}

function getCard(row, column) { return document.getElementById(getCardId(row, column)); }

// Type0, Type1, Type2, etc
function getClassForCardValue(cardValue) { return ("Type" + cardValue); }

// 選択された2つのカードの値が一致した場合はカードの画像を隠す
function removeCards(firstCardRow, firstCardColumn, secondCardRow, secondCardColumn) {
  // visibilityを用いて位置関係を保ちつつカードを隠す
  let card = getCard(firstCardRow, firstCardColumn);
  card.style.visibility = "hidden";

  card = getCard(secondCardRow, secondCardColumn);
  card.style.visibility = "hidden";
}

// レベルがクリアされた場合に呼び出す関数
function levelComplete(level, tries, hasAnotherLevel) {
  document.getElementById("levelComplete").style.display = "";
  document.getElementById("levelSummary").innerText = `Good job! You've completed level ${level} with ${tries} tries.`;

  if (!hasAnotherLevel) { document.getElementById("playNextLevel").style.display = "none"; }
}

function pause(callbackNamePointer, milliseconds) {
  // ミリ秒単位で指定された時間だけ一時停止する
  // コールバック関数は戻り値とパラメータを持たせない
  window.setTimeout(function() {
    // コールバック関数として呼び出す関数の名前をWebAssemblyモジュールのメモリから読み取る
    const name = ("_" + getStringFromMemory(callbackNamePointer));

    // 要求されたメソッドを呼び出す
    moduleExports[name]();
  }, milliseconds);
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

// どのカードがクリックされたかをWebAssemblyモジュールに伝える関数
function onClickCard(row, col) {
  moduleExports._CardSelected(row, col);
}

// 「Replay」ボタンがクリックされた場合の処理
function replayLevel() {
  document.getElementById("levelComplete").style.display = "none";

  moduleExports._ReplayLevel();
}

// 「Play Next Level」ボタンがクリックされた場合の処理
function playNextLevel() {
  document.getElementById("levelComplete").style.display = "none";

  moduleExports._PlayNextLevel();
}

function log(functionNamePointer, triesValue) {
  const name = getStringFromMemory(functionNamePointer);
  console.log(`Function name: ${name}  triesValue: ${triesValue}`);
}