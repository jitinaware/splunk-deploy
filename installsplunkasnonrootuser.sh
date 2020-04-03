#!/bin/bash

# Referenced Documentation:
# https://docs.splunk.com/Documentation/Splunk/7.2.6/Security/Secureyouradminaccount#Create_admin_credentials_for_automated_installations_with_the_.27hash-passwd.27_CLI_command

# Variables

SPLUNK_HOME=/opt/splunk/
splunkuser=splunk                              # This is the user that Splunk runs as. Uncomment to enable.
splunkgroup=splunk
#splunkuserpassword=                            # You can specify the password here, instead of the script prompting you.
                                                # NOTE: THIS IS INSECURE. USE ONLY FOR TESTING PURPOSES!
splunkinstallerfilename=splunk-8.0.3-a6754d8441bf-Linux-x86_64.tgz
splunkinstallerdownloadurl="wget -O splunk-8.0.3-a6754d8441bf-Linux-x86_64.tgz 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=8.0.3&product=splunk&filename=splunk-8.0.3-a6754d8441bf-Linux-x86_64.tgz&wget=true'"




# Read secret string
read_secret()
{
    # Disable echo.
    stty -echo

    # Set up trap to ensure echo is enabled before exiting if the script
    # is terminated while echo is disabled.
    trap 'stty echo' EXIT

    # Read secret.
    read "$@"

    # Enable echo.
    stty echo
    trap - EXIT

    # Print a newline because the newline entered by the user after
    # entering the passcode is not echoed. This ensures that the
    # next line of output begins at a new line.
    echo
}


# Installs wget
if [ ! -x /usr/bin/wget ] ; then                                                                          
    command -v wget >/dev/null 2>&1 || command sudo yum -y install wget
fi

## This section creates the splunk user

sudo useradd splunk
printf "Create password for $splunkuser user: "
read_secret splunkuserpassword                                                                              # Prompts input for password
sudo useradd -p $(openssl passwd -1 $splunkuserpassword) $splunkuser                                        # Creates user and sets password (encrypted)
# echo splunk:$password | sudo chpasswd                                                                     # Another way to create the user, but unsure about 'echo' command security
groupadd $splunkgroup                                                                                       # Creates the 'splunk' group



## This section deals with $SPLUNK_HOME


if [ -x $SPLUNK_HOME ] ; then
    echo "$SPLUNK_HOME found, renaming and moving to /tmp/";
    sudo mv -v $SPLUNK_HOME /tmp/splunk_$(date +%d-%m-%Y_%H:%M:%S)
else
    echo "$SPLUNK_HOME not found, progressing with installation..."
fi

sudo mkdir $SPLUNK_HOME
wget -O splunk-8.0.3-a6754d8441bf-Linux-x86_64.tgz 'https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=8.0.3&product=splunk&filename=splunk-8.0.3-a6754d8441bf-Linux-x86_64.tgz&wget=true'
sudo tar -xzvC /opt -f $splunkinstallerfilename
sudo chown -vR $splunkuser:$splunkgroup $SPLUNK_HOME                                                             # Takes ownership of $SPLUNK_HOME to $splunkuser



su - $splunkuser -c "$SPLUNK_HOME/bin/splunk start --accept-license"        
su - $splunkuser -c "$SPLUNK_HOME/bin/splunk stop"        
su - $splunkuser -c "sudo $SPLUNK_HOME/bin/splunk disable boot-start"      

sudo $SPLUNK_HOME/bin/splunk enable boot-start -systemd-managed 1 -user $splunkuser                             # Sets Splunk to run as $splunkuser on boot
su - $splunkuser -c "$SPLUNK_HOME/bin/splunk start" 

#su - $splunkuser -c "$SPLUNK_HOME/bin/splunk edit licenser-localslave -master_uri 'https://master:port"         # Add license slave