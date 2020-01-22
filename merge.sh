#!/bin/bash

base=$(realpath playground)
svn_repo=$base/project1
git_repo=$base/git

# working copy
svn_wc=$base/wc-project1
svn_wc_tmp=$base/wc-project1-tmp

prefix="some-path"



rm -rf $svn_wc_tmp

path=branches/b1
svn co file://$svn_repo/$prefix/$path $svn_wc_tmp
(
	cd $svn_wc_tmp

	svn merge -q "^/$prefix/branches/b2"

	# "fix" conflict
	perl -pi -e "s/[<>|=]/_/g" a
	svn resolve --accept=working a

	svn commit -m "merge"
)



