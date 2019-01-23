#!/bin/bash

##############################################################
#                Sonny Installer Script V 0.0.1 			 #
# 		                  Maddog0057			 			 #
# https://github.com/Maddog0057/PlexRequestBot_Installer.git #
##############################################################

if [[ "$EUID" -ne 0 ]]
	then echo "Installer must be run as root!"
	exit 0
else
	main
fi

install_dependancies() {
	echo "Checking for Dependancies"

	foreach i in ('python3', 'python3-pip', 'git')
	t=$(which $i)
	if [[ ! $t ]]
		then
			apt install -y $i
	fi
}

function env_setup(name) {
	useradd -s $name /sbin/nologin
	mkdir /opt/PlexRequestBot
	git clone https://github.com/Maddog0057/PlexRequestBot.git /opt
	chown -R $name:$name /opt/PlexRequestBot
	cd /opt/PlexRequestBot/
	python3 -m pip install -U https://github.com/Rapptz/discord.py/archive/rewrite.zip
	pip3 install -r requirements.txt
}

function fill_vars(config_vars){
	echo "Enter the following information or press enter to use default values."
	read -p "Enter Discord Bot Name [Sonny]" config_vars[0]
	BOTNAME=${config_vars[0]:-Sonny}
	read -p "Enter Discord Bot Token []" config_vars[1]
	read -p "Enter Radarr URL [http://localhost:7878/api]" config_vars[2]
	RURL=${config_vars[2]:-http://localhost:7878/api}
	read -p "Enter Radarr API Token []" config_vars[3]
	read -p "Enter OMDB API Key []" config_vars[4]
	return $config_vars
}

config_setup(vars) {
	conf_file="/opt/PlexRequestBot/config.json"
	cat <<EOF >$conf_file
{
  "discord":{
    "name":"${vars[0]}",
    "token":"${vars[1]}"
  },
  "radarr":{
    "url":"${vars[2]}",
    "token":"${vars[3]}"
  },
  "omdb":{
        "token":"${vars[4]}"
  }
}
EOF
}

install_service(name) {
	serv_file="/usr/lib/systemd/system/$name.service"
	cat <<EOF >$serv_file
[Unit]
Description=${name} Service
After=network.target

[Service]
Type=idle
ExecStart=/usr/bin/python3 /opt/PlexRequestBot/main.py
WorkingDirectory=/opt/PlexRequestBot
User=${name}
Group=${name}

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
read -p "Run $name on startup?" start_check
if [[ $start_check =~ ^(yes|y)$ ]]
then
	systemctl enable $name.service
fi
}



function main () {
	cat << EOF
PRERQUISITES: Before installation you will need the following:
Discord Bot name and secret: https://discordapp.com/developers/applications/me
URL of your Radarr server (Usually http://localhost:7878/api if running locally)
OMDB Token: http://www.omdbapi.com/apikey.aspx (Free works just fine)

EOF

	Read -p "Press [ENTER] Key when you have aquired the prereqs..."
	clear

	declare -a config_vars
	fill_vars(vars)
	echo "Discord Bot Name: $config_vars[0]"
	echo "Discord Bot Token: $config_vars[1]"
	echo "Radarr URL: $config_vars[2]"
	echo "Radarr API Token: $config_vars[3]"
	echo "OMDB API Key: $config_vars[4]"
	echo " "
	read -p "Are these variables correct?" VAR_CHECK
	if [[ ! $VAR_CHECK =~ ^(yes|y)$ ]]
	then
		fill_vars(config_vars)
	fi

	install_dependancies
	env_setup(config_vars)
	cd /opt/PlexRequestBot
	config_setup(config_vars)
	read -p "Install $config_vars[0] as a service?" serv_check
	if [[ $serv_check =~ ^(yes|y)$ ]]
	then
		install_service(config_vars[0])
	fi
	echo "Complete"
	if [[ $serv_check =~ ^(yes|y)$ ]]
	then
		echo "$config_vars[0] can be started and stopped using systemctl start/stop $config_vars[0]"
	else
		echo "$config_vars[0] can be run from the /opt/PlexRequestBot/ directory using python3 main.py"
	fi
}
exit 0