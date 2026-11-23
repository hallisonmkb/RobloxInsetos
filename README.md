# roblox-kit-base

Template dos nossos jogos Roblox. Cada jogo novo nasce como cópia deste repositório e troca só
`games/<nome>/` (Config + mecânica) e a arte. O servidor é sempre a fonte da verdade: o cliente pede,
o servidor valida.

## Primeira vez no PC (Windows)

1. Instale o [Rokit](https://github.com/rojo-rbx/rokit), feche e abra o PowerShell.
2. Na pasta do repositório:
   ```powershell
   rokit install
   rojo plugin install
   ```
3. Abra o Roblox Studio → **New → Baseplate**. Salve o lugar e **publique** (File → Publish to Roblox).
4. Em **Game Settings → Security**, ligue **Enable Studio Access to API Services** (sem isso o save não funciona no Studio).
5. No VS Code, abra a pasta e rode no terminal:
   ```powershell
   rojo serve
   ```
6. No Studio, aba **Plugins → Rojo → Connect**. O código aparece no Explorer.
7. Aperte **Play**: o botão "Clique!" dá moedas. Saia, entre de novo e as moedas continuam lá.

## Estrutura

| Pasta | Vai para | O que é |
| --- | --- | --- |
| `src/server/` | ServerScriptService.Server | Bootstrap + serviços do kit base |
| `src/shared/` | ReplicatedStorage.Shared | Código usado pelos dois lados (Remotes) |
| `src/client/` | StarterPlayerScripts.Client | Interface e input |
| `games/exemplo/shared/` | ReplicatedStorage.Game | `Config.luau`: balanceamento do jogo |
| `games/exemplo/server/` | ServerScriptService.Game | Mecânicas do jogo: `Mechanic.luau` (clique) e `ZoneEnemy.luau` (inimigos). Todo ModuleScript aqui com `start()` arranca sozinho. |

## Módulos

| Módulo | Status |
| --- | --- |
| DataService (save, trava de sessão, autosave 60 s) | Pronto |
| CurrencyService (moedas, multiplicador, renda offline) | Pronto |
| RemoteGuard (`src/shared/Remotes.luau`, limite de chamadas) | Pronto |
| Config | Pronto |
| ZoneEnemy (exemplo): inimigos presos a uma zona (`Config.Enemies`), andantes ou voadores (que também pousam), com tamanho (`Scale`), vários iguais (`Count`), movimento realista e patas, antenas e asas animadas em modelos com Motor6D. Modelos próprios feitos em código em `games/exemplo/server/Models/` (formiga, pulgão, mosquito-tigre) | Pronto (formiga própria por testar) |
| ProgressionService, ShopService, MonetizationService, DailyRewardService, Leaderboards, UI Kit, AnalyticsService | A fazer |

## Regras

- Todo script começa com `--!strict`.
- Nada de valor (moedas, itens, preços) é decidido no cliente.
- Novo serviço: criar em `src/server/Services/`, ter `start()` e entrar na lista `ORDER` de `init.server.luau`.
- Nunca usar assets do Toolbox de autores não verificados.
