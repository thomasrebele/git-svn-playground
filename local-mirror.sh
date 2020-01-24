#!/bin/bash

# This script initialize a SVN repository with several branches and imports some of them with git-svn.
# It allows to practice the import of a big SVN project into git.

base=$(realpath playground)
svn_repo="$base/project1"
git_repo="$base/git"
svn_mirror="$base/project1_mirror"

# working copy
svn_wc=$base/wc-project1
svn_wc_tmp=$base/wc-project1-tmp
prefix="some-path"



source common.sh

if [ -d "$base" ] && confirm "delete $base?"; then
	rm -rf $base
fi

mkdir "$base"
cd "$base"


# create a svn repository with commits and branches
counter=0
n=1
svn_setup
svn_example_commits $n


(
	cd "$base"
	svnadmin create project1_mirror

	mkdir -p "$svn_mirror"
	cd "$svn_mirror"
	echo '#!/bin/sh' > hooks/pre-revprop-change
	chmod 755 hooks/pre-revprop-change

	# svnsync init "file://$svn_mirror" "file://$svn_repo"
	svnsync init "file://$(realpath .)" "file://$(realpath ../project1)/$prefix"
	svnsync sync "file://$svn_mirror"
)

# import first two SVN branches into git
(
	rm -rf git
	git svn init --trunk=$prefix/trunk --branches=$prefix/branches --tags=$prefix/tags "file://$svn_mirror" $git_repo

	cd $git_repo
	git config svn.pushmergeinfo true
	git config svn-remote.svn.useSvnsyncProps true

	svn_remote_branches "b1|b2"

	echo ""
	git config -l | grep "svn"
	echo ""

	pwd
	git svn fetch -r1

	# fix ref
	git update-ref refs/heads/master $(git show-ref | head -n 1 | awk '{print $2}')

	git svn fetch 
)

# TODO: try git svn dcommit --commit-url ...




