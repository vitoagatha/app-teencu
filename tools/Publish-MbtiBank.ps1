[CmdletBinding()]
param(
    [ValidateSet('Draft', 'Publish', 'Activate')][string]$Action = 'Publish',
    [string]$TestId = 'mbti-v1',
    [string]$SeedPath = (Join-Path $PSScriptRoot '../seed/mbti-v1.json'),
    [string]$ProjectId = 'teencu-dev',
    [string]$Email,
    [System.Management.Automation.PSCredential]$Credential,
    [switch]$Activate,
    [switch]$ValidateOnly,
    [switch]$UseEmulator
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
if ($TestId -notmatch '^[a-zA-Z0-9_-]{1,80}$') { throw 'TestId tidak valid.' }

function ConvertTo-FirestoreValue($Value) {
    if ($null -eq $Value) { return @{ nullValue = $null } }
    if ($Value -is [string]) { return @{ stringValue = $Value } }
    if ($Value -is [bool]) { return @{ booleanValue = $Value } }
    if ($Value -is [int] -or $Value -is [long]) { return @{ integerValue = [string]$Value } }
    if ($Value -is [System.Collections.IDictionary]) {
        $fields = @{}
        foreach ($key in $Value.Keys) { $fields[$key] = ConvertTo-FirestoreValue $Value[$key] }
        return @{ mapValue = @{ fields = $fields } }
    }
    if ($Value -is [System.Management.Automation.PSCustomObject]) {
        $fields = @{}
        foreach ($property in $Value.PSObject.Properties) { $fields[$property.Name] = ConvertTo-FirestoreValue $property.Value }
        return @{ mapValue = @{ fields = $fields } }
    }
    if ($Value -is [System.Collections.IEnumerable]) {
        return @{ arrayValue = @{ values = @($Value | ForEach-Object { ConvertTo-FirestoreValue $_ }) } }
    }
    throw 'Tipe seed tidak didukung.'
}

$seed = Get-Content -Raw -LiteralPath $SeedPath | ConvertFrom-Json
if ($seed.title -isnot [string] -or $seed.title.Trim().Length -eq 0 -or $seed.title.Length -gt 160 -or
    $seed.version -isnot [string] -or $seed.version.Trim().Length -eq 0 -or $seed.version.Length -gt 80 -or
    $seed.scoringVersion -ne 'teencu-centered-v1' -or $seed.questions -isnot [array] -or
    $seed.questions.Count -lt 4 -or $seed.questions.Count -gt 80) { throw 'Metadata atau jumlah soal seed tidak valid.' }
$ids = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
$dimensions = [System.Collections.Generic.HashSet[string]]::new()
foreach ($question in $seed.questions) {
    if ($question.id -isnot [string] -or $question.id -notmatch '^[a-zA-Z0-9_-]{1,80}$' -or
        -not $ids.Add($question.id) -or $question.text -isnot [string] -or
        $question.text.Trim().Length -eq 0 -or $question.text.Length -gt 1000 -or
        $question.agreeWith -cnotmatch '^[EISNTFJP]$') { throw 'Ada soal/ID/arah yang tidak valid atau duplikat.' }
    $dimension = switch -CaseSensitive ($question.agreeWith) {
        'E' { 'ei' } 'I' { 'ei' } 'S' { 'sn' } 'N' { 'sn' }
        'T' { 'tf' } 'F' { 'tf' } 'J' { 'jp' } 'P' { 'jp' }
    }
    [void]$dimensions.Add($dimension)
}
if ($dimensions.Count -ne 4) { throw 'Setiap dimensi harus memiliki setidaknya satu soal.' }
Write-Host "Seed valid: $($seed.questions.Count) soal, versi $($seed.version)."
if ($ValidateOnly) { return }

$config = Get-Content -Raw (Join-Path $PSScriptRoot '../android/app/google-services.json') | ConvertFrom-Json
if (-not $UseEmulator -and $ProjectId -ne $config.project_info.project_id) {
    throw 'ProjectId tidak sama dengan konfigurasi Android. Hentikan untuk menghindari salah project.'
}
if ($UseEmulator -and $ProjectId -ne 'demo-teencu') { throw 'Emulator wajib memakai demo-teencu.' }
if ($null -eq $Credential) {
    $Credential = Get-Credential -UserName $Email -Message "Akun konten admin Firebase $ProjectId (password tidak disimpan)"
}
if ($null -eq $Credential) { throw 'Login dibatalkan.' }
$apiKey = $config.client[0].api_key[0].current_key
$authBase = if ($UseEmulator) { 'http://127.0.0.1:9099/identitytoolkit.googleapis.com' } else { 'https://identitytoolkit.googleapis.com' }
$firestoreBase = if ($UseEmulator) { 'http://127.0.0.1:8080' } else { 'https://firestore.googleapis.com' }
$root = "projects/$ProjectId/databases/(default)/documents"
$url = "$firestoreBase/v1/$root"
$loginBody = @{ email = $Credential.UserName; password = $Credential.GetNetworkCredential().Password; returnSecureToken = $true } | ConvertTo-Json -Compress
try {
    $login = Invoke-RestMethod -Method Post -Uri "$authBase/v1/accounts:signInWithPassword?key=$apiKey" -ContentType 'application/json' -Body ([System.Text.Encoding]::UTF8.GetBytes($loginBody))
} catch { throw 'Login gagal. Periksa akun email/password dan project yang dipilih.' }
$loginBody = $null
$Credential = $null
$headers = @{ Authorization = "Bearer $($login.idToken)" }

function Commit-Writes($Writes) {
    $body = @{ writes = @($Writes) } | ConvertTo-Json -Depth 40 -Compress
    Invoke-RestMethod -Method Post -Uri "${url}:commit" -Headers $headers -ContentType 'application/json' -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) | Out-Null
}
function Read-Version {
    try { return Invoke-RestMethod -Uri "$url/mbti_tests/$TestId" -Headers $headers }
    catch {
        if ([int]$_.Exception.Response.StatusCode -eq 404) { return $null }
        throw 'Versi tidak dapat dibaca. Pastikan content_admins/{UID} memiliki enabled=true dan rules sudah dideploy.'
    }
}
function Active-Write {
    return @{
        update = @{ name = "$root/mbti_config/active"; fields = @{ testId = @{ stringValue = $TestId } } }
        updateTransforms = @(@{ fieldPath = 'updatedAt'; setToServerValue = 'REQUEST_TIME' })
    }
}
try {
    $admin = Invoke-RestMethod -Uri "$url/content_admins/$($login.localId)" -Headers $headers
    if ($admin.fields.enabled.booleanValue -ne $true) { throw 'Izin konten admin belum aktif.' }
    $existing = Read-Version
    if ($Action -eq 'Activate') {
        if ($null -eq $existing -or $existing.fields.status.stringValue -ne 'published') { throw 'Hanya versi published yang dapat diaktifkan.' }
        Commit-Writes @((Active-Write))
        Write-Host "Versi $TestId sekarang aktif di $ProjectId."
        return
    }
    if ($null -ne $existing -and $existing.fields.status.stringValue -ne 'draft') {
        throw 'Versi sudah dipublikasikan dan tidak dapat ditimpa. Gunakan TestId baru.'
    }
    $data = @{
        title = $seed.title; version = $seed.version; scoringVersion = $seed.scoringVersion
        status = 'draft'; questions = $seed.questions; questionIds = @($seed.questions | ForEach-Object { $_.id }); publishedAt = $null
    }
    $fields = (ConvertTo-FirestoreValue $data).mapValue.fields
    $write = @{ update = @{ name = "$root/mbti_tests/$TestId"; fields = $fields } }
    if ($null -eq $existing) {
        $write.currentDocument = @{ exists = $false }
        $write.updateTransforms = @(@{ fieldPath = 'createdAt'; setToServerValue = 'REQUEST_TIME' })
    } else {
        $fields.createdAt = $existing.fields.createdAt
        $write.currentDocument = @{ updateTime = $existing.updateTime }
    }
    Commit-Writes @($write)
    if ($Action -eq 'Draft') { Write-Host "Draft $TestId tersimpan di $ProjectId."; return }
    $draft = Read-Version
    $publish = @{
        update = @{ name = "$root/mbti_tests/$TestId"; fields = @{ status = @{ stringValue = 'published' } } }
        updateMask = @{ fieldPaths = @('status') }
        currentDocument = @{ updateTime = $draft.updateTime }
        updateTransforms = @(@{ fieldPath = 'publishedAt'; setToServerValue = 'REQUEST_TIME' })
    }
    $writes = @($publish)
    if ($Activate) { $writes += Active-Write }
    Commit-Writes $writes
    Write-Host "Published $TestId di $ProjectId. Aktif: $Activate."
} finally {
    $headers.Clear()
    $login = $null
}
