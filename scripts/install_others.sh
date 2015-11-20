#!/bin/bash
###############################################################
#File Name      :   startup.sh
#Arthor         :   kylin
#Created Time   :   Wed 08 Sep 2015 11:03:52 AM CST
#Email          :   kylinlingh@foxmail.com
#Blog           :   http://www.cnblogs.com/kylinlin/
#Github         :   https://github.com/Kylinlin
#Version        :	1.0
#Description    :	To install non-suits 's software.
###############################################################

source ~/global_directory.txt

CONFIGURED_OPTIONS=$GLOBAL_DIRECTORY/../log/configured_options.log
UNCONFIGURED_OPTIONS=$GLOBAL_DIRECTORY/../log/unconfigured_options.log

function Install_Necessary_Tools {
	echo -e "\e[1;33mInstalling necessary tools, please wait for a while...\e[0m"
	yum install net-tools -y > /dev/null
	yum install lrzsz -y > /dev/null	
	yum install p7zip -y > /dev/null
}

function Install_Other_Softwares { 
    #echo -e "\e[1;32mInstalling command line web broswer, please wait for a while...\e[0m"
    #yum install links -y > /dev/null
    echo -e "\e[1;35mInstall nagios, yes or no: \e[0m"
    read CHOICE
    if [[ $CHOICE == 'yes' ]]; then
        echo -e "\e[1;35mEnter 1 for nagios_server, 2 for nagios_client: \e[0m"
        read NAGIOS
        if [[ $NAGIOS == 1 ]]; then
            cd $GLOBAL_DIRECTORY/../packages
            wget -qO- https://raw.github.com/Kylinlin/nagios/master/setup_for_server.sh | sh -x
            echo -e "\e[1;32m+Installed nagios_for_server \e[0m" >> $CONFIGURED_OPTIONS
        elif [[ $NAGIOS == 2 ]]; then
            cd $GLOBAL_DIRECTORY/../packages
            wget -qO- https://raw.github.com/Kylinlin/nagios/master/setup_for_client.sh | sh -x
            echo -e "\e[1;32m+Installed nagios_for_client \e[0m" >> $CONFIGURED_OPTIONS
        else
            echo "\e[1;36mWrong input. It will not install nagios. \e[0m"
        fi
    fi
    
}

function Install_DEV_Softwares {
    echo -e "\e[1;33mInstalling develop tools and libraries, please wait for a while...\e[0m"
    yum install gcc -y > /dev/null
    yum install cmake -y > /dev/null
    yum install gcc-c++ -y > /dev/null
    yum install python-devel -y > /dev/null
    yum install java -y > /dev/null
}

function Install_Secure_Softwares { 
    echo -e "\e[1;33mInstalling NMAP, please wait for a while...\e[0m"
    yum install nmap -y > /dev/null
	echo -e "\e[1;32m+Installed Nmap\e[0m" >> $CONFIGURED_OPTIONS

    echo -e "\e[1;33mInstalling Rootkit Hunter, please wait for a while...\e[0m"
    yum install rkhunter -y > /dev/null
	
	echo -e "\e[1;32m+Installed Rkhunter\e[0m" >> $CONFIGURED_OPTIONS

    echo -e "\e[1;33mInstalling and downloading Malware Detect(LMD), please wait for a while...\e[0m"
	rm -rf /usr/local/mal*
	
	MALDETECT=maldetect-1.4.2
	cd $GLOBAL_DIRECTORY/../packages/secure
	tar -xf maldetect-current.tar.gz > /dev/null
	cd $MALDETECT
	./install.sh > /dev/null
	MALDETECT_COND=/usr/local/maldetect/conf.maldet
	if [ -f $MALDETECT_COND.bak ] ; then
		rm -f $MALDETECT_COND
		mv $MALDETECT_COND.bak $MALDETECT_COND
	fi
	cp $MALDETECT_COND $MALDETECT_COND.bak
	echo -n -e "\e[1;35mEnter the email address which you want to reveive the report: \e[0m"
	read EMAIL
	sed -i '/^email_alert=0/c \email_alert=1' $MALDETECT_COND
	sed -i '/^email_subj/c \email_subj="Malware alerts for $HOSTNAME - $(date +%Y-%m-%d)"' $MALDETECT_COND
	sed -i "/^email_addr/c \email_addr=$EMAIL" $MALDETECT_COND
	sed -i '/^quar_hits=0/c \quar_hits=1' $MALDETECT_COND
	sed -i '/^quar_susp=0/c \quar_susp=1' $MALDETECT_COND
	sed -i '/^clamav_scan=0/c \clamav_scan=1' $MALDETECT_COND

    echo -e "\e[1;33mInstalling and downloading Antivirus Engine(ClamAV size:90M), please wait for a while...\e[0m"
    yum install epel-release -y > /dev/null
    yum install clamav-server clamav-data clamav-update clamav-filesystem clamav clamav-scanner-systemd clamav-devel clamav-lib clamav-server-systemd -y > /dev/null
    sed -i -e “s/^Example/#Example/” /etc/freshclam.conf
    sed -i -e “s/^Example/#Example/” /etc/clamd.d/scan.conf
    freshclam
    sed -i '25d' /etc/sysconfig/freshclam 
    sed -i "/^#LocalSocket /var/run/clamd.scan/clamd.sock/c \LocalSocket /var/run/clamd.scan/clamd.sock" /etc/clam.d/scan.conf
    systemctl enable clamd@scan
    ln -s '/usr/lib/systemd/system/clamd@scan.service' '/etc/systemd/system/multi-user.target.wants/clamd@scan.service'

    #Scan Maleware everyday!	
    cp -f cron.daily /etc/cron.daily/
	echo "00 02 *  *  * root run-part /etc/cron.daily"
	systemctl restart crond
    CRON_CONF=/var/spool/cron/root 
	
cat>>$CRON_CONF <<EOF
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root
HOME=/
SHELL=/bin/bash
EOF

	echo -e "\e[1;32m+Installed LMD and ClamAV\e[0m" >> $CONFIGURED_OPTIONS
}



Install_Other_Softwares
Install_Necessary_Tools
Install_DEV_Softwares
Install_Secure_Softwares


echo -e "\e[1;32mInstall finished!!!\e[0m"
