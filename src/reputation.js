const main = require("./main.js")


const EMOJIS = {
    GOOD: '\👍',
    BAD: '\👎',
    IGNORE: '➖',
    HELP: '❓'
}

var msgs = {}


function getRep(member) {
    return new Promise(resolve => {
        if (member) {
            if (member.id)
                member = member.id
            main.dbcon.query('SELECT * FROM rep WHERE member = ?', [member], (err, res) => {
                if (err)
                    throw err
                else
                    resolve(res[0] ? res[0].value : 0)
            })    
        }
        else {
            main.dbcon.query('SELECT * FROM rep', (err, res) => {
                if (err)
                    throw err
                else {
                    let out = {}
                    res.forEach(r => out[r.member] = r.value)
                    resolve(out)
                }
            })
        }
    })
}


exports.cmd = (msg, args) => {

    var chan = msg.channel
    var memb = msg.member

    if (!args[0]) {
        getRep(memb).then(rep => {
            main.sendEmbed(chan, 'Your Reputation: ```' + rep + '```', 'Reputation', main.color.green)
        }).catch(err => {
            main.sendEmbed(chan, 'An error occured ```' + err + '```', 'Error', main.color.red)
        })
        return
    }
    
    var target = memb.guild.members.find(m => 
        m.id == args[0].replace(/[<@!>]/gm, '') ||
        m.id == args[0] ||
        m.username.toLowerCase() == args[0].toLowerCase() ||
        m.username.toLowerCase().startsWith(args[0].toLowerCase()) ||
        m.username.toLowerCase().indexOf(args[0].toLowerCase()) > -1
    )

    if (!target) {
        main.sendEmbed(chan, 'Can not fetch any member to the entered query ```' + args[0] + '```', 'Error', main.color.red)
        return
    }

    getRep(target).then(rep => {
        main.sendEmbed(chan, target.username + '\'s Reputation: ```' + rep + '```', 'Reputation', main.color.green)
    }).catch(err => {
        main.sendEmbed(chan, 'An error occured ```' + err + '```', 'Error', main.color.red)
    })

}


exports.reaction = (msg, emote, userid) => {
    var addr = msgs[msg.id]
    if (addr) {
        if (userid == addr) {
            switch (emote.name) {

                case EMOJIS.HELP:
                    main.sendEmbed(msg.channel, 
                                   `${EMOJIS.GOOD} - This answer was good and helpful\n` +
                                   `${EMOJIS.BAD} - Thsi answer was not good and not helpful\n` +
                                   `${EMOJIS.IGNORE} - Do not give a assessment on this message`,
                                   null, main.color.red)
                        .then(m => setTimeout(() => m.delete(), 30000))
                    break

                case EMOJIS.GOOD:
                    msg.removeReactions().then(() => {
                        msg.addReaction(EMOJIS.GOOD)
                    })
                    main.dbcon.query('UPDATE rep SET value = value + 5 WHERE member = ?', [msg.member.id], (err, res) => {
                        if (err)
                            return
                        if (res.affectedRows == 0) {
                            main.dbcon.query('INSERT INTO rep (member, value) VALUES (?, 5)', [msg.member.id])
                        }
                    })
                    delete msgs[msg.id]
                    break

                case EMOJIS.BAD:
                    msg.removeReactions().then(() => {
                        msg.addReaction(EMOJIS.BAD)
                    })
                    main.dbcon.query('UPDATE rep SET value = value - 4 WHERE member = ?', [msg.member.id], (err, res) => {
                        if (err)
                            return
                        if (res.affectedRows == 0) {
                            main.dbcon.query('INSERT INTO rep (member, value) VALUES (?, -4)', [msg.member.id])
                        }
                    })
                    delete msgs[msg.id]
                    break

                case EMOJIS.IGNORE:
                    msg.removeReactions().then(() => {
                        msg.addReaction(EMOJIS.IGNORE)
                    })
                    delete msgs[msg.id]
                    break
            }
        } 
        else {
            main.sendEmbed(msg.channel, 'Only the adressed member can give an assessment on this answer!', null, main.color.red)
                .then(m => setTimeout(() => m.delete(), 6000))
        }
        msg.removeReaction(emote.name, userid)
    }
}


exports.msgSend = (msg) => {
    var memb = msg.member
    var cont = msg.content

    var match = cont.match(/[aA]:\s?<@!?\d+>/gm)
    console.log(match)

    if (match) {
        let addr = match[0].match(/\d+/gm)[0]
        msgs[msg.id] = addr
        msg.addReaction(EMOJIS.GOOD).then(() => {
            msg.addReaction(EMOJIS.BAD).then(() => {
                msg.addReaction(EMOJIS.IGNORE).then(() => {
                    msg.addReaction(EMOJIS.HELP)
                })
            })
        })
    }
}