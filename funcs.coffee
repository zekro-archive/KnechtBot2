main = require "./main.js"
mysql = require "mysql"

# Getting bot instance from main script
bot = null
exports.setBot = (b) -> bot = b


###
Setting bots game with members stats.
"[...] membs ([...] online) | !help"
###
exports.setStatsGame = (guild) ->
    membs = online = 0
    membarr = guild.members.map (m) -> return m
    for m in membarr
        if !m.bot
            membs++
            if m.status != "offline"
                online++
    bot.editStatus {name: "#{membs} membs (#{online} online) | !help"}


###
Chekcing permission level of member.
Returns if max permsision level, the user has,
is bigger or even the required permission level.
###
exports.checkPerm = (memb, lvl) ->
    maxperm = 0
    for rid in memb.roles
        if rid of main.perms
            perm = main.perms[rid]
            maxperm = if perm > maxperm then perm else maxperm
    return maxperm >= lvl


###
Sending welcome message to (new) member.
###
exports.welcome = (memb) ->
    guild = memb.guild
    bot.getDMChannel(memb.id)
        .then (chan) ->
            main.sendEmbed chan,
                           """
                           **Hey #{memb.mention} and welcome on zekro's Dev Discord!** :wave: 


                           I tell you some interesting stuff you could need to know about this server :^)

                           In the #{bot.getChannel("307085753744228356").mention} cahannel, you can find some more information about the server and the team and please take a look in the #{bot.getChannel("364849566375215104").mention} channel to check out the server rules! ;)

                           We have language roles on the guild which you can add with the command `!dev` *(please only use commands in #{bot.getChannel("358364792614027265").mention})*. Thats helpful if you need help in a special language, then you can mention the group and everyone who has experience in this language will be notificated.

                           If you have some questions, feel free to ask some of the supporters and admins for help :)

                           Now, have a lot of fun on the server and with the community! <3
                           """,
                           null,
                           main.color.gold


###
Adding bot and his owner to mySQL database.
Giving bot the userbot role and owner the bot owner role.
Also the bot will get a prefix in his nickname and the owner's 
name in parenthesis behind the name.
###
exports.addbot = (ubot, owner) ->
    main.dbcon.query 'SELECT * FROM userbots WHERE botid = ?', [ubot.id], (err, res) ->
        if typeof res != "undefined"
            return
    main.dbcon.query 'SELECT * FROM userbots WHERE ownerid = ?', [owner.id], (err, res) ->
        if typeof res != "undefined"
            return
    if !ubot.bot or owner.bot
        return
    main.dbcon.query 'INSERT INTO userbots (botid, ownerid, prefix) VALUES (?, ?, "UNSET")', [ubot.id, owner.id], (err, res) ->
        if !err
            ubot.edit {nick: "🤖 #{ubot.username} (#{if owner.nick != null then owner.nick else owner.username})"}
            bot.addGuildMemberRole ubot.guild.id, ubot.id, "309622223285780481"
            bot.addGuildMemberRole owner.guild.id, owner.id, "324537251071787009"
            for u in main.inviteReceivers
                bot.getDMChannel(u)
                    .then (chan) ->
                        main.sendEmbed chan, "Bot unvite from #{owner.username} got accepted.", "BOT INVTE ACCEPTED", main.color.green
            bot.getDMChannel(owner.id)
                .then (chan) ->
                    main.sendEmbed chan, 
                                   """
                                   Your bot got accepted!

                                   Please now, register your bot's prefix with the `!prefix` command!
                                   **Bot's without an registered prefix will be kicked after one day!**
                                   """, "BOT INVTE ACCEPTED", main.color.green


###
If a bor gets kicked, this will remove its entry from mySQL databse
and will remove bot owner role from the user who was invited the bot.
###
exports.removebot = (ubot) ->
    main.dbcon.query 'SELECT * FROM userbots WHERE botid = ?', [ubot.id], (err, res) ->
        if typeof res == "undefined"
            console.log "BOT NOT REGISTERED"
            return
    main.dbcon.query 'SELECT * FROM userbots WHERE botid = ?', [ubot.id], (err, res) ->
        if !err and res != null
            ownerid = res[0].ownerid
            console.log "OWNER ID: #{ownerid}"
            main.dbcon.query 'DELETE FROM userbots WHERE botid = ?', [ubot.id], (err, res) ->
                if !err
                    bot.removeGuildMemberRole ubot.guild.id, ownerid, "324537251071787009"


###
Changes the nicknames of users if they get or lose a role
entered in main's 'exports.rolepres' map with the set
prefix.
Also adding and removing staff role.
###
exports.rolepres = (after, before) ->
    if before.roles.length < after.roles.length
        for r in after.roles
            if !(r in before.roles)
                if r of main.rolepres
                    after.edit {nick: "#{main.rolepres[r]} #{if after.nick != null then after.nick else after.username}"}
                    bot.addGuildMemberRole after.guild.id, after.id, "373081803487182849"
    else if before.roles.length > after.roles.length
        for r in before.roles
                if !(r in after.roles)
                    if r of main.rolepres
                        try after.edit {nick: "#{after.nick.substring 2, after.nick.length}"}
                        catch e then console.log e
                        bot.removeGuildMemberRole after.guild.id, after.id, "373081803487182849"