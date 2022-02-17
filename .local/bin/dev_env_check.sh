#!/usr/bin/env bash
set -e

__looksgood() {
    read  -n 1 -p "🤔🤔 Press y/Y if all is looking good? : 🤔🤔" __looks_good
    if [[ "$__looks_good" == "Y" || "$__looks_good" == "y" ]]; then
        echo ""
        echo ""
        echo "💯💯 Great  💯💯"
        echo ""
        sleep 1
    else
        echo ""
        echo ""
        echo "🤬🤬 Go and fix the problema then retry  🤬🤬"
        echo ""
        sleep 5
        exit 1
    fi
}

echo "################################################################################################"
echo "#####################                  Java                      ###############################"
echo "################################################################################################"
echo ""
echo ""

unset expected_java_home

if [[  $JAVA_HOME  ]]; then
    echo ""
    echo "😀😀  JAVA_HOME=$JAVA_HOME  😀😀"
    echo ""
else
    echo ""
    echo "💢💢 JAVA_HOME is not set 💢💢"
    echo ""
fi

if hash javac &>/dev/null ; then
	expected_java_home=$(dirname $(dirname $(readlink -f "$(which javac)")))
elif hash java &>/dev/null ; then
    echo ""
	echo "🤨🤨 Java compiler (javac) not installed, which is not recommended, Using java instead 🤨🤨"
	expected_java_home=$(dirname $(dirname $(readlink -f "$(which java)")))
    echo ""
else
    echo ""
	echo "💢💢 Java not installed, please install Java 💢💢"
    echo ""
fi

if [[  $JAVA_HOME != $expected_java_home ]] ; then
    echo ""
    echo "Actual Java executable is pointing to $expected_java_home"
    echo "But JAVA_HOME is pointing to $JAVA_HOME"
    echo "😵‍💫😵‍💫 this two should be same 😵‍💫😵‍💫"
    echo ""
else
    echo ""
    echo "🥰🥰 All looks good for java 🥰🥰"
    echo ""
    echo "java --version"
    java --version
    echo ""
    echo "javac --version"
    javac --version
    echo ""
fi

__looksgood

unset expected_maven_home


if [[  $MAVEN_HOME  ]]; then
    echo ""
    echo "😀😀  MAVEN_HOME=$MAVEN_HOME  😀😀"
    echo ""
else
    echo ""
    echo "💢💢 MAVEN_HOME is not set 💢💢"
    echo ""
fi

if hash mvn &>/dev/null ; then
	expected_maven_home=$(dirname $(dirname $(readlink -f "$(which mvn)")))
else
    echo ""
	echo "💢💢 mvn not installed, please install Apache Maven 💢💢"
    echo ""
fi

if [[  $MAVEN_HOME != $expected_maven_home ]] ; then
    echo ""
    echo "Actual maven executable is pointing to $expected_maven_home"
    echo "But MAVEN_HOME is pointing to $MAVEN_HOME"
    echo "😵‍💫😵‍💫 this two should be same 😵‍💫😵‍💫"
    echo ""
else
    echo ""
    echo "🥰🥰 All looks good for Maven also 🥰🥰"
    echo ""
    echo "mvn --version"
    mvn --version
    echo ""
fi

__looksgood

echo ""
echo ""
echo "################################################################################################"
echo "#####################                  Java                      ###############################"
echo "################################################################################################"
