# HANDOFF — roblox-kit-base

Estado em **2026-11-23**. Este ficheiro serve para uma sessão nova (app desktop) continuar o trabalho sem o histórico anterior. Convenções permanentes estão em `CLAUDE.md`.

---

## 1. Objetivo do projeto

`roblox-kit-base` é o **template base dos jogos Roblox** do utilizador. Cada jogo novo nasce como cópia deste repositório e troca apenas:

- `games/<nome>/shared/Config.luau`: balanceamento e dados do jogo;
- `games/<nome>/server/*.luau`: mecânicas do jogo;
- a arte (feita no Studio).

O kit base (`src/`) fornece serviços reutilizáveis: save de dados, moeda, remotes protegidos, e no futuro progressão, loja, monetização, recompensas diárias, leaderboards, UI kit e analytics.

Princípio central: **o servidor é a fonte da verdade.** O cliente pede, o servidor valida e decide.

O projeto de exemplo (`games/exemplo`) é um jogo de clicar para ganhar moedas, e agora também tem um inimigo (uma formiga, modelo "Fire Worker") preso a uma zona.

---

## 2. Estado atual do repositório

Tudo sincronizado: esta pasta = `origin/main` em https://github.com/hallisonmkb/RobloxInsetos.

Histórico: o commit da formiga (`64d2d5e`) existia só num zip (`Downloads\roblox-kit-base (1).zip`) e foi trazido em 2026-11-23 com `git fetch` + **merge** (`38e32ba`), não rebase, porque os commits de HANDOFF/CLAUDE já estavam publicados. O zip já não é necessário. Esse commit trouxe:

1. **`games/exemplo/server/ZoneEnemy.luau`** (novo): inimigo preso a uma zona.
2. **`src/server/init.server.luau`** (alterado): em vez de fazer `require` só do `Mechanic`, inicia **todos** os ModuleScripts de `ServerScriptService.Game` que tenham `start()`, cada um dentro de `pcall`.
3. **`games/exemplo/shared/Config.luau`** (alterado): nova secção `Config.Enemies`.

---

## 3. O que já está feito

### Kit base (commit `79295f3`)
- Estrutura Rojo (`default.project.json`) e toolchain via Rokit (`rokit.toml`).
- **DataService**: save/load por jogador com trava de sessão, autosave a cada 60 s, save ao sair e no `BindToClose`, e reconciliação de campos novos da `Config.DefaultData`.
- **CurrencyService**: moedas, multiplicador, renda offline, `leaderstats` e atributo `Coins` no jogador.
- **Remotes** (RemoteGuard): RemoteEvents centralizados com limite de chamadas por jogador e por segundo.
- **Cliente**: HUD provisório com contador de moedas e botão "Clique!".
- **Jogo de exemplo**: `Mechanic.luau`, em que clicar dá moedas (cooldown de 0,15 s e limite de 15 chamadas/s).
- README com instruções de setup para Windows.

### Inimigo de zona (commit `64d2d5e`)
- `ZoneEnemy.luau`: para cada entrada de `Config.Enemies`, procura no Workspace o `Model` e a `Part` da zona pelo nome. O modelo é ancorado e movido pelo servidor com `PivotTo` no `Heartbeat`, por isso não precisa de Humanoid. Passeia em pontos aleatórios da zona, persegue o jogador mais próximo que esteja dentro dela, para a 60 % do alcance e aplica `TakeDamage` respeitando o cooldown.
- Ao arrancar, `neutralize()` destrói todos os scripts que vieram com o modelo (proteção contra backdoors do Toolbox), ancora as partes e desliga colisões.
- Config atual: modelo `"Fire Worker"`, zona `"ZonaFormiga"`, dano 10, alcance 5, cooldown 1 s, velocidade a perseguir 14, a passear 5, margem 2 e `FacingOffset` 0.
- No Studio, o lugar tem de ter um Model chamado `Fire Worker` e uma Part chamada `ZonaFormiga` diretamente no `Workspace`. Isso fica no ficheiro do place, não no repositório.

### Não verificado
- **Não confirmei** nesta sessão se o kit ou o ZoneEnemy foram testados com Play no Studio. Convém perguntar ao utilizador ou testar.

---

## 4. Ficheiros principais

| Ficheiro | Destino no Roblox (Rojo) | Para que serve |
| --- | --- | --- |
| `default.project.json` | — | Mapeia as pastas para o DataModel. **Aponta para `games/exemplo`**; num jogo novo, troca-se o caminho. |
| `rokit.toml` | — | Versões fixas: rojo 7.4.4, wally 0.3.2, selene 0.27.1, stylua 0.20.0. |
| `selene.toml` / `stylua.toml` | — | Lint (std roblox) e formatação (tabs, 110 colunas, aspas duplas). |
| `src/server/init.server.luau` | `ServerScriptService.Server` | Bootstrap: inicia os serviços pela lista `ORDER` e depois os módulos do jogo. |
| `src/server/Services/DataService.luau` | `…Server.Services` | Perfis em DataStore `PlayerData_v1`, chave `u_<UserId>`. API: `get`, `waitFor`, `onBeforeRelease`, evento `Loaded(player, data)`. |
| `src/server/Services/CurrencyService.luau` | `…Server.Services` | API: `add(player, base, ignoreMultiplier?)`, `spend`, `get`, `getMultiplier`, `setMultiplier`. Publica `Coins` como atributo e em `leaderstats`. |
| `src/shared/Remotes.luau` | `ReplicatedStorage.Shared` | `Remotes.onServer(nome, maxPorSegundo, handler)` no servidor; `Remotes.get(nome):FireServer(...)` no cliente. Cria a pasta `ReplicatedStorage.Remotes`. |
| `src/client/init.client.luau` | `StarterPlayerScripts.Client` | HUD provisório. Lê o atributo `Coins` e dispara o remote `Click`. |
| `games/exemplo/shared/Config.luau` | `ReplicatedStorage.Game` | `GameName`, `DefaultData`, `Currency`, `Click` e `Enemies`. |
| `games/exemplo/server/Mechanic.luau` | `ServerScriptService.Game` | Mecânica de clique. |
| `games/exemplo/server/ZoneEnemy.luau` | `ServerScriptService.Game` | Inimigo de zona. |
| `README.md` | — | Setup para Windows, estrutura, estado dos módulos e regras. |

---

## 5. Decisões tomadas

- **Rojo + VS Code** como fonte do código. O Studio só serve para arte e teste. O fluxo é `rojo serve` aberto e o plugin Rojo ligado no Studio.
- **Toolchain via Rokit**, com versões fixas.
- **Luau `--!strict`** em todos os scripts.
- **Servidor autoritativo:** nenhum valor (moedas, itens, preços, dano) é decidido no cliente. O cliente só lê atributos e dispara remotes.
- **Todos os remotes passam por `Remotes.onServer`**, com rate limit. Chamadas acima do limite são ignoradas em silêncio, e erros do handler são apanhados com `pcall` e registados com `warn`.
- **Separação kit/jogo:** `src/` é genérico, `games/<nome>/` é específico. Os serviços leem a `Config` de `ReplicatedStorage.Game`.
- **DataService feito à mão** (sem ProfileService/ProfileStore): trava de sessão por `JobId`, expiração de 30 min e 6 tentativas de load com 5 s de intervalo. Na última tentativa, a trava é "roubada". Se ainda assim falhar, o jogador é expulso (`Kick`). O save não sobrescreve se outro servidor tiver a trava.
- **Novo serviço do kit:** criar em `src/server/Services/` com `start()` e acrescentá-lo à lista `ORDER`, por ordem de dependência.
- **Módulos do jogo** (após o commit `64d2d5e`): qualquer ModuleScript em `games/<jogo>/server/` com `start()` arranca automaticamente. Não há registo manual.
- **Inimigos sem Humanoid**, ancorados e movidos pelo servidor, para funcionar com qualquer modelo.
- **Assets do Toolbox:** a regra é não usar assets de autores não verificados. O ZoneEnemy, por precaução, destrói todos os scripts do modelo.
- **Idioma:** comentários, mensagens de log e textos para o jogador estão em **português do Brasil**.
- **Plugin `backend-design` do Claude Code desativado**: o hook dele (`check_migration.py`) precisa de Git Bash e Python, que não estão instalados, e bloqueava todas as escritas de ficheiros. Também não tem utilidade num projeto Roblox.

---

## 6. Problemas em aberto

### Ambiente
1. ~~A pasta local está um commit atrás~~ **Resolvido em 2026-11-23** (ver §2).
2. ~~O `git` não está no PATH~~ **Resolvido em 2026-11-23:** Git for Windows 2.56.1 instalado via winget (inclui Git Bash). **Atenção à identidade:** o `git config --global` está com a conta de trabalho (`noesis.hbittencourt`), mas os commits deste repo foram feitos como `hallisonmkb <hallisonmkb@users.noreply.github.com>`. Decidido: este repo usa a identidade pessoal, configurada localmente (sem `--global`); a global de trabalho fica intacta.
3. ~~Sem remote~~ **Resolvido em 2026-11-23:** `origin` = https://github.com/hallisonmkb/RobloxInsetos (branch `main`, com tracking). O login ficou guardado no Git Credential Manager. Nota: o Claude Code define `GCM_INTERACTIVE=never`; se o GCM voltar a pedir login, correr o push com `$env:GCM_INTERACTIVE='always'` para abrir a janela. O repo pareceu **público** (o `ls-remote` funcionou sem login); confirmar com o utilizador se deve ficar privado.
4. O utilizador usava Remote Control / claude.ai/code. Agora passa para a app desktop. Deve manter a janela do `rojo serve` aberta para as edições chegarem ao Studio.
5. **O Python também não está instalado** (o comando `python` abre o atalho da Microsoft Store).

### Código (encontrados na revisão)
6. ~~**DataService, corrida entre autosave e release**~~ **Corrigido em 2026-11-23 (falta testar no Studio):** flags `saving`/`releasing` por jogador. O autosave ignora quem está a sair ou já tem save em curso; o save de saída espera o autosave em curso terminar, por isso é sempre o último.
7. ~~**DataService, save duplicado no shutdown**~~ **Corrigido junto com o 6:** a flag `releasing` faz a segunda chamada (`BindToClose` + `PlayerRemoving`) sair logo.
8. **DataService:** não há verificação de orçamento (`GetRequestBudgetForRequestType`) nem retentativa nos saves.
9. **CurrencyService.spend** não valida se `amount` é inteiro/finito (NaN passa no `amount < 0`). Hoje só é chamado por código do servidor, mas convém validar.
10. **ZoneEnemy**:
    - o inimigo não tem vida e não pode ser morto;
    - só funciona com zonas planas (altura fixa calculada no início);
    - mover um modelo ancorado com `PivotTo` a cada frame no servidor replica de forma pouco suave para o cliente;
    - procura modelo e zona com `workspace:WaitForChild(nome)`, por isso só existe uma instância por nome e é preciso uma entrada de config para cada inimigo;
    - choca com a regra "nunca usar assets do Toolbox de autores não verificados" se o Fire Worker veio do Toolbox. Confirmar a origem com o utilizador.
11. **README** não menciona o ZoneEnemy nem o arranque automático de módulos do jogo.
12. **Wally** está no `rokit.toml`, mas não há `wally.toml` nem mapeamento de `Packages` no `default.project.json`.

---

## 7. Próximos passos (por ordem)

1. (Feito em 2026-11-23: commit da formiga trazido do zip por merge.)
2. (Feito em 2026-11-23: identidade git local `hallisonmkb <hallisonmkb@users.noreply.github.com>` só neste repo; push para `origin/main`.) Confirmar com o utilizador se o repo no GitHub deve ficar privado.
3. Testar no Studio: Play, clicar, sair e voltar (as moedas devem persistir), e entrar na `ZonaFormiga` (a formiga persegue e morde).
4. Ajustar o comportamento da formiga conforme o feedback do utilizador (valores em `Config.Enemies`).
5. Corrigir os pontos 8–9 de §6 (6 e 7 já corrigidos em 2026-11-23).
6. Atualizar o README (ZoneEnemy e arranque automático).
7. Módulos do kit ainda por fazer, segundo o README: ProgressionService (Level/XP/Rebirths já estão em `DefaultData`), ShopService, MonetizationService (game passes e dev products via `ProcessReceipt`), DailyRewardService (`DailyStreak` já está em `DefaultData`), Leaderboards (OrderedDataStore), UI Kit (substitui o HUD provisório) e AnalyticsService.
