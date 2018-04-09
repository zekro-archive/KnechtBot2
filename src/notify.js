const main = require('./main.js');
const funcs = require('./funcs.coffee');

const NOTIFY_ROLE_ID = '423370910033117194';


var bot

exports.setBot = (_bot) => {
    bot = _bot

    bot.on('guildMemberAdd', (guild, member) => {
        member.addRole(NOTIFY_ROLE_ID)
    })
}



function ex(msg, args) {

    let memb = msg.member
    let chan = msg.channel

    if (args[0] && args[0] == 'all') {
        
	if (!funcs.checkPerm(memb, 4, chan))
             return;

	let i = 0
        memb.guild.members.forEach(m => {
            if (!m.bot)
                m.addRole(NOTIFY_ROLE_ID)        
        })
        main.sendEmbed(chan, `Added notify role to ${i} members.`)
        return;    
    }

    var has_role = memb.roles.find(r => r == NOTIFY_ROLE_ID)

    if (has_role) {
        memb.removeRole(NOTIFY_ROLE_ID)
        main.sendEmbed(chan, `**Disabled** notification for you, <@${memb.id}>`)
    }
    else {
        memb.addRole(NOTIFY_ROLE_ID)
        main.sendEmbed(chan, `**Enabled** notification for you, <@${memb.id}>`)
    }

}

exports.ex = ex
