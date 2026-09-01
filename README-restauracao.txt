# BACKUP OPENCODE - Nunca perca o opencode

Data: 2026-08-31 23:16:47
Versão: 1.18.23 (1.18.23)
Binário original: C:\Users\azand\AppData\Local\opencode\bin\opencode.exe

## O que foi salvo aqui

Este backup contém TUDO para restaurar o opencode do zero, mesmo offline:

1. bin/opencode.exe (179 MB) - Binário principal (Bun 1.3.14)
   Origem: C:\Users\azand\AppData\Local\opencode\bin\opencode.exe

2. config/ - Configuração completa
   Origem: C:\Users\azand\.config\opencode\
   - opencode.jsonc - config principal (provider, etc)
   - tui.json - tema (tech-neon-blue)
   - package.json / package-lock.json - plugins (@opencode-ai/plugin 1.18.23)
   - skills/ - 70 skills instaladas
   - themes/ - tema custom
   - node_modules/ - 53 MB de dependências (para funcionar offline sem npm install)

3. data/ - Dados e histórico
   Origem: C:\Users\azand\.local\share\opencode\
   - opencode.db (16 MB) - 8 sessões, 163 mensagens, tokens, etc (com WAL checkpoint)
   - opencode.db-shm / opencode.db-wal
   - log/opencode.log
   - repos/ , tool-output/ 

## Como restaurar (Windows)

### Restauração completa (cópia reversa):

`powershell
# 1. Restaurar binário
Copy-Item -Path "C:\opencode\BACKUP-OPENCODE-v1.18.23-2026-08-31\bin\opencode.exe" -Destination "C:\Users\azand\AppData\Local\opencode\bin\opencode.exe" -Force

# 2. Restaurar config (feche o opencode antes)
Copy-Item -Path "C:\opencode\BACKUP-OPENCODE-v1.18.23-2026-08-31\config\*" -Destination "C:\Users\azand\.config\opencode\" -Recurse -Force

# 3. Restaurar dados (feche o opencode antes)
Copy-Item -Path "C:\opencode\BACKUP-OPENCODE-v1.18.23-2026-08-31\data\opencode.db" -Destination "C:\Users\azand\.local\share\opencode\opencode.db" -Force
Copy-Item -Path "C:\opencode\BACKUP-OPENCODE-v1.18.23-2026-08-31\data\log" -Destination "C:\Users\azand\.local\share\opencode\log" -Recurse -Force -ErrorAction SilentlyContinue

# 4. Verificar
opencode --version
opencode stats
`

### Restauração offline (sem internet):
O node_modules já está no backup, então NÃO precisa rodar npm install. Basta copiar.

### Se perder tudo e precisar reinstalar do zero:
1. Copie opencode.exe para C:\Users\azand\AppData\Local\opencode\bin\
2. Adicione ao PATH: C:\Users\azand\AppData\Local\opencode\bin
3. Copie config e data como acima
4. Rode: opencode

## Garantia de gratuito para sempre

- Este backup garante o PROGRAMA para sempre (offline).
- Para garantir MODELO grátis para sempre, configure Ollama local após restaurar:
  winget install Ollama.Ollama
  ollama pull qwen2.5-coder:7b
  # e adicione provider ollama no opencode.jsonc

## Checksum (para verificar integridade)



Algorithm : SHA256
Hash      : F831518278DED5090C41CC532B16AB80629E980F710A0B46D1E5B605808BB1D9
Path      : C:\opencode\BACKUP-OPENCODE-v1.18.23-2026-08-31\bin\opencode.exe






Algorithm : SHA256
Hash      : 2528A75FBECFA1C93E96E3374D6D4B9456D589C74B36397BA5ED786CCFF6DAF8
Path      : C:\opencode\BACKUP-OPENCODE-v1.18.23-2026-08-31\data\opencode.db




