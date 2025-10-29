const crypto = require('crypto');
const http = require('http');
const fs = require("fs");
const axios = require('axios');
const sharp = require("sharp");
const decodeGif = require("decode-gif");
const tmi = require("tmi.js");

let streamer = "";
let MOD_IMG_FILE_PATH = "";
const filePath = __dirname + '/settings.txt';
try {
  const setData = fs.readFileSync(__dirname + '/settings.txt', 'utf8');
  const setLines = setData.split('\n');
  const settings = {};
  setLines.forEach(line => {
    const trimmedLine = line.trim();
    if (trimmedLine && !trimmedLine.startsWith('#')) {
      const [key, value] = trimmedLine.split('=').map(s => s.trim());
      if (key && value) {
        settings[key] = value;
      }
    }
  });
  streamer = settings.streamer;
  MOD_IMG_FILE_PATH = settings.MOD_IMG_FILE_PATH;
  console.log(`streamer: ${streamer}`);
  console.log(`MOD_IMG_FILE_PATH: ${MOD_IMG_FILE_PATH}`);
} catch (err) {
  console.error('Error reading settings:', err);
}


const server = http.createServer();
const ngFileMap = new Map();

function Queue() {
    this.__a = new Array();
}
Queue.prototype.enqueue = function (o) {
    this.__a.push(o);
}
Queue.prototype.dequeue = function () {
    if (this.__a.length > 0) {
        return this.__a.shift();
    }
    return null;
}
Queue.prototype.size = function () {
    return this.__a.length;
}
Queue.prototype.toString = function () {
    return '[' + this.__a.join(',') + ']';
}

var chatRunning = false;

function replaceWindowsNGChar(filename) {
    filename = filename.replaceAll(":", "_COLON_")
    filename = filename.replaceAll("*", "_ASTERISK_")
    filename = filename.replaceAll("?", "_QMARK_")
    filename = filename.replaceAll("\"", "_DBLQUOTE_")
    filename = filename.replaceAll("<", "_LESSTHAN_")
    filename = filename.replaceAll(">", "_GREATERTHAN_")
    filename = filename.replaceAll("|", "_VERTICAL_")
    filename = filename.replaceAll("\\", "_BACKSLASH_")
    return filename;
}

function convertToWidePng(result, frameData) {
    const arr = new Uint8Array(result.width * result.frames.length * result.height * 4)
    let idx = 0
    for (let y = 0; y < result.height; y++) {
        for (let n = 0; n < result.frames.length; n++) {
            for (let x = 0; x < result.width; x++) {
                const srcidx = (y * result.width * 4) + (x * 4);
                arr[idx++] = frameData[n][srcidx];
                arr[idx++] = frameData[n][srcidx + 1];
                arr[idx++] = frameData[n][srcidx + 2];
                arr[idx++] = frameData[n][srcidx + 3];
            }
        }
    }
    return arr;
}

// 画像ファイルをダウンロード、定義ファイルを作成、キューに先頭iを付与したファイル名を入れる
function makeImageFile(url, filename) {
    filename = replaceWindowsNGChar(filename);
    let imageFilePath = null;
    if (MOD_IMG_FILE_PATH.substring(MOD_IMG_FILE_PATH.length - 1, MOD_IMG_FILE_PATH.length) === "\\") {
        imageFilePath = MOD_IMG_FILE_PATH + "gfx\\" + filename + ".png";
    } else {
        imageFilePath = MOD_IMG_FILE_PATH + "\\gfx\\" + filename + ".png";
    }
    if (fs.existsSync(imageFilePath)) {
        // 存在するならの先頭にiを付与したファイル名をNoitaに教える
		//file exists
		return Promise.resolve("i" + filename);
    } else {
        if (ngFileMap.get(filename)) {
            // 処理できないファイルと判明しているならDLしない
            return Promise.resolve(null);
        }
        // 存在しないならDLする
        return axios({ method: "get", url: url, responseType: "arraybuffer" })
			.then((res) => {
				const buffer = new Buffer.from(res.data)
				if (buffer[0] == 0x89) {
					// PNGだったら画像ファイルを作成
					return sharp(buffer).metadata()
					.then(metadata => {
						const width = metadata.width;
						const height = metadata.height;
						fs.writeFileSync(MOD_IMG_FILE_PATH + "gfx\\" + filename + ".png", buffer, 'binary');
						// 定義ファイルを作成 - PASS width and height
						makeImageXML(filename, width, height); 
						// 先頭にiを付与したファイル名をNoitaに教える
						return "i" + filename;
					});
				} else {
					// GIFデータをRGBAの１ピクセル４要素の配列に変換
					const result = decodeGif(buffer);
					let frameData = result.frames.map(frame => Uint8Array.from(frame.data));
					const middleFrameData = frameData[parseInt(result.frames.length / 2)]


					// 横長の画像データに変換
					const widePngArray = convertToWidePng(result, frameData)

					return Promise.all([
					sharp(widePngArray, { raw: { width: result.width * result.frames.length, height: result.height, channels: 4 } })
						.toFormat("png")
						.toFile(MOD_IMG_FILE_PATH + "gfx\\" + filename + ".png"),
					sharp(middleFrameData, { raw: { width: result.width, height: result.height, channels: 4 } })
						.toFormat("png")
						.toFile(MOD_IMG_FILE_PATH + "gfx\\physic_" + filename + ".png")
					])
					.then(() => {
						// 定義ファイルを作成
						makeAnimeImageXML(filename, result.width, result.height, result.frames.length, 0.03);

						// 先頭にiを付与したファイル名をNoitaに教える
						return "i" + filename;
					});
				}
			})
			.catch((excep) => {
				console.log(excep)
					// NGリストに追加
					ngFileMap.set(filename, true)
					return null;
			});
    }

}

// 定義ファイルを作成する
function makeImageXML(filename, width, height) {
	const offsetX = Math.floor(width / 2);
    const offsetY = Math.floor(height / 2);
    if (!fs.existsSync(MOD_IMG_FILE_PATH + "img\\img_" + filename + ".xml")) {
        fs.writeFileSync(MOD_IMG_FILE_PATH + "img\\img_" + filename + ".xml",
            `<Entity tags="prop"><VelocityComponent/><SpriteComponent z_index="1" image_file="mods/comment/files/entities/imgs/gfx/img_gfx_${filename}.xml" offset_x="${offsetX}" offset_y="${offsetY}"></SpriteComponent></Entity>`, "utf8")
        fs.writeFileSync(MOD_IMG_FILE_PATH + "img\\pimg_" + filename + ".xml",
            `<Entity tags="mortal"><Base file="mods/comment/files/entities/pbase.xml"><PhysicsImageShapeComponent image_file="mods/comment/files/entities/imgs/gfx/${filename}.png"/><SpriteComponent z_index="1" image_file="mods/comment/files/entities/imgs/gfx/img_gfx_${filename}.xml" offset_x="0" offset_y="0"/></Base></Entity>`, "utf8")
        fs.writeFileSync(MOD_IMG_FILE_PATH + "gfx\\img_gfx_" + filename + ".xml",
            `<Sprite filename="mods/comment/files/entities/imgs/gfx/${filename}.png"></Sprite>`, "utf8")
    }
}
function makeAnimeImageXML(filename, width, height, frameCount, time) {
	const offsetX = Math.floor(width / 2);
    const offsetY = Math.floor(height / 2);
    if (!fs.existsSync(MOD_IMG_FILE_PATH + "img\\img_" + filename + ".xml")) {
        fs.writeFileSync(MOD_IMG_FILE_PATH + "img\\img_" + filename + ".xml",
            `<Entity tags="prop"><VelocityComponent/><SpriteComponent z_index="1" image_file="mods/comment/files/entities/imgs/gfx/img_gfx_${filename}.xml" offset_x="${offsetX}" offset_y="${offsetY}"></SpriteComponent></Entity>`, "utf8")
        fs.writeFileSync(MOD_IMG_FILE_PATH + "img\\pimg_" + filename + ".xml",
            `<Entity tags="mortal"><Base file="mods/comment/files/entities/pbase.xml"><PhysicsImageShapeComponent image_file="mods/comment/files/entities/imgs/gfx/physic_${filename}.png"/><SpriteComponent z_index="1" image_file="mods/comment/files/entities/imgs/gfx/img_gfx_${filename}.xml" offset_x="0" offset_y="0"/></Base></Entity>`, "utf8")
        fs.writeFileSync(MOD_IMG_FILE_PATH + "gfx\\img_gfx_" + filename + ".xml",
            `<Sprite filename="mods/comment/files/entities/imgs/gfx/${filename}.png" default_animation="stand"><RectAnimation name="stand" pos_x="0" pos_y="0" frame_count="${frameCount}" frame_width="${width}" frame_height="${height}" frame_wait="${time}" frames_per_row="${frameCount}" loop="1"></RectAnimation></Sprite>`, "utf8")
    }
}

const messageQueue = new Queue();

const client = new tmi.Client({
	channels: [streamer]
});
client.connect();
//what if connection to twitch drops?
client.on('connected', (addr, port) => {
	console.log(`* Connected to ${addr}:${port}`);
});
client.on('join', (channel, username, self) => {
    if (self) console.log(`${channel} joined.`);
});
client.on('message', (channel, tags, message, self) => {
	async function decompileAll() {
		var emoteCol = [];
		if (tags["emotes"]) {
			for (const e in tags["emotes"]) {
				var name = e;
				var positions = tags["emotes"][e];
				for (let p in positions) {
					var [start, end] = positions[p].split("-").map(Number);
					emoteCol.push({ name, start, end });
				}
			}
			emoteCol.sort((a, b) => a.start - b.start);
		}
		let messages = [];
		if (emoteCol.length > 0) {
			let workingPos = 0;
			//step through emotes and push message pieces
			emoteCol.forEach(e => {
				if (message.substring(workingPos, e.start - 1).length > 0) {
					messages.push(message.substring(workingPos, e.start));	
				}
				workingPos = e.end + 1;
				if (tags["msg-id"] === "gigantified-emote-message") {
					messages.push(`https://static-cdn.jtvnw.net/emoticons/v2/${e.name}/default/dark/4.0`)
				} else {
					messages.push(`https://static-cdn.jtvnw.net/emoticons/v2/${e.name}/default/dark/1.0`)
				}
			});
			messages.push(message.substring(workingPos, message.length + 1));
		} else {
			messages.push(message.trim()); //no emotes, push all
		}
		//stack messages
		let promises = [];

		for (const mes of messages) {
			if (/^/.test(mes)){
				continue;
			}
			console.log(mes) //mes
			if (/^https:\/\/static-cdn\.jtvnw\.net\/emoticons\/v2\//.test(mes)) {
				const filename = crypto.createHash('sha256').update(mes).digest("hex");
				console.log(filename); //filename
				promises.push(makeImageFile(mes, filename));
			} else {		
				promises.push(Promise.resolve(mes.split("").map((c)=>{return c.codePointAt(0)}).join(",")));
			}
		}
		let ti = false;
		let tiArr = ["49","50","51","52"];
		let queueStack = await Promise.all(promises);
		//console.log(queueStack);
		
		queueStack = queueStack.flat().filter(Boolean);
		//console.log(queueStack);
		
		queueStack = queueStack.join(",");
		if (queueStack.length === 2) {
			ti = tiArr.includes(queueStack);
		}
		//console.log(queueStack);
		
		let charCount = queueStack.split(",").length - emoteCol.length;
		
		console.log('{["sender"] = "' + tags["username"] + '"}');
		console.log('{["text"] = "' + queueStack + '"}');
		console.log('{["characters"] = ' + charCount + '}'); 
		console.log('{["emotes"] = ' + emoteCol.length + '}');
		console.log('{["ti"] = ' + ti + '}');
		
		messageQueue.enqueue('{' +
			'["sender"] = "' + tags["username"] + '",' +
			'["text"] = "' + queueStack + '",' +
			'["characters"] = ' + charCount + ',' +
			'["emotes"] = ' + emoteCol.length + ',' +
			'["ti"] = ' + ti +
		'}');
	}
	decompileAll();
});

function response(req, res, body) {
    res.writeHead(200, {
        'Content-Type': 'text/html',
        //"Access-Control-Allow-Origin": "http://localhost",
		"Access-Control-Allow-Origin": "null",
        "Access-Control-Allow-Headers": "Content-Type"
    });
    if (body) {
        res.write(body);

    } else {
        res.write("ok");
    }
    res.end();
}

//server for queue
server.on('request', function (req, res) {
    if (req.method === "OPTIONS") {
        // プリフライトリクエスト
        response(req, res);
        return;
    }
	if (req.url === "/all") { // NEW ENDPOINT, show all for text html
         response(req, res, JSON.stringify(messageQueue));
    } else if (req.url.length === 1) {
        // NOITAからのリクエスト
		// when requested, dequeue is performed
        const mes = messageQueue.dequeue()
        response(req, res, mes);
    }
});
console.log("http server started")
server.listen(7505);
