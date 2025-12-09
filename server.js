/*
Thanks to syagami for most of this code from comment mod
:::::::::::::::::::::.-*#%%%%.-**+...........
:::::::::::::::::::::.-*#%%***+-+**-.........
::::::::::::::::%#=-::=******=+**+:::::......
::::::::::::::--%#++*:::========-:::::::::...
:::::::::::::=*%-----%+::-%%%%%%%#:*%%%%%#::.
:::::::::::::=*%---*%%%%%%%%%%%%--%%%@@@@%::.
:::::::::::::=*%-=%=-%%%%%%%%===%%%##:::::::.
:::::::::::==%+-%*-*%%%%%%%%%===%%%=:::::::::
=-:::::::::==%%%-=%%%%%%%#-*#++=%%%=::=#%%%%#
==--:::::::==%*=**%*+%%%*****%*=%%%#*:-=#%%+=
=====:+#:-=##%+.::=:..=%*+=*%%*=-=@%%%##%%@+:
=====%+::-=#%...........#%%%%%*===:*@@@@@%:::
%%%%#=-::=%=-...........-----%*===:::::::::::
======-:%%%=-............:---%*===:*%%%%%#::.
===+++#%%%%%%..............:-%*==+%%#####*::.
***#%%%%%%%+=+-............:-%*=%%%+=:::::::.
=+%%%%=.%#***-*%.........-%=-%*=%%%=::=%%%%%%
=+%%#-:..:*=--*%.........-%=-%*=%%%=::+@%%%%@
=+%**%=....*%%+.++=:....##---%*=%%%%%:::#%%=:
===+**#%...---:......%%%--.:-%*=:-@%%%%%%%@+:
===++***#*===........:::...:-%*===:+#####*---
=====++******+-............+*%#*==--:::::-===
========******#%%%%%%%%%%%%%%%%%===-:::::-===
========***********#%%%%%%%%%%%%===-:::::-=-:

Thanks to HoodieSoupp for live testing
                                            #+ 
             .@@@@==-@@@@@@@@@@@@@@++.=%@ @    
:@@%:.:-=+-:..  ....                .   @   @@*
 @@@@**#=-=+:..-:.:....-::.....:-*#*###@@@@@@@ 
    -+#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=:      
 ..                                         .: 
 ::::::::.        ..:::::::::::::::::::::::::: 
 :::::::  .@@@@        :               ::::::: 
 ::::::: @.   @@@@@@@@ : @@@@@@@@@@@@% ::::::: 
  ::::::               .               ::::::  
*  :::::::: +@@@@@@@@@   @%@@@@@@@@ ..:.::::   
 @  ::::... @* @#%#@ @+  @  @@@@@@@:.::::::  @ 
 :@  ::::..                         .:::::  @# 
  #@. :-=-@=- ##       .        @=-*%*--:. @@  
    @ .:-:::- =@@@@@@@@@@@@@@@@@- --:---  @@   
      .  .:::.                   .::::.  @     
 @@@@@@@        .:::... ..::::::        @@%@@@ 
 @@ .::+#@@@@%=      .::::.       -=@@@=.  .#@ 
  @@@+:    .-#@@@@@-        *%%@@@@@@+  @@@@@* 
.@-  +@@@@@@+=+=%@@@@@@@@@@@@@@@@%@@@@@@@%   .=
  @@@        .:..   +     .               :@@@ 
 @#  :===.@@@:=====.-@.==.@=:=====:@@ ===-.  @*
 @ :===== @@ :=====- @ == @ -=====. @ -====-. :
@ .====-. @..======--@.== @ ...-==- @- -=====. 
@        @                   .       @         
*/
const fs = require("fs");
const path = require('path');
const axios = require('axios');
const sharp = require("sharp");
const decodeGif = require("decode-gif");
const tmi = require("tmi.js");

let streamer = "";
let NOITA_DATA_PATH = "";
let SERVER_STATUS_FILE = "";
//obtain settings
try {
  const setData = fs.readFileSync(__dirname + '/settings.txt', 'utf8');
  const setLines = setData.split('\n');
  const settings = {};
  setLines.forEach(line => {
    const trimmedLine = line.trim();
    if (trimmedLine && !trimmedLine.startsWith('#')) {
	  const eqIndex = trimmedLine.indexOf('=');
      if (eqIndex > 0) {
        const key = trimmedLine.substring(0, eqIndex).trim();
        let value = trimmedLine.substring(eqIndex + 1).trim();
        if (value.startsWith('"') && value.endsWith('"')) {
            value = value.substring(1, value.length - 1);
        }
        settings[key] = value;
      }
    }
  });
  streamer = settings.streamer.toLowerCase();
  SERVER_STATUS_FILE = path.join(settings.MOD_FILE_PATH, "files", "servercheck.txt");
  NOITA_DATA_PATH = path.join(settings.NOITA_DATA_PATH, "data", "twitchcommentslive");
  console.log(`streamer: ${streamer}`);
  console.log(`MOD_FILE_PATH: ${settings.MOD_FILE_PATH}`);
  console.log(`NOITA_DATA_PATH: ${NOITA_DATA_PATH}`);
} catch (err) {
  console.error('Error reading settings:', err);
}
function makeDir(dirPath) {
    if (!fs.existsSync(dirPath)) {
        try {
            fs.mkdirSync(dirPath, { recursive: true });
            console.log(`Directory created successfully: ${dirPath}`);
        } catch (err) {
            console.error(`Error creating directory: ${err.message}`);
        }
    }
}
makeDir(path.join(NOITA_DATA_PATH,"gfx"));
makeDir(path.join(NOITA_DATA_PATH,"img"));
//write heartbeat
function writeTimestamp() {
    // Get the current Unix timestamp in seconds
    const timestamp = Math.floor(Date.now() / 1000);
    const content = `RUNNING:${timestamp}\n`;
    // Write the content to the file. 'writeFileSync' is simple for this type of task.
    try {
        fs.writeFileSync(SERVER_STATUS_FILE, content, 'utf8');
        //console.log(`Updated status file with timestamp: ${timestamp}`);
    } catch (err) {
        console.error(`Error writing status file: ${err.message}`);
    }
}
//interval to write the timestamp repeatedly
const intervalId = setInterval(writeTimestamp, 1000);
//shutdown
process.on('SIGINT', () => {
    console.log('\nShutting down...');
    clearInterval(intervalId);
    process.exit();
});

const ngFileMap = new Map();

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

async function makeImageFile(url, filename) {
	const imageFilePath = path.join(NOITA_DATA_PATH, "gfx", `${filename}.png`);

    if (fs.existsSync(imageFilePath)) {
		//file exists
		return;
    } else {
        if (ngFileMap.get(filename)) {
            //known error, cancel
            return;
        }
        //download
		try {
			const res = await axios({ method: "get", url: url, responseType: "arraybuffer" });
			const buffer = new Buffer.from(res.data)
			const gfxDir = path.join(NOITA_DATA_PATH, "gfx");
			if (buffer[0] == 0x89) {
				// Make PNG
				const metadata = await sharp(buffer).metadata();
				const width = metadata.width;
				const height = metadata.height;

				fs.writeFileSync(path.join(gfxDir, `${filename}.png`), buffer, 'binary');
				makeImageXML(filename, width, height); 
			} else {
				// Make GIF in RGBA
				const result = decodeGif(buffer);
				let frameData = result.frames.map(frame => Uint8Array.from(frame.data));
				const middleFrameData = frameData[parseInt(result.frames.length / 2)]
				// convert GIF to landscape
				const widePngArray = convertToWidePng(result, frameData)

				await sharp(widePngArray, { raw: { width: result.width * result.frames.length, height: result.height, channels: 4 } })
					.toFormat("png")
					.toFile(path.join(gfxDir, `${filename}.png`));
				await sharp(middleFrameData, { raw: { width: result.width, height: result.height, channels: 4 } })
					.toFormat("png")
					.toFile(path.join(gfxDir, `physic_${filename}.png`));

				makeAnimeImageXML(filename, result.width, result.height, result.frames.length, 0.03);
			}
		} catch (excep) {
			console.log(excep)
			// assign known error
			ngFileMap.set(filename, true)
		}
    }
}

// Make XML
function makeImageXML(filename, width, height) {
	const offsetX = Math.floor(width / 2);
    const offsetY = Math.floor(height / 2);
	const imgDir = path.join(NOITA_DATA_PATH, "img");
    const gfxDir = path.join(NOITA_DATA_PATH, "gfx");
    if (!fs.existsSync(path.join(imgDir, `img_${filename}.xml`))) {
        fs.writeFileSync(path.join(imgDir, `img_${filename}.xml`),
            `<Entity tags="prop"><VelocityComponent/><SpriteComponent z_index="1" image_file="data/twitchcommentslive/gfx/img_gfx_${filename}.xml" offset_x="${offsetX}" offset_y="${offsetY}"></SpriteComponent></Entity>`, "utf8")
        fs.writeFileSync(path.join(imgDir, `pimg_${filename}.xml`),
            `<Entity tags="mortal"><Base file="mods/twitchcommentslive/files/entities/pbase.xml"><PhysicsImageShapeComponent image_file="data/twitchcommentslive/gfx/${filename}.png"/><SpriteComponent z_index="1" image_file="data/twitchcommentslive/gfx/img_gfx_${filename}.xml" offset_x="${offsetX}" offset_y="${offsetY}"/></Base></Entity>`, "utf8")
        fs.writeFileSync(path.join(gfxDir, `img_gfx_${filename}.xml`),
            `<Sprite filename="data/twitchcommentslive/gfx/${filename}.png"></Sprite>`, "utf8")
    }
}
function makeAnimeImageXML(filename, width, height, frameCount, time) {
	const offsetX = Math.floor(width / 2);
    const offsetY = Math.floor(height / 2);
	const imgDir = path.join(NOITA_DATA_PATH, "img");
    const gfxDir = path.join(NOITA_DATA_PATH, "gfx");
   if (!fs.existsSync(path.join(imgDir, `img_${filename}.xml`))) {
        fs.writeFileSync(path.join(imgDir, `img_${filename}.xml`),
            `<Entity tags="prop"><VelocityComponent/><SpriteComponent z_index="1" image_file="data/twitchcommentslive/gfx/img_gfx_${filename}.xml" offset_x="${offsetX}" offset_y="${offsetY}"></SpriteComponent></Entity>`, "utf8")
        fs.writeFileSync(path.join(imgDir, `pimg_${filename}.xml`),
            `<Entity tags="mortal"><Base file="mods/twitchcommentslive/files/entities/pbase.xml"><PhysicsImageShapeComponent image_file="data/twitchcommentslive/gfx/physic_${filename}.png"/><SpriteComponent z_index="1" image_file="data/twitchcommentslive/gfx/img_gfx_${filename}.xml" offset_x="${offsetX}" offset_y="${offsetY}"/></Base></Entity>`, "utf8")
        fs.writeFileSync(path.join(gfxDir, `img_gfx_${filename}.xml`),
            `<Sprite filename="data/twitchcommentslive/gfx/${filename}.png" default_animation="stand"><RectAnimation name="stand" pos_x="0" pos_y="0" frame_count="${frameCount}" frame_width="${width}" frame_height="${height}" frame_wait="${time}" frames_per_row="${frameCount}" loop="1"></RectAnimation></Sprite>`, "utf8")
    }
}

const client = new tmi.Client({
	channels: [streamer]
});
client.connect();
client.on('connected', (addr, port) => {
	console.log(`* Connected to ${addr}:${port}`);
	writeTimestamp();
});
client.on('join', (channel, username, self) => {
    if (self) console.log(`${channel} joined.`);
});
client.on('message', (channel, tags, message, self) => {
	function decompileAll() {
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
			//gather emote URLs
			emoteCol.forEach(e => {
				if (tags["msg-id"] === "gigantified-emote-message") {
					messages.push(`https://static-cdn.jtvnw.net/emoticons/v2/${e.name}/default/dark/4.0`)
				} else {
					messages.push(`https://static-cdn.jtvnw.net/emoticons/v2/${e.name}/default/dark/1.0`)
				}
			});

		}
		for (const mes of messages) {
			if (/^/.test(mes)){
				continue;
			}
			console.log(mes) //mes
			if (/^https:\/\/static-cdn\.jtvnw\.net\/emoticons\/v2\//.test(mes)) {
				let filename = mes.match(/\/v2\/([a-zA-Z0-9_]+)\/default\//);
				if (mes.match(/dark\/4\.0/)) {
					filename = "4_" + filename[1];
				} else {
					filename = "1_" + filename[1];
				}
				console.log(filename); //filename
				makeImageFile(mes, filename);
			}
		}
	}
	decompileAll();
});
