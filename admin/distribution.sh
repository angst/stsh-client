#!/bin/bash
set -o errexit

BUILD_STYLE="Release"

VERSION=$(defaults read "$BUILT_PRODUCTS_DIR/$PROJECT_NAME.app/Contents/Info" CFBundleVersion)
DOWNLOAD_BASE_URL="http://stsh.me/dist"
RELEASENOTES_URL="http://stsh.me/dist/release-notes#version-$VERSION"

ARCHIVE_FILENAME="$PROJECT_NAME-$VERSION.zip"
DOWNLOAD_URL="$DOWNLOAD_BASE_URL/$ARCHIVE_FILENAME"
PRIVATE_KEY="~/Dropbox/stsh.dsa.pem"

WD=$PWD
cd "$BUILT_PRODUCTS_DIR"
rm -f "$PROJECT_NAME"*.zip
ditto -ck --keepParent "$PROJECT_NAME.app" "$ARCHIVE_FILENAME"

SIZE=$(stat -f %z "$ARCHIVE_FILENAME")
PUBDATE=$(LC_TIME=c date +"%a, %d %b %G %T %z")

# For OS X >=10.6:
SIGNATURE=$(
	ruby "$PROJECT_DIR"/admin/sign_update.rb "$ARCHIVE_FILENAME" /Users/"$USER"/Dropbox/stsh.dsa.pem
)
# For OS X <=10.5:
#SIGNATURE=$(
#	openssl dgst -sha1 -binary < "$ARCHIVE_FILENAME" \
#	| openssl dgst -dss1 -sign <(security find-generic-password -g -s "$KEYCHAIN_PRIVKEY_NAME" 2>&1 1>/dev/null | perl -pe '($_) = /"(.+)"/; s/\\012/\n/g') \
#	| openssl enc -base64
#)

[ $SIGNATURE ] || { echo Unable to load signing private key with name "'$SIGNATURE'" from keychain; false; }


python - <<EOF
# encoding: utf-8
import sys, re
ITEM = '''
		<item>
			<title>Version $VERSION</title>
			<sparkle:releaseNotesLink>$RELEASENOTES_URL</sparkle:releaseNotesLink>
			<pubDate>$PUBDATE</pubDate>
			<enclosure
				url="$DOWNLOAD_URL"
				sparkle:version="$VERSION"
				type="application/octet-stream"
				length="$SIZE"
				sparkle:dsaSignature="$SIGNATURE"
			/>
		</item>
'''
newver = re.findall(r'sparkle:version="([^"]+)"', ITEM)[0]
newsig = re.findall(r'sparkle:dsaSignature="([^"]+)"', ITEM)[0]

f = open('$WD/admin/appcast.xml','r')
APPCAST = f.read()
f.close()

if newver in re.findall(r'sparkle:version="([^"]+)"', APPCAST):
  print >> sys.stderr, ('Version %s is already in the appcast.xml -- you need to manually '\
  'remove it from the appcast.xml if this is not an error.') % newver
  sys.exit(1)
elif newsig in re.findall(r'sparkle:dsaSignature="([^"]+)"', APPCAST):
  print >> sys.stderr, ('Signature %s is already in the appcast.xml -- you need to manually '\
  'remove it from the appcast.xml if this is not an error.') % newsig
  sys.exit(1)

APPCAST = re.compile(r'(\n[ \r\n\t]*</channel>)', re.M).sub(ITEM.rstrip()+r'\1', APPCAST)
open('$WD/admin/appcast.xml','w').write(APPCAST)
EOF

python - <<EOF
# encoding: utf-8
import sys, re
ITEM = '''
		<section id="version-$VERSION">
			<h2>Version $VERSION</h2>
			<ul>
				<li>DESCRIPTION</li>
			</ul>
		</section>
'''
VERSIONRE = r'<section id="version-([^"]+)">'
newver = re.findall(VERSIONRE, ITEM)[0]

f = open('$WD/admin/release-notes.html','r')
HTML = f.read()
f.close()

if newver in re.findall(VERSIONRE, HTML):
  print >> sys.stderr, ('Version %s is already in the release-notes.html -- you need to manually '\
  'remove it from release-notes.html if this is not an error.') % newver
  sys.exit(1)

HTML = re.compile(r'(\n[ \r\n\t]*</body>)', re.M).sub(ITEM.rstrip()+r'\1', HTML)
open('$WD/admin/release-notes.html','w').write(HTML)
EOF

PATH=~/bin:$PATH # if mate is in home/bin
/usr/local/bin/mate -a "$WD/admin/appcast.xml" "$WD/admin/release-notes.html"
/usr/local/bin/mate -a <<EOF

                  ------------- INSTRUCTIONS -------------

1. Complete the new entry created in release-notes.html

mate '$WD/admin/release-notes.html'

2. Publish the archive, release notes and appcast -- in that order:

scp '$BUILT_PRODUCTS_DIR/$ARCHIVE_FILENAME' stsh.me:/var/www/stsh/current/public/dist/
scp '$WD/admin/release-notes.html' stsh.me:/var/www/stsh/current/public/dist/release-notes.html
scp '$WD/admin/appcast.xml' stsh.me:/var/www/stsh/current/public/dist/appcast.xml

3. Commit, tag and push the source

git ci 'Release $VERSION' -a
git tag -sm 'Release $VERSION' 'v$VERSION'
git pu

EOF
