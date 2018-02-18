const main = require("./main.js")
const mysql = require("mysql")
const fs = require('fs')
const db = main.dbcon;

const WATCHED_GUILD = '307084334198816769'


var bot = null

exports.setBot = (_bot) => {
    bot = _bot

    setInterval(() => {

        let time = main.getTime()
        let users = bot.guilds
            .find(g => g.id == WATCHED_GUILD).members
            .filter(m => !m.bot)
            .length
        let online = bot.guilds
            .find(g => g.id == WATCHED_GUILD).members
            .filter(m => !m.bot && m.status != 'offline')
            .length
    
        main.dbcon.query(`INSERT INTO stats (time, users, online) VALUES ('${time}', '${users}', '${online}')`)
    
    }, 30 * 60 * 1000)
}