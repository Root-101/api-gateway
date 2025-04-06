FROM gradle:8.5.0-jdk21-alpine AS build

ARG APP_HOME=/home/gradle/src

COPY --chown=gradle:gradle . $APP_HOME
WORKDIR $APP_HOME

RUN gradle --configure-on-demand -x check clean build --no-daemon

FROM eclipse-temurin:21-jre-alpine

RUN mkdir /app
COPY --from=build /home/gradle/src/build/libs/*.jar /app/app.jar

EXPOSE $PORT

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -Dserver.port=$PORT -jar /app/app.jar"]