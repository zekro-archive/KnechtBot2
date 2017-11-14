require('coffee-script/register');
const Eris = require('eris');
const path = require('path');
const fs = require('fs');
const mysql = require('mysql');
const cmds = require("./cmds.coffee");
const funcs = require("./funcs.coffee");
const colors = require("colors");
const aload = require('after-load');
var config = null;

var VERSION = "2.1.C";
// Extending version with number of commits from github master branch
VERSION += parseInt(aload.$(aload("https://github.com/zekroTJA/KnechtBot2"))('li[class="commits"]').text());

// Getting config object from json file if existent
if (fs.existsSync("config.json")) {
    info("Loading config...")
    config = JSON.parse(fs.readFileSync('config.json', 'utf8'));
} else {
    error("'config.json' does not exists! Please download it from github repository!");
    process.exit(0);
}

// Initialize Token and Prefix from config

info("Loading preferences...")
var token = config["token"];
var PREFIX  = config["prefix"];

// Commands list with invokes
const COMMANDS = {
    "test":     [cmds.test, "just for testing"],
    "help":     [cmds.help, "get this message"],
    "info":     [cmds.info, "get information about this bot"],
    "say":      [cmds.say, "send messages with the bot (also embeds)"],
    "dev":      [cmds.dev, "get dev language roles"],
    "invite":   [cmds.invite, "invite a user bot"],
    "prefix":   [cmds.prefix, "set prefies of your bot(s) or list them of all bots"],
    "github":   [cmds.github, "link your github profile with discord or list all links"],
    "git":      [cmds.github, "*alias for `github`*"],
    "user":     [cmds.user, "get users profile"],
    "profile":  [cmds.user, "*alias for `user`*"],
    "userinfo": [cmds.user, "*alias for `user`*"],
    "id":       [cmds.getid, "get ids of elements by search query"],
    "report":   [cmds.report, "Report a user or get reports of a user"],
    "rep":      [cmds.report, "*Alias for `report`*"]
}

// Getting role settings (permlvl, prefix) of config.json
info("Setting up role preferences...")
const PERMS = {}
exports.rolepres = {}
for (var key in config["roles"]) {
    var role = config["roles"][key];
    PERMS[role["id"]] = role["permlvl"];
    exports.rolepres[role["id"]] = role["prefix"];
}

// Just some color codes
const Color = {
    red:    0xe50202,
    green:  0x51e502,
    cyan:   0x02e5dd,
    blue:   0x025de5,
    violet: 0x9502e5,
    pink:   0xe502b4,
    gold:   0xe5da02,
    orange: 0xe54602
}

// Setting up mysql connectipn properties from config file
info("Setting up MySql connection...")
exports.dbcon = mysql.createConnection({
    host: config["mysql"]["host"],
    user: config["mysql"]["user"],
    password: config["mysql"]["passwd"],
    database: config["mysql"]["database"]
});

// Connecting database
exports.dbcon.connect();
info("Database connected!")

// Map for invited bots and their owners
exports.botInvites = {}
// List of users which get the invite acception message
exports.inviteReceivers = ["98719514908188672"  /* SkillKiller */, "221905671296253953" /* zekro */]



console.log(`\nKnechtBot V2 running on version ${VERSION}\n` + 
            `(c) 2017 Ringo Hoffman (zekro Development)` +
            `All rights reserved.\n\n`); 
info(`Starting up and logging in...`);


// Creating bot instance
const bot = new Eris(token);

// Giving bot instance to cmds and funcs script
cmds.setBot(bot);
funcs.setBot(bot);

/*
    +-------------------+
    | L I S T E N E R S |
    +-------------------+
*/

// Ready listener
bot.on('ready', () => {
    info(`Logged in successfully as account ${bot.user.username}#${bot.user.discriminator}.`); 
    info(`ID: ${bot.user.id}\n\n`);
    // Setting the current members and online members as game message
    funcs.setStatsGame(bot.guilds.find(() => { return true; }));
});

// Command listener
bot.on('messageCreate', (msg) => {
    var cont = msg.content;

    xmammount = parseInt(Math.log(cont.length) * 100)
    funcs.xpchange(msg.member, xmammount == NaN ? 0 : xmammount);

    if (cont.startsWith(PREFIX) && cont.length > PREFIX.length) {
        var invoke = cont.split(" ")[0].substr(PREFIX.length).toLowerCase();
        var args = cont.split(" ").slice(1);
        try {
            console.log(`${"[CMD] ".green} [${msg.member.username} (${msg.member.id})] '${msg.content}'`);
        }
        catch (error) {}
        if (invoke in COMMANDS) {
            try {
                COMMANDS[invoke][0](msg, args);
            } catch (err) {
                sendEmbed(msg.channel, `Following error occured while executing command:\`\`\`\n${err}\n\`\`\``, "Error", Color.red)      
            }
        }
    }
});

// Guild join event
bot.on('guildMemberAdd', (guild, member) => {
    // Refreshing members stats game message
    funcs.setStatsGame(guild);
    // Sending welcome message to new user
    funcs.welcome(member);
    // Handling if joined member is a userbot
    if (member.bot && member.id in exports.botInvites) {
        var owner = exports.botInvites[member.id];
        console.log(exports.botInvites[member.id]);
        funcs.addbot(member, owner);
    }
});

// Guild leave event
bot.on('guildMemberRemove', (guild, member) => {
    // Refreshing members stats game message
    funcs.setStatsGame(guild);
    // Handling if left user was a userbot
    if (member.bot) {
        funcs.removebot(member);
    }
})

// Member update event
bot.on('guildMemberUpdate', (guild, member, oldMember) => {
    // Refreshing members stats game message
    funcs.setStatsGame(guild);
    // Checking and changing role prefixes
    funcs.rolepres(member, oldMember);
})


/*
    +----------------------+
    | E X T R A  F U N C S |
    +----------------------+
*/

/**
 * Sending an embed message.
 * @param {MessageChannel} chan 
 * @param {String} content 
 * @param {String} title 
 * @param {Number} clr
 * @returns Message
 */
function sendEmbed(chan, content, title, clr) {
    if (typeof title === "undefined")
        title = null;
    if (typeof color === "undefined")
        color = null;
    return bot.createMessage(chan.id, {embed: {title: title, description: content, color: clr}})
}

/**
 * Getting current system time  and date 
 * in formatted string
 */
function getTime() {
    function btf(inp) {
    	if (inp < 10)
	    return "0" + inp;
    	return inp;
    }
    var date = new Date(),
        y = date.getFullYear(),
        m = btf(date.getMonth()),
	d = btf(date.getDate()),
	h = btf(date.getHours()),
	min = btf(date.getMinutes()),
    s = btf(date.getSeconds());
    return `${d}.${m}.${y} - ${h}:${min}:${s}`;
}

function error(content) {
    console.log(`[ERROR] ${content}`.red)
}

function info(content) {
    console.log(`${"[INFO] ".cyan} ${content}`)
}

// Export configuration and methods for other scripts
exports.sendEmbed = sendEmbed;
exports.info = info;
exports.error = error;
exports.getTime = getTime;
exports.color = Color;
exports.commands = COMMANDS;
exports.perms = PERMS;
exports.version = VERSION;

// Function loops
//setInterval(funcs.xptimer, 10 * 60 * 1000);

// Connect bot
bot.connect().catch(err => error(`Logging in failed!\n ${err}`));