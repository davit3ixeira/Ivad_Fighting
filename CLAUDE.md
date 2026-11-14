# Ivad Fighting

Jogo de luta 2D local para 2 jogadores, estilo Street Fighter, em Godot 4.7.2 (GDScript, renderer Compatibility). Todo visual gerado por código, sem assets externos. O usuário dirige, joga e testa; o código inteiro é escrito pela IA.

## Ambiente

- Godot: `"C:\Users\dtmal\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"` (a pasta tem `.exe` no nome; sempre citar o caminho completo entre aspas).
- Console (imprime no terminal): `"C:\Users\dtmal\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"`.
- Projeto: `C:\Users\dtmal\Downloads\Ivad_Fighting`.
- Máquina alvo: HP 15-dy1xxx, i5-1035G1, 8 GB, Intel UHD integrada, tela 1366x768. Meta: 60 fps estáveis.
- Resolução base 1280x720, stretch `canvas_items`, passo físico 60 Hz, vsync ligado.
- Não há Python na máquina. Scripts auxiliares em bash/sed ou GDScript.

## Comandos

Rodar no Git Bash a partir da pasta do projeto. `G` é o executável de console.

```
G="C:/Users/dtmal/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
"$G" --headless --path . --import                                             # importa e reporta erros de parse
"$G" --headless --path . res://tests/sim_smoke_test.tscn --quit-after 600     # teste automático da simulação (imprime ok/FALHA)
"$G" --headless --path . --quit-after 300                                     # roda a cena principal sem janela
"$G" --path . res://tests/visual_capture.tscn -- "<pasta>" poses              # PNGs das poses do genérico
"$G" --path . res://tests/visual_capture.tscn -- "<pasta>" ivad               # PNGs dos golpes e efeitos do Ivad
"$G" --path . res://tests/visual_capture.tscn -- "<pasta>" ko                 # PNGs do KO
"$G" --path . res://tests/visual_capture.tscn -- "<pasta>" perf full          # fps e custo (variantes: generic, idle, brawl, full)
"$G" --path .                                                                 # roda normal para o usuário testar
"$G" --path . res://scenes/controller_test.tscn                               # tela de teste de controles
```

Antes de entregar: import, smoke test, captura visual (ler os PNGs) e perf. Nunca dizer que funciona sem ter rodado.

## Regras do projeto

- Nenhum comentário no código: nem de linha, nem de bloco, nem docstring. Nomes claros no lugar.
- Código e identificadores em inglês. Todo texto exibido ao jogador em português.
- Orientado a dados: golpes, frames, personagens e balanceamento em scripts de dados (`data/`). Todos os números de ajuste de um personagem ficam em um único arquivo (`data/characters/<nome>/<nome>_data.gd`); constantes globais em `core/global_tuning.gd`.
- Lógica separada da aparência: `Fighter`, `FightSim`, módulos e comportamentos de entidade não conhecem a view. A view lê estado e reage a sinais do sim.
- Sem RigidBody nem física do motor na luta. Simulação determinística em frames inteiros com retângulos próprios.
- Habilidades únicas são módulos (`FighterModule`) e comportamentos (`EntityBehavior`) por composição. Nada de `if` por personagem no núcleo.
- Áudio: `AudioManager.play_sfx(nome)` já posicionado nos eventos; não faz nada se não existe `audio/sfx/<nome>.wav|ogg`. Bipes de teste atrás de `AudioManager.test_beeps_enabled`.
- Git: commit ao fim de cada marco e antes de refatorações grandes, mensagem curta em português. Sem push sem pedido.
- Debug: F1 caixas e frame data. F2 boneco de treino no P2. F3 modo do boneco. F4 reinicia. F5 troca personagem do P1. F6 troca personagem do P2. F7 enche as barras de poder. F11 tela cheia.
- Entregas por marcos jogáveis; parar ao fim de cada um para o usuário testar. Falar em português, curto e direto.

## Desempenho (regra medida, não opinião)

- `draw_circle`, `draw_colored_polygon`, `draw_polygon`, `draw_polyline` e `draw_arc` criam uma malha nova na GPU a cada chamada. Com centenas por frame o custo de script passou de 10 ms e o jogo caiu para 44 fps na máquina alvo.
- Em tudo que redesenha todo frame usar só primitivas em lote: `draw_line`, `draw_rect`, `draw_primitive` (até 4 pontos) e `draw_texture_rect`. `DrawKit` já entrega `disc`, `soft_disc`, `capsule`, `quad`, `diamond`, `star`, `ring`, `ellipse_ring` nesse formato, com texturas geradas em código.
- As chamadas proibidas só valem em desenho estático (uma vez), como o palco.
- Sem shaders de glow, sem Light2D. Brilho = halo aditivo + contorno opaco + `soft_disc`.
- Referência atual: dois Ivads com especiais e supremo custam cerca de 4 ms de script por frame, 60,0 fps cravados.

## Convenções da simulação

- `Fighter.state_frame` começa em 0 ao entrar no estado e soma 1 ao fim de cada passo. Depois do passo em que o botão foi lido vale 1.
- Golpe com `startup` N fica ativo nos frames N+1 até N+active. Total preso = startup + active + recovery.
- Golpes aéreos não têm recovery: duram até pousar e geram `ATTACK_LANDING_FRAMES` de pouso.
- Retângulos de golpe ficam no espaço do personagem virado para a direita, origem nos pés, y negativo para cima.
- Defesa: segurar para trás. Em pé segura HIGH e MID; agachado segura LOW e MID. Golpes aéreos são HIGH, chutes agachados são LOW.
- Todo contato vira um `HitInfo` (cópia dos campos do golpe + overrides da janela + carga + `modify_hit` dos módulos). Projéteis também geram `HitInfo`.
- Golpe com várias janelas de acerto usa `MoveData.windows` (`HitWindow`). Sem isso vale uma janela padrão de `startup`/`active`/`hitboxes`.
- Eventos de golpe (`MoveData.events`): `{"frame", "type"}` com tipos `spawn` (entidade), `effect`, `sfx`, `module` (vai para `FighterModule.on_move_event`).
- Carga: `charge_frame` é o frame em que o golpe fica parado enquanto o botão está segurado, até `charge_max_frames`.
- Supremo: `meter_cost`, `super_freeze` (duração) e `super_freeze_frame` (quando congela). Durante o congelamento ninguém avança, só os buffers de entrada.
- Tipos de golpe: NORMAL, SPECIAL, SUPER, UNIQUE (R1). Normais com `special_cancel` cancelam em especial ou supremo no acerto ou na defesa. Especiais com `super_cancel` cancelam em supremo.
- Comandos (`CommandParser`): QCF 236, QCB 214, DP 623, HCF, HCB, duplo QCF/QCB, carga. Tolerância de 10 frames entre passos; o último passo precisa ter começado há no máximo 10 frames.
- Toque duplo para dash só conta com direção horizontal pura; qualquer direção vertical no meio zera a contagem.
- Combo: escala de dano por `combo_scale_hits` e queda de hitstun por `combo_hits`. `scales_combo = false` tira um acerto da escala (usado no supremo).
- No canto, o knockback que o defensor não pode receber volta para o atacante (só golpes corpo a corpo).
- Entidades (`Entity` + `EntityData`): dono, vida útil, velocidade, hitboxes, `hits` e `hit_interval`, `clash` e `durability` (projétil contra projétil), `cuttable` (golpes com `cuts_projectiles` destroem), `destructible` com `hurtbox` e `health`. Lógica extra em `EntityBehavior`.
- `FightSim.snapshot_overrides[slot]` substitui a entrada do jogador (testes, futura IA).

## Convenções do rig e do visual

- Ângulos absolutos em graus: 0 aponta para baixo, 90 para frente, 180 para cima, negativo para trás.
- Chaves de pose: `spine, neck, arm_n, fore_n, arm_f, fore_f, thigh_n, shin_n, thigh_f, shin_f, lean_x, hip_y`. Sufixo `n` é o lado perto da câmera, `f` o lado longe.
- `hip_y` -1 calcula a altura do quadril para os pés tocarem o chão. No ar usar valor explícito.
- Animação: `{"loop": bool, "keys": [{"t": frame, "pose": {...}}]}`. O `t` segue o `state_frame`, então a pose de impacto fica em `startup + 1`.
- Nomes de animação esperados pelo núcleo: `idle, walk_forward, walk_back, crouch, prejump, jump, landing, dash, backdash, block_stand, block_crouch, hit_stand, hit_crouch, hit_air, knockdown, getup, ko` e o `id` (ou `animation`) de cada golpe. Opcionais: `intro`, `win`.
- Extras do rig em `rig["extras"]` (lista de configs com `type`). Hoje existe `hair_chain` (cadeia com mola, gravidade e atraso). Novos tipos entram em `FighterView._create_extra`.
- Visual de entidade: `EntityData.visual` mapeia em `EntityVisuals.create`. Efeitos por nome em `EffectLibrary` (presets de `BurstEffect` ou efeitos próprios).
- Cor: contorno do jogador (azul P1, vermelho P2), `accent_color` do personagem nos detalhes e `power_color` nos efeitos de poder.

## Entrada

- Cada jogador lê só o próprio device id. Nunca assumir ordem de conexão.
- Mapeamento de botões e teclas de debug em um único arquivo: `input/button_map.gd`.
- Teclado lido por tecla física, não pelo Input Map do projeto.
- Pseudo-devices: `-2` teclado WASD, `-3` teclado Setas, `-1` nenhum.
- Steam Input pode duplicar controles: `poll_join_press` ignora um segundo device que repita o mesmo estado dentro de 10 frames.
- Controle PS5: □ soco fraco, △ soco forte, X chute fraco, ○ chute forte, R1 habilidade, Options pausa.
- Teclado P1: WASD, J U K I, L habilidade, Esc pausa. Teclado P2: setas, Numpad 1 4 2 5, Numpad 3 habilidade, Esc pausa.

## Personagens

### Ivad (completo)

- Postura relaxada, cabelo loiro longo simulado, cor de poder violeta.
- Normais: Peteleco, Palma Cósmica, Chute Desleixado, Órbita, Cutucão, Ascensão (lança), Rasteirinha (baixo), Varredura Orbital (derruba), Tapa Aéreo, Meteoro, Joelhada, Cometa.
- Soco de Ivad: ↓↘→ + soco. Segurar o botão carrega; carga cheia fura a defesa. Lança e gera o anel cósmico.
- Poço Gravitacional: ↓↙← + soco. Esfera lenta (fraco) ou rápida (forte) que puxa o oponente e desvia projéteis, acerta 3 vezes. Um por vez.
- Passo Estelar: ↓↙← + chute. Fraco reaparece atrás do oponente. Forte vai até a Marca Cósmica; sem marca, recua.
- R1 Marca Cósmica: planta a marca no chão por 15 s.
- Supremo Singularidade: ↓↘→↓↘→ + soco forte com barra cheia. Abre na posição do oponente (entre 150 e 460 px), puxa, esmaga 5 vezes e termina em supernova.

### Sombra e Eco

- Lutadores genéricos provisórios do M1, só com normais. Servem de saco de pancada até os outros personagens entrarem.

## Mapa dos arquivos

- `project.godot`: renderer Compatibility, 1280x720, autoloads `InputRouter` e `AudioManager`, cena principal `scenes/fight.tscn`.
- `input/button_map.gd`, `input/input_snapshot.gd`, `input/input_router.gd` (autoload): mapeamento, snapshot por frame, devices e slots.
- `audio/audio_manager.gd` (autoload): `play_sfx`, pool de players, bipes de teste.
- `core/global_tuning.gd`: constantes globais.
- `core/move_data.gd`, `core/hit_window.gd`, `core/hit_info.gd`: dados de golpe, janelas de acerto e o acerto resolvido.
- `core/character_data.gd`: dados de personagem, lista de golpes de comando ordenada por prioridade.
- `core/command_parser.gd`, `core/input_buffer.gd`: comandos de direção, buffer de botões, histórico, carga, toque duplo.
- `core/fighter.gd`: máquina de estados, física própria, caixas, defesa, dano, cancelamentos, carga, eventos.
- `core/fighter_module.gd`: base dos módulos de personagem.
- `core/entity.gd`, `core/entity_data.gd`, `core/entity_behavior.gd`: projéteis e invocações genéricos.
- `core/fight_sim.gd`: passo da luta, entidades, contatos, choques, congelamento, KO, boneco de treino, sinais para a view.
- `core/fight_camera.gd`: câmera com zoom por distância, limites, tremor e foco dramático.
- `data/data_kit.gd`: construtores de golpe, entidade, pose e animação.
- `data/roster.gd`: lista de personagens disponíveis.
- `data/characters/generic/`: dados e animações do genérico.
- `data/characters/ivad/ivad_data.gd`: todos os números do Ivad (atributos, golpes, entidades, parâmetros do módulo).
- `data/characters/ivad/ivad_anims.gd`: rig, cabelo e animações do Ivad.
- `characters/ivad/ivad_module.gd`: marca, teleporte, poço e singularidade (lógica).
- `characters/ivad/gravity_well_behavior.gd`, `characters/ivad/singularity_behavior.gd`: comportamento das entidades do Ivad.
- `view/draw_kit.gd`: primitivas em lote e texturas geradas em código.
- `view/pose_resolver.gd`, `view/fighter_view.gd`, `view/rig_layer.gd`, `view/extras/hair_chain.gd`: rig neon e extras.
- `view/entity_view.gd`, `view/entity_visuals.gd`, `view/entities/`: visuais de entidades.
- `view/effects/`: `effect_library.gd`, `burst_effect.gd`, `rift_effect.gd`.
- `view/hit_spark.gd`, `view/stage_dimmer.gd`, `view/draw_layer.gd`, `view/stage_placeholder.gd`.
- `ui/fight_hud.gd`: vida, poder, medidores de personagem, combo, faixa do supremo, flash.
- `ui/debug_overlay.gd`: caixas e frame data.
- `scenes/fight.tscn/.gd`: cena de luta; liga sim, views, entidades, efeitos, câmera, HUD e teclas de debug.
- `scenes/controller_test.tscn/.gd`: tela de teste de controles.
- `tests/sim_smoke_test.*`: teste automático da simulação.
- `tests/visual_capture.*`: capturas roteirizadas e medição de fps.

## Como adicionar um personagem

1. `data/characters/<nome>/<nome>_data.gd` com `build()`: atributos, normais, especiais, supremo, R1, entidades e parâmetros.
2. `data/characters/<nome>/<nome>_anims.gd`: `rig()` com extras e `build()` com todas as animações esperadas.
3. `characters/<nome>/<nome>_module.gd` estendendo `FighterModule` e comportamentos de entidade se precisar.
4. Visuais de entidade em `view/entities/` + registro em `EntityVisuals`; efeitos em `EffectLibrary`.
5. Entrada no `data/roster.gd`.
6. Testes no `sim_smoke_test.gd` e modo de captura no `visual_capture.gd`.

## Arquitetura planejada para os próximos marcos

- `GameFlow` (autoload): entrada → menu → seleção de personagem → seleção de mapa → luta → vitória. Pausa com Options.
- Introdução com falas (`intro_line`, `win_line`) e "LUTAR!".

## Marcos

- [x] M0 preparação: projeto, input, tela de teste de controles.
- [x] M1 base de luta: dois lutadores genéricos, movimento, 12 normais, defesa, hit, KO, câmera, HUD, F1/F2.
- [x] M2 sistema de golpes em dados, comandos, módulos, projéteis e invocações, barra de poder e Ivad completo. Medido: 60,0 fps com dois Ivads.
- [ ] M3 fluxo completo: entrada, menu, seleções, luta, vitória, pausa.
- [ ] M4 Haluho, God Slayer, Oãoj, Keitchoueitchou, Xing Zhang.
- [ ] M5 três mapas.
- [ ] M6 polimento e otimização.
