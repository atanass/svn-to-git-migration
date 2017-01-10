#!/bin/bash
#This script is for creating a git repo out from an svn repo.
#This is achieved by exporting the svn history revision by revision into a diff file
#and importing it into the git repo.
#The script is executed from within a local svn repo and takes 2 arguments:
# 1. Path to the desired destination directory for git repo (mandatory)
# 2. Revision range to convert in the format "STARTREV:ENDREV" (optional). This would be translated into
#an svn log -rSTARTENV:ENDREV. This argument is optional and defaults to 1:HEAD (from first revision to the last one)

USAGE="Usage:$0 [path-to-dest-git-dir] [start-revision:end-revision] (default value is 1:HEAD)"

[ $# == 0 ] && echo $USAGE && exit 0


SVN_DIR=`pwd`
GIT_DIR=$1
if [ -z $2 ]; then
  REV_RANGE="1:HEAD"
else
  REV_RANGE=$2 ;
fi

mkdir -p $GIT_DIR ; cd $GIT_DIR ; git init ; cd $SVN_DIR ;

declare -a revisions
revisions=`svn log -r${REV_RANGE} -q | grep -P "^r\d" | awk '{print substr($1, 2, length($1))}'`

for rev in $revisions; do
	echo "Writing to rev-map.txt..." ;
	svn log -r $rev > rev-temp.txt ;
	commit_message=`grep -Pv "[-]{60,}|^$|^r${rev}" rev-temp.txt` ;
	author=`grep -P "^r[\d]{1,5} \|" rev-temp.txt | awk '{print $3}'`;
	echo "Writing to diff-temp.diff..."
	echo $rev ;
	svn diff -c $rev --force --diff-cmd /usr/bin/diff -x "-au --binary" > diff-temp.diff ;
	cd $GIT_DIR ;
	[ -z $commit_message ] && commit_message="Changes, imported from svn" ;
	echo "Patching..."
	patch -p0 --remove-empty-files < $SVN_DIR/diff-temp.diff ;
	git add . ;
	git commit -m "$commit_message" --author "$author <$author@foobar.com>" ;
	cd $SVN_DIR ;
done
