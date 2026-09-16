# instala-opencode-windows.ps1 — instala opencode v1.18.31 + 184 agentes + 283 skills (bundle offline)
# Uso: .\instala-opencode-windows.ps1 [caminho-do-tarball]
# O arquivo opencode-payload-v1.18.31.tar.gz deve estar no mesmo diretorio.
# Requer Windows 10+ (tar nativo). Rode no PowerShell.
$ErrorActionPreference = "Stop"

$Version = "1.18.31"
$TarballName = "opencode-payload-v1.18.31.tar.gz"
$Tarball = if ($args.Count -ge 1) { $args[0] } else { Join-Path $PSScriptRoot $TarballName }

if (-not (Test-Path $Tarball)) {
  Write-Host "ERRO: $TarballName nao encontrado."
  Write-Host "Coloque o tarball no mesmo diretorio deste script ou passe o caminho:"
  Write-Host "  .\instala-opencode-windows.ps1 C:\caminho\para\$TarballName"
  exit 1
}

Write-Host "== opencode $Version — instalacao offline (Windows x64) =="
$Work = Join-Path $env:TEMP ("opencode-install-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $Work | Out-Null
try {
  Write-Host "-- extraindo $TarballName ..."
  tar -xzf "$Tarball" -C "$Work"
  $P = Join-Path $Work "payload"
  if (-not ((Test-Path (Join-Path $P "bin")) -and (Test-Path (Join-Path $P "config")) -and (Test-Path (Join-Path $P "plugins")))) {
    throw "payload invalido."
  }

  $Ts = Get-Date -Format "yyyyMMdd-HHmmss"
  $BinDir = Join-Path $HOME ".opencode\bin"
  $CfgDir = Join-Path $HOME ".config\opencode"
  $PkgDir = Join-Path $HOME ".cache\opencode\packages"
  New-Item -ItemType Directory -Force -Path $BinDir, $CfgDir, $PkgDir | Out-Null
  foreach ($s in @("documentos", "txt", "audios", "videos", "imagens", "outros")) {
    New-Item -ItemType Directory -Force -Path (Join-Path $HOME "opencode\arquivos\$s") | Out-Null
  }

  Write-Host "-- instalando binario em $BinDir ..."
  Copy-Item -Force (Join-Path $P "bin\opencode.exe") (Join-Path $BinDir "opencode.exe")

  if ((Test-Path $CfgDir) -and ((Get-ChildItem $CfgDir -Force | Measure-Object).Count -gt 0)) {
    $Bak = "$CfgDir.bak-$Ts"
    Write-Host "-- backup da config existente em $Bak"
    Rename-Item $CfgDir $Bak
    New-Item -ItemType Directory -Path $CfgDir | Out-Null
  }
  Write-Host "-- copiando config (agentes, skills, tema, ajustes) ..."
  Copy-Item -Recurse -Force (Join-Path $P "config\*") $CfgDir

  Write-Host "-- restaurando plugins em cache (5 offline) ..."
  foreach ($d in (Get-ChildItem (Join-Path $P "plugins") -Directory)) {
    $n = $d.Name
    foreach ($t in @($n, "$n@latest")) {
      $dest = Join-Path $PkgDir $t
      if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
      Copy-Item -Recurse -Force $d.FullName $dest
    }
    Write-Host "   ok: $n"
  }

  Write-Host "-- ajustando PATH do usuario ..."
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if ($userPath -notlike "*.opencode\bin*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$BinDir", "User")
    Write-Host "   PATH atualizado (reabra o terminal para valer)."
  }

  Write-Host "-- verificando ..."
  & (Join-Path $BinDir "opencode.exe") --version
  $na = (Get-ChildItem (Join-Path $CfgDir "agents") | Measure-Object).Count
  $ns = (Get-ChildItem (Join-Path $CfgDir "skills") | Measure-Object).Count
  Write-Host "agentes: $na | skills: $ns"

  Write-Host ""
  Write-Host "== pronto =="
  Write-Host "1. Reabra o terminal e rode: opencode"
  Write-Host "2. Dentro do opencode, autentique com: /connect"
  Write-Host ""
  Write-Host "Notas:"
  Write-Host "- Nenhuma chave de API foi copiada; a autenticacao e feita por voce no primeiro uso."
  Write-Host "- 4 plugins (notifier, tavily, shell-strategy, dynamic-context-pruning) baixam"
  Write-Host "  sozinhos na primeira execucao com internet. Os outros 5 ja vieram no bundle."
}
finally {
  Remove-Item -Recurse -Force $Work -ErrorAction SilentlyContinue
}
