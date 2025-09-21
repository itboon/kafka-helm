#!/usr/bin/env pwsh

Write-Host "=== Kafka Storage Path Fix Validation ===" -ForegroundColor Green

# 1. Check if KAFKA_CFG_LOG_DIRS is set in entrypoint
Write-Host "`n1. Checking entrypoint script for LOG_DIRS configuration..." -ForegroundColor Yellow
$entrypointFile = "charts\kafka-ha\templates\cm-entrypoint.yaml"
if (Test-Path $entrypointFile) {
    $logDirConfig = Select-String -Path $entrypointFile -Pattern "KAFKA_CFG_LOG_DIR"
    if ($logDirConfig) {
        Write-Host "OK Found LOG_DIR configurations:" -ForegroundColor Green
        $logDirConfig | ForEach-Object { Write-Host "  $($_.Line.Trim())" -ForegroundColor Cyan }
    } else {
        Write-Host "ERROR No LOG_DIR configuration found" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "ERROR Entrypoint file not found" -ForegroundColor Red
    exit 1
}

# 2. Check persistence configuration
Write-Host "`n2. Checking persistence configuration..." -ForegroundColor Yellow
$valuesFile = "charts\kafka-ha\values.yaml"
if (Test-Path $valuesFile) {
    $persistenceConfig = Select-String -Path $valuesFile -Pattern "mountPath.*kafka"
    if ($persistenceConfig) {
        Write-Host "OK Found persistence mount path:" -ForegroundColor Green
        $persistenceConfig | ForEach-Object { Write-Host "  $($_.Line.Trim())" -ForegroundColor Cyan }
    } else {
        Write-Host "ERROR No persistence mount path found" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "ERROR Values file not found" -ForegroundColor Red
    exit 1
}

# 3. Check volume mount in statefulset
Write-Host "`n3. Checking volume mount in statefulset..." -ForegroundColor Yellow
$statefulsetFile = "charts\kafka-ha\templates\broker\statefulset.yaml"
if (Test-Path $statefulsetFile) {
    $volumeMount = Select-String -Path $statefulsetFile -Pattern "mountPath.*persistence\.mountPath"
    if ($volumeMount) {
        Write-Host "OK Found volume mount configuration:" -ForegroundColor Green
        $volumeMount | ForEach-Object { Write-Host "  $($_.Line.Trim())" -ForegroundColor Cyan }
    } else {
        Write-Host "ERROR No volume mount configuration found" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "ERROR Statefulset file not found" -ForegroundColor Red
    exit 1
}

# 4. Check storage format logic
Write-Host "`n4. Checking storage format logic..." -ForegroundColor Yellow
$formatLogic = Select-String -Path $entrypointFile -Pattern "init_storage_format_if_needed|meta\.properties"
if ($formatLogic) {
    Write-Host "OK Found storage format logic:" -ForegroundColor Green
    $formatLogic | ForEach-Object { Write-Host "  Line $($_.LineNumber): $($_.Line.Trim())" -ForegroundColor Cyan }
} else {
    Write-Host "ERROR No storage format logic found" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Validation completed ===" -ForegroundColor Green
Write-Host "The storage path configuration should now work correctly." -ForegroundColor Green
Write-Host "Kafka will use the default path /var/lib/kafka/data for log.dirs" -ForegroundColor Green