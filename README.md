This README file was not present in the upstream source and has been written by
Andrew Harvey.

INSTALL
=======

To compile and install you can issue

    > mvn compile test package

Or you are running Debian and don't wish to download a bunch of 3rd party java libraries from the web you can try

    > mvn-debian compile test package

However, I was unable to complete the build using `mvn-debian`. I got stuck when it couldn't find org.xnap.commons:maven-gettext-plugin as that isn't packaged for debain. You will also run into problems trying to package jspc-maven-plugin... what a mess, sigh.

But to get at least that far I needed to change the web/pom.xml jasper version to 6.0.32 (for libtomcat6-java)

Also to hack around http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=596420 you may need to do this:

    > cd /usr/share/maven-repo/org/eclipse/
    > sudo mkdir -p jdt/core/compiler/ecj/debian/
    > sudo ln -s -T /usr/share/java/eclipse-ecj.jar ecj-debian.jar
    > sudo pico ecj-debian.pom

with something like:
    <?xml version='1.0' encoding='UTF-8'?>
    <project xmlns="http://maven.apache.org/POM/4.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4_0_0.xsd">
        <modelVersion>4.0.0</modelVersion>
        <groupId>org.eclipse.jdt.core.compiler</groupId>
        <artifactId>ecj</artifactId>
        <version>debian</version>
        <packaging>jar</packaging>
        <description>blah blah Package</description>
    </project>

I also had to install http://anonscm.debian.org/gitweb/?p=pkg-java/libpjl-comp-filter-java.git

I also had to fix javax.servlet.jsp/jsp-api with
    su -
    mkdir -p /usr/share/maven-repo/javax/servlet/jsp/jsp-api/debian/
    cp /usr/share/maven-repo/javax/servlet/jsp/jsp-api/2.1/jsp-api-2.1.pom /usr/share/maven-repo/javax/servlet/jsp/jsp-api/debian/jsp-api-debian.pom
    ln -s -T /usr/share/maven-repo/javax/servlet/jsp/jsp-api/2.1/jsp-api-2.1.jar /usr/share/maven-repo/javax/servlet/jsp/jsp-api/debian/jsp-api-debian.jar
    pico /usr/share/maven-repo/javax/servlet/jsp/jsp-api/debian/jsp-api-debian.pom # and replace version 2.0 with debian

DEPLOY
======

Also the war only seemed to work with jetty (it didn't work with tomcat and it didn't work with winstone)
