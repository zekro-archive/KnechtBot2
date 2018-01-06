main = require "./main.js"
funcs = require "./funcs.coffee"
aload = require "after-load"
main = require "./main.js"
fs = require "fs"

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
    if !funcs.checkPerm msg.member, 4, msg.channel
        return
    console.log bot.getUserProfile msg.member.id
    # console.log msg.member.guild.members.find (m) -> m.id = "333707981155729410"
    # funcs.xpchange msg.member, -8
    # RETURN ROLENAMES IN CONSOLE
    # console.log bot.guilds.find(-> return true).roles.map (m) -> return "#{m.name} - #{m.id}"

    # COLOR DEV ROLES LIKE GITHUB COLORS
    # clrs = JSON.parse require("fs").readFileSync('colors.json', 'utf8')
    # for c of clrs
    #     role = msg.member.guild.roles.find (r) -> r.name.toLowerCase() == c.toLowerCase()
    #     if typeof role != "undefined"
    #         bot.editRole msg.member.guild.id, role.id, {color: parseInt clrs[c].replace "#", "0x" }
    #         console.log "Updated role #{role.name} to Color: #{parseInt clrs[c].replace "#", "0x"}"


###
Help command: '!help'
Sends all command invokes in a private message.
###
exports.help = (msg, args) ->
    everyone = botowners = staff = admins = owner = ""
    cmds = main.commands
    for invoke of cmds
        cstr = ":white_small_square:  `!#{invoke}`  -  #{cmds[invoke][1]}\n"
        switch cmds[invoke][2]
            when 1
                botowners += cstr
            when 2
                staff += cstr
            when 3
                admins += cstr
            when 4
                owner += cstr
            else
                everyone += cstr
    ifepty = (inpt) -> if inpt == "" then "- no commands -" else inpt
    emb =
        embed:
            description: "Here you have an overview of all commands of this bot, sorted by required permission levels:"
            color: 0xedde0e
            fields: [
                {
                    name: "[0] - everyone"
                    value: ifepty everyone
                    inline: false
                }
                {
                    name: "[1] - Bot Owners"
                    value: ifepty botowners
                    inline: false
                }
                {
                    name: "[2] - Staff"
                    value: ifepty staff
                    inline: false
                }
                {
                    name: "[3] - Admins"
                    value: ifepty admins
                    inline: false
                }
                {
                    name: "[4] - zekro only"
                    value: ifepty owner
                    inline: false
                }
            ]
    bot.getDMChannel msg.member.id
        .then (chan) -> bot.createMessage chan.id, emb
    bot.deleteMessage msg.channel.id, msg.id


###
Say command: '!say <-e(:[color])> <message>'
Send a message, can be also an embeded message (with customizable color) with the bot.
###
exports.say = (msg, args) ->
    if !funcs.checkPerm msg.member, 2, msg.channel
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
    available = aload.$(aload "https://pastebin.com/raw/7UE5euBg")('pre').text().split ", "

    if args.length > 0
        entered = []
        added = ""
        guildroles = guild.roles.map (r) -> return r
        entered.push(if "," in arg then arg.substring 0, arg.length - 1 else arg) for arg in args
        for rn in entered
            if rn in available
                for role in guildroles
                    if role.name.toLowerCase() == rn
                        bot.addGuildMemberRole guild.id, memb.id, role.id
                        added += "#{role.name}, "
        main.sendEmbed msg.channel,
                       """
                       Successfully added roles:
                       ```
                       #{if added.length == 0 then "- none -" else added.substring 0, added.length - 2}
                       ```
                       """
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
        bot.getDMChannel msg.member.id
            .then (chan) -> main.sendEmbed chan, """
                                                 Because bot invites need's to be accepted manually, the invite link was send to the admins!
                                                 One of them will accept it as soon as possible.
                                                 **Please stay patient** and don't send your invite multiple times!
                                                 It will take approximately 12 to 24 hours until someone will accept if no admin is online
                                                 currently.
                                                 """, null, main.color.gold
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
            if err or res == null or res.length == 0
                main.sendEmbed chan, "Bot with the id `#{botid}` is not registered!", "Error", main.color.red
                return
            if res[0].ownerid != sender.id
                main.sendEmbed chan, "You can only set prefix of your own bots!", "Error", main.color.red
                return
            main.dbcon.query 'SELECT * FROM userbots WHERE prefix = ?', [prefix], (err, res) ->
                if err or res.length > 0
                    main.sendEmbed chan, "The preifix `#{prefix}` is still used!", "Error", main.color.red
                    return
                main.dbcon.query 'UPDATE userbots SET prefix = ? WHERE botid = ?', [prefix, botid], (err, res) ->
                    if err or res == null or res.length == 0
                        main.sendEmbed chan, "There occured an error setting the prefix.", "Error", main.color.red
                        return
                    main.sendEmbed chan, "Prefix successfully set to `#{prefix}`!", "Error", main.color.green


    if args.length < 2
        main.sendEmbed chan, """
                             `!prefix list`  -  List all bots with theirs prefixes
                             `!prefix <BotID> <Prefix>`
                             """, "USAGE:", main.color.red
    else
        if args[0] == "list"
            listbots sender, chan
            return
        botid = args[0]
        ownerid = sender.id
        prefix = args[1]
        set()


listbots = (sender, chan) ->
    out = unset = whitelisted = ""
    main.dbcon.query 'SELECT * FROM userbots', (err, res) ->
        if !err and row != null
            maxlen = 0
            for row in res
                maxlen = if row.prefix.length > maxlen then row.prefix.length else maxlen
            btf = (inpt) ->
                out = inpt
                while out.length < maxlen
                    out += " "
                return out
            for row in res
                ubot = sender.guild.members.find (m) -> m.id == "#{row.botid}"
                uowner = sender.guild.members.find (m) -> m.id == "#{row.ownerid}"            
                if typeof ubot != "undefined" and typeof uowner != "undefined"
                    if row.prefix == "UNSET" and row.whitelisted == 0
                        unset += "#{ubot.username} *(#{uowner.username})*\n"
                    else if row.whitelisted == 0
                        out += "#{btf row.prefix}  -  #{ubot.username} (#{uowner.username})\n"
                    else if row.whitelisted == 1
                        whitelisted += "#{ubot.username} *(#{uowner.username})*\n"
            bot.createMessage chan.id, "**REGISTERED PREFIXES**\n\n```\n#{out}\n```\n\n\n**BOTS WITH UNSET PREFIX**\n\n#{unset}\n\n**WHITELISTED BOTS WITHOUT PREFIX**\n\n#{whitelisted}"


###
Info command: '!info'
Displays info text about bot.
###
exports.info = (msg, args) ->

    emb =
        embed:
            title: "KnechtBot V2 - Info"
            color: main.color.gold
            description: """
                         Discord bot created for managing zekro's Dev Guild.
                         This bot is a rework of [KnechtBot](https://github.com/zekroTJA/regiusBot) project in NodeJS.

                         © 2017 Ringo Hoffmann (zekro Development)
                         """
            thumbnail:
                url: bot.user.avatarURL
            fields: [ 
                {
                    name: "Current Version"
                    value: "v.#{main.version}"
                    inline: false,
                }
                {
                    name: "GitHub"
                    value: "**[KnechtBot V2 GitHub Repository](https://github.com/zekroTJA/KnechtBot2)**"
                    inline: false
                }
                {
                    name: "Contributors"
                    value: """
                           :white_small_square:   [zekro](https://github.com/zekrotja)
                           """
                    inline: false
                }
                {
                    name: "Used 3rd Party Packages"
                    value: """
                           :white_small_square:   [Eris](https://github.com/abalabahaha/eris)
                           :white_small_square:   [CoffeeScript](https://github.com/jashkenas/coffeescript)
                           :white_small_square:   [After-Load](https://www.npmjs.com/package/after-load)
                           :white_small_square:   [MySql](https://github.com/mysqljs/mysql)
                           :white_small_square:   [PushBullet](https://github.com/alexwhitman/node-pushbullet-api)
                           """
                    inline: false,
                } ]
    bot.createMessage msg.channel.id, emb


###
Github command: '!github list'
                '!github add <github profile name>'
                '!github remove'
Command to link github profiles to discord accounts in database.
Thats essential for user command to display github account there.
###
exports.github = (msg, args) ->
    sender = msg.member
    chan = msg.channel

    add = (profile) ->
        main.dbcon.query 'SELECT * FROM github WHERE uid = ?', [sender.id], (err, res) ->
            if res == null or res.length == 0
                main.sendEmbed chan, "Testing profile existence..."
                    .then (m) ->
                        if aload.$(aload "https://github.com/#{profile}")('title').text().indexOf("Page not found") > -1
                            bot.editMessage chan.id, m.id, {embed: {description: "Github profile `#{profile}` does not exist!", color: main.color.red}}
                        else
                            main.dbcon.query 'INSERT INTO github (uid, gitid) VALUES (?, ?)', [sender.id, profile], (err, res) ->
                                if !err
                                    bot.editMessage chan.id, m.id, {embed: {description: "Linked profile `#{profile}` to discord user #{sender.mention}.", color: main.color.green}}
            else if res.length > 0
                main.sendEmbed chan, "Testing profile existence..."
                    .then (m) ->
                        if aload.$(aload "https://github.com/#{profile}")('title').text().indexOf("Page not found") > -1
                            bot.editMessage chan.id, m.id, {embed: {description: "Github profile `#{profile}` does not exist!", color: main.color.red}}
                        else
                            main.dbcon.query 'UPDATE github SET gitid = ? WHERE uid = ?', [profile, sender.id], (err, res) ->
                                if !err
                                    bot.editMessage chan.id, m.id, {embed: {description: "Linked profile `#{profile}` to discord user #{sender.mention}.", color: main.color.green}}

    remove = ->
        main.dbcon.query 'SELECT * FROM github WHERE uid = ?', [sender.id], (err, res) ->
            if res == null or res.length == 0
                main.sendEmbed chan, "You don't have a github profile linked to remove!", null, main.color.red
            else
                main.dbcon.query 'DELETE FROM github WHERE uid = ?', [sender.id], (err, res) ->
                    if !err
                        main.sendEmbed chan, "Successfully unlinked github profile!", null, main.color.green

    list = ->
        main.dbcon.query 'SELECT * FROM github', (err, res) ->
            if !err and res.length > 0
                out = ""
                for row in res
                    user = sender.guild.members.find (m) -> m.id == "#{row.uid}"
                    git = "https://github.com/#{row.gitid}"
                    if typeof user != "undefined"
                        out += ":white_small_square:  [#{user.username}](#{git})\n"
                main.sendEmbed chan, out, "Linked GitHub profiles"

    if args.length > 1
        if args[0] == "add" or args[0] == "link"
            profile = ""
            if args[1].startsWith("https://github.com/")
                profile = args[1].replace("https://github.com/", "")
            else if args[1].startsWith("http://github.com/")
                profile = args[1].replace("http://github.com/", "")
            else if args[1].startsWith("www.github.com/")
                profile = args[1].replace("www.github.com/", "")
            else if args[1].startsWith("github.com/")
                profile = args[1].replace("github.com/", "")
            else
                profile = args[1]
            add profile
    else if args.length > 0
        if args[0] == "remove" or args[0] == "unlink"
            remove()
        else if args[0] == "list"
            list()
    else
        main.sendEmbed chan, """
                             `!git list`  -  List all linked GitHub accounts
                             `!git add <Profile name or URL>`  -  Link GitHub profile to your discord account
                             `!git remove`  -  Unlink GitHub profile from your discord account
                             """, "USAGE:", main.color.red


###
User profile command: '!user <mention/ID/name>'
Get general information about user and his userbots
and registered github profile, when existent.
###
exports.user = (msg, args) ->
    user = null
    if args.length > 0
        if msg.mentions.length > 0
            user = msg.member.guild.members.find (m) -> m.id == msg.mentions[0].id
        else
            user = msg.member.guild.members.find (m) -> m.id == args[0]
            if typeof user == "undefined"
                user = msg.member.guild.members.find (m) -> m.username.toLowerCase().indexOf(args[0].toLowerCase()) > -1
                if typeof user == "undefined"
                    main.sendEmbed msg.channel, "User `#{args[0]}` could not be found!", "Error", main.color.red
                    return

        getRoles = ->
            out = ""
            for r in user.roles
                out += ", " + msg.member.guild.roles.find((role) -> role.id == r).name
            return out.substring 2

        getColor = ->
            switch funcs.getPerm user
                when 0 then return 0xf9f9f9
                when 1 then return 0x0ec4ed
                when 2 then return 0x45ed0e
                when 3 then return 0xed0e0e
                when 4 then return 0xf4024f

        orEmpty = (str) ->
            if !str or str == ""
                return 'empty'
            return str

        botout = ""
        main.dbcon.query 'SELECT * FROM userbots WHERE ownerid = ?', [user.id], (err, res) ->
            if err or res.length == 0
                botout = "No userbots"
            else
                for row in res
                    ubot = msg.member.guild.members.find (b) -> b.id == row.botid
                    if typeof ubot != "undefined"
                        botout += ", " + ubot.mention
                botout = botout.substring 2

            github = ""
            main.dbcon.query 'SELECT * FROM github WHERE uid = ?', [user.id], (err, res) ->
                if err or res.length == 0
                    github = "No GitHub profile linked"
                else
                    github = "[#{res[0].gitid}](https://github.com/#{res[0].gitid})"

                main.dbcon.query 'SELECT * FROM reports WHERE victim = ?', [user.id], (err, res) ->
                    reports = res.length

                    main.dbcon.query 'SELECT * FROM xp WHERE uid = ?', [user.id], (err, res) ->
                        if err or res.length == 0
                            xpval = 0
                        else if !err
                            xpval = res[0].xp
                        xpvals = funcs.xpgetlvl(xpval)
                        xpd = """
                              **LVL #{xpvals[0]}**
                              #{xpvals[1]} / #{xpvals[2]} *(#{xpvals[3]} %)*
                              """

                        emb =
                            embed:
                                title: "#{user.username} - User Profile"
                                thumbnail:
                                    url: orEmpty user.avatarURL
                                color: getColor user
                                fields: [
                                    {
                                        name: "Username"
                                        value: orEmpty "#{user.username}##{user.discriminator}"
                                        inline: false
                                    }
                                    {
                                        name: "Nickname"
                                        value: if user.nick then user.nick else "No nick set"
                                        inline: false
                                    }
                                    {
                                        name: "ID"
                                        value: orEmpty user.id
                                        inline: false
                                    }
                                    {
                                        name: "Current Game"
                                        value: orEmpty "#{if user.game == null then 'No game played' else user.game.name}"
                                        inline: false
                                    }
                                    {
                                        name: "Current Status"
                                        value: orEmpty user.status
                                        inline: false
                                    }
                                    {
                                        name: "Joined Guild at"
                                        value: orEmpty main.formatTime user.joinedAt
                                        inline: false
                                    }
                                    {
                                        name: "Roles on this Guild"
                                        value: orEmpty getRoles()
                                        inline: false
                                    }
                                    {
                                        name: "Permission level"
                                        value: "Lvl.  `#{funcs.getPerm user}`"
                                    }
                                    {
                                        name: "GitHub"
                                        value: "**#{github}**"
                                        inline: false
                                    }
                                    {
                                        name: "Level"
                                        value: orEmpty xpd
                                        inline: false
                                    }
                                    {
                                        name: "Reports"
                                        value: orEmpty "#{if reports == 0 then "This user has a white west!" else "**#{reports} reports** in past."}"
                                        inline: false
                                    }
                                    {
                                        name: "User Bots"
                                        value: orEmpty botout
                                        inline: false
                                    }
                                ]
                        bot.createMessage msg.channel.id, emb


###
ID command: '!id <search query>'
Getting IDs of guild elements by search query.
###
exports.getid = (msg, args) ->
    if args.length < 1
        main.sendEmbed msg.channel, "`!id <search query>`", "USAGE:", main.color.red
        return
    
    query = ""
    query += " " + arg for arg in args
    query = query.substr(1).toLowerCase()
    guild = msg.member.guild
    roles = membs = chans = ""

    roles += "#{r.name}  -  `#{r.id}`\n" for r in guild.roles.filter (role) -> role.name.toLowerCase().indexOf(query) > -1
    chans += "#{c.name}  -  `#{c.id}`\n" for c in guild.channels.filter (chan) -> chan.name.toLowerCase().indexOf(query) > -1
    membs += "#{m.username}  -  `#{m.id}`\n" for m in guild.members.filter (memb) -> memb.username.toLowerCase().indexOf(query) > -1

    emb =
        embed:
            title: "Results for '#{query}'"
            fields: [
                {
                    name: "Roles"
                    value: "#{if roles.length == 0 then "Nothing found." else roles}"
                    inline: false
                }
                {
                    name: "Channels"
                    value: "#{if chans.length == 0 then "Nothing found." else chans}"
                    inline: false
                }
                {
                    name: "Members"
                    value: "#{if membs.length == 0 then "Nothing found." else membs}"
                    inline: false
                }
            ]

    bot.createMessage msg.channel.id, emb

###
Report command: '!report <@mention/ID> <reason>'
                '!report info <@mention/ID>'
Report a user for rule-violating behaviour.
Reports will be saved in the DB and counted.
You can also get info about report state with 'info'
argument or in the profile page of the user ('user' command)
###
exports.report = (msg, args) ->
    chan = msg.channel
    sender = msg.member
    victim = null
    reason = ""

    if args.length < 2
        main.sendEmbed chan, """
                             `!rep <@mention/ID> <reason>`  -  Report a member
                             `!rep info <@mention/ID>`  -  Get all reports of a member
                             """, "USAGE:", main.color.red
        return

    if args[0] == "info"
        if msg.mentions.length > 0
            victim = sender.guild.members.find (m) -> m.id == msg.mentions[0].id
        else    
            victim = sender.guild.members.find (m) -> m.id == args[1]

        if typeof victim == "undefined"
            main.sendEmbed chan, "Please enter a valid member!", "USAGE:", main.color.red
            return

        main.dbcon.query 'SELECT * FROM reports WHERE victim = ?', [victim.id], (err, res) ->
            if !err
                if res.length == 0
                    main.sendEmbed chan, "User #{victim.mention} has a white west! :thumbsup:", "Reports", main.color.green
                else
                    reps = ""
                    for row in res
                        reporter = sender.guild.members.find (m) -> m.id == row.reporter
                        reps += "`[#{row.date}]` - by #{if typeof reporter == "undefined" then "Not more on guild" else reporter.mention} - Reason: #{row.reason}\n"
                    main.sendEmbed chan, """
                                         User #{victim.mention} got reported **#{res.length} times**.

                                         **Reports:**
                                         #{reps}
                                         """, "Reports", main.color.orange
    else
        if !funcs.checkPerm msg.member, 2, msg.channel
            return

        if msg.mentions.length > 0
            victim = sender.guild.members.find (m) -> m.id == msg.mentions[0].id
        else    
            victim = sender.guild.members.find (m) -> m.id == args[0]

        if typeof victim == "undefined"
            main.sendEmbed chan, "Please enter a valid member!", "USAGE:", main.color.red
            return

        reason += " " + arg for arg in args[1..]
        main.dbcon.query 'INSERT INTO reports (victim, reporter, date, reason) VALUES (?, ?, ?, ?)', [victim.id, sender.id, main.getTime(), reason.substr 1], (err, res) ->
            if !err
                main.dbcon.query 'SELECT * FROM reports WHERE victim = ?', [victim.id], (err, res) ->
                    main.sendEmbed chan, "Reported #{victim.mention} by #{sender.mention} for reason ```\n#{reason}\n```\nUser got reported **#{res.length} times** now.", "Report", main.color.orange
                    kerbholz = bot.getChannel main.kerbholzid
                    main.sendEmbed kerbholz, "Reported #{victim.mention} by #{sender.mention} for reason ```\n#{reason}\n```\nUser got reported **#{res.length} times** now.", "Report", main.color.orange
                    if res.length == 2
                        bot.getDMChannel(victim.id)
                            .then (chan) -> main.sendEmbed chan, """
                                                                 :warning:   **WARNING**

                                                                 You got reported **2 times** now on this guild by a staff member.
                                                                 If you will show any rule-violating behaviour again, **you will be kicked or banned!**

                                                                 Remember: Reports will **never** expire and will be always visible in your profile, also
                                                                 all reports of you can be displayed every user with the `!report info` command.
                                                                 Reports will not disappear if you quit and rejoin the guild!
                                                                 """, null, main.color.red


###
XP command: '!xp'
            '!xp <@mention/ID/name>'
Get the current top 20 list of xp on the guild or
get the specific xp ammount and need-xp for next
level of a specified user.
###
exports.xp = (msg, args) ->
    user = null
    if args.length > 0
        if msg.mentions.length > 0
            user = msg.member.guild.members.find (m) -> m.id == msg.mentions[0].id
        else
            user = msg.member.guild.members.find (m) -> m.id == args[0]
            if typeof user == "undefined"
                user = msg.member.guild.members.find (m) -> m.username.toLowerCase().indexOf(args[0].toLowerCase()) > -1
                if typeof user == "undefined"
                    main.sendEmbed msg.channel, "User `#{args[0]}` could not be found!", "Error", main.color.red
                    return
        main.dbcon.query 'SELECT * FROM xp WHERE uid = ?', [user.id], (err, res) ->
            if !err and res.length > 0
                lvldata = funcs.xpgetlvl res[0].xp
                main.sendEmbed msg.channel,
                               """
                               **LVL #{lvldata[0]}** *(#{res[0].xp} XP)*
                               ```
                               #{lvldata[1]} / #{lvldata[2]} (#{lvldata[3]} %)
                               [#{"####################".substring(0, parseInt(20 * lvldata[3] / 100))}#{"                    ".substring(0, 20 - parseInt(20 * lvldata[3] / 100))}]
                               ```
                               """, "LVL OF USER #{user.username}", main.color.gold
    else
        toplist = ""
        main.dbcon.query 'SELECT * FROM `xp` ORDER BY `xp`.`xp` DESC', (err, res) ->
            if !err and res.length > 0
                ind = 0
                numbs = names = xps = ""
                btf = (inpt, should) -> 
                    while should > "#{inpt}".length
                        inpt = "0" + inpt
                    return inpt
                maxxplen = "#{res[0].xp}".length
                for row in res
                    if ind < 20
                        user = msg.member.guild.members.find (m) -> m.id == row.uid
                        if !user.bot
                            toplist += "**#{btf(++ind, 2)}**  -  `LVL #{btf(funcs.xpgetlvl(row.xp)[0], 2)} (#{btf(row.xp, maxxplen)} XP)`  -  #{if typeof user == "undefined" then "Not on server" else user.username}\n"
                emb =
                    embed:
                        title: "GUILD XP TOP 20 LIST"
                        color: main.color.gold
                        description: toplist
                bot.createMessage msg.channel.id, emb


###
Command Log command: '!cmdlog (<@mention/ID/name>)'
Displays last send commands of the bot with username, command + arguments,
timestamp and channel name.
###
exports.cmdlog = (msg, args) ->
    if !funcs.checkPerm msg.member, 1, msg.channel
        return
    user = null
    if args.length > 0
        if msg.mentions.length > 0
            user = msg.member.guild.members.find (m) -> m.id == msg.mentions[0].id
        else
            user = msg.member.guild.members.find (m) -> m.id == args[0]
            if typeof user == "undefined"
                user = msg.member.guild.members.find (m) -> m.username.toLowerCase().indexOf(args[0].toLowerCase()) > -1
                if typeof user == "undefined"
                    main.sendEmbed msg.channel, "User `#{args[0]}` could not be found!", "Error", main.color.red
                    return
    outtext = temptext = "**CMD LIST**\n\n"
    main.dbcon.query 'SELECT * FROM cmdlog', (err, res) ->
        if !err and res.length > 0
            for row in res
                if typeof user == "undefined" or user.id == row.uid
                    temptext += "#{row.uname} - `#{row.content}` in #{row.channame} @ #{row.timestamp}\n"
                    if temptext.length > 2000
                        bot.createMessage msg.channel.id, outtext
                        return
                    else
                        outtext = temptext
            bot.createMessage msg.channel.id, if outtext == "**CMD LIST**\n\n" then "<no commands executed>" else outtext


###
WhoIs command: '!whois <ID>'
Getting the member/bot from an ID.
###
exports.whois = (msg, args) ->
    if args.length > 0
        user = msg.member.guild.members.find (m) -> m.id == args[0]
        if typeof user == "undefined"
            main.sendEmbed msg.channel, "No member found with the ID `#{args[0]}`.", null, main.color.red
        else
            main.sendEmbed msg.channel, """
                                        Found #{if user.bot then "bot" else "member"} #{user.mention} (#{user.username}#{user.discriminator})
                                        """, null, main.color.gold
    else
        main.sendEmbed msg.channel, "`!whois <ID>`", "USAGE:", main.color.red


###
Restart command: '!restart'
Stops the bot. Bash start script auto restarts the
bot after shutdown or crash.
Sender's channelID will be saved in this file to
send back 'restart finished' message after restart.
###
exports.restart = (msg, args) ->
    if !funcs.checkPerm msg.member, 3, msg.channel
        return
    fs.writeFile "restarted", msg.channel.id
    main.sendEmbed msg.channel, "Bot will restart now... :wave:", null, main.color.orange
        .then (m) -> fs.writeFile "restarted", "#{m.channel.id},#{m.id}"
    setTimeout ( -> process.exit(0)), 1000


###
Bots Utilities command: '!bots list'
                        '!bots link <@BotMention> <@UserMention>'
                        '!bots wl <@BotMention>'
With this command for the staff team, we can easily change owners
of bots or link new non-userbots to a member without changing
values in the MySql DB.
Same with the whitelist command, admins can whitelist and
unwhitelist bots without a prefix, because some bots just
don't have commands they need a prefix for.
###
exports.bots = (msg, args) ->
    chan = msg.channel
    help = ->
        main.sendEmbed chan, """
                             `!bots list`  -  List all userbots on this guild
                             `!bots link <Bot Mention> <User Mention>`  -  Manually (re)link a bot to a user
                             `!bots wl <Bot Mention>  -  Whitelist/Unwhitelist a bot from prefix list`
                             """, "USAGE:", main.color.red

    if args.length < 1
        help()
        return
    
    switch args[0]
        when "list"
            listbots msg.member, chan

        when "link"
            if !funcs.checkPerm msg.member, 2, msg.channel
                return
            if args.length < 3
                help()
            else
                u1 = msg.mentions[0]
                u2 = msg.mentions[1]
                if typeof u1 == "undefined" or typeof u2 == "undefined"
                    help()
                else if (u1.bot and u2.bot) or (!u1.bot and !u2.bot)
                    help()
                else
                    ubot = if u1.bot then u1 else u2
                    user = if !u1.bot then u1 else u2
                    main.dbcon.query 'SELECT * FROM userbots WHERE botid = ?', [ubot.id], (err, res) ->
                        if !err and res.length > 0
                            main.dbcon.query 'UPDATE userbots SET ownerid = ? WHERE botid = ?', [user.id, ubot.id], (err, res) ->
                                if err
                                    main.sendEmbed chan, "An error occured while linking:\n```\n#{err}\n```", null, main.color.red
                                else
                                    main.sendEmbed chan, "Successfully linked bot #{ubot.mention} to member #{user.mention}.", null, main.color.green
                        else if !err
                            main.dbcon.query 'INSERT INTO userbots (botid, ownerid, prefix) VALUES (?, ?, "UNSET")', [ubot.id, user.id], (err, res) ->
                                if err
                                    main.sendEmbed chan, "An error occured while linking:\n```\n#{err}\n```", null, main.color.red
                                else
                                    main.sendEmbed chan, "Successfully linked bot #{ubot.mention} to member #{user.mention}.\nPrefix of bot is **UNSET**, please remember setting the prefix or whitelist the bot!", null, main.color.green

        when "wl"
            if !funcs.checkPerm msg.member, 3, msg.channel
                return
            if args.length < 2
                help()
            ubot = msg.mentions[0]
            if typeof ubot == "undefined"
                help()
            else if !ubot.bot
                help()
            else
                main.dbcon.query 'SELECT * FROM userbots WHERE botid = ?', [ubot.id], (err, res) ->
                    if err
                        main.sendEmbed chan, "An error occured while whitelisting:\n```\n#{err}\n```", null, main.color.red
                    else if res.length < 1
                        main.sendEmbed chan, "This bot is not registered in the userbots database! Please link it with `!bots link`", null, main.color.red
                    else if res[0].whitelisted == 0
                        main.dbcon.query 'UPDATE userbots SET whitelisted = 1 WHERE botid = ?', [ubot.id], (err, res) ->
                            if err
                                main.sendEmbed chan, "An error occured while whitelisting:\n```\n#{err}\n```", null, main.color.red
                            else
                                main.sendEmbed chan, "Successfully whitelisted bot #{ubot.mention}.", null, main.color.green
                    else if res[0].whitelisted == 1
                        main.dbcon.query 'UPDATE userbots SET whitelisted == 0 WHERE botid = ?', [ubot.id], (err, res) ->
                            if err
                                main.sendEmbed chan, "An error occured while unwhitelisting:\n```\n#{err}\n```", null, main.color.red
                            else
                                main.sendEmbed chan, "Successfully unwhitelisted bot #{ubot.mention}.", null, main.color.green

        else
            help()


###
Notification function command: '!nots add (<Pushbullet Token>)'
                               '!nots toggle'
                               '!nots remove'
Enable your bot(s) to get notifications if they go offline unexpectedly.
Also you can add ypur pushbullet token which will be saved in the
userbots database to notify you via pushbullet over smartphone for
example if your bot went down.
###
exports.notification = (msg, args) ->
    sender = msg.member
    chan = msg.channel

    help = ->
        main.sendEmbed chan, """
                             `!nots add (<Pushbullet Token¹>)`  -  Get notificated if you bots goes offline
                             `!nots toggle`  -  Pause/Unpause this service
                             `!nots remove`  -  Remove your entry from this list (disabled notifications)
                             ___
                             * ¹ You can enter your Pushbullet API token to get notificated on your phone for example.
                             **[Here](https://gist.github.com/zekroTJA/75d172968db923afce5272e54d431e4d)** you can read ybout how to get your Pushbullet API token.
                             I will not publish the token anywhere and if you don't trust me or my team, just don't set your token.
                             If you want to have your token removed for some reason, just use the `!nots remove` command.
                             """, "USAGE:", main.color.red

    main.dbcon.query 'SELECT * FROM userbots WHERE ownerid = ?', [sender.id], (err, res) ->
        if err
            return
        if res.length < 1
            main.sendEmbed chan, "You don't own any registered bot!", "Error", main.color.red
        else
            switch args[0]
                when "add"
                    main.dbcon.query 'UPDATE userbots SET enabled = 1, pbtoken = ? WHERE ownerid = ?', [(if typeof args[1] != "undefined" then args[1] else ""), sender.id], (err, res) ->
                        if !err
                            main.sendEmbed chan, "Successfully enabled notification service for your bot(s)", null, main.color.green
                        else
                            main.sendEmbed chan, "An error occured while executing SQL query.\n#{err}", "Error", main.color.red
                when "toggle"
                    main.dbcon.query 'UPDATE userbots SET enabled = 1 - enabled WHERE ownerid = ?', [sender.id], (err, res) ->
                        if !err
                            main.dbcon.query 'SELECT * FROM userbots WHERE ownerid = ?', [sender.id], (err, res) ->
                                if res.length > 0
                                    main.sendEmbed chan, "Successfully #{if res[0].enabled == 1 then "enabled" else "disabled"} notification service for your bot(s)", null, main.color.green
                        else
                            main.sendEmbed chan, "An error occured while executing SQL query.\n#{err}", "Error", main.color.red
                when "remove"
                    main.dbcon.query 'UPDATE userbots SET enabled = 0, pbtoken = "" WHERE ownerid = ?', [sender.id], (err, res) ->
                        if !err
                            main.sendEmbed chan, "Successfully cleared your entry from notification system.", null, main.color.green
                        else
                            main.sendEmbed chan, "An error occured while executing SQL query.\n#{err}", "Error", main.color.red
                else
                    help()

            bot.deleteMessage chan.id, msg.id


exports.exec = (msg, args) ->
    if !funcs.checkPerm msg.member, 4, msg.channel
        return
    command = args.join(' ')
    fs.writeFileSync 'src/exec.coffee', """
                                    exports.ex = (bot, msg) ->
                                        #{command}
                                    """
    setTimeout (-> 
        try
            ext = require "./exec.coffee"
            ext.ex bot, msg
        catch e
            console.log e
        finally
            fs.unlink 'src/exec.coffee'
    ), 500


exports.kick = (msg, args) ->
    if !funcs.checkPerm msg.member, 3, msg.channel
        return

    if args.length < 3 || args.join(' ').split('-r ').length < 2
        main.sendEmbed msg.channel, "`!kick <UserID> -r <Reason>`", "USAGE:", main.color.red

    guild = msg.member.guild
    reason = args.join(' ').split('-r ')[1]
    victim = args[0]

    if not guild.members.find((m) -> m.id == victim)
        main.sendEmbed msg.channel, "Can not find a user on this guild with the ID ```#{victim}```", "ERROR", main.color.red
        return

    embk =
        embed:
            description: """#{guild.members.find((m) -> m.id == victim).username} got kicked from the Guild."""
            color: 0xe74c3c
            fields: [
                {
                    name: "Executor"
                    value: """#{msg.author.username}"""
                    inline: false
                }
                {
                    name: "Reason"
                    value: """#{reason}"""
                    inline: false
                }
            ]
    bot.createMessage main.kerbholzid, embk

    emb =
        embed:
            description: """You got kicked from the Guild `#{guild.name}`"""
            color: 0xe74c3c
            image:
                url: "https://media.giphy.com/media/H99r2HtnYs492/giphy.gif"
            fields: [
                {
                    name: "Executor"
                    value: """#{msg.author.username}"""
                    inline: false
                }
                {
                    name: "Reason"
                    value: """#{reason}"""
                    inline: false
                }
            ]
    bot.getDMChannel victim
        .then (chan) -> bot.createMessage chan.id, emb
        .then ->
            bot.kickGuildMember guild.id, victim, "Kicked by an staff member"

    main.dbcon.query 'INSERT INTO reports (victim, reporter, date, reason) VALUES (?, ?, ?, ?)', [victim, message.member.id, main.getTime(), "[KICK] " + reason], (err, res) ->
        if !err
            main.dbcon.query 'SELECT * FROM reports WHERE victim = ?', [victim.id], (err, res) ->
                if res.length == 2
                    bot.getDMChannel(victim.id)
                        .then (chan) -> main.sendEmbed chan, """
                                                             :warning:   **WARNING**

                                                             You got reported **2 times** now on this guild by a staff member.
                                                             If you will show any rule-violating behaviour again, **you will be kicked or banned!**

                                                             Remember: Reports will **never** expire and will be always visible in your profile, also
                                                             all reports of you can be displayed every user with the `!report info` command.
                                                             Reports will not disappear if you quit and rejoin the guild!
                                                             """, null, main.color.red


exports.ban = (msg, args) ->
    if !funcs.checkPerm msg.member, 4, msg.channel
        return

    if args.length < 3 || args.join(' ').split('-r ').length < 2
        main.sendEmbed msg.channel, "`!ban <UserID> -r <Reason>`", "USAGE:", main.color.red

    guild = msg.member.guild
    reason = args.join(' ').split('-r ')[1]
    victim = args[0]

    if not guild.members.find((m) -> m.id == victim)
        main.sendEmbed msg.channel, "Can not find a user on this guild with the ID ```#{victim}```", "ERROR", main.color.red
        return

    embk =
        embed:
            description: """#{guild.members.find((m) -> m.id == victim).username} got banned from the Guild."""
            color: 0xe74c3c
            fields: [
                {
                    name: "Executor"
                    value: """#{msg.author.username}"""
                    inline: false
                }
                {
                    name: "Reason"
                    value: """#{reason}"""
                    inline: false
                }
            ]
    bot.createMessage main.kerbholzid, embk

    emb =
        embed:
            description: """You got banned from the Guild `#{guild.name}`"""
            color: 0xe74c3c
            image:
                url: "https://media.giphy.com/media/H99r2HtnYs492/giphy.gif"
            fields: [
                {
                    name: "Executor"
                    value: """#{msg.author.username}"""
                    inline: false
                }
                {
                    name: "Reason"
                    value: """#{reason}"""
                    inline: false
                }
            ]
    bot.getDMChannel victim
        .then (chan) -> bot.createMessage chan.id, emb
        .then ->
            bot.banGuildMember guild.id, victim, 7, "Banned by an staff member"

    main.dbcon.query 'INSERT INTO reports (victim, reporter, date, reason) VALUES (?, ?, ?, ?)', [victim, message.member.id, main.getTime(), "[BAN] " + reason], (err, res) ->
        if !err
            main.dbcon.query 'SELECT * FROM reports WHERE victim = ?', [victim.id], (err, res) ->
                if res.length == 2
                    bot.getDMChannel(victim.id)
                        .then (chan) -> main.sendEmbed chan, """
                                                             :warning:   **WARNING**

                                                             You got reported **2 times** now on this guild by a staff member.
                                                             If you will show any rule-violating behaviour again, **you will be kicked or banned!**

                                                             Remember: Reports will **never** expire and will be always visible in your profile, also
                                                             all reports of you can be displayed every user with the `!report info` command.
                                                             Reports will not disappear if you quit and rejoin the guild!
                                                             """, null, main.color.red