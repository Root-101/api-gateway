FROM gradle:8.4.0-jdk21-alpine AS build

ARG APP_HOME=/home/gradle/src

COPY --chown=gradle:gradle . $APP_HOME
WORKDIR $APP_HOME

RUN gradle --configure-on-demand -x check clean build --no-daemon

FROM openjdk:21-jdk-oracle

RUN mkdir /app
COPY --from=build /home/gradle/src/build/libs/*.jar /app/app.jar

EXPOSE $PORT

ENTRYPOINT exec java $JAVA_OPTS -jar -Dserver.port=$PORT /app/app.jar