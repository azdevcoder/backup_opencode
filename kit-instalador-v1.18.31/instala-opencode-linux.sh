#!/usr/bin/env bash
# instala-opencode-linux.sh — instala opencode v1.18.31 + 184 agentes + 283 skills (bundle offline)
# Uso: ./instala-opencode-linux.sh [caminho-do-tarball]
# O arquivo opencode-payload-v1.18.31.tar.gz deve estar no mesmo diretório (ou passe o caminho).
set -euo pipefail

VERSION="1.18.31"
TARBALL_NAME="opencode-payload-v1.18.31.tar.gz"
TARBALL="${1:-$TARBALL_NAME}"

if [ ! -f "$TARBALL" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  TARBALL="$SCRIPT_DIR/$TARBALL_NAME"
fi
if [ ! -f "$TARBALL" ]; then
  echo "ERRO: $TARBALL_NAME nao encontrado."
  echo "Coloque o tarball no mesmo diretorio deste script ou passe o caminho:"
  echo "  ./instala-opencode-linux.sh /caminho/para/$TARBALL_NAME"
  exit 1
fi

echo "== opencode $VERSION — instalacao offline (Linux x86_64) =="
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
echo "-- extraindo $TARBALL ..."
tar -xzf "$TARBALL" -C "$WORK"
P="$WORK/payload"
[ -d "$P/bin" ] && [ -d "$P/config" ] && [ -d "$P/plugins" ] || { echo "ERRO: payload invalido."; exit 1; }

TS="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$HOME/.opencode/bin" "$HOME/.config" "$HOME/.cache/opencode/packages"
mkdir -p "$HOME/opencode/arquivos"/{documentos,txt,audios,videos,imagens,outros}

echo "-- instalando binario em ~/.opencode/bin ..."
cp -f "$P/bin/opencode" "$HOME/.opencode/bin/opencode"
chmod +x "$HOME/.opencode/bin/opencode"

if [ -d "$HOME/.config/opencode" ]; then
  echo "-- backup da config existente em ~/.config/opencode.bak-$TS"
  mv "$HOME/.config/opencode" "$HOME/.config/opencode.bak-$TS"
fi
echo "-- copiando config (agentes, skills, tema, ajustes) ..."
mkdir -p "$HOME/.config/opencode"
cp -a "$P/config/." "$HOME/.config/opencode/"

echo "-- restaurando plugins em cache (5 offline) ..."
for d in "$P/plugins"/*/; do
  n="$(basename "$d")"
  rm -rf "$HOME/.cache/opencode/packages/$n" "$HOME/.cache/opencode/packages/$n@latest"
  cp -a "$d" "$HOME/.cache/opencode/packages/$n"
  cp -a "$d" "$HOME/.cache/opencode/packages/$n@latest"
  echo "   ok: $n"
done

echo "-- ajustando PATH ..."
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
  [ -f "$rc" ] || continue
  grep -q '.opencode/bin' "$rc" || echo 'export PATH="$HOME/.opencode/bin:$PATH"  # opencode' >> "$rc"
done
export PATH="$HOME/.opencode/bin:$PATH"

echo "-- verificando ..."
opencode --version
echo "agentes: $(ls "$HOME/.config/opencode/agents" | wc -l) | skills: $(ls "$HOME/.config/opencode/skills" | wc -l)"

echo ""
echo "== pronto =="
echo "1. Recarregue o shell ou rode: export PATH=\"\$HOME/.opencode/bin:\$PATH\""
echo "2. Rode: opencode"
echo "3. Dentro do opencode, autentique com: /connect"
echo ""
echo "Notas:"
echo "- Nenhuma chave de API foi copiada; a autenticacao e feita por voce no primeiro uso."
echo "- 4 plugins (notifier, tavily, shell-strategy, dynamic-context-pruning) baixam"
echo "  sozinhos na primeira execucao com internet. Os outros 5 ja vieram no bundle."
