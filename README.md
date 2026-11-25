# TP5 – Configuration centralisée et conteneurisation (projet complet)

Projet TP1 → TP5 : Eureka (TP2), Feign (TP3), Resilience4j (TP4), **Config Server + Docker Compose (TP5)**.
Spring Boot 3.3.5 · Spring Cloud 2023.0.3 · Java 21 · Maven

## Structure
```
microservices-tp5/
├── docker-compose.yml
├── build-all.ps1               génère les 4 JARs
├── config-repo/                dépôt de configuration local (backend "native")
│   ├── order-service.properties          profil par défaut (localhost)
│   └── order-service-docker.properties   profil "docker" (eureka-server)
├── eureka-server/   :8761
├── config-server/   :8888      NOUVEAU (TP5)
├── demo/            :8080
└── order-service/   :8090      bootstrap.properties NOUVEAU, application.properties vidé
```
Chaque service a son `Dockerfile`.

## Ce qui change par rapport au TP4
1. **config-server** : `@EnableConfigServer`, backend `native` sur `config-repo/`.
2. **order-service** :
   - dépendances `spring-cloud-starter-config` et `spring-cloud-starter-bootstrap` ;
   - `bootstrap.properties` (nom de l'application, URI du Config Server, `fail-fast`) ;
   - `application.properties` vidé : sa configuration est dans `config-repo/order-service.properties`.
3. **Dockerfile** par service et **docker-compose.yml**.

## Points d'attention
- `spring-cloud-starter-bootstrap` est obligatoire avec Spring Boot 3, sinon `bootstrap.properties` est ignoré.
- Image Java : `eclipse-temurin:21-jre` (`openjdk:21-jre-slim` n'existe pas).
- Les propriétés servies par le Config Server **ont priorité** sur les variables d'environnement.
  Une variable `EUREKA_CLIENT_...` dans le compose serait écrasée par `localhost`
  du `order-service.properties`. D'où le profil `docker` (`SPRING_PROFILES_ACTIVE=docker`)
  qui charge `order-service-docker.properties` avec `http://eureka-server:8761/eureka/`.
- Lancé en local, le Config Server cherche `file:./config-repo/` : le démarrer depuis la racine du projet.

## 1. Générer les JARs
```powershell
powershell -ExecutionPolicy Bypass -File .\build-all.ps1
```
Le script utilise Maven s'il est installé, sinon Maven dans Docker.
Manuellement, dans chaque dossier : `mvn clean package -DskipTests` (ou `.\mvnw.cmd ...` si vous avez le wrapper).

## 2. Lancer avec Docker (Docker Desktop démarré)
```powershell
docker-compose up -d --build
docker-compose ps
docker-compose logs -f order-service
```

## 3. Vérifier
| URL | Attendu |
|---|---|
| http://localhost:8761 | DEMO et ORDER-SERVICE enregistrés |
| http://localhost:8888/order-service/default | propriétés de `order-service.properties` |
| http://localhost:8888/order-service/docker | idem + URL Eureka `eureka-server` |
| http://localhost:8090/order | `Commande créée. Réponse du service demo : Hello, Microservice!` |
| http://localhost:8090/actuator/circuitbreakers | état du disjoncteur `demoService` |

Test du disjoncteur (TP4) en Docker :
```powershell
docker-compose stop demo      # puis appeler /order au moins 5 fois -> fallback, état OPEN
docker-compose start demo     # attendre ~10 s -> HALF_OPEN puis CLOSED
```

Arrêt : `docker-compose down`

## Exécution locale sans Docker (ordre)
1. `eureka-server` (8761) → 2. `config-server` (8888, depuis la racine du projet :
   `java -jar config-server\target\config-server-0.0.1-SNAPSHOT.jar`) → 3. `demo` (8080) → 4. `order-service` (8090).

## Zuul Gateway (port 8765)
Zuul 1 n'existe plus dans Spring Cloud 2020+ et ne fonctionne pas avec Spring Boot 3 :
`zuul-gateway` est donc en **Spring Boot 2.3.12 / Spring Cloud Hoxton.SR12 / Java 11**
(image Docker `eclipse-temurin:11-jre`). Il récupère sa configuration auprès du Config Server
(`config-repo/zuul-gateway.properties`) et trouve les services via Eureka.

| URL via la gateway | Service appelé |
|---|---|
| http://localhost:8765/order-service/order | order-service `/order` |
| http://localhost:8765/demo/hello | demo `/hello` |
| http://localhost:8765/actuator/routes | liste des routes Zuul |

Build : `cd zuul-gateway` puis `mvnw.cmd clean package -DskipTests` (copier `.mvn` et `mvnw.cmd` d'un autre projet).
Alternative moderne : Spring Cloud Gateway.
