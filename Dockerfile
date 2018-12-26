### BUILD
FROM openjdk:10.0.1-10-jdk-slim-sid

LABEL maintainer="magnus@magnusart.com"

# ADD SBT Dependencies
RUN apt-get update && \
  apt-get install -my gnupg && \
  echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list && \
  apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 && \
  apt-get update && \
  apt-get install -my sbt tree

# Download all SBT dependencies
RUN sbt sbtVersion

# Add dependencies
ONBUILD COPY . /app/

# Setup resources
COPY /resources/assembly-plugin.sbt /app/project/assembly-plugin.sbt
COPY /resources/assembly.sbt /app/assembly.sbt

ONBUILD ARG version
ONBUILD ARG artifact_name
ONBUILD ARG main_launch_file

ONBUILD RUN test -n "$version" 
ONBUILD RUN test -n "$artifact_name" 
ONBUILD RUN test -n "$main_launch_file"

ONBUILD ARG full_assembly_artifact_name=${artifact_name}-assembly-${version}

#Change directory
ONBUILD WORKDIR /app
ONBUILD RUN tree

# Package Scala code
ONBUILD RUN sbt assemblyPackageScala

# Package dependencies
ONBUILD RUN sbt assemblyPackageDependency

# Test and package application code
ONBUILD RUN sbt test
ONBUILD RUN sbt assembly

# Setup launch script
ONBUILD RUN printf '#!/bin/bash\njava ' > launch.sh && \ 
  echo `cat java.args` | xargs -n1 printf "%s " $1 >> launch.sh && \
  printf -- "-cp \"/deps/*\" %s\n" $main_launch_file >> launch.sh && \
  chmod +x ./launch.sh

ONBUILD RUN tree
