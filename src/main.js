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

var VERSION = "2.4.C";
// Extending version with number of commits from github master branch
VERSION += parseInt(aload.$(aload("https://github.com/zekroTJA/KnechtBot2"))('li[class="commits"]').text());

info(`Started at ${getTime()}`);

// Getting config object from json file if existent
if (fs.existsSync("config.json")) {
    info("Loading config...")
    config = JSON.parse(fs.readFileSync('config.json', 'utf8').substring(1));
} else {
    error("'config.json' does not exists! Please download it from github repository!");
    process.exit(0);
}

// Initialize Token and Prefix from config
info("Loading preferences...")
var token = config.token;
var PREFIX  = config.prefix;
exports.botprefix = config.botprefix

// Commands list with invokes
const COMMANDS = {
    "test":     [cmds.test, "just for testing", 4],
    "help":     [cmds.help, "get this message"],
    "info":     [cmds.info, "get information about this bot"],
    "say":      [cmds.say, "send messages with the bot (also embeds)", 2],
    "dev":      [cmds.dev, "get dev language roles"],
    "invite":   [cmds.invite, "invite a user bot"],
    "prefix":   [cmds.prefix, "set prefies of your bot(s) or list them of all bots", 1],
    "github":   [cmds.github, "link your github profile with discord or list all links"],
    "git":      [cmds.github, "*alias for `github`*"],
    "user":     [cmds.user, "get users profile"],
    "profile":  [cmds.user, "*alias for `user`*"],
    "userinfo": [cmds.user, "*alias for `user`*"],
    "id":       [cmds.getid, "get ids of elements by search query"],
    "report":   [cmds.report, "report a user or get reports of a user"],
    "rep":      [cmds.report, "*Alias for `report`*"],
    "xp":       [cmds.xp, "see xp toplist or xp of specific user"],
    "cmdlog":   [cmds.cmdlog, "get list of last executed commands", 1],
    "whois":    [cmds.whois, "get a member/bot by ID"],
    "restart":  [cmds.restart, "restart the bot", 3],
    "bots":     [cmds.bots, "List all registered bots, manage bot links and whitelist", 2],
    "nots":     [cmds.notification, "Let you get notificated if you user bot goes offline", 1],
    "exec":     [cmds.exec, "Just for testing purposes, privately for zekro ;)", 4]
}

// Getting role settings (permlvl, prefix) of config.json
info("Setting up role preferences...")
const PERMS = {}
exports.rolepres = {}
for (var key in config.roles) {
    var role = config.roles[key];
    PERMS[role.id] = role.permlvl;
    if (role.prefix != "")
        exports.rolepres[role.id] = role.prefix;
}

// Getting bot invite receivers from config.json
exports.inviteReceivers = []
for (var ind in config.invitereceivers)
    exports.inviteReceivers.push(config.invitereceivers[ind]);

console.log(exports.inviteReceivers)


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
    host: config.mysql.host,
    user: config.mysql.user,
    password: config.mysql.passwd,
    database: config.mysql.database
});

// Connecting database
exports.dbcon.connect();
info("Database connected!")

// Map for invited bots and their owners
exports.botInvites = {}



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
    // Checks if 'restart' file is existent
    // -> Send 'restart finished" message if true into saved channel
    //    and deletes file after sending.
    if (fs.existsSync("restarted")) {
        ids = fs.readFileSync('restarted', 'utf8').split(",");
        fs.unlink("restarted", (err) => {
            bot.editMessage(ids[0], ids[1], {embed: {description: "Restart finished. :v:", color: Color.green}});
            if (err)
                console.log(err);
        });
    }
    funcs.createWelcMsg()
});

// Message listener
bot.on('messageCreate', (msg) => {
    var cont = msg.content;

    // Adding ammount of XP from message length to message sender
    try {
        if (msg.channel.type == 0) {
            // Thats a little mathematical function to control xp gain in relation to message lenght
            xmammount = parseInt(Math.log((cont.length / config["exp"]["flatter"]) + config["exp"]["cap"]) * config["exp"]["xpmsgmultiplier"]);
            if (xmammount > 0)
                funcs.xpchange(msg.member, xmammount);
        }
    } catch (e) { error("Faild adding xp to member on message:\n" + e); }
    
    // Command parser
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
                funcs.log(msg);
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
        funcs.addbot(member, owner);
    }
});

// Guild leave event
bot.on('guildMemberRemove', (guild, member) => {
    // Refreshing members stats game message
    funcs.setStatsGame(guild);
    // Handling if left user was a userbot
    funcs.removebot(member);
})

// Member update event
bot.on('guildMemberUpdate', (guild, member, oldMember) => {
    // Checking and changing role prefixes
    funcs.rolepres(member, oldMember);
    // Welcome staff message update
    funcs.welcomeStaff();
    
})

bot.on('presenceUpdate', (other, oldPresence) => {
    guild = other.guild
    if (guild.id == "307084334198816769") {
        // Refreshing members stats game message
        funcs.setStatsGame(guild);
        // Bot notification system handler
        funcs.notshandle(other, oldPresence);
    }
})

bot.on('messageReactionAdd', (msg, emote, userid) => {
    if (userid != bot.user.id && msg.id == exports.welcmsg.id)
        funcs.welcMsgAccepted(msg, emote, userid)
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
 * @returns {*String} formated time stamp
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

/**
 * Getting formatted time from
 * unix time stamp.
 * @param {*Number} timestamp
 * @returns {*String} formated time stamp
 */
exports.formatTime = (timestamp) => {
    function btf(inp) {
    	if (inp < 10)
	    return "0" + inp;
    	return inp;
    }
    var date = new Date(timestamp),
        y = date.getFullYear(),
        m = btf(date.getMonth()),
        d = btf(date.getDate()),
        h = btf(date.getHours()),
        min = btf(date.getMinutes()),
        s = btf(date.getSeconds());
    return `${d}.${m}.${y} - ${h}:${min}:${s}`;
}

/**
 * Short function for sending a colored
 * error message in console.
 * @param {*String} content 
 */
function error(content) {
    console.log(`[ERROR] ${content}`.red)
}

/**
 * Short function for sending a colored
 * information message in console.
 * @param {*String} content 
 */
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
exports.config = config;
exports.welcmsg;

// ID of 'kerbholz' channel, just because I don't want to hardcode it,
// but hardcode it tho' xD
exports.kerbholzid = "342627519825969172"

/*
    +--------------------+
    | F U N C  L O O P S |
    +--------------------+
*/
try {
    setInterval(funcs.xptimer, config["exp"]["interval"] * 60 * 1000);
    info("Startet xp loop")
} catch (e) { error("Failed staring xp loop") }


// Connect bot
bot.connect().catch(err => error(`Logging in failed!\n ${err}`));