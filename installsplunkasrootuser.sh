#!/bin/bash

# Not tested on 8.x and above!

# Variables

SPLUNK_HOME=/opt/splunk
splunkuser=splunk                               # This is the user that Splunk runs as. Uncomment to enable.
splunkgroup=splunk
splunkuserpassword=                           # You can specify the password here, instead of the script prompting you.
                                                # NOTE: THIS IS INSECURE. USE ONLY FOR TESTING PURPOSES!
splunkinstallerfilename=splunk-7.3.5.tgz
splunkinstallerdownload="wget -O $splunkinstallerfilename https://www.splunk.com/page/download_track?file=7.3.5/linux/splunk-7.3.5-86fd62efc3d7-Linux-x86_64.tgz&ac=&wget=true&name=wget&platform=Linux&architecture=x86_64&version=7.3.5&product=splunk&typed=release"



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




## This section deals with $SPLUNK_HOME


if [ -x $SPLUNK_HOME ] ; then
    echo "$SPLUNK_HOME found, renaming and moving to /tmp/";
    sudo mv -v $SPLUNK_HOME /tmp/splunk_$(date +%d-%m-%Y_%H:%M:%S)
else
    echo "$SPLUNK_HOME not found, progressing with installation..."
fi

sudo mkdir $SPLUNK_HOME
$splunkinstallerdownload
sudo tar -xzvC /opt -f $splunkinstallerfilename
sudo chown -vR root $SPLUNK_HOME                                                             # Takes ownership of $SPLUNK_HOME to $splunkuser

$SPLUNK_HOME/bin/splunk start --accept-license                                               # Starts splunk as $splunkuser, still needs password input, admin acct not created
sudo $SPLUNK_HOME/bin/splunk enable boot-start                                               # Sets splunk to start on boot

$SPLUNK_HOME/bin/splunk start --accept-license     

#$SPLUNK_HOME/bin/splunk set default-hostname $hostname
#$SPLUNK_HOME/bin/splunk set servername $hostname
#$SPLUNK_HOME/bin/splunk edit licenser-localslave -master_uri 'https://master:port'      # Add license slave