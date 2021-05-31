import requests


url = "https://discord.com/api/v8/applications/Nzc5MzA4MTk3NjA0MjI5MTUw.X7epUQ.nYAj_ZPJLBbMu1yehrFeBgjdZJg/guilds/847610096825794581/commands"

json = {
    "name": "blep",
    "description": "Send a random adorable animal photo",
    "options": [
        {
            "name": "animal",
            "description": "The type of animal",
            "type": 3,
            "required": True,
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
            "required": False
        }
    ]
}

# For authorization, you can use either your bot token
headers = {
    "Authorization": "Bot Nzc5MzA4MTk3NjA0MjI5MTUw.X7epUQ.nYAj_ZPJLBbMu1yehrFeBgjdZJg"
}

r = requests.post(url, headers=headers, json=json)