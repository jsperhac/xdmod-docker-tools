#!/bin/bash

XDMOD_GIT_USER=${XDMOD_GIT_USER:-'ubccr'}
XDMOD_GIT_BRANCH=${XDMOD_GIT_BRANCH:-'xdmod9.0'}

#upgrade if you dont want to reingest data and are not testing that portion
#otherwise fresh_install
export XDMOD_TEST_MODE=${XDMOD_TEST_MODE:-'upgrade'}

SRCDIR=/root/src/github.com/ubccr

mkdir -p $SRCDIR

git clone --single-branch https://github.com/$XDMOD_GIT_USER/xdmod/ --branch $XDMOD_GIT_BRANCH $SRCDIR/xdmod

cd $SRCDIR/xdmod
echo "Running composer install"
composer install -q
echo "Composer install finished"

BUILD_DIR=$SRCDIR/xdmod/open_xdmod/build
SCRIPT_DIR=$SRCDIR/xdmod/open_xdmod/build_scripts
mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
echo '%_topdir %(echo $HOME)/rpmbuild' > ~/.rpmmacros

rm -rf $BUILD_DIR/*.tar.gz

$SCRIPT_DIR/build_package.php --module xdmod

for file in $BUILD_DIR/*.tar.gz
do
    rpmfile=$(basename $file)
    rpmname=$(basename $rpmfile .tar.gz)
    pkgname=$(echo $rpmname | egrep -o '^[a-z,-]*' | sed 's/-$//')

    cp $file $HOME/rpmbuild/SOURCES
    cd $HOME/rpmbuild/SPECS
    tar xOf $HOME/rpmbuild/SOURCES/$rpmfile $rpmname/$pkgname.spec > $pkgname.spec
    rpmbuild -bb $pkgname.spec
done
$SRCDIR/xdmod/tests/ci/bootstrap.sh

sed -i -- 's/value: this.dateRanges\[this.defaultCannedDateIndex\].start,$/value: new Date(2016, 11, 22),/' /usr/share/xdmod/html/gui/js/DurationToolbar.js
sed -i -- 's/value: this.dateRanges\[this.defaultCannedDateIndex\].end,$/value: new Date(2018, 7, 2),/' /usr/share/xdmod/html/gui/js/DurationToolbar.js
sed -i -- 's/this.defaultCannedDate = this.dateRanges\[this.defaultCannedDateIndex\].text;/this.defaultCannedDate = "User Defined";/' /usr/share/xdmod/html/gui/js/DurationToolbar.js

\cp /etc/xdmod/portal_settings.ini $SRCDIR/xdmod/configuration

git config --global user.email "jsperhac@buffalo.edu"
git config --global user.name "Jeanette Sperhac"

git init /etc/xdmod
git --git-dir=/etc/xdmod/.git --work-tree=/etc/xdmod add .
git --git-dir=/etc/xdmod/.git --work-tree=/etc/xdmod commit -m init


git init /usr/share/xdmod
git --git-dir=/usr/share/xdmod/.git --work-tree=/usr/share/xdmod add .
git --git-dir=/usr/share/xdmod/.git --work-tree=/usr/share/xdmod commit -m init

# we may want to do this for the purpose of connecting to the docker from campanula:
mysql -e "create user 'root'@'172.17.0.1' identified by ''; GRANT ALL PRIVILEGES ON *.* TO 'root'@'172.17.0.1'; flush privileges;"
