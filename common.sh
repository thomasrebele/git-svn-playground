
confirm() {
	read -p "$1 (y/n): " choice
		case "$choice" in 
		  y|Y ) return 0;;
		  n|N ) return 1;;
		  * ) echo "please enter y or n";;
		esac
		return 2
}


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

svn_setup() {
	rm -rf $svn_repo $svn_wc $svn_wc_tmp

	cd "$base"
	if [ ! -d project1 ]; then
		svnadmin create project1
	fi

	# setup repo
	svn co "file://$svn_repo" "$svn_wc"
	(
		cd "$svn_wc"
		svn mkdir --parents $prefix/trunk $prefix/tags $prefix/branches
		svn commit -m"Creating basic directory structure"
	)
}

# make some commits and create some branches
# usage: [<n>]
svn_example_commits() {
	n="${1:-2}"
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

# configure git-svn to only import certain branches
svn_remote_branches() {
	branches="$1"
	git config --replace-all svn-remote.svn.ignore-refs "^refs/remotes/origin/(?!($branches)$).*$"
	git config --replace-all svn-remote.svn.include-paths "^$prefix/trunk/.*|^$prefix/branches/($branches)/.*$"
}

