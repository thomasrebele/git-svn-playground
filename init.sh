#!/bin/bash

# This script initialize a SVN repository with several branches and imports some of them with git-svn.
# It allows to practice the import of a big SVN project into git.

base=$(realpath playground)
svn_repo=$base/project1
git_repo=$base/git

# working copy
svn_wc=$base/wc-project1
svn_wc_tmp=$base/wc-project1-tmp

prefix="some-path"


source common.sh



if [ -d "$base" ] && confirm "delete $base?"; then
	rm -rf $base
fi

mkdir $base



# create a svn repository with commits and branches
counter=0
n=2
svn_setup $n
svn_example_commits $n


# import first two SVN branches into git
(
	rm -rf git
	git svn init --trunk=$prefix/trunk --branches=$prefix/branches --tags=$prefix/tags file://$svn_repo $git_repo

	cd $git_repo
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

# create a new branch in svn and add some commits
branch branches/b1 branches/b3
repeat $n commit branches/b1
repeat $n commit branches/b3

# 
(
	cd $git_repo
	svn_remote_branches "b1|b2"

	git svn fetch 
)

repeat $n commit branches/b1
repeat $n commit branches/b3

# import the new SVN branch into git
(
	cd $git_repo
	svn_remote_branches "b1|b2|b3"

	echo "\nfetch all"
	git svn fetch --all -r1
	echo "\nfetch again"
	git svn fetch
)

echo
echo "counter: $counter"
echo

# checkout the third branch, commit a change, and push it to SVN
(
	cd $git_repo
	git checkout -b b3 origin/b3

	echo "GIT" >> a
	git add a
	git commit -m "update"
	git svn dcommit
)





