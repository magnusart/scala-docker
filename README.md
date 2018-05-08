# Scala docker

This project builds a sbt project using OpenJDK Java 10 JDK and assembles those artifacts with a launch script.

This docker will add the sbt-assembly and version into your project for you.

This is done using Docker a multi stage build. Dependencies and application code are build in separate layers which enable layer caching and will speed up build times.

## Setup

### Constraints
This docker will assemble the root project and dockerize that. If you have multiple sub project it may not work.

### Files
In your project you need to create
- runtime.args
- Dockerfile

### java.args
These are the runtime arguments that will be added as jvm runtime arguments. One argument per line. Currently an empty `java.args` file is untested.
```
-Dfile.encoding=UTF-8
-Duser.timezone=UTC
```

### Dockerfile
```Dockerfile
FROM magnusart/scala-docker:0.0.1 AS builder

### RUNTIME
FROM openjdk:10.0.1-10-jre-slim-sid

LABEL maintainer="yourname@yourdomain.com"

ARG artifact_name
ARG version

ARG full_assembly_artifact_name=${artifact_name}-assembly-${version}

EXPOSE 8080/tcp
COPY --from=builder /target/scala-2.12/scala-library-2.12.6-assembly.jar /deps/.

COPY --from=builder /target/scala-2.12/$full_assembly_artifact_name-deps.jar /deps/.

COPY --from=builder /target/scala-2.12/$full_assembly_artifact_name.jar /deps/.

COPY --from=builder /launch.sh .

ENTRYPOINT ["./launch.sh"]
```

## Building

When building you use docker build. You need to provide the following `--buildtime-args`:

- **version:** the version your build should have
- **artifact_name:** the name of your project/artifact
- **main_launch_file:** name of your main class

Below is an example of a build shell script that takes the current tag/sha and uses as version.

## build-docker
```Bash
#!/bin/bash

version=`git describe --always --dirty --abbrev=10 --tags`
artifact_name=project-name
main_launch_file=your.package.MainApplication

docker build $@ --rm \
    --build-arg version=$version \
    --build-arg artifact_name=$artifact_name \
    --build-arg main_launch_file=$main_launch_file \
    -t $artifact_name:$version .
```

Execute it like so
```Bash
# Normal build
./build-docker

# Clean build from the top
./build-docker --no-cache
```