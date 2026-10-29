param([Parameter(Mandatory=$true)][string]$BackupDirectory)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$workspace=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
$destination=(Resolve-Path -LiteralPath $BackupDirectory).Path
$expectedRoot=Join-Path $env:USERPROFILE 'Documents\BoteParroquial-backups\firestore-rules'
if(-not $destination.StartsWith($expectedRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Unexpected backup directory'}
if(-not (Test-Path -LiteralPath (Join-Path $destination 'manifest.json'))){throw 'Verified Rules backup required'}
$archivePath=Join-Path $destination 'working-tree-candidate.zip'
$stream=[IO.File]::Open($archivePath,[IO.FileMode]::CreateNew)
$archive=[IO.Compression.ZipArchive]::new($stream,[IO.Compression.ZipArchiveMode]::Create)
$count=0
try {
  $names=@(& git -c "safe.directory=$($workspace.Replace('\','/'))" -C $workspace ls-files --cached --others --exclude-standard)
  if($LASTEXITCODE -ne 0){throw 'Cannot list working tree'}
  foreach($name in ($names|Sort-Object -Unique)) {
    if($name -match '(^|/)(\.env[^/]*|[^/]*\.(pem|key|p12|jks|keystore))$'){continue}
    $source=[IO.Path]::GetFullPath((Join-Path $workspace $name))
    if(-not $source.StartsWith($workspace+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Path outside workspace'}
    if(-not [IO.File]::Exists($source)){continue}
    [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$source,$name.Replace('\','/'),[IO.Compression.CompressionLevel]::Optimal)|Out-Null
    $count++
  }
}finally{$archive.Dispose();$stream.Dispose()}
$metadata=[ordered]@{createdAt=[DateTime]::UtcNow.ToString('o');files=$count;includesWorkingChanges=$true;source='current candidate before publication';zipSha256=(Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()}
$apk=Join-Path $workspace 'build\app\outputs\flutter-apk\app-debug.apk'
if([IO.File]::Exists($apk)) {
  $apkCopy=Join-Path $destination 'app-debug-before-completion.apk'
  [IO.File]::Copy($apk,$apkCopy,$false)
  $metadata.apkSha256=(Get-FileHash -LiteralPath $apkCopy -Algorithm SHA256).Hash.ToLowerInvariant()
  $metadata.apkIsPreviousBuild=$true
}
$metadata|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $destination 'working-tree-manifest.json') -Encoding UTF8
$metadata|ConvertTo-Json -Compress
