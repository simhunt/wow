import fetch from 'node-fetch';
import * as dotenv from 'dotenv';
dotenv.config();

const GLOBAL_URL = "https://discord.com/api/v8/applications/<my_application_id>/commands";
const GUILD_URL = "https://discord.com/api/v8/applications/<my_application_id>/guilds/<guild_id>/commands";

const data = {
    "name": "blep",
    "description": "Send a random adorable animal photo",
    "options": [
        {
            "name": "animal",
            "description": "The type of animal",
            "type": 3,
            "required": true,
            "choices": [
                {
                    "name": "Dog",
                    "value": "animal_dog"
                },
                {
                    "name": "Cat",
                    "value": "animal_cat"
                },
                {
                    "name": "Penguin",
                    "value": "animal_penguin"
                }
            ]
        },
        {
            "name": "only_smol",
            "description": "Whether to show only baby animals",
            "type": 5,
            "required": false
        }
    ]
}

const postUrl = process.env.GLOBAL_SLASH_CMD == 'true' ?  // process.env.GLOBAL_SLASH_CMD is a string :(
    GLOBAL_URL.replace('<my_application_id>', process.env.DISCORD_BOT_ID) : 
    GUILD_URL.replace('<my_application_id>', process.env.DISCORD_BOT_ID).replace('<guild_id>', process.env.GUILD_ID)


const getUrl = "https://discord.com/api/v8/applications/<my_application_id>/guilds/<guild_id>/commands"
    .replace('<my_application_id>', process.env.DISCORD_BOT_ID).replace('<guild_id>', process.env.GUILD_ID); // Temporary


// const getUrl = "https://discord.com/api/v8/applications/<my_application_id>/commands"
//     .replace('<my_application_id>', process.env.DISCORD_BOT_ID);

async function main() {
    const request = fetch(postUrl, {
        method: 'POST', // *GET, POST, PUT, DELETE, etc.
        headers: {
            "Authorization": `Bot ${process.env.DISCORD_BOT_TOKEN}`,
            "Content-Type": 'application/json;charset=utf8'
        },
        body: JSON.stringify(data) // body data type must match "Content-Type" header
    });
    // const request = fetch(getUrl, {
    //     method: 'GET', // *GET, POST, PUT, DELETE, etc.
    //     headers: {
    //         "Authorization": `Bot ${process.env.DISCORD_BOT_TOKEN}`,
    //     },
    // });
    const response = await request;
    console.log(`response`)
    console.log(response);
    console.log(`response body: ${response.body.read().toString()}`);
}

main();