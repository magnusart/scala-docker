### BUILD
FROM openjdk:10.0.1-10-jdk-slim-sid

LABEL maintainer="magnus@magnusart.com"

# ADD SBT Dependencies
RUN apt-get update && \
    apt-get install -my gnupg && \
    echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 && \
    apt-get update && \
    apt-get install -my sbt

# Download all SBT dependencies
RUN sbt sbtVersion

# Setup resources
COPY /resources/launch-template.sh /launch-template.sh
COPY /resources/assembly-plugin.sbt /project/assembly-plugin.sbt
COPY /resources/assembly.sbt /assembly.sbt

# Add dependencies
ONBUILD COPY /build.sbt /build.sbt
ONBUILD COPY /project/build.properties /project/build.properties
ONBUILD COPY /project/plugins.sbt /project/plugins.sbt

ONBUILD ARG version
ONBUILD ARG artifact_name
ONBUILD ARG main_launch_file

ONBUILD RUN test -n "$version" 
ONBUILD RUN test -n "$artifact_name" 
ONBUILD RUN test -n "$main_launch_file"

ONBUILD ARG full_assembly_artifact_name=${artifact_name}-assembly-${version}

ONBUILD RUN echo "version := \"${version}\"" > ./version.sbt

ONBUILD COPY /src /src

# Package the application
ONBUILD RUN sbt assemblyPackageScala assemblyPackageDependency
ONBUILD RUN sbt assembly

ONBUILD RUN printf '#!/bin/bash\njava ' > launch.sh

# Add runtime arguments
ONBUILD COPY /java.args /java.args
ONBUILD RUN echo `cat java.args` | xargs -n1 printf "%s " $1 >> launch.sh
ONBUILD RUN printf -- "-cp \"/deps/*\" %s\n" $main_launch_file >> launch.sh
ONBUILD RUN chmod +x ./launch.sh

