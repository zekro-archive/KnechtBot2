require('coffee-script/register');
const Eris = require('eris')
const path = require('path')
const fs = require('fs')
const mysql = require('mysql')
const cmds = require("./cmds.coffee")
const funcs = require("./funcs.coffee")

var config = null;

// Getting config object from json file if existent
if (fs.existsSync("config.json")) {
    config = JSON.parse(fs.readFileSync('config.json', 'utf8'));
} else {
    console.log("[ERROR] 'config.json' does not exists! Please download it from github repository!");
    process.exit(0);
}

// Initialize Token and Prefix from config
var token = config["token"];
var PREFIX  = config["prefix"];

// Commands list with invokes
const COMMANDS = {
    "test": cmds.test,
    "help": cmds.help,
    "info": cmds.info,
    "say": cmds.say,
    "dev": cmds.dev,
    "invite": cmds.invite,
    "prefix": cmds.prefix,
    "github": cmds.github,
    "git": cmds.github,
    "user": cmds.user,
    "profile": cmds.user,
    "userinfo": cmds.user,
}

// Permission roles and their level
const PERMS = {
    "307084714890625024": 3, // Admin
    "307084559303049216": 3, // Owner
    "307084853155725312": 2, // Supporter
    "353193585727766539": 2, // Moderator
    "324537251071787009": 1  // Bot Owner
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

const VERSION = "2.1.3";

// Setting up mysql connectipn properties from config file
exports.dbcon = mysql.createConnection({
    host: config["mysql"]["host"],
    user: config["mysql"]["user"],
    password: config["mysql"]["passwd"],
    database: config["mysql"]["database"]
});

// Connecting database
exports.dbcon.connect();

// Map for invited bots and their owners
exports.botInvites = {}
// List of users which get the invite acception message
exports.inviteReceivers = ["98719514908188672"  /* SkillKiller */, "221905671296253953" /* zekro */]

// Role Prefixes set by giving the role to a user
exports.rolepres = {
    "307084714890625024": "⚡", // Admins
    "307084853155725312": "🌠", // Supporter
    "353193585727766539": "⚔"   // Moderator
}


console.log(`\nKnechtBot V2 running on version ${VERSION}\n` + 
            `(c) 2017 Ringo Hoffman (zekro Development)` +
            `All rights reserved.\n\n` + 
            `Starting up and logging in...`);


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
    console.log(`Logged in successfully as account ${bot.user.username}#${bot.user.discriminator}.\n` + 
                `ID: ${bot.user.id}\n\n`);
    // Setting the current members and online members as game message
    funcs.setStatsGame(bot.guilds.find(() => { return true; }));
});

// Command listener
bot.on('messageCreate', (msg) => {
    var cont = msg.content;
    if (cont.startsWith(PREFIX) && cont.length > PREFIX.length) {
        var invoke = cont.split(" ")[0].substr(PREFIX.length);
        var args = cont.split(" ").slice(1);
        console.log(`[CMD] [${msg.member.username} (${msg.member.id})] '${msg.content}'`);
        if (invoke in COMMANDS) {
            try {
                COMMANDS[invoke](msg, args);
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
    return `[${d}.${m}.${y} - ${h}:${min}:${s}]`;
}

// Export configuration and methods for other scripts
exports.sendEmbed = sendEmbed;
exports.getTime = getTime;
exports.color = Color;
exports.commands = COMMANDS;
exports.perms = PERMS;
exports.version = VERSION;

// Connect bot
bot.connect().catch(err => console.log(`[ERROR] Logging in failed!\n ${err}`));