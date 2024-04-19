#!/bin/bash

# This script is meant to be run as the tomcat user
if [[ $USER != 'tomcat' ]]; then
    echo "Please run this script as tomcat"
	exit 1
fi

# Verify proper usage
if [ $# -ne 1 ]; then
    echo "usage: upgrade_tomcat.sh \$version"
	echo "where \$version is the version of tomcat you wish to upgrade to"
	exit 1
fi

# Grab the version we want to use from cmd arg
vers=$1 
v=$(echo $vers | cut -c1-2)

cd ~tomcat

# Download the new version of Tomcat
curl -v https://archive.apache.org/dist/tomcat/tomcat-$v/v$vers/bin/apache-tomcat-$vers.tar.gz -o apache-tomcat-$vers.tar.gz

# Verify the file downloaded correctly.
if [[ -z $(file apache-tomcat-$vers.tar.gz | grep gzip) ]]; then
    # Alternate download location for latest version 
    echo "Attempting alternate download loacation"
    curl -v https://dlcdn.apache.org/tomcat/tomcat-$v/v$vers/bin/apache-tomcat-$vers.tar.gz -o apache-tomcat-$vers.tar.gz
    if [[ -z $(file apache-tomcat-$vers.tar.gz | grep gzip) ]]; then
       echo "Alternate download failed. Downloaded file not a gzip archive. Exiting script."
       exit 1
    fi
fi

# Extract the tar file
tar -zxvf apache-tomcat-$vers.tar.gz

# Compile jsvc daemon
cd apache-tomcat-$vers/bin; tar -zxvf commons-daemon-native.tar.gz 
cd commons-daemon-*-native-src/unix 
export JAVA_HOME=$HOME/java17
./configure && make
# Copy jsvc to the bin directory
cp jsvc ../../
# Return to ~tomcat
cd ~tomcat

# Link the jar files in shared_lib
for i in $(ls shared_lib)
do 
    ln -s ~/shared_lib/$i ~/apache-tomcat-$vers/lib/$i
done 

# Remove current symlink and recreate with new version
if [[ -e apache-tomcat-$vers ]]
then
    rm tomcat10
    ln -s apache-tomcat-$vers tomcat10
else
    echo "apache-tomcat-$vers directory does not exist. Exiting."
	exit 1
fi

# Restart all tomcat instances
#sudo systemctl restart tomcat_*

# And just to display the restarted status
#sudo systemctl -l status tomcat_*

echo "Tomcat 10 upgrade complete"
exit 0
