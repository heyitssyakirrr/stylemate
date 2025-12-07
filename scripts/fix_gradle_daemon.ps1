# PowerShell script to attempt automated fixes for Gradle daemon crashes
# Usage: Run from project root or execute this script directly.

Set-StrictMode -Version Latest

function Safe-RenameIfExists($path) {
    if (Test-Path -LiteralPath $path) {
        $bak = $path + '.bak'
        Write-Host "Renaming '$path' -> '$bak'"
        try {
            Rename-Item -LiteralPath $path -NewName $bak -ErrorAction Stop
        } catch {
            Write-Host "Rename failed, attempting Remove and fallback backup..." -ForegroundColor Yellow
            try { Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction Stop } catch { Write-Host "Failed to remove $path: $_" -ForegroundColor Red }
        }
    } else {
        Write-Host "Path not present: $path"
    }
}

try {
    $root = Resolve-Path -LiteralPath "$PSScriptRoot\.." | Select-Object -First 1
    $root = $root.Path
    Write-Host "Project root: $root"

    $gradlew = Join-Path $root 'android\gradlew.bat'
    if (-not (Test-Path $gradlew)) { Write-Host "gradlew not found at $gradlew" -ForegroundColor Yellow }

    Write-Host "Stopping any running Gradle daemons..."
    if (Test-Path $gradlew) { & $gradlew --stop }

    # Backup problematic transform/daemon caches
    $userGradle = Join-Path $env:USERPROFILE '.gradle'
    $transforms = Join-Path $userGradle 'caches\8.10.2\transforms'
    $daemonDir = Join-Path $userGradle 'daemon'
    $cachesDir = Join-Path $userGradle 'caches'

    Safe-RenameIfExists -path $transforms
    Safe-RenameIfExists -path $daemonDir

    # Optionally rename whole caches directory if extreme corruption suspected
    # Only do if transforms rename didn't exist or user wants; here we check size and skip
    if (-not (Test-Path $transforms) -and (Test-Path $cachesDir)) {
        Write-Host "(Optional) caches dir exists: $cachesDir - leaving it in place to avoid long re-downloads." -ForegroundColor Yellow
    }

    # Remove JVM crash logs in android dir
    $hsLogs = Get-ChildItem -Path (Join-Path $root 'android') -Filter 'hs_err_pid*.log' -ErrorAction SilentlyContinue
    foreach ($f in $hsLogs) {
        Write-Host "Removing JVM crash log: $($f.FullName)"
        Remove-Item -LiteralPath $f.FullName -Force -ErrorAction SilentlyContinue
    }

    # Ensure gradle jvm args are set to a safe value in android/gradle.properties
    $gradleProps = Join-Path $root 'android\gradle.properties'
    $jvmLine = 'org.gradle.jvmargs=-Xmx4096m'
    if (-not (Test-Path $gradleProps)) {
        Write-Host "Creating $gradleProps with JVM args"
        "$jvmLine`norg.gradle.parallel=true`n" | Out-File -FilePath $gradleProps -Encoding UTF8
    } else {
        $content = Get-Content -LiteralPath $gradleProps -ErrorAction Stop
        if ($content -match '^org.gradle.jvmargs=') {
            Write-Host "Replacing existing org.gradle.jvmargs line"
            $content = $content -replace '^org.gradle.jvmargs=.*', $jvmLine
        } else {
            Write-Host "Appending org.gradle.jvmargs to gradle.properties"
            $content += "`n$jvmLine"
        }
        $content | Set-Content -LiteralPath $gradleProps -Encoding UTF8
    }

    Write-Host "Running Gradle clean build (no-daemon) to avoid daemon crashes..."
    if (Test-Path $gradlew) {
        Push-Location (Join-Path $root 'android')
        # run without daemon to avoid daemon JVM issues and force fresh work
        & $gradlew --no-daemon clean assembleDebug --refresh-dependencies
        $exit = $LASTEXITCODE
        Pop-Location
        if ($exit -eq 0) {
            Write-Host "Gradle build finished successfully."
        } else {
            Write-Host "Gradle build finished with exit code $exit" -ForegroundColor Red
            throw "Gradle build failed with exit code $exit"
        }
    } else {
        throw "gradlew not found; cannot run Gradle build"
    }
} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}

Write-Host "All done. If issues persist, consider rebooting and re-running this script or reinstalling JDK/NDK." -ForegroundColor Green
