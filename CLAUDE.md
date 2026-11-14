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
"$G" --path . res://tests/visual_capture.tscn -- "<pasta>" poses              # salva PNGs de poses para inspeção visual
"$G" --path . res://tests/visual_capture.tscn -- "<pasta>" ko                 # salva PNGs do KO
"$G" --path . res://tests/visual_capture.tscn -- "<pasta>" perf               # mede fps com dois lutadores trocando golpes
"$G" --path .                                                                 # roda normal para o usuário testar
"$G" --path . res://scenes/controller_test.tscn                               # tela de teste de controles
```

Antes de entregar: import, smoke test, captura visual (ler os PNGs) e perf. Nunca dizer que funciona sem ter rodado.

## Regras do projeto

- Nenhum comentário no código: nem de linha, nem de bloco, nem docstring. Nomes claros no lugar.
- Código e identificadores em inglês. Todo texto exibido ao jogador em português.
- Orientado a dados: golpes, frames, personagens e balanceamento em scripts de dados (`data/`). Todos os números de ajuste de um personagem ficam em um único arquivo; constantes globais em `core/global_tuning.gd`.
- Lógica separada da aparência: `Fighter` e `FightSim` não conhecem a view. A view só lê `anim_name`, `anim_frame`, posição e estado.
- Sem RigidBody nem física do motor na luta. Simulação determinística em frames inteiros com retângulos próprios.
- Habilidades únicas são módulos que estendem o lutador base por composição. Nada de `if` por personagem no núcleo.
- Desempenho: sem shaders de glow pesados, sem Light2D em quantidade, partículas controladas. Brilho = halo aditivo em duas camadas + contorno opaco. CPUParticles2D com teto.
- Áudio: `AudioManager.play_sfx(nome)` já posicionado nos eventos; não faz nada se não existe `audio/sfx/<nome>.wav|ogg`. Bipes de teste atrás de `AudioManager.test_beeps_enabled`.
- Git: commit ao fim de cada marco e antes de refatorações grandes, mensagem curta em português. Sem push sem pedido.
- Debug: F1 hitboxes, hurtboxes, estados e frame data. F2 boneco de treino no P2. F3 modo do boneco (parado, defende em pé, defende agachado, agachado). F4 reinicia o round. F11 tela cheia.
- Entregas por marcos jogáveis; parar ao fim de cada um para o usuário testar. Falar em português, curto e direto.

## Convenções da simulação

- `Fighter.state_frame` começa em 0 ao entrar no estado e soma 1 ao fim de cada passo. Depois do passo em que o botão foi lido vale 1.
- Golpe com `startup` N fica ativo nos frames N+1 até N+active (o frame do botão conta como 1). Total preso = startup + active + recovery.
- Golpes aéreos não têm recovery: duram até pousar e geram `ATTACK_LANDING_FRAMES` de pouso.
- Retângulos de golpe ficam no espaço do personagem virado para a direita, origem nos pés, y negativo para cima. `Fighter.to_world` espelha.
- Defesa: segurar para trás. Em pé segura HIGH e MID; agachado segura LOW e MID. Golpes aéreos são HIGH, chutes agachados são LOW.
- Combo: escala de dano e queda de hitstun por `defender.combo_hits` (tabelas em `GlobalTuning`). Limite de juggle em `MAX_JUGGLE_HITS`.
- No canto, o knockback que o defensor não pode receber volta para o atacante.
- `FightSim.snapshot_overrides[slot]` substitui a entrada do jogador (testes, futura IA).

## Convenções do rig

- Ângulos absolutos em graus: 0 aponta para baixo, 90 para frente, 180 para cima, negativo para trás. `PoseResolver.direction`.
- Chaves de pose: `spine, neck, arm_n, fore_n, arm_f, fore_f, thigh_n, shin_n, thigh_f, shin_f, lean_x, hip_y`. Sufixo `n` é o lado perto da câmera, `f` o lado longe.
- `hip_y` -1 calcula a altura do quadril para os pés tocarem o chão. No ar usar valor explícito.
- Animação: `{"loop": bool, "keys": [{"t": frame, "pose": {...}}]}`. O `t` segue o `state_frame` do estado, então a pose de impacto fica em `startup + 1`.
- Nomes de animação esperados pelo núcleo: `idle, walk_forward, walk_back, crouch, prejump, jump, landing, dash, backdash, block_stand, block_crouch, hit_stand, hit_crouch, hit_air, knockdown, getup, ko` e o `id` de cada golpe.

## Entrada

- Cada jogador lê só o próprio device id. Nunca assumir ordem de conexão.
- Mapeamento de botões e teclas de debug em um único arquivo: `input/button_map.gd`.
- Teclado lido por tecla física (`Input.is_physical_key_pressed`), não pelo Input Map do projeto.
- Pseudo-devices: `-2` teclado WASD, `-3` teclado Setas, `-1` nenhum.
- Steam Input pode duplicar controles: `poll_join_press` ignora um segundo device que repita o mesmo estado dentro de 10 frames.
- Controle PS5: □ soco fraco, △ soco forte, X chute fraco, ○ chute forte, R1 habilidade, Options pausa.
- Teclado P1: WASD, J U K I, L habilidade, Esc pausa. Teclado P2: setas, Numpad 1 4 2 5, Numpad 3 habilidade, Esc pausa.
- `InputBuffer` (por lutador): buffer de 6 frames por botão, toque duplo em 12 frames para dash.

## Mapa dos arquivos

- `project.godot`: renderer Compatibility, 1280x720, autoloads `InputRouter` e `AudioManager`, cena principal `scenes/fight.tscn`.
- `input/button_map.gd`: enum `Action`, mapas de joypad e teclado, teclas de debug.
- `input/input_snapshot.gd`: direção digital e bitmask de ações de um frame.
- `input/input_router.gd` (autoload): devices, leitura por device/slot, atribuição P1/P2, "aperte um botão" com dedupe.
- `audio/audio_manager.gd` (autoload): `play_sfx`, pool de players, bipes de teste.
- `core/global_tuning.gd`: constantes globais (palco, buffers, knockdown, escala de combo, barra de poder, tremor).
- `core/move_data.gd`: dados de um golpe (frames, dano, stun, altura, knockback, hitboxes, cancelamentos).
- `core/character_data.gd`: dados de um personagem (vida, movimento, caixas, golpes, rig, animações).
- `core/input_buffer.gd`: buffer de botões, direções relativas ao lado, toque duplo.
- `core/fighter.gd`: máquina de estados do lutador, física própria, caixas, defesa, dano.
- `core/fight_sim.gd`: passo da luta, pushbox, troca de lado, contatos, escala de combo, KO, boneco de treino.
- `core/fight_camera.gd`: câmera que segue os dois, zoom pela distância, limites do palco, tremor.
- `data/characters/generic/generic_data.gd`: números e 12 golpes normais do lutador genérico.
- `data/characters/generic/generic_anims.gd`: proporções do rig e poses/animações do genérico.
- `view/pose_resolver.gd`: interpola keyframes de pose.
- `view/fighter_view.gd` + `view/rig_layer.gd`: desenha o rig neon (halo aditivo + contorno + corpo escuro).
- `view/hit_spark.gd`: faísca de impacto e de defesa.
- `view/stage_placeholder.gd`: palco provisório (será trocado no M5).
- `ui/fight_hud.gd`: barras de vida e poder, nomes, contador de combo, texto central.
- `ui/debug_overlay.gd`: caixas e frame data (F1).
- `scenes/fight.tscn/.gd`: cena de luta; liga sim, views, câmera, HUD, debug, teclas de debug.
- `scenes/controller_test.tscn/.gd`: tela de teste de controles do M0.
- `tests/sim_smoke_test.*`: teste automático da simulação com entradas roteirizadas.
- `tests/visual_capture.*`: capturas de tela roteirizadas e medição de fps.

## Arquitetura planejada para os próximos marcos

- `FighterModule`: nós/objetos com ganchos (`on_frame`, `on_hit_dealt`, `on_damage_taken`, `modify_move`) para habilidades únicas.
- `Projectile` e `Summon` genéricos com dono, vida, hitbox e regras de colisão; `EntityManager` por luta.
- `CommandParser`: quarto de círculo, meio círculo, ascendente, carga; tolerância de 10 frames.
- `GameFlow` (autoload): entrada → menu → seleção de personagem → seleção de mapa → luta → vitória.

## Marcos

- [x] M0 preparação: projeto, input, tela de teste de controles.
- [x] M1 base de luta: dois lutadores genéricos, movimento, 12 normais, defesa, hit, KO, câmera, HUD, F1/F2. Medido: 59,8 fps de média na máquina alvo.
- [ ] M2 dados e Ivad completo, barra de poder, projéteis e invocações.
- [ ] M3 fluxo completo: entrada, menu, seleções, luta, vitória, pausa.
- [ ] M4 Haluho, God Slayer, Oãoj, Keitchoueitchou, Xing Zhang.
- [ ] M5 três mapas.
- [ ] M6 polimento e otimização.
