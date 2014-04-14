#  Created by ddrccw on 13-1-21.
#  Modified by ddrccw 14-04-10
#  should fill content into <%%> with your according to your demand.

#!/bin/bash

help()
{
	echo "error param num(case sensitive)!"
	echo "usage:"
	echo "    package --workspace [workspace] --scheme [scheme] --target [target-name] --configration [configuration-name] --sdk [iphonesdk] --public --version [n.n.n] --temp [temp-name]"
	echo ""
	echo "Options:"
	echo "-w, --workspace <workspace>"
	echo "-s, --scheme <scheme>"
	echo "-t, --target <target-name>"
	echo "-c, --configuration <configration>"
	echo "-S, --sdk <iphone-sdk>               argument's value is optional"
	echo "--public                             optional, not add build-number"
	echo "--version                            optional, must be together with -public, ignore version number in package.plist"
	echo "--temp                               optional, argument's value is also optional, suggested to use alphabet or number, not add build-number once setted"
	exit -1	
}

checkSuccess()
{
	#Check if build succeoded
	if [ $? != 0 ]
	then
		echo -e "$ERR_CLR---------** RUN FAILED!!! **------------------$RESET_CLR"
		exit 1
	fi
}

trim() {
    local var=$@
    var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
    var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
    echo "$var"
}

#####################################################################################
# http://stackoverflow.com/questions/16483119/example-of-how-to-use-getopt-in-bash
# http://stackoverflow.com/questions/402377/using-getopts-in-bash-shell-script-to-get-long-and-short-command-line-options
# on Mac OS X and FreeBSD getopt needs to be installed separately
TEMP=`getopt -o w:s:t:c:S:: --long workspace:,scheme:,target:,configuration:,sdk::,public,version:,temp:: -- "$@"`

if [ $? != 0 ] || [ $# -lt 4 ];
then
	help
fi

# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP"

IS_PUBLIC_VERSION=0
TARGET_VERSION=""
SDK="iphoneos"
IS_TEMP_VERSION=0
TEMP_DIR_NAME=`date "+%Y%m%d"`
WORKSPACE=""
SCHEME=""

while true; do
  case "$1" in
	# for options with required arguments, an additional shift is required
	-w|--workspace)
		WORKSPACE="$2"; shift 2;;
	-s|--scheme)
		SCHEME="$2"; shift 2;;
    -t|--target)
		TARGET_NAME="$2"; shift 2;;
    -c|--configuration) CONFIGURATION_NAME="$2"; shift 2;;
    -S|--sdk)
		# s has an optional argument. As we are in quoted mode,
		# an empty parameter will be generated if its optional
		# argument is not found.
		case "$2" in
			"") 
				SDK="iphoneos"; shift 2;;
			*)  
				SDK="$2"; shift 2;;
		esac ;;
	--public) IS_PUBLIC_VERSION=1; shift ;;
	--version)
		param="$2"
		TARGET_VERSION=${param:0}
		shift 2;;
	--temp)
		case "$2" in
			"") IS_TEMP_VERSION=1; shift 2;;
			*) 
				IS_TEMP_VERSION=1;
				TEMP_DIR_NAME="$2";
				shift 2;;
		esac ;;
    --) shift; break ;;
    *) help break ;;
  esac
done


WORKSPACE=`trim "$WORKSPACE"`
SCHEME=`trim "$WORKSPACE"`
TARGET_NAME=`trim "$TARGET_NAME"`
TARGET_VERSION=`trim "$TARGET_VERSION"`

USE_WORKSPACE_AND_SCHEME=1
if [ -z "$WORKSPACE" ] || [ -z "$SCHEME" ];
then
	if [ -z "$TARGET_NAME" ];
	then
		help
	fi
	USE_WORKSPACE_AND_SCHEME=0
	BASIC_BUILD_OPTIONS="-target $TARGET_NAME"
else
	BASIC_BUILD_OPTIONS="-workspace $WORKSPACE.xcworkspace -scheme $SCHEME"
fi

if [ $IS_PUBLIC_VERSION -eq 0 ] && [ ! -z "$TARGET_VERSION" ];
then
	help
fi

#echo "Remaining arguments:"
#for arg do echo '--> '"\`$arg'" ; done

SERVER_IP="192.168.0.109" # such as "192.168.100.100"
SERVER_PORT="8080"    # such as "8000"
ICON_NAME="Icon.png"
ICON_2X_NAME="Icon@2x.png"

PROJECT_NAME=Edu901
PACKAGE_PLIST=./package.plist   #保存不同target的共享信息，版本号
PLIST_BUDDY=/usr/libexec/PlistBuddy
GIT_LOG=$(git log --no-merges --pretty=format:'<li>%s</li>' --abbrev-commit --date=relative -n 7)
XCPRETTY=`type -p xcpretty`  # https://github.com/mneorr/XCPretty

INFO_CLR="\033[01;33m"
RESULT_CLR="\033[01;32m"
RESET_CLR="\033[0m"
ERR_CLR="\033[01;31m"

####################################################################################
xcodebuild -configuration $CONFIGURATION_NAME $BASIC_BUILD_OPTIONS -showBuildSettings | grep --color=never -E '=' | awk -F"=" -v currentPath=$PWD -v useWorkspaceAndScheme=$USE_WORKSPACE_AND_SCHEME '{
	gsub(/[[:blank:]]*/,"",$1);       #去除$1中的所有blank
	sub(/^[[:blank:]|"]*/,"",$2);      #去除头的blank,以及头的双引号
	sub(/[[:blank:]|"]*$/,"", $2);    #去除尾的blank,以及尾的双引号

	#print "export "$1"=\134\""$2"\134\"";
	#print $1"=\134\""$2"\134\"";

	if (tmp == "" && $1=="BUILD_DIR"){
		tmp=$2;
		sub(/\/Products$/, "/", tmp);
		pattern=tmp"[Products|Intermediates]*";
		#print pattern;
		#print tmp;
	}
	else if (tmp !="") {
		#pattern1 = "/Build/[Products|Intermediates]*";
		#pattern1 = "/Build\\\//";
		#print pattern1;
		r = match($2, tmp);
		if (tmp != "" && r) {
			#print tmp" $2="$2;
			#gsub(/\/Users\/user\/Library\/Developer\/Xcode\/DerivedData\/iMCS-dyjtwathdeohngecyfpefawlwwbt\/Build\/[Products|Intermediates]*/, currentPath"/build", $2);
			if (!useWorkspaceAndScheme) {
				gsub(pattern, currentPath"/build", $2);
			}
			else {
				gsub(pattern, currentPath"/derivedDataPath/Build/Products", $2);   #in cooperation with $DERIVED_DATA_PATH
			}
			#gsub(/Build\/[Products|Intermediates]*/, "00000000", $2);
			#print $2;
		}
	}

	print $1"="$2;   #key=value
}' >buildTmp

checkSuccess

while read buf
do
	#echo $c
	arr[$c]=$buf
	let "c = $c + 1"
done <buildTmp

rm -rf buildTmp

#只有awk支持关联数组，shell本身的数组不支持,仅支持数字的下标
#echo "array len:" $c

for((i=0;i<$c;i++));
do
	key=${arr[$i]/=*/}
	value=${arr[$i]/*=/}
	
#	echo $key,$value
#	UID is readonly
	if [ "$key" != "UID" ]; then
#		if [ -d "$value" ]; then
#			echo $key,$value
#		fi
		export $key="$value"
	fi
done

#需要在Http服务器中先配置好
if [ $IS_TEMP_VERSION = 0 ]; then
	if [ $IS_PUBLIC_VERSION = 0 ]; then
		IPA_PATH=$SRCROOT/ipa
		DIR_NAME=$PROJECT_NAME
		DIR_NAME_ENCODE=$PROJECT_NAME
	else
		IPA_PATH=$SRCROOT/ipa-distribution
		DIR_NAME=$PROJECT_NAME-distribution
		DIR_NAME_ENCODE=$PROJECT_NAME%2ddistribution
	fi
else
	IPA_PATH=$SRCROOT/ipa-tmp
	DIR_NAME=$PROJECT_NAME-tmp
	DIR_NAME_ENCODE=$PROJECT_NAME%2dtmp
fi

PAYLOAD_PATH=$IPA_PATH/Payload
SERVER_ROOT="/Users/Shared/WebServer/Documents/$DIR_NAME"  #such as "/Users/Shared/WebServer/Documents/$DIR_NAME"
ICON_PATH=$IPA_PATH
if [ $USE_WORKSPACE_AND_SCHEME ];
then
	DERIVED_DATA_PATH_OPTION="-derivedDataPath $SRCROOT/derivedDataPath"
else
	DERIVED_DATA_PATH_OPTION=""
fi

####################################################################################
echo -e "$INFO_CLR---------** START CLEANING... **------------------$RESET_CLR"

xcodebuild clean -configuration $CONFIGURATION_NAME $BASIC_BUILD_OPTIONS $DERIVED_DATA_PATH_OPTION -sdk $SDK

rm -rf $BUILT_PRODUCTS_DIR
rm -rf $IPA_PATH

echo -e "$RESULT_CLR---------** CLEAN SUCCEEDED **--------------------$RESET_CLR"

####################################################################################
echo -e "$INFO_CLR---------** START BUILDING... **------------------$RESET_CLR"

mkdir -p $PAYLOAD_PATH

if [ -z $TARGET_VERSION ]; then
	VERSION_NUMBER=$($PLIST_BUDDY -c "Print :CFBundleShortVersionString" "$PACKAGE_PLIST")
else 
	VERSION_NUMBER=$TARGET_VERSION
	$PLIST_BUDDY -c "Set :CFBundleShortVersionString $VERSION_NUMBER" "$PACKAGE_PLIST"
fi
$PLIST_BUDDY -c "Set :CFBundleShortVersionString $VERSION_NUMBER" "$INFOPLIST_FILE"

BUILD_NUMBER=$($PLIST_BUDDY -c "Print :CFBundleVersion" "$PACKAGE_PLIST")
if [ $IS_PUBLIC_VERSION = 0 ] && [ $IS_TEMP_VERSION = 0 ]; then
	BUILD_NUMBER=$(($BUILD_NUMBER + 1))    #只有适用于测试环境的app编译时,才增加buildNumber
	$PLIST_BUDDY -c "Set :CFBundleVersion $BUILD_NUMBER" "$PACKAGE_PLIST"
fi

BUNDLE_IDENTIFER=$($PLIST_BUDDY -c "Print :CFBundleIdentifier" "$INFOPLIST_FILE")
$PLIST_BUDDY -c "Set :CFBundleVersion $BUILD_NUMBER" "$INFOPLIST_FILE"

BUILD_NUMBER=$(printf "%06d" $BUILD_NUMBER)
APP_TITLE="$PRODUCT_NAME Version $VERSION_NUMBER(Build $BUILD_NUMBER)"

convert -fill white -pointsize 13 -draw "text 20,69 '$BUILD_NUMBER'" $ICON_NAME $IPA_PATH/$ICON_NAME
convert -fill white -pointsize 26 -draw "text 40,138 '$BUILD_NUMBER'" $ICON_2X_NAME $IPA_PATH/$ICON_2X_NAME
mv $ICON_NAME $ICON_NAME.bak
mv $ICON_2X_NAME $ICON_2X_NAME.bak
cp $IPA_PATH/$ICON_NAME $SRCROOT
cp $IPA_PATH/$ICON_2X_NAME $SRCROOT

if [ -x "$XCPRETTY" ]; then
	xcodebuild -configuration $CONFIGURATION_NAME $BASIC_BUILD_OPTIONS $DERIVED_DATA_PATH_OPTION -sdk $SDK | $XCPRETTY -c 
else
	xcodebuild -configuration $CONFIGURATION_NAME $BASIC_BUILD_OPTIONS $DERIVED_DATA_PATH_OPTION -sdk $SDK
fi

checkSuccess

mv $ICON_NAME.bak $ICON_NAME
mv $ICON_2X_NAME.bak $ICON_2X_NAME

echo -e "$RESULT_CLR---------** BUILD SUCCEEDED **--------------------$RESET_CLR"

####################################################################################
echo -e "$INFO_CLR---------** START PACKAGING... **-----------------$RESET_CLR"

cp -r $BUILT_PRODUCTS_DIR/$WRAPPER_NAME $PAYLOAD_PATH
cd $IPA_PATH
zip -r $PROJECT_NAME.ipa *

checkSuccess

cp -r $DWARF_DSYM_FOLDER_PATH/$DWARF_DSYM_FILE_NAME $IPA_PATH/$PROJECT_NAME.app.dSYM
zip -r $PROJECT_NAME.app.dSYM.zip $PROJECT_NAME.app.dSYM

echo -e "LOCATION:$IPA_PATH"
echo -e "$RESULT_CLR--------** PAKCAGING SUCCEEDED **-----------------$RESET_CLR"

####################################################################################
echo -e "$INFO_CLR--------** START RELEASING... **--------------------$RESET_CLR"

INSTALL_HTML=install.html
APP_URL_ROOT=http://$SERVER_IP:$SERVER_PORT/$DIR_NAME
APP_URL_SUB_ROOT=$APP_URL_ROOT
PUBLISH_VERSION_TIP=''
SERVER_SUB_ROOT=$SERVER_ROOT

if [ $IS_TEMP_VERSION = 0 ]; then
	if [ $IS_PUBLIC_VERSION = 1 ]; then
		PUBLISH_VERSION_TIP="警告:因为使用的是线上环境的数据，请大家小心使用!!!" #such as "警告:因为使用的是线上环境的数据，请大家小心使用!!!"
		cd $SERVER_ROOT
		INDEX_FILE='index.html'
		HISTORY_APPLINKS_HTML=''
		LATEST_APPLINK_HTML=''

		if [ ! -z $TARGET_VERSION ]; then
			APP_URL_SUB_ROOT=$APP_URL_ROOT/$VERSION_NUMBER
			SERVER_SUB_ROOT=$SERVER_ROOT/$VERSION_NUMBER
			TARGET_VERSION_ENCODE=%2F$VERSION_NUMBER
		else
			APP_URL_SUB_ROOT=$APP_URL_ROOT/latest
			SERVER_SUB_ROOT=$SERVER_ROOT/latest
			TARGET_VERSION_ENCODE=%2Flatest
		fi

		mkdir -p $SERVER_SUB_ROOT
		
		for f in `ls $SERVER_ROOT`
		do
			if [ -d "$SERVER_ROOT/$f" ]; then
				if [ $f != 'latest' ]; then
					HISTORY_APPLINKS_HTML="$HISTORY_APPLINKS_HTML<li><a href="$APP_URL_ROOT/$f/$INSTALL_HTML">V$f</a></li>"
				else
					LATEST_APPLINK_HTML="<ul><li><a href="$APP_URL_ROOT/$f/$INSTALL_HTML">latest</a></li></ul>"
				fi
			fi
		done

		cd $IPA_PATH

cat << EOF > $INDEX_FILE
<!DOCTYPE html>
<html>
	<head>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0">
		<title>$APP_TITLE</title>
		<style type="text/css">
			body{
				text-align:center;
				font-family:"Helvetica";
				font-size:13px;
			}
			ul{text-align:left;}
			.container{width:280px;margin:0 auto;}
			h1{margin:0;padding:0;font-size:14px;}
			.caution{color:red}
			footer{font-size:x-small;font-weight:bolder;}
			</style>
	</head>
	<body>
		<div class="container">
			<h2 class="caution">$PUBLISH_VERSION_TIP</h2>
			<h3>历史版本</h3>
			<ul>$HISTORY_APPLINKS_HTML</ul>
			<h3>最新版本</h3>
			$LATEST_APPLINK_HTML
			<footer>`date`</footer>
		</div>
	</body>
</html>
EOF

		cp $INDEX_FILE $SERVER_ROOT
	fi
else
	cd $SERVER_ROOT
	INDEX_FILE='index.html'
	HISTORY_APPLINKS_HTML=''
	
	APP_URL_SUB_ROOT=$APP_URL_ROOT/$TEMP_DIR_NAME
	SERVER_SUB_ROOT=$SERVER_ROOT/$TEMP_DIR_NAME
	TARGET_VERSION_ENCODE=%2F$TEMP_DIR_NAME
	mkdir -p $SERVER_SUB_ROOT

	for f in `ls $SERVER_ROOT`
	do
		if [ -d "$SERVER_ROOT/$f" ]; then
			HISTORY_APPLINKS_HTML="$HISTORY_APPLINKS_HTML<li><a href="$APP_URL_ROOT/$f/$INSTALL_HTML">$f</a></li>"			
		fi
	done

	cd $IPA_PATH

cat << EOF > $INDEX_FILE
<!DOCTYPE html>
<html>
	<head>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0">
		<title>$APP_TITLE</title>
		<style type="text/css">
			body{
				text-align:center;
				font-family:"Helvetica";
				font-size:13px;
			}
			ul{text-align:left;}
			.container{width:280px;margin:0 auto;}
			h1{margin:0;padding:0;font-size:14px;}
			.caution{color:red}
			footer{font-size:x-small;font-weight:bolder;}
			</style>
	</head>
	<body>
		<div class="container">
			<h3>临时版本</h3>
			<ul>$HISTORY_APPLINKS_HTML</ul>
			<footer>`date`</footer>
		</div>
	</body>
</html>
EOF

	cp $INDEX_FILE $SERVER_ROOT
fi


mkdir -p $SERVER_SUB_ROOT
ICON_URL=$APP_URL_SUB_ROOT/$ICON_NAME
PLIST_URL=$APP_URL_SUB_ROOT/$PROJECT_NAME.plist
INSTALL_URL=$APP_URL_SUB_ROOT/$INSTALL_HTML

#检测qrencode，有则encode
QRENCODE=`type -p qrencode &>/dev/null && qrencode "$INSTALL_URL" -s 6 -o - | base64 | sed 's/^\(.*\)/<p><img src="data:image\/png;base64,\1"><\/p>/g'`
GOOGL=$(curl -s -d "{'longUrl':'$INSTALL_URL'}" -H 'Content-Type: application/json' https://www.googleapis.com/urlshortener/v1/url | grep -o 'http://goo.gl/[^\"]*' | sed 's/^\(.*\)/<p><a href="\1">\1<\/a><\/p>/g')


cat << EOF > $INSTALL_HTML
<!DOCTYPE html>
<html>
	<head>
		<meta charset="UTF-8">
		<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=0">
		<title>$APP_TITLE</title>
		<style type="text/css">
			body{
				text-align:center;
				font-family:"Helvetica";
				font-size:13px;
			}
			ul{text-align:left;}
			.container{width:280px;margin:0 auto;}
			h1{margin:0;padding:0;font-size:14px;}
			.caution{color:red}
			.install_button{
				background-image:-webkit-linear-gradient(top,rgb(126,203,26),rgb(92,149,19));
				background-origin:padding-box;background-repeat:repeat;
				-webkit-box-shadow:rgba(0,0,0,0.36) 0px 1px 3px 0px;
				-webkit-font-smoothing:antialiased;
				-webkit-user-select:none;
				background-attachment:scroll;
				background-clip:border-box;
				background-color:rgba(0,0,0,0);
				border-color:#75bc18;
				border-bottom-left-radius:18px;
				border-bottom-right-radius:18px;
				border-bottom-style:none;
				border-bottom-width:0px;
				border-left-style:none;
				border-left-width:0px;
				border-right-style:none;
				border-right-width:0px;
				border-top-left-radius:18px;
				border-top-right-radius:18px;
				border-top-style:none;
				border-top-width:0px;
				box-shadow:rgba(0,0,0,0.359375) 0px 1px 3px 0px;
				cursor:pointer;display:inline-block;margin:10px 0;padding:1px;position:relative;
				-webkit-box-shadow:0 1px 3px rgba(0,0,0,0.36);
				line-height:50px;margin:.5em auto;
			}
			.install_button a{
				-webkit-box-shadow:rgba(255,255,255,0.25) 0px 1px 0px 0px inset;
				-webkit-font-smoothing:antialiased;
				-webkit-user-select:none;
				background-attachment:scroll;
				background-clip:border-box;background-color:rgba(0,0,0,0);
				background-image:-webkit-linear-gradient(top,rgb(195,250,123),rgb(134,216,27) 85%%,rgb(180,231,114));
				background-origin:padding-box;
				background-repeat:repeat;border-bottom-color:rgb(255,255,255);border-bottom-left-radius:17px;border-bottom-right-radius:17px;border-bottom-style:none;border-bottom-width:0px;border-left-color:rgb(255,255,255);border-left-style:none;border-left-width:0px;border-right-color:rgb(255,255,255);border-right-style:none;border-right-width:0px;border-top-color:rgb(255,255,255);border-top-left-radius:17px;border-top-right-radius:17px;border-top-style:none;border-top-width:0px;
				box-shadow:rgba(255,255,255,0.246094) 0px 1px 0px 0px inset;color:#fff;cursor:pointer;display:block;font-size:16px;font-weight:bold;height:36px;line-height:36px;margin:0;padding:0;text-decoration:none;text-shadow:rgba(0,0,0,0.527344) 0px 1px 1px;width:278px;
			}
			.icon{border-radius:10px;box-shadow:1px 2px 3px lightgray;width:57px;height:57px;}
			.release_notes{border:1px solid lightgray;padding:30px 10px 15px 30px;border-radius:8px;overflow:hidden;line-height:1.3em;box-shadow:1px 1px 3px lightgray;}
			.release_notes:before{font-size:10px;content:"Release Notes";background:lightgray;margin:-31px;float:left;padding:3px 8px;border-radius:4px 0 6px 0;color:white;}
			footer{font-size:x-small;font-weight:bolder;}
			</style>
	</head>
	<body>
		<div class="container">
			<p>
			<h2 class="caution">$PUBLISH_VERSION_TIP</h2>
			<img class="icon" src="$ICON_URL"/></p><h1>$APP_TITLE</h1>
			<div class="install_button"><a href="itms-services://?action=download-manifest&url=http%3A%2F%2F$SERVER_IP%3A$SERVER_PORT%2F$DIR_NAME_ENCODE$TARGET_VERSION_ENCODE%2F$PROJECT_NAME.plist">$PRODUCT_NAME</a></div>
			<p><a href="$APP_URL_SUB_ROOT/$PROJECT_NAME.app.dSYM.zip">点击下载dSYM文件(仅开发人员需要)</a></p>
			<ul class="release_notes">$GIT_LOG</ul>
			$GOOGL
			$QRENCODE
			<footer>`date`</footer>
		</div>
	</body>
</html>
EOF

checkSuccess

cat << EOF > $PROJECT_NAME.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>items</key>
	<array>
		<dict>
			<key>assets</key>
			<array>
				<dict>
					<key>kind</key>
					<string>software-package</string>
					<key>url</key>
					<string>$APP_URL_SUB_ROOT/$PROJECT_NAME.ipa</string>
				</dict>
				<dict>
					<key>kind</key>
					<string>display-image</string>
					<key>needs-shine</key>
					<false/>
					<key>url</key>
					<string>$ICON_URL</string>
				</dict>
			</array>
			<key>metadata</key>
			<dict>
				<key>bundle-identifier</key>
				<string>$BUNDLE_IDENTIFER</string>
				<key>bundle-version</key>
				<string>$VERSION_NUMBER</string>
				<key>kind</key>
				<string>software</string>
				<key>subtitle</key>
				<string>Test</string>
				<key>title</key>
				<string>$PROJECT_NAME</string>
			</dict>
		</dict>
	</array>
</dict>
</plist>
EOF

checkSuccess

cat << EOF > $PROJECT_NAME.yml
$PROJECT_NAME:
    Version:		$VERSION_NUMBER
    BuildNumber:	$BUILD_NUMBER
EOF

checkSuccess

cp $INSTALL_HTML $SERVER_SUB_ROOT
cp $PROJECT_NAME.plist $SERVER_SUB_ROOT
cp $PROJECT_NAME.yml $SERVER_SUB_ROOT
cp $PROJECT_NAME.ipa $SERVER_SUB_ROOT
cp $ICON_PATH/$ICON_NAME $SERVER_SUB_ROOT
mv $IPA_PATH/$PROJECT_NAME.app.dSYM.zip $SERVER_SUB_ROOT

echo -e "PLEASE ACCESS THE URL:$INSTALL_URL"
echo -e "$RESULT_CLR--------** RELEASE SUCCEEDED **-------------------$RESULT_CLR"

