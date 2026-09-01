# backup_opencode

Backup completo do **OpenCode v1.18.23** (Bun 1.3.14) — criado em 2026-08-31 23:16:47.

> **Nunca perca o opencode:** este repositório guarda tudo para restaurar offline, mesmo sem internet.

## 📦 O que está no backup

O backup completo está na **Release** como ZIP (144 MB comprimido, 412 MB descomprimido):

**[⬇️ Baixar backup_opencode-v1.18.23-2026-08-31.zip na Release](../../releases)**

Conteúdo do ZIP (BACKUP-OPENCODE-v1.18.23-2026-08-31/):

1.  **bin/opencode.exe** (179 MB) — binário principal  
    Origem: \C:\Users\azand\AppData\Local\opencode\bin\opencode.exe\

2.  **config/** — configuração completa  
    Origem: \C:\Users\azand\.config\opencode\  
    - \opencode.jsonc\, \	ui.json\, \package.json\ / \package-lock.json\ (\@opencode-ai/plugin 1.18.23\)  
    - \skills/\ — 70 skills  
    - \	hemes/tech-neon-blue.json\  
    - \
ode_modules/\ — 53 MB (para funcionar offline sem \
pm install\)

3.  **data/** — dados e histórico  
    Origem: \C:\Users\azand\.local\share\opencode\  
    - \opencode.db\ (16 MB, 8 sessões, 163 mensagens) + WAL checkpoint  
    - \log/opencode.log\, \epos/\, \	ool-output/\

4.  **README-restauracao.txt** + **versao.txt** com checksums SHA256

## 🔄 Como restaurar (Windows)

Descompacte o ZIP da Release e rode (feche o opencode antes):

\\\powershell
# 1. Restaurar binário
Copy-Item -Path "BACKUP-OPENCODE-v1.18.23-2026-08-31\bin\opencode.exe" -Destination "C:\Users\azand\AppData\Local\opencode\bin\opencode.exe" -Force

# 2. Restaurar config
Copy-Item -Path "BACKUP-OPENCODE-v1.18.23-2026-08-31\config\*" -Destination "C:\Users\azand\.config\opencode\" -Recurse -Force

# 3. Restaurar dados
Copy-Item -Path "BACKUP-OPENCODE-v1.18.23-2026-08-31\data\opencode.db" -Destination "C:\Users\azand\.local\share\opencode\opencode.db" -Force
Copy-Item -Path "BACKUP-OPENCODE-v1.18.23-2026-08-31\data\log" -Destination "C:\Users\azand\.local\share\opencode\log" -Recurse -Force -ErrorAction SilentlyContinue

# 4. Verificar
opencode --version
opencode stats
\\\

Restauração offline: \
ode_modules\ já incluso, não precisa \
pm install\.

## 🆓 Grátis para sempre

- Este backup garante o **programa** para sempre (offline).
- Para garantir **modelo grátis para sempre**, configure Ollama local após restaurar:

\\\powershell
winget install Ollama.Ollama
ollama pull qwen2.5-coder:7b
# adicione provider ollama no opencode.jsonc (baseURL http://localhost:11434/v1)
\\\

## 📍 Local original

- Backup em disco: \C:\opencode\BACKUP-OPENCODE-v1.18.23-2026-08-31\ (412 MB, 3755 arquivos)
- ZIP: \C:\opencode\backup_opencode-v1.18.23-2026-08-31.zip\ (144 MB)
- Versão: \1.18.23\ | Data: \2026-08-31 23:16:47\
- Repo: \https://github.com/azdevcoder/backup_opencode\

## 🔍 Verificação

\\\
bin/opencode.exe --version => 1.18.23
data/opencode.db => 8 sessões OK
\\\

---
Backup gerado automaticamente via opencode (muse-spark-1.2-contributor-free).
