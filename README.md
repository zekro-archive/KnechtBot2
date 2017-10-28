<div align="center">
    <h1> ~ KnechtBot V2 ~ </h1>
    <strong>Server management system of zekro's Dev Discord<br>Complete reworked version of <a href="https://github.com/zekroTJA/regiusBot">KnechtBot</a> in NodeJS.</strong>
</div>

---

## Information

This is a very powerfull bot administrating my development discord and making the life of my staff team a lot of easier. :^)  
Below, you will se some functions of this bot:

---

### UBAAMS™ (Userbot Administration and Managing System)
With the command `!invite <BotID>`, users can add their own bots on the guild to show others their functions and ask for help.  
Then, all admin users get the invite link as PM from the bot, they need to accept manually. After that, the bot will automatically give the user bot the user bot role. The owner (inviter) of the bot will get the bot owner role to be able to perform some more stuff working with their bots. Also, the bots will lautomatically be renamed with a prefix emoticon and the bots owners name at the end of the name.  
Also all bots and their owners are registered in a database to look which bot belongs to which member.  
Also, every bot needs a unique, registered prefix which can registered and changed by the bots owner with the `!prefix` command, also where you can look for all bots prefixes. This is very important to avoid multiple prefixes which can cause a huge chaos and also, it's easier to get the prefix of a bot if you want to work with it.  
When a user bot gets kicked, the owner will lose the bots owner role automatically and the bot will be unregistered from the database.

### Dev Language Roles
After joining the server, every user should set their languages they have experiences with with the `!dev` command. For a lot of development languages, there are roles on the server synced with an online file, which will be tested if the entered role is able to get with this command, else it would be a command everyone could get every role ^^  
Then other users can mention the specific language roles if they need help in this language.

### Role management
If a user gets promoted or demoted in roles, they get / lose automatically a prefix for their roles. Also, staff members, which are Supporters, Moderators and Admins, automatically get the role "Staff", that you don't need to mention every staff role if you want to mention staff. Also this role will automatically be removed if a member gets demoted.

### User Welcome Messages
When a member joins the guild, he automatically get's a welcome message by the bot with some important information about the guild, roles and bots and which commands he can use and where he can use them.

### User Profiles
With the command `!user <Mention/ID/name>` you can get a detailed information sheet about the targeted user. Also there will be displayed all userbots, if existent, of this user, his roles and his linked GitHub profile, if existent.

---

## Projects

- **Report System**  
    ✅ if someone's getting reported, that will be saved in the database
    🔲 at a special count of reports, the user will be warned (1st report), kicked (2nd report) or banned (3rd report)
    🔲 userdata and last messages saved in files and db if user quits or is getting kicked / banned from the guild
    🔲 kicked users will also be saved that they will be recognized after rejoining that they got reported some times
    ✅ reports / kicks / bans in user profiles (maybe something like VAC ban notification in steam profiles)
    
- **Stats System**
    🔲 Server Stats (onlinem mebs, membs total, supps, message count...) in gspread document
    🔲 -> [npm Gspread Lib](https://www.npmjs.com/package/google-spreadsheet)
