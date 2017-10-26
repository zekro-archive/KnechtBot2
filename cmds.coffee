main = require "./main.js"
funcs = require "./funcs.coffee"
aload = require "after-load"
main = require "./main.js"

# Getting bot instance from main script
bot = null
exports.setBot = (b) -> bot = b


###
<>      -> Argument
(<>)    -> optional argument
[]      -> variable option
###


# Just a test command for development purposes
exports.test = (msg, args) ->
    console.log bot.guilds.find(-> return true).roles.map (m) -> return "#{m.name} - #{m.id}"


###
Help command: '!help'
Sends all command invokes in a private message.
###
exports.help = (msg, args) ->
    cmdlist = ""
    for invoke of main.commands
        cmdlist += ":white_small_square:  `#{invoke}`\n"
    bot.getDMChannel(msg.author.id)
        .then (chan) ->
            main.sendEmbed chan,
                           """
                           Hey! :wave:

                           Currently, this bot is in early developent, so a lot of functions of the old Knecht Bot will be implemented later ;)

                           **Commands:**
                           #{cmdlist}
                           """


###
Say command: '!say <-e(:[color])> <message>'
Send a message, can be also an embeded message (with customizable color) with the bot.
###
exports.say = (msg, args) ->
    if !funcs.checkPerm msg.member, 2
        console.log "Not permitted"
        return
    if args.length > 0
        argstr = ""
        argstr += arg + " " for arg in args
        if argstr.toLowerCase().indexOf("-e") > -1 and argstr.toLowerCase().indexOf("-e") < 1
            color = main.color.gold
            if argstr.toLowerCase().indexOf("-e:") > -1
                clrstr = argstr.toLowerCase().split("-e:")[1].split(" ")[0]
                if clrstr of main.color
                    color = main.color[clrstr]
                argstr = argstr.split("-e:#{clrstr} ")[1]
            else
                argstr = argstr.split("-e ")[1]
            main.sendEmbed msg.channel, argstr, null, color
        else
            bot.createMessage msg.channel.id, argstr
    else
        colors = ""
        colors += "'#{c}', " for c of main.color
        main.sendEmbed msg.channel,
                       """
                       `!say <message>`  -  Send a normal message
                       `!say -e <message>`  -  Send an gold colored embed message
                       `!say -e:<color> <message>`  -  Send an colored embed message
                        *Available colors: #{colors.substring 0, colors.length - 2}*
                       """,
                       "USAGE:",
                       main.color.red
    bot.deleteMessage msg.channel.id, msg.id


###
Dev command: '!dev (<lang1>) (<lang2>) (<lang3>) ...'
Adding dev language roles to sender.
Roles will be get out of an online pastebin text file.
###
exports.dev = (msg, args) ->
    memb = msg.member
    chan = msg.channel
    guild = memb.guild
    available = aload.$(aload "https://pastebin.com/raw/7UE5euBg")('pre').text().split(", ")

    if args.length > 0
        entered = []
        added = failed = ""
        guildroles = guild.roles.map (r) -> return r
        for arg in args
            entered.push if "," in arg then arg.substring(0, arg.length - 1) else arg
        for rn in entered
            if rn in available
                for role in guildroles
                    if role.name.toLowerCase() == rn
                        bot.addGuildMemberRole guild.id, memb.id, role.id
                        added += "#{role.name}, "
                    else if role.name.toLowerCase() in entered
                        failed += "#{role.name} (failed), "
            else
                failed += "#{rn} (not available), "
        main.sendEmbed msg.channel,
                       """
                       Added roles:
                       ```
                       #{if added.length == 0 then "- none -" else added.substring 0, added.length - 2}
                       ```
                       Failed adding roles:
                       ```
                       #{if failed.length == 0 then "- none -" else failed.substring 0, failed.length - 2}
                       ```
                       """,
                       null,
                       main.color.gold
    else
        avstring = "" 
        avstring += "#{av}, " for av in available
        main.sendEmbed msg.channel,
                       """
                       `!dev lang1 lang2 lang3 ...`  -  Add lanuage roles

                       Available roles:
                       ```
                       #{avstring.substring 0, avstring.length - 2}
                       ```
                       """,
                       "USAGE:",
                       main.color.red


###
Invite command: '!invite (<botId>)'
Invite your bot as a userbot to the server.
In main's 'exports.inviteReceivers' map's members will receive a message with
the assmebled invite link, which they need to accept manually. Then, the botowner
will get a message and the bot and owner will be pushed in main's 'exports.botinvites'
list to prepare for bot acception procedure.
###
exports.invite = (msg, args) ->
    if args.length > 0
        bid = args[0]
        main.botInvites[args[0]] = msg.member
        console.log main.botInvites
        for u in main.inviteReceivers
            bot.getDMChannel(u)
                .then (chan) ->
                    main.sendEmbed chan, "[Bot unvite from #{msg.author.username}](https://discordapp.com/oauth2/authorize?client_id=#{bid}&scope=bot)", "BOT INVTE", main.color.gold
    else
        main.sendEmbed msg.channel, "`!invite <botID>`\n*You can get your Bot ID from the [Discord Apps Panel](https://discordapp.com/developers/applications/me) from `Client ID`.*", "USAGE:", main.color.red


###
Prefix command: '!prefix (<botId>) (<prefix>)'
With no argument, the command will display all bots and their owners
with the registered prefix. All unregistered bots will be listed 
in a special list below.
Prefix can be set with entering botID and prefix as argument.
In dtabase will be checked before, if bot is registered as userbot,
if the prefix ist still given to another bot and if the sender is the
owner of the bot he will change prefix of.
###
exports.prefix = (msg, args) ->
    botid = ownerid = prefix = null
    chan = msg.channel
    sender = msg.member

    set = ->
        main.dbcon.query 'SELECT * FROM userbots WHERE botid = ?', [botid], (err, res) ->
            if err or res == null
                main.sendEmbed chan, "Bot with the id `#{botid}` is not registered!", "Error", main.color.red
                return
            if res[0].ownerid != sender.id
                main.sendEmbed chan, "You can only set prefix of your own bots!", "Error", main.color.red
                return
            main.dbcon.query 'SELECT * FROM userbots WHERE prefix = ?', [prefix], (err, res) ->
                if err or res.length > 0
                    console.log res
                    console.log prefix
                    main.sendEmbed chan, "The preifix `#{prefix}` is still used!", "Error", main.color.red
                    return
                main.dbcon.query 'UPDATE userbots SET prefix = ? WHERE botid = ?', [prefix, botid], (err, res) ->
                    if err or res == null
                        main.sendEmbed chan, "There occured an error setting the prefix.", "Error", main.color.red
                        return
                    main.sendEmbed chan, "Prefix successfully set to `#{prefix}`!", "Error", main.color.green

    list = ->
        out = ""
        unset = ""
        main.dbcon.query 'SELECT * FROM userbots', (err, res) ->
            if !err and row != null
                for row in res
                    ubot = sender.guild.members.find (m) -> m.id == "#{row.botid}"
                    uowner = sender.guild.members.find (m) -> m.id == "#{row.ownerid}"
                    if typeof ubot != "undefined" and typeof uowner != "undefined"
                        if row.prefix == "UNSET"
                            unset += "#{ubot.username} *(#{uowner.username})*\n"
                        else
                            out += "#{ubot.username} *(#{uowner.username})*  -  `#{row.prefix}`\n"
                bot.createMessage chan.id, "**REGISTERED PREFIXES**\n\n#{out}\n\n\n**BOTS WITH UNSET PREFIX**\n\n#{unset}"


    if args.length < 2
        list()
    else
        botid = args[0]
        ownerid = sender.id
        prefix = args[1]
        set()
        