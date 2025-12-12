# twitchcommentslive
## A Noita mod that brings Twitch comments to life in-game

Bring Twitch chat in game as floating text, turn them into physical materials at random, or have chat discover creating specific materials based on what they say.
Makes Twitch chat messages show up as in-game letters. Have your chat interact by also turning on physical conversion, where the letters turn into physical materials. Make them random, or turn on static seed and have messages tied to materials made. This way, chat plays a game of trying to find out what message becomes healthium, gold, instant death, etc. Every run is different! Loads of settings to play casually, with absolute chaos, small chats, large chats. Also supports emotes by running a script to convert emotes into sprites.
With Static Seed mode on, an example would be a chatter says "bald", it appears in game, and turns into polymorph. "bald" will ALWAYS turn into polymorph for this run. While "sweat" turns into another material, like acid. For each run, chat gets to discover what their messages turn into, allowing them to choose to help or hurt the streamer.

Subscribe to the [workshop mod](https://steamcommunity.com/sharedfiles/filedetails/?id=3606516759)).

[Download emote server](https://github.com/ScienceLion/twitchcommentslive/blob/main/twitchcommentslive_server.zip); requires [Node](https://nodejs.org/)

Use the emote server to download emotes as chatters use them, use it offline to pre-populate only approved emotes, or not use it at all (replaces emotes with spaces).

To run, <ins>**connect to Twitch in Noita via the options menu Streaming tab**</ins>.

To add server, download the server, **edit settings.txt** to change the channel. If Noita or your Steam Library is at a different location than the settings, put in the correct location. On Windows, you must use double backslash ("\\\\") for folders, not just a single backslash. For Linux, use forward slash "/". Open start_server (If it closes, you may need to run a command prompt as administrator, navigate to server folder, and run start_server).

[Demo Video](https://www.youtube.com/watch?v=M359qFks2uo)

## Recommended Options
**Speed running mode:** Physical Conversion: Off

**Maximum chat chaos:** Physical Conversion: On, Conversion Material: Random , Announce: Off, Static Seed: On, Pause: Off

For casual pace, longer chat lifetime and shorter display rate.

For rapid chatters, set chat lifetime as short as you need to read, set display rate to large number to limit how fast materials spammed at you, use moderation to put character and emote limits.

## Options
General
- Use Emote Server: If Off, emotes not downloaded replaced by space.
- Chat Lifetime: Lifetime of chat messages in-game (frames)
- Display Rate: Number of frames between chat messages appearing
- Chat In Front: If On, text will be in front of terrain and player
- Wiggle: Adjust how much text wiggles. This gives the chat a fun little animation.
- Damage Display: If On, display the damage you have taken (non physical chat only)
- Pause in Holy Mountain: If On, text will not appear while in Holy Mountain
- Pause in Boss Area: If On, text will not appear while in Boss Area

Physical
- Physical Conversion: If On, chat messages convert to physical form at end of lifetime
- Conversion Material: Set of materials which convsersion selects from (wood, random, potions, powders)
- Reroll Deathium: If On, rerolls, but does not remove, Deathium. This gives you a lower chance of these materials appearing and also prevents them being spammed.
- Reroll Monstrous Powder: If On, rerolls, but does not remove, Monstrous Powder. 
- Announce Material: Displays notification of randomly selected material
- Static Seed: If On, same chat messages result in same material

Moderation
- Ignore List: Usernames to ignore (separated by comma). This is mostly to prevent bot spam. Add your own personal bot names if you have any.
- Twitch Integration Voting: If Off, disables Twitch Integration voting
- Ignore Twitch Integration Votes: Turn this on if you want to Twitch Integration votes to not appear in game
- Maximum Characters: Do not display if chat message is over this many characters. Setting this to 0 essentialy creates emote only mode.
- Maximum Emotes: Do not display if chat message is over this many emotes

Thanks to [syagami](https://www.twitch.tv/syagami) for in-game comment and emote code.

Support me at [PayPal](https://www.paypal.me/scienceliontwitch)

<img width="500" height="500" alt="qrcode" src="https://github.com/user-attachments/assets/f04ab628-1cc6-448b-a81e-bbaba46948ff" />
