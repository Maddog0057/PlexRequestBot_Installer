#!/bin/bash

##############################################################
#                Sonny Installer Script V 0.0.1 			 #
# 		                  Maddog0057			 			 #
# https://github.com/Maddog0057/PlexRequestBot_Installer.git #
##############################################################

install_dependancies() 
{
	clear
	echo "Checking for Dependancies"
	OS="$(awk '/ID_LIKE=/' /etc/os-release | sed 's/ID_LIKE=//')"
	deps=("python3" "python3-pip" "git")
	if [[ $OS =~ debian ]]
	then
		apt update -y
		apt upgrade -y
		pkmgr="apt install -y "
		deps=("python3.6" "python3-pip" "git")
	elif [[ $OS =~ rhel ]]
	then
		yum update -y
		yum upgrade -y
		#yum install -y yum-utils epel-release 
		pkmgr="yum install -y "
		deps=("yum-utils" "epel-release" "python36-setuptools" "git")
	else
		read -p "Could not determine OS, Enter command to install package [ex. apt install -y] " pkmgr
	fi
	for i in "${deps[@]}"
		do
		if [[ "$(which $i 2>&1)" =~ no ]]
		then
			clear
			echo "Installing $i"
			$pkmgr $i
		fi
	done
	if [[ $OS =~ rhel ]]; then easy_install-3.6 pip; fi
			ln -s /bin/python36 /bin/python3
}

env_setup () 
{
	export PATH="$PATH:/usr/bin/local"
	if [[ "$(id -u $usname 2>&1)" =~ no ]]
	then
		useradd $usname -s /sbin/nologin
	fi
	#mkdir /opt/PlexRequestBot
	git clone https://github.com/Maddog0057/PlexRequestBot.git /opt/PlexRequestBot
	mkdir $lpath
	if [[ ! $(echo $lpath) =~ /opt/PlexRequestBot ]]; then chown -R $usname:$usname $lpath; fi
	chown -R $usname:$usname /opt/PlexRequestBot
	cd /opt/PlexRequestBot/
	python3 -m pip install -U https://github.com/Rapptz/discord.py/archive/rewrite.zip
	python3 -m pip install -r requirements.txt
}

fill_vars ()
{
	echo "Enter the following information or press enter to use default values."
	read -p "Enter Discord Bot Name [Sonny] " dname
	dname=${dname:-Sonny}
	read -p "Enter Discord Bot Token [] " dtoken
	dtoken=${dtoken:-0.0.0}
	read -p "Enter Radarr URL [http://localhost:7878/api] " rurl
	rurl=${rurl:-http://localhost:7878/api}
	read -p "Enter path to Movies directory [/mnt/MEDIA/MOVIES] " rpath
	rpath=${rpath:-/mnt/MEDIA/MOVIES}
	read -p "Enter Radarr API Token [] " rapi
	rapi=${rapi:-0}
	read -p "Enter OMDB API Key [] " oapi
	oapi=${oapi:-0}
	read -p "Enter path to log directory (needs a trailing /) [/opt/PlexRequestBot/logs/] " lpath
	lpath=${lpath:-/opt/PlexRequestBot/logs/}
	sdname="$(echo "$dname" | tr '[:upper:]' '[:lower:]')"
	read -p "User to run bot as? (Default is Bot Name) [$sdname] " usname
	usname=${usname:-"$sdname"}
}

config_setup () 
{
	conf_file="/opt/PlexRequestBot/config.json"
	cat <<EOF >$conf_file
{
  "discord":{
    "name":"$dname",
    "token":"$dtoken"
  },
  "radarr":{
    "url":"$rurl",
    "token":"$rapi",
    "path":"$rpath"
  },
  "omdb":{
  	"token":"$oapi"
  },
  "system":{
  	"log":"$lpath"
  }
}
EOF
}

install_service() 
{
	serv_file="/usr/lib/systemd/system/$sdname.service"
	cat <<EOF >$serv_file
[Unit]
Description=$sdname Service
After=network.target

[Service]
Type=idle
ExecStart=/usr/bin/python3 /opt/PlexRequestBot/main.py
WorkingDirectory=/opt/PlexRequestBot
User=$usname
Group=$usname

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
read -p "Run $dname on startup? " start_check
if [[ $start_check =~ ^(yes|y)$ ]]
then
	systemctl enable $sdname
fi
}

main () 
{
	clear
	cat << EOF

PRERQUISITES: Before installation you will need the following:
Discord Bot name and secret: https://discordapp.com/developers/applications/me
URL of your Radarr server (Usually http://localhost:7878/api if running locally)
OMDB Token: http://www.omdbapi.com/apikey.aspx (Free works just fine)

EOF

	read -p "Press [ENTER] Key when you have aquired the prereqs..."
	clear

	#declare -a config_vars
	fill_vars
	clear
	usname=$(echo "$usname" | tr '[:upper:]' '[:lower:]')
	echo "Discord Bot Name: $dname"
	echo "Discord Bot Token: $dtoken"
	echo "Radarr URL: $rurl"
	echo "Radarr Path: $rpath"
	echo "Radarr API Token: $rapi"
	echo "OMDB API Key: $oapi"
	echo "Log Path: $lpath"
	echo "Username to run as: $usname"
	echo " "
	read -p "Are these variables correct? " VAR_CHECK
	if [[ ! $VAR_CHECK =~ ^(yes|y)$ ]]
	then
		fill_vars
	fi

	install_dependancies
	env_setup 
	cd /opt/PlexRequestBot
	config_setup
	clear 
	read -p "Install $dname as a service? " serv_check
	if [[ $serv_check =~ ^(yes|y)$ ]]
	then
		clear
		install_service
	fi
	echo "Complete"
	if [[ $serv_check =~ ^(yes|y)$ ]]
	then
		clear
		echo "$dname can be started and stopped using systemctl start/stop $sdname"
	else
		clear
		echo "$dname can be run from the /opt/PlexRequestBot/ directory using python3 main.py"
	fi
	read -p "Start $dname now? " start_check
	if [[ $start_check =~ ^(yes|y)$ ]]; then systemctl start $sdname; fi
}
if [[ "$EUID" -ne 0 ]]
	then echo "Installer must be run as root!"
	exit 0
else
	main
fi
