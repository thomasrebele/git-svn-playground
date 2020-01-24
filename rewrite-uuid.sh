#!/bin/bash

base=$(realpath playground)
svn_repo="$base/project1"
svn_workdir="$base/project1_wd"
git_repo="$base/git"
svn_mirror="$base/project1_mirror"

# working copy
svn_wc=$base/wc-project1


mkdir "$base"
cd "$base"

if [ ! -d project1 ]; then
	svnadmin create project1
fi

# setup repo
svn co "file://$svn_repo" "$svn_wc"
(
	cd "$svn_wc"
	svn mkdir --parents trunk tags branches
	svn commit -m"Creating basic directory structure"
)

svn co "file://$svn_repo/trunk" "$svn_workdir"
(
	cd $svn_workdir
	echo "1" >> a
	svn add --force "a"
	svn commit -m "commit"
)

(
	cd "$base"
	svnadmin create project1_mirror

	mkdir -p "$svn_mirror"
	cd "$svn_mirror"
	echo '#!/bin/sh' > hooks/pre-revprop-change
	chmod 755 hooks/pre-revprop-change

	svnsync init "file://$(realpath .)" "file://$(realpath ../project1)"
	svnsync sync "file://$svn_mirror"
)

uuid_repo=$(svnlook uuid "$svn_repo")
uuid_mirror=$(svnlook uuid "$svn_mirror")

echo "uuid repo: $uuid_repo"
echo "uuid mirror: $uuid_mirror"

(
	rm -rf git
	git svn init --stdlayout "file://$svn_repo" $git_repo

	cd $git_repo
	git config svn.pushmergeinfo true
	#git config svn-remote.svn.useSvnsyncProps true
	# git config svn-remote.svn.rewriteRoot "file://$svn_repo"
	# git config svn-remote.svn.rewriteUUID "$uuid_repo"

	echo ""
	echo "git-svn config:"
	git config -l | grep "svn"
	echo ""

	pwd
	git svn fetch -r1

	git checkout origin/trunk

	git log --pretty=full | cat

	git svn find-rev r1
)




