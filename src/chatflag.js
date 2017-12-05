const main = require('./main.js')
const fs   = require('fs')
require('extendutils')

var bot

const type = {
    BLACKLISTED_LINK: "BLACKLISTED_LINK",
}

var flags = {}

function _maxperm(memb) {
    var lvl = memb.roles
    .map(rid => {
        return main.perms[rid]
    })
    .sort((a, b) => b - a)[0]
    return lvl ? lvl : 0
}

function setBot(_bot) {
    bot = _bot
    if (fs.existsSync('flags.json'))
        flags = require('../flags.json')
}

function check(msg) {
    var memb = msg.member
    var cont = msg.content
    if (_maxperm(memb) < 2) {
        var linkflags = !flags.links ? [] : flags.links
        if (cont.contains(linkflags) && cont.contains(['http://', 'https://', 'www.'])) {
            bot.deleteMessage(msg.channel.id, msg.id, `Not allowed content: ${type.BLACKLISTED_LINK}`)
            main.dbcon.query(
                'INSERT INTO chatflags (time, user, msg, channel, channelname, type) VALUES (?, ?, ?, ?, ?, ?)',
                [new Date(), memb.id, cont, msg.channel.id, msg.channel.name, type.BLACKLISTED_LINK]
            )
            bot.getDMChannel(memb.id)
                .then((chan) => main.sendEmbed(chan, "Sending flaged links **is absolutly not allowed** on this guild, so your message got deleted and an the flag was saved in the database.", "NOT ALLOWED LINK", main.color.red))
        }
    }
}

function edit(msg, args) {
    if (args.length < 1) {
        main.sendEmbed(msg.channel, "```!flaglinks\n<URL1>\n<URL2>\n...```", "USAGE", main.color.red)
        return
    }
    else if (args[0] == "list") {
        var linkflags = !flags.links ? [] : flags.links
        main.sendEmbed(msg.channel, "Current links on flaglist:\n```" + linkflags.join('\n') + "```", null, main.color.green)
        return
    }
    var links = args.join(" ").split("\n").slice(1)
    flags.links = links
    fs.writeFile('flags.json', JSON.stringify(flags), (err) => {
        if (err)
            main.sendEmbed(msg.channel, err, "ERROR", main.color.red)
        else
            main.sendEmbed(msg.channel, "Sucessfully added following links to flaglist:\n```" + links.join('\n') + "```", null, main.color.green)
    })
    
}


exports.setBot = setBot
exports.check = check
exports.edit = edit