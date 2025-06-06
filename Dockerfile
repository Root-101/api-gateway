#Stage 1: Build
FROM gradle:jdk-21-and-22-graal-jammy AS builder

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

# Command to run the application
ENTRYPOINT ["/app/graalvm"]