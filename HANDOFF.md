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

### Mosquito voador e busca robusta (2026-11-23, sem commit no momento da escrita)
- No primeiro teste com Play, a formiga **ficou parada**. Provável causa: o modelo/zona não estavam diretamente no Workspace (ou tinham outro nome). O `ZoneEnemy` agora procura em todo o Workspace (`FindFirstChild(nome, true)`) durante até 15 s e imprime `[ZoneEnemy] "<modelo>" ativo…` no Output quando arranca. Se continuar parada, ler o Output.
- Suporte a voadores: campos opcionais `FlyHeight`, `BobAmplitude`, `BobSpeed`, `VerticalSpeed`. O voador paira acima da zona, balança e desce até o tronco do jogador para picar.
- Nova entrada em `Config.Enemies`: modelo `"Asian tiger mosquito"`, zona `"ZonaMosquito"` (o utilizador tem de criar esta Part no Studio).
- Testado: com as Parts renomeadas para `ZonaFormiga`/`ZonaMosquito`, os dois **funcionaram**.
- Realismo (campos opcionais na Config): curvas graduais (`TurnSpeed`), aceleração (`Acceleration`), pausas no passeio (`WanderPause`), passada da formiga (`StepBob`, `StepRate`, `TiltAngle`), voo irregular e inclinado do mosquito (`Jitter`, `TiltAngle`). Mosquito agora mais rápido (perseguir 18 vs. formiga 14). Ainda não testado no Studio.
- **Testado e aprovado pelo utilizador em 2026-11-23:** patas, tamanhos (`Scale`), mosquito e pulgão.
- Patas animadas por código: o Fire Worker tem 35 MeshParts ligadas por Motor6D (`LeftFrontLeg1..4`, `...Antennae1/2`, `LMandible/RMandible`, `Torso` como raiz) e UniversalConstraints de ragdoll. O `setupRig` ancora só a raiz, desliga as constraints e roda o `C0` dos Motor6D em passo de tripé (quadril e joelho), mexe as antenas e fecha as mandíbulas ao morder; toca o som `Bite`. Os eixos são calculados a partir da pose inicial. Config: `LegSwing`, `LegLift`, `AttackSound`.
- **Modelos próprios (testado e aprovado pelo utilizador):** `games/exemplo/server/Models/<Nome>.luau` com `build(nome, origin) -> Model`, feitos de Parts + SpecialMesh esfera + cilindros, todos ligados por Motor6D com nomes do padrão animado (`<Lado><Pos>Leg1/2/3`, `<Lado>Antennae1/2`). Na Config: `Build = "<Nome>"`; o modelo é criado no topo da zona e um modelo antigo com o mesmo nome é destruído só durante o jogo. Primeiro modelo: `Pulgao.luau`, um afídeo verde-claro com abdómen em pera, faixas, olhos vermelhos, rostro, antenas compridas, 6 patas de 3 segmentos, sifúnculos e cauda (Scale 0.5, cerca de 2,8 studs). O modelo antigo da Toolbox pode ser apagado do place.
- Segundo modelo próprio (sem testar): `MosquitoTigre.luau`, um Aedes albopictus preto com risca dorsal branca no tórax, manchas brancas no tórax e no abdómen, faixas no dorso, patas pretas com faixas brancas (pontas das patas de trás brancas), tromba, palpos com ponta branca, olhos grandes, antenas e asas translúcidas `LeftWing`/`RightWing` que batem em voo. Na Config: `Model = "Mosquito"`, `Build = "MosquitoTigre"`, Scale 0.7. O utilizador vai apagar do place o mosquito e o pulgão antigos da Toolbox.
- Terceiro modelo próprio (sem testar): `Formiga.luau`, uma formiga-de-fogo com cabeça e tórax castanho-avermelhados, gáster escuro com faixas, pecíolo de 2 nós, antenas cotoveladas com clava, mandíbulas (`LeftMandible`/`RightMandible`) e ferrão. `Count = 2`, Scale 1. Substitui a Fire Worker da Toolbox, que o utilizador deve apagar do place.
- Corrigido: a formiga andava de marcha-atrás porque o `WorldPivot` era o CFrame do tórax (um `longEllipsoid` criado a apontar para trás). A primeira correção (`model.WorldPivot`) **não funcionou**: com PrimaryPart, o Roblox ignora o WorldPivot e usa o pivô da peça principal. **Regra para os modelos:** chamar `Parts.setPivot(b, centro)`, que ajusta o `PivotOffset` da PrimaryPart para o modelo ficar virado para -Z.
- **Testado:** com `setPivot`, a formiga anda de frente.
- Ajustes pedidos: só 3 pulgões (`Count = 3`); gafanhoto mais rápido que o mosquito (ChaseSpeed 22 contra 18, WanderSpeed 8 contra 7, HopDistance 10).
- Antenas: o segmento 2 (`Antennae2`) também mexe; ficam mais amplas e mais rápidas quando o inseto persegue.
- Quarto modelo próprio (sem testar): `Gafanhoto.luau` na `ZonaGafanhoto`, com 4 patas de andar (`Front/Mid`), 2 patas de saltar (`HindLeg1` coxa grossa, `HindLeg2` tíbia com espinhos, joelho escuro), asas dobradas (`Tegmen`, não batem), pronoto e antenas. Scale 2 (~8,8 studs; o tamanho real seria ~30). Saltos no ZoneEnemy: `HopInterval`, `HopTime`, `HopHeight`, `HopDistance`, com o coice das patas `hind1`/`hind2` (os sinais de rotação foram deduzidos e não testados; se as patas rodarem ao contrário, trocar o sinal em `animateRig`).
- **Cenário (corrido e aprovado pelo utilizador):** `tools/Montanhas.luau`, para colar uma vez na Command Bar. Esculpe com `Terrain:ReadVoxels/WriteVoxels` uma faixa de montanhas realistas junto às bordas da Baseplate: relva, terra, rocha nas encostas íngremes e neve acima de 72 % da altura máxima. Nunca cobre as Parts `Zona*` nem o SpawnLocation (30 studs de folga). Se não existir, acrescenta uma `Atmosphere`. Configuração no topo do script: `SEMENTE`, `ALTURA_MAX`, `LARGURA_FAIXA`, `NEVE`. Pode correr-se de novo para substituir as montanhas.
- **Muro (corrido e aprovado pelo utilizador, a seguir o contorno):** `tools/Muro.luau`, para colar na Command Bar. Cria o Model `MuroDaArea`. Por omissão usa cópias do modelo **`StudWall`** do utilizador (veio da Toolbox, dentro de "Stud Wall"; procurado primeiro no ServerStorage e depois no Workspace), lado a lado, alinhadas pelo eixo mais comprido da caixa do modelo. Se não o encontrar, faz um muro de tijolo com pilares e remate de pedra. A primeira versão fazia um retângulo à volta de tudo, e o utilizador pediu para seguir as zonas. Agora segue o **contorno real** da união das Parts `Zona*` (incluindo a ZonaPrincipal) e do SpawnLocation, alargadas pela `MARGEM` (4 studs): marca numa grelha de 2 studs as células dentro das zonas e junta as arestas entre dentro e fora em troços retos. Por cima tem uma barreira invisível de 60 studs. Correr outra vez substitui o muro.
- **Ciclo do jogo: ovos, fazenda e descanso (2026-11-23, sem testar).** Decisões do utilizador: o ovo vai nos braços à velocidade normal; os insetos perseguem até quem leva o ovo sair da zona; a fazenda é pessoal e fica guardada; o utilizador cria no Studio as Parts `ZonaFazenda` e `ZonaDescanso*`.
  - `Config.Insetos` (por tipo: zona, modelo, ninho, cor do ovo, dificuldade, `ChocaEm`, `CresceEm`, `Rende`, `EscalaFazenda`), `Config.Ovos`, `Config.Fazenda`, `Config.Descanso`, e `DefaultData.Fazenda = {}` (lista de `{Tipo, Nasceu}`).
  - `Models/Ovo.luau` (ovo de 5 studs com pintas e luz) e `Models/Ninhos.luau` (`Folhas` para o pulgão, `Formigueiro` em degraus de 2,2 studs onde se sobe aos saltos com o ovo na cratera, `Chao` com gravetos).
  - `Ovos.luau`: constrói o ninho no centro de cada zona, põe `Acordado=false` e `NinhoRaio` na Part da zona, e cria um ProximityPrompt "Pegar ovo". Ao pegar: o ovo é soldado ao HumanoidRootPart e a zona acorda. Ao sair da zona: a zona dorme e aparece um ovo novo após `VoltaEm`. Se o jogador morrer na zona, o ovo volta ao ninho; fora da zona, perde-se. Ao entrar na `ZonaFazenda`: `Fazenda.addInsect`.
  - `ZoneEnemy`: com `Acordado == false`, ignora os jogadores, vai para um lugar à volta do ninho, pousa (voadores), vira-se para o ninho e mexe as antenas devagar.
  - `Fazenda.luau`: divide a `ZonaFazenda` em `Lotes` (cerca e placa com o nome do dono), com uma grelha de 4 colunas por lote. Ovo -> Bebé (escala 0,55) -> Adulto, com BillboardGui e tempo restante; paga moedas a cada segundo (acumula frações).
  - `Descanso.luau`: decora cada `ZonaDescanso*` (2 bancos com Seat, candeeiro, placa, flores) e cura `CuraPorSegundo`.
  - Cliente (genérico do kit): atributo `Estado` = faixa fixa; `Aviso` + `AvisoId` = mensagem de 4 s.
  - Depois de criar as zonas novas, voltar a correr `tools/Muro.luau` (o muro inclui todas as `Zona*`).
- **Revisão de 2026-11-24 (sem testar):**
  - Primeiro teste do utilizador: não havia fazenda (faltava a Part `ZonaFazenda`); pediu para poder soltar os ovos e para os ovos caírem quando é picado.
  - **Posturas realistas** (`Models/Ovo.luau`, `Forma`): `Pulgao` (cacho de ovos amarelos alongados), `Formiga` (monte de "grãos de arroz" creme, alguns com pinta escura), `Mosquito` (jangada de tubos castanhos), `Gafanhoto` (casulo de terra com ovos creme em arcos), `Unico` (o ovo antigo). A peça principal é `Base` (invisível).
  - **Ninhos** (`Models/Ninhos.luau`): `Folha`, `Formigueiro(origin, count)` (cone de 28 WedgeParts, raio 8 e altura 5,5, que se sobe a andar, com palhinhas, entradas, relva, e uma postura no topo e as outras na base; **a orientação das cunhas não foi vista**: se o cone sair invertido, rodar 180° em `CFrame.lookAt`), `Poca` (água, lama, juncos) e `Toca` (casulo meio enterrado).
  - **Várias posturas por zona** (`OvosNaZona`, 3 ou 4): formigueiro no centro; nos outros, em círculo à volta do centro. Os insetos dormem no meio (`NinhoRaio` 4; 10 na formiga). A zona fica acordada enquanto alguém lá dentro levar uma postura dela. Cada sítio volta a ter ovos `VoltaEm` s depois.
  - **Soltar e cair:** tecla G ou botão no HUD (atributo genérico `Acao` + remote `Acao`, no kit), e queda automática quando perde vida (`CaiAoSerPicado`). A postura caída fica no chão `CaidoVoltaEm` s (30) e depois volta ao ninho.
  - **Comportamento dos insetos (sem testar), depois do 2.º teste do utilizador** ("saio da zona e volto com ovos e ignoram-me"):
    - `Ovos.refreshAwake` corre a cada 0,2 s: a zona fica `Acordado=true` enquanto alguém com ovos (de qualquer inseto) estiver lá dentro.
    - `ZoneEnemy`: com a zona acordada, ou já em perseguição, persegue o portador mais próximo (atributo `CarregandoOvo`) **mesmo fora da zona**, até `Alcance` (250) studs do centro, e nunca dentro das zonas seguras (`ZonaPrincipal`, `ZonaFazenda`, `ZonaDescanso*`; ver `Config.ZonasSeguras`). Fora da zona move-se livre e, ao perder o alvo, volta a entrar.
    - Vida própria: cada inseto alterna entre "dormir" (lugar à volta do ninho, 20 a 60 s) e "passear" (15 a 40 s), com `SonoChance` 0,5. Quem passeia ataca quem chegar a menos de `AggroRange` (12) studs.
    - Mais insetos: formiga 6, pulgão 8, gafanhoto 3, mosquito 4.
  - **Fazenda e níveis (sem testar):**
    - Bug encontrado: a Fazenda usava `workspace:WaitForChild("ZonaFazenda")`, mas o Mapa põe as zonas em `Workspace.Zonas`, por isso não aparecia. Agora procura em todo o Workspace e, se não existir, cria-a ao lado da ZonaPrincipal (`TamanhoAuto`).
    - Área nova: celeiro (vermelho, telhado de duas águas, fardos) na ponta mais afastada do centro do mapa; **12 lotes em duas filas** com um caminho de 12 studs no meio. Cada lote tem terra lavrada com sulcos, cerca com postes, portão virado para o caminho, placa com o nome e o bónus de nível, e ninhos de palha. ZonaFazenda no Mapa: 220x120.
    - **ProgressionService** (kit, `src/server/Services`, na `ORDER` a seguir ao CurrencyService): `addXP`, `getLevel`, `xpToNext`, evento `LevelUp`, atributos `Level`/`XP`/`XPNext` e "Nível" na leaderstats. Valores em `Config.Progressao`.
    - Nível -> tempo: fator = max(`FatorMinimo` 0,3; 1 - `ReducaoPorNivel` 0,06 x (nível-1)), aplicado a ChocaEm e CresceEm (também retroativo, aos ovos já na fazenda). Entregar ovos dá `Dificuldade x XPPorDificuldade` (25) XP.
    - HUD (kit): caixa "Nível N, xp/next" com barra verde, em baixo à esquerda.
    - Recomendado: no Studio, Game Settings -> Places -> Max Players = 12 (igual ao número de lotes).
    - 3.º teste: "o ovo sumiu e o lote não ficou no meu nome". O Output mostrou a fazenda criada sem erros: o lote foi dado, mas era o lote ao lado do celeiro, no fundo, e o utilizador só via "Lote livre" à entrada. Correções: os lotes são ordenados pela distância à ZonaPrincipal/spawn (o 1.º é o mais perto da entrada); o lote do dono tem um feixe Neon de 60 studs com "Lote N: nome"; o atributo `LoteFazenda` aparece no aviso "leva-os para o teu lote N"; e a decoração de cada lote corre em `pcall`.
  - **Insetos da fazenda mexem-se (sem testar):** nova função `ZoneEnemy.pet(model, area, halfX, halfZ, speed)`. Passeia dentro do retângulo do lote com pausas de 1 a 5 s, anima as patas e as antenas (alert -0,3), corre a 30 Hz e para sozinha quando o modelo é destruído. A Fazenda chama-a para bebés (1,2 studs/s) e adultos (2 studs/s); os ovos ficam parados.
  - **`tools/Mapa.luau`:** apaga as `Zona*` e os SpawnLocation e cria a fila Fazenda (160x80) | Principal (80x80, spawn) | Descanso1 | Pulgão (140) | Descanso2 | Formiga (140) | Descanso3 | Mosquito (150) | Descanso4 | Gafanhoto (160) na pasta `Workspace.Zonas`. O utilizador autorizou apagar as zonas feitas à mão. Depois é preciso correr de novo o `tools/Muro.luau`.
- As funções comuns de construção estão em `Models/Parts.luau` (`newBuilder`, `ellipsoid`, `longEllipsoid`, `segment`, `joint`, `mirror`).
- Tamanhos proporcionais (cerca de 0,8 studs por mm real): formiga Scale 1 (~4,3 studs), pulgão 0.6 (~2,2), mosquito 1.2 (~3,8 de corpo, 5,2 com a tromba).
- `Count` na Config (só com `Build`): cria N inimigos iguais (`Pulgao1`…`Pulgao6`), cada um num ponto aleatório da zona. Pulgões: `Count = 6`.
- Os eixos das patas (quadril/joelho/asa) passaram a usar a direção lateral pura; isto também muda um pouco o passo da formiga.
- Mosquito pousa e anda (sem testar): alterna entre voar (`FlyTime` {6,12} s) e pousar a andar no chão (`GroundTime` {4,8} s, `GroundSpeed` 2). Quando vê um jogador, levanta voo logo; o zumbido pára enquanto está pousado. Suporte genérico a asas (`WingFlap`, `WingRate`) para peças com "wing"/"asa" no nome presas por Motor6D, só a bater quando está no ar.
- O mosquito é **uma única MeshPart** (gerado por IA, `.gltf`): não dá para animar asas/patas sem trocar de modelo.
- Novo inimigo `Pulgao` na `ZonaPulgao` (lento, dano 3, `Scale` 0.6). O modelo tem esqueleto R6 (Torso, `Left/Right Hip`, `Left/Right Shoulder`, HumanoidRootPart) e peças Union numeradas 1–18 presas por Motor6D chamados `Joint`. O código agora balança os membros R6 em pares diagonais (sem testar). Se as patas visíveis estiverem presas ao Torso e não aos membros, não vão mexer: o Output lista as juntas (`Part0 -> Part1`) para descobrir.
- Patas do pulgão: as patas visíveis são cadeias de Unions presas ao `Mainbody` (1-2-3, 4-5-6, … 16-17-18). Config `LegParts = {"1","4","7","10","13","16"}`; lado e ordem do tripé calculados pela posição. Sem testar.
- Testado: as pernas do pulgão mexem (12 juntas animadas).
- Feito a seguir (**testado e aprovado**; os IDs de áudio já estão na Config: zumbido 109978104393702, picada/mordida 9125466770): o nome e a barra de vida do Humanoid deixam de aparecer por cima do pulgão; investida ao atacar para todos (`Lunge`, `LungePitch`); flash vermelho no ecrã ao perder vida, no cliente (`src/client/init.client.luau`, ScreenGui `DamageFlash`), porque o flash padrão do Roblox não aparece com danos pequenos; `AttackSound`/`LoopSound` aceitam um ID de áudio. **Faltam os IDs de áudio** do mosquito (picada e zumbido) e do pulgão: o utilizador tem de os escolher na Toolbox → Audio.
- Moedas: o utilizador confirmou que persistem entre Plays (save OK).
- **INCIDENTE DE SEGURANÇA (2026-11-23 19:13):** durante o Play apareceu uma janela falsa "Roblox Studio — Recovery" (desenhada dentro do jogo) a pedir para colar na Command Bar um código que liga o HttpService, faz `GetAsync("https://recovery.rbx-cdn.com")` e `require` do ID devolvido, ou seja, um backdoor. Vem quase de certeza de um asset da Toolbox no place (suspeitos: `Pulgao`, `Ant Life Ragdolls`, `Tree3`). O utilizador **só clicou em "Recover"** e não correu o comando (o Output não mostra o comando a ser executado na Command Bar). Allow HTTP Requests foi desligado.
  - Limpeza feita com `tools/LimpezaScripts.luau`, colado na Command Bar. Apagou a pasta `Ant Life Ragdolls`, 4 scripts do `Pulgao` (Animate, GainpointswhenKill, Respawn, Move) e o backdoor **`Workspace.Assets.Building.Ground.Texture.Runtime`**, que tinha dentro o `ScreenBuilder`, o script que desenhava a janela falsa. Os nossos scripts não tinham código suspeito.
  - Falta: testar com Play (a janela não deve voltar a aparecer), guardar com File → Save to Roblox, e ver se a pasta `Workspace.Assets` é do utilizador ou também veio da Toolbox.
  - Regra: correr `tools/LimpezaScripts.luau` sempre que se inserir um modelo da Toolbox.
- No Output aparecem erros de animação `73406197912221` e de asset `203785492`, provavelmente de scripts da pasta `Ant Life Ragdolls` (Toolbox). Recomendado apagar essa pasta.

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
6. (Feito em 2026-11-23: README atualizado com o ZoneEnemy e o arranque automático.)
7. Módulos do kit ainda por fazer, segundo o README: ProgressionService (Level/XP/Rebirths já estão em `DefaultData`), ShopService, MonetizationService (game passes e dev products via `ProcessReceipt`), DailyRewardService (`DailyStreak` já está em `DefaultData`), Leaderboards (OrderedDataStore), UI Kit (substitui o HUD provisório) e AnalyticsService.
