# Stage 1: build with Maven. Copy poms first so the dependency layer is
# cached and rebuilds only recompile source.
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /workspace
COPY pom.xml ./
COPY libs/common/pom.xml libs/common/
COPY app/wallet/pom.xml app/wallet/
RUN mvn -B -q -pl app/wallet -am dependency:go-offline
COPY libs libs
COPY app app
RUN mvn -B -pl app/wallet -am package -DskipTests

# Stage 2: JRE-only runtime, non-root user.
FROM eclipse-temurin:21-jre
RUN useradd --system --uid 1001 --create-home appuser
WORKDIR /app
COPY --from=build /workspace/app/wallet/target/wallet-*.jar app.jar
EXPOSE 8080
USER appuser
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
