# CLAUDE.md — roblox-kit-base

Template dos jogos Roblox do utilizador. `src/` é o kit base genérico; `games/<nome>/` é o jogo específico (Config + mecânicas). Para o estado atual do trabalho, ler `HANDOFF.md`.

## Comunicação
- Responder ao utilizador em português.
- Comentários de código, mensagens de `warn`/`print` e textos visíveis ao jogador: **português do Brasil**, como no código existente.
- O utilizador não é programador experiente: explicar passos no Studio/PowerShell de forma concreta (menus, botões, comandos exatos).

## Stack e ferramentas
- Luau, sincronizado com o Studio via **Rojo** (`rojo serve` + plugin Rojo → Connect). Ferramentas fixadas em `rokit.toml` (instalar com `rokit install`).
- Lint: `selene .` · Formatação: `stylua .` (tabs, 110 colunas, aspas duplas). Correr ambos depois de editar `.luau`, se estiverem no PATH.
- Windows / PowerShell 5.1. O `git` e o Python podem não estar no PATH. Verificar antes de prometer commits.
- Não há testes automatizados; a validação é feita com Play no Roblox Studio.

## Regras de código
- Todo script começa com `--!strict`.
- **Servidor autoritativo:** nada de valor (moedas, itens, preços, dano, recompensas) é decidido no cliente. O cliente lê atributos/valores e dispara remotes; o servidor valida tudo, incluindo os tipos dos argumentos recebidos.
- Remotes só através de `src/shared/Remotes.luau`: `Remotes.onServer(nome, maxPorSegundo, handler)` no servidor e `Remotes.get(nome)` no cliente. Nunca criar RemoteEvents à mão.
- Dados do jogador só via `DataService` (`get`/`waitFor`/`Loaded`/`onBeforeRelease`). Campos novos vão para `Config.DefaultData` (são reconciliados automaticamente). Não mudar `STORE_NAME` sem plano de migração: perde os saves.
- Moedas só via `CurrencyService` (`add`/`spend`).
- Novo serviço do kit: `src/server/Services/<Nome>.luau` com `start()`, adicionado à lista `ORDER` de `src/server/init.server.luau` depois das suas dependências.
- Nova mecânica do jogo: ModuleScript em `games/<jogo>/server/` com `start()`. Números de balanceamento vão para `games/<jogo>/shared/Config.luau`, não ficam hard-coded.
- Código em `src/` não pode depender de nada específico de um jogo além da `Config`.
- Nunca usar assets do Toolbox de autores não verificados. Qualquer modelo externo deve ter os scripts removidos (ver `neutralize` em `ZoneEnemy.luau`).
- Erros em handlers/callbacks: `pcall` + `warn` com prefixo `[NomeDoMódulo]`.

## Estrutura (Rojo)
| Pasta | Vai para |
| --- | --- |
| `src/server/` | `ServerScriptService.Server` |
| `src/shared/` | `ReplicatedStorage.Shared` |
| `src/client/` | `StarterPlayer.StarterPlayerScripts.Client` |
| `games/exemplo/shared/` | `ReplicatedStorage.Game` |
| `games/exemplo/server/` | `ServerScriptService.Game` |

## Ao terminar trabalho relevante
- Atualizar o README (tabela de módulos) quando um módulo mudar de estado.
- Atualizar o `HANDOFF.md` se a sessão for encerrada a meio de uma tarefa.
