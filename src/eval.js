var main = require('./main.js');
var funcs = require('./funcs.coffee');
var util = require('util');


var bot;

exports.get = (session) => { 
    bot = session;
    return ex;
}

function ex(msg, args) {
    let guild = msg.member.guild;
    let channel = msg.channel;

    if (!funcs.checkPerm(msg.member, 3, channel))
        return;

    if (args.length == 0) {
        main.sendEmbed(channel, "`!eval <code>`\n*Available variables: `bot`, `msg`, `guild`, `channel`*", "USAGE:", 0xd50000);
        return;
    }
    
    let cmd = args.join(' ');
    let res;
    let success = true;
    try {
        res = eval(cmd);
        if (typeof res !== 'string')
            res = util.inspect(res);
    }
    catch (e) {
        success = false;
        res = e;
    }

    main.sendEmbed(
        channel,
        `\`\`\`${res.length != 0 ? res : "no eval output"}\`\`\``,
        success ? "Eval Output" : "Eval Error",
        success ? 0x76FF03 : 0xd50000
    ).then(m => {
        msg.delete();
        setTimeout(() => m.delete(), 10000);
    });
}