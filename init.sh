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





confirm() {
	read -p "$1 (y/n): " choice
		case "$choice" in 
		  y|Y ) return 0;;
		  n|N ) return 1;;
		  * ) echo "please enter y or n";;
		esac
		return 2
}

if [ -d "$base" ] && confirm "delete $base?"; then
	rm -rf $base
fi

mkdir $base


# creates a commit in the specified branch
# usage: <trunk or branches/...>
commit() {
	path=$1
	(( counter++ ))
	rm -rf $svn_wc_tmp
	svn co file://$svn_repo/$prefix/$path $svn_wc_tmp
	(
		cd $svn_wc_tmp
		echo "adding entry $counter to a"
		echo "$(date) $counter" >> a
		svn add --force "a"
		svn commit -m "commit $counter, at $path"
	)
}

# creates a branch
# usage: <branches/...> <branches/parent_branch or trunk>
branch() {
	parent=$1
	dest=$2
	(
		cd $svn_wc
		echo "create branch $dest from parent $parent"
		svn copy \
			file://$svn_repo/$prefix/$parent \
			file://$svn_repo/$prefix/$dest \
			-m "create branch $dest from parent $parent"
	)
}

# repeat a command n times
# usage: <n> <command...>
repeat() {
	number=$1
	shift
	for i in `seq $number`; do
		$@
	done
}

# create a svn repository with commits and branches
counter=0
n=2
svn_setup() {
	rm -rf $svn_repo $svn_wc $svn_wc_tmp

	cd $base
	if [ ! -d project1 ]; then
		svnadmin create project1
	fi

	# setup repo
	svn co file://$svn_repo $svn_wc
	(
		cd $svn_wc
		svn mkdir --parents $prefix/trunk $prefix/tags $prefix/branches
		svn commit -m"Creating basic directory structure"
	)

	# create branches and commits
	repeat $n commit trunk
	branch trunk branches/ignore1
	repeat $n commit branches/ignore1
	repeat $n commit trunk
	branch trunk branches/b1
	repeat $n commit branches/b1
	repeat $n commit trunk
	branch branches/b1 branches/b2
	repeat $n commit branches/b1
	repeat $n commit branches/b2

	branch trunk branches/ignore2
	repeat $n commit branches/ignore2
	branch trunk branches/ignore3
	repeat $n commit branches/ignore3
}

svn_setup

# configure git-svn to only import certain branches
svn_remote_branches() {
	branches="$1"
	git config --replace-all svn-remote.svn.ignore-refs "^refs/remotes/origin/(?!($branches)$).*$"
	git config --replace-all svn-remote.svn.include-paths "^$prefix/trunk/.*|^$prefix/branches/($branches)/.*$"
}

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


