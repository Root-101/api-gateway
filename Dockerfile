FROM gradle:jdk-21-and-22-graal-jammy AS builder

WORKDIR /workspace

# Copia el código fuente
COPY . .

# Da permisos de ejecución al script gradlew
RUN chmod +x gradlew

# Compila el binario nativo
RUN ./gradlew clean nativeCompile --stacktrace --info

# Etapa 2: Imagen final ultraligera
FROM debian:bookworm-slim

WORKDIR /app

# Copia el binario nativo desde la etapa de compilación
COPY --from=builder /workspace/build/native/nativeCompile/graalvm /app/

RUN chmod +x /app/graalvm

# Comando para ejecutar la aplicación
ENTRYPOINT ["/app/graalvm"]