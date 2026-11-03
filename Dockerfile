#Stage 1: Build
#GraalVM CE 25 (same java version as the project)
FROM ghcr.io/graalvm/native-image-community:25 AS builder

#gradlew needs xargs (findutils), and git to fetch the `java-commons` source dependency
RUN microdnf install -y findutils git && microdnf clean all

WORKDIR /workspace

# Copy source coe
COPY . .

# Give execution permissions to the gradlew script
RUN chmod +x gradlew

# Compile the native binary
RUN ./gradlew clean nativeCompile --stacktrace --info


#Stage 2: Deploy
#Final Ultralight Image
FROM debian:bookworm-slim

WORKDIR /app

# Copy the native binary from the build stage
COPY --from=builder /workspace/build/native/nativeCompile/graalvm /app/

RUN chmod +x /app/graalvm

# Don't run as root
RUN useradd --system --uid 10001 --no-create-home gateway
USER gateway

# Command to run the application
ENTRYPOINT ["/app/graalvm"]