
PACKAGE=$(shell pwd)/package.sh

####################################################################################
#                              not use workspace
####################################################################################

#default: debug
#
#debug:
#	$(PACKAGE) -t <target-for-debug> -c Debug
#
#release:
#	$(PACKAGE) -t <target-for-release> -c Release --public
#
##demo: make release-version v=n.n.n
#release-version:
#	$(PACKAGE) -t <target-for-release> -c Release --public --version $(v)
#
##temp ipa of debug version
#debug-temp:
#	$(PACKAGE) -t <target-for-debug> -c Debug --temp=$(t)
#
##temp ipa of release version
#release-temp:
#	$(PACKAGE) -t <target-for-release> -c Release --temp=$(t)
#
##demo: make compatible-Release t=xxx
#compatible-release:
#	$(PACKAGE) -t <target-for-compatible-release> -c Release
# -siphoneos6.1 --temp=$(t)
#
#
#all: debug release

####################################################################################
#                                use workspace
####################################################################################
default: debug

debug:
	$(PACKAGE) -w DistributionDemo -s DistributionDemo -c Debug

release:
	$(PACKAGE) -w DistributionDemo -s DistributionDemo -c Release --public

#demo: make release-version v=n.n.n
release-version:
	$(PACKAGE) -w DistributionDemo  -s DistributionDemo -c Release --public --version $(v)

#temp ipa of debug version
debug-temp:
	$(PACKAGE) -w DistributionDemo -s DistributionDemo -c Debug --temp=$(t)

#temp ipa of release version
release-temp:
	$(PACKAGE) -w DistributionDemo -s DistributionDemo -c Release --temp=$(t)

#demo: make compatible-Release t=xxx
compatible-release:
	$(PACKAGE) -w DistributionDemo -s DistributionDemo -c Release
 -siphoneos6.1 --temp=$(t)

all: debug release

