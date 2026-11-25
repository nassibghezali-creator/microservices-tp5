# Genere les 4 JARs (target/*.jar) necessaires aux Dockerfile.
# Utilise Maven local s'il est installe, sinon Maven dans un conteneur Docker.
# Lancement (PowerShell, a la racine du projet) :
#   powershell -ExecutionPolicy Bypass -File .\build-all.ps1

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$projects = @("eureka-server", "config-server", "demo", "order-service", "zuul-gateway")
$useMvn = [bool](Get-Command mvn -ErrorAction SilentlyContinue)

if ($useMvn) {
    Write-Host "Maven local detecte." -ForegroundColor Yellow
} else {
    Write-Host "Maven absent : utilisation de Maven dans Docker (Docker Desktop doit etre demarre)." -ForegroundColor Yellow
}

foreach ($p in $projects) {
    Write-Host "=== Build $p ===" -ForegroundColor Cyan
    $dir = Join-Path $root $p
    if ($useMvn) {
        Push-Location $dir
        mvn -B clean package -DskipTests
        $code = $LASTEXITCODE
        Pop-Location
    } else {
        docker run --rm -v "${dir}:/app" -v "maven-repo:/root/.m2" -w /app maven:3.9-eclipse-temurin-21 mvn -B clean package -DskipTests
        $code = $LASTEXITCODE
    }
    if ($code -ne 0) { throw "Echec du build de $p" }
}

Write-Host "Tous les JARs sont generes." -ForegroundColor Green
Get-ChildItem -Path $root -Recurse -Filter "*.jar" | Where-Object { $_.FullName -like "*\target\*" } | Select-Object FullName, Length
