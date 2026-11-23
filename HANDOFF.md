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

## 2. ⚠️ Estado atual: a pasta local está desatualizada

Há **duas versões** do projeto:

| Onde | Commits | Conteúdo |
| --- | --- | --- |
| `C:\Roblox\Projetos\roblox-kit-base` (esta pasta) | `79295f3` (inicial) → `d16e8b2` (HANDOFF/CLAUDE) | kit base + jogo de clique |
| `%USERPROFILE%\Downloads\roblox-kit-base (1).zip` | `79295f3` → **`64d2d5e`** "Inimigo preso a uma zona (ZoneEnemy) e bootstrap inicia todos os módulos do jogo" | o mesmo, mais o inimigo de zona |

Diferenças do zip em relação a esta pasta (verificadas ficheiro a ficheiro; o resto é idêntico):

1. **`games/exemplo/server/ZoneEnemy.luau`** (novo): inimigo preso a uma zona.
2. **`src/server/init.server.luau`** (alterado): em vez de fazer `require` só do `Mechanic`, inicia **todos** os ModuleScripts de `ServerScriptService.Game` que tenham `start()`, cada um dentro de `pcall`.
3. **`games/exemplo/shared/Config.luau`** (alterado): nova secção `Config.Enemies`.

A sessão anterior encontrou o zip, extraiu-o para uma pasta temporária e **parou antes de copiar os ficheiros para o projeto**. A extração temporária já não existe.

**Primeiro passo da próxima sessão:** trazer o commit `64d2d5e` para esta pasta (ver §7, passo 1).

---

## 3. O que já está feito

### Kit base (commit `79295f3`, presente nesta pasta)
- Estrutura Rojo (`default.project.json`) e toolchain via Rokit (`rokit.toml`).
- **DataService**: save/load por jogador com trava de sessão, autosave a cada 60 s, save ao sair e no `BindToClose`, e reconciliação de campos novos da `Config.DefaultData`.
- **CurrencyService**: moedas, multiplicador, renda offline, `leaderstats` e atributo `Coins` no jogador.
- **Remotes** (RemoteGuard): RemoteEvents centralizados com limite de chamadas por jogador e por segundo.
- **Cliente**: HUD provisório com contador de moedas e botão "Clique!".
- **Jogo de exemplo**: `Mechanic.luau`, em que clicar dá moedas (cooldown de 0,15 s e limite de 15 chamadas/s).
- README com instruções de setup para Windows.

### Inimigo de zona (commit `64d2d5e`, **só no zip**)
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
| `games/exemplo/shared/Config.luau` | `ReplicatedStorage.Game` | `GameName`, `DefaultData`, `Currency`, `Click` e (no zip) `Enemies`. |
| `games/exemplo/server/Mechanic.luau` | `ServerScriptService.Game` | Mecânica de clique. |
| `games/exemplo/server/ZoneEnemy.luau` | `ServerScriptService.Game` | **Só no zip.** Inimigo de zona. |
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
1. **A pasta local está um commit atrás** (ver §2).
2. ~~O `git` não está no PATH~~ **Resolvido em 2026-11-23:** Git for Windows 2.56.1 instalado via winget (inclui Git Bash). **Atenção à identidade:** o `git config --global` está com a conta de trabalho (`noesis.hbittencourt`), mas os commits deste repo foram feitos como `hallisonmkb <hallisonmkb@users.noreply.github.com>`. Decidido: este repo usa a identidade pessoal, configurada localmente (sem `--global`); a global de trabalho fica intacta.
3. **O repositório não tem remote** (`.git/config` sem `[remote]`). O código só existe neste PC e nos zips.
4. O utilizador usava Remote Control / claude.ai/code. Agora passa para a app desktop. Deve manter a janela do `rojo serve` aberta para as edições chegarem ao Studio.
5. **O Python também não está instalado** (o comando `python` abre o atalho da Microsoft Store).

### Código (encontrados na revisão; nenhum foi corrigido)
6. **DataService, corrida entre autosave e release:** um autosave (`release=false`) em curso quando o jogador sai pode terminar *depois* do save de release e voltar a gravar a trava. Na entrada seguinte noutro servidor, o load espera cerca de 25 s até roubar a trava. Correção possível: marcar o jogador como "a sair" e ignorar autosaves desse jogador, ou serializar os saves por jogador.
7. **DataService, save duplicado no shutdown:** o `BindToClose` chama `onPlayerRemoving` e o evento `PlayerRemoving` também. Isso dá dois saves por jogador e gasta orçamento de DataStore. Inofensivo, mas desperdiça pedidos.
8. **DataService:** não há verificação de orçamento (`GetRequestBudgetForRequestType`) nem retentativa nos saves.
9. **CurrencyService.spend** não valida se `amount` é inteiro/finito (NaN passa no `amount < 0`). Hoje só é chamado por código do servidor, mas convém validar.
10. **ZoneEnemy** (no zip):
    - o inimigo não tem vida e não pode ser morto;
    - só funciona com zonas planas (altura fixa calculada no início);
    - mover um modelo ancorado com `PivotTo` a cada frame no servidor replica de forma pouco suave para o cliente;
    - procura modelo e zona com `workspace:WaitForChild(nome)`, por isso só existe uma instância por nome e é preciso uma entrada de config para cada inimigo;
    - choca com a regra "nunca usar assets do Toolbox de autores não verificados" se o Fire Worker veio do Toolbox. Confirmar a origem com o utilizador.
11. **README** não menciona o ZoneEnemy nem o arranque automático de módulos do jogo.
12. **Wally** está no `rokit.toml`, mas não há `wally.toml` nem mapeamento de `Packages` no `default.project.json`.

---

## 7. Próximos passos (por ordem)

1. **Sincronizar com o zip.** Esta pasta já tem um commit próprio (`d16e8b2`, com HANDOFF/CLAUDE) sobre `79295f3`, e o zip tem `64d2d5e` sobre o mesmo `79295f3`. **Não substituir a `.git/`**, porque isso perderia o `d16e8b2`. Em vez disso:
   - extrair `Downloads\roblox-kit-base (1).zip` para uma pasta temporária **nova e vazia**;
   - `git fetch "<pasta>\roblox-kit-base" main:zoneenemy` e confirmar `git log zoneenemy` → `64d2d5e`;
   - `git merge zoneenemy` (não há conflitos esperados: os ficheiros não se sobrepõem), ou `git rebase zoneenemy` para histórico linear;
   - apagar a pasta temporária e o branch `zoneenemy`.
   **Confirmar com o utilizador antes.**
2. (Feito: identidade local `hallisonmkb <hallisonmkb@users.noreply.github.com>` configurada só neste repo; HANDOFF/CLAUDE commitados em `d16e8b2`.) Se o utilizador quiser, criar um remote privado no GitHub e fazer push.
3. Testar no Studio: Play, clicar, sair e voltar (as moedas devem persistir), e entrar na `ZonaFormiga` (a formiga persegue e morde).
4. Ajustar o comportamento da formiga conforme o feedback do utilizador (valores em `Config.Enemies`).
5. Corrigir os pontos 6–9 de §6, a começar pela corrida de saves (6).
6. Atualizar o README (ZoneEnemy e arranque automático).
7. Módulos do kit ainda por fazer, segundo o README: ProgressionService (Level/XP/Rebirths já estão em `DefaultData`), ShopService, MonetizationService (game passes e dev products via `ProcessReceipt`), DailyRewardService (`DailyStreak` já está em `DefaultData`), Leaderboards (OrderedDataStore), UI Kit (substitui o HUD provisório) e AnalyticsService.
