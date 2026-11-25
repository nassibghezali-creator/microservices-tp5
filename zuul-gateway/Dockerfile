# Java 11 : Spring Boot 2.3 / Zuul 1 ne demarre pas correctement sur Java 21
FROM eclipse-temurin:11-jre
WORKDIR /app
COPY target/*.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
