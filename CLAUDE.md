# Ivad Fighting

Jogo de luta 2D local para 2 jogadores, estilo Street Fighter, em Godot 4.7.2 (GDScript, renderer Compatibility). Todo visual gerado por código, sem assets externos. O usuário dirige, joga e testa; o código inteiro é escrito pela IA.

## Ambiente

- Godot: `"C:\Users\dtmal\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe"` (a pasta tem `.exe` no nome; sempre citar o caminho completo entre aspas).
- Console (imprime no terminal): `"C:\Users\dtmal\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"`.
- Projeto: `C:\Users\dtmal\Downloads\Ivad_Fighting`.
- Máquina alvo: HP 15-dy1xxx, i5-1035G1, 8 GB, Intel UHD integrada, tela 1366x768. Meta: 60 fps estáveis.
- Resolução base 1280x720, stretch `canvas_items` com aspecto `keep`, passo físico 60 Hz, vsync ligado.

## Comandos

Rodar no shell Git Bash a partir da pasta do projeto. `G` é o executável de console.

```
G="C:/Users/dtmal/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
"$G" --headless --path . --import                 # importa e reporta erros de parse de todos os scripts
"$G" --headless --path . --quit-after 120         # roda a cena principal 120 frames sem janela (erros de runtime)
"$G" --path . --quit-after 90                     # roda com janela (valida o renderer)
"$G" --path .                                     # roda normal para o usuário testar
"$G" --path . res://scenes/<cena>.tscn            # roda uma cena específica
```

Sempre rodar import e quit-after antes de entregar. Nunca dizer que funciona sem ter rodado.

## Regras do projeto

- Nenhum comentário no código: nem de linha, nem de bloco, nem docstring. Nomes claros no lugar.
- Código e identificadores em inglês. Todo texto exibido ao jogador em português.
- Orientado a dados: golpes, frames, personagens e balanceamento em Resources `.tres` ou scripts de dados. Todos os números de ajuste de um personagem ficam em um único lugar; constantes globais em um arquivo só.
- Lógica separada da aparência: estado, hitbox e dano não dependem de como se desenha.
- Sem RigidBody nem física do motor na luta. Simulação determinística em frames inteiros com retângulos próprios.
- Habilidades únicas são módulos que estendem o lutador base por composição. Nada de `if` por personagem no núcleo.
- Desempenho: sem shaders de glow pesados, sem Light2D em quantidade, partículas controladas. Brilho = contorno em duas camadas aditivas (Line2D/Polygon2D). CPUParticles2D com teto.
- Áudio: `AudioManager.play_sfx(nome)` já posicionado nos eventos; não faz nada se o arquivo não existe. Bipes gerados por código atrás de flag.
- Git: commit ao fim de cada marco e antes de refatorações grandes, mensagem curta em português. Sem push sem pedido.
- Debug: F1 mostra hitboxes, hurtboxes, estados e frame data. F2 liga boneco de treino no P2. F11 alterna tela cheia.
- Entregas por marcos jogáveis; parar ao fim de cada um para o usuário testar. Falar em português, curto e direto.

## Entrada

- Cada jogador lê só o próprio device id. Nunca assumir ordem de conexão.
- Mapeamento de botões em um único arquivo: `input/button_map.gd` (joypad, teclado P1, teclado P2, zona morta, preferência por direcional digital).
- Teclado é lido por tecla física (`Input.is_physical_key_pressed`), não pelo Input Map do projeto, para manter tudo em um arquivo.
- Pseudo-devices: `-2` teclado WASD, `-3` teclado Setas, `-1` nenhum.
- Steam Input pode duplicar controles: `poll_join_press` ignora um segundo device que repita o mesmo estado dentro de 10 frames do primeiro.
- Controle PS5: □ soco fraco, △ soco forte, X chute fraco, ○ chute forte, R1 habilidade, Options pausa.
- Teclado P1: WASD, J U K I, L habilidade, Esc pausa. Teclado P2: setas, Numpad 1 4 2 5, Numpad 3 habilidade, Esc pausa.

## Arquitetura (plano)

- `FightSim`: avança a luta em frames inteiros dentro de `_physics_process`. Entrada congelada em `InputSnapshot` por jogador no início do frame.
- `Fighter`: máquina de estados genérica + `CharacterData` (.tres) + lista de `MoveData` + poses. `FighterModule` filhos com ganchos (`on_frame`, `on_hit_dealt`, `on_damage_taken`, `modify_move`).
- `FighterView`: lê estado e pose do `Fighter` e desenha o rig procedural (Polygon2D + Line2D em duas camadas aditivas).
- `Projectile` e `Summon` genéricos com dono, vida, hitbox e regras de colisão. `EntityManager` por luta.
- `CommandParser`: histórico de direções por jogador; quarto de círculo, meio círculo, ascendente, carga. Buffer 6 frames, tolerância 10 frames.
- `GlobalTuning`: gravidade, hitstop, escala de combo, tamanho do palco. Mapas só mudam o visual.
- `GameFlow` (autoload): entrada → menu → seleção de personagem → seleção de mapa → luta → vitória.

## Estrutura de pastas

```
project.godot
CLAUDE.md
core/        sim, fighter, state machine, hit detection, camera, entities, command parser
data/        global_tuning.tres, characters/<nome>/ (character.tres, moves, poses)
characters/  um módulo por lutador (habilidade única e mecânicas próprias)
view/        rig procedural, efeitos, trail, partículas
input/       input router, button map, snapshot
ui/          hud, menus, seleção, vitória, pausa, debug overlay
stages/      3 mapas procedurais com parallax
audio/       audio manager
scenes/      cenas principais (entrada, menu, selects, fight, victory, controller_test)
```

## Mapa dos arquivos atuais

- `project.godot`: renderer Compatibility, 1280x720, autoload `InputRouter`, cena principal `scenes/controller_test.tscn`.
- `input/button_map.gd`: enum `Action` e todos os mapeamentos de botão e tecla.
- `input/input_snapshot.gd`: direção digital (`dir_x`, `dir_y`) e bitmask de ações de um frame.
- `input/input_router.gd` (autoload `InputRouter`): enumera devices, lê snapshot por device/slot, atribui P1/P2, detecta "aperte um botão" com dedupe.
- `scenes/controller_test.tscn/.gd`: tela de teste que mostra cada controle por device id, leitura mapeada, eixos, botões brutos e últimos eventos. F5 libera P1/P2.

## Marcos

- [x] M0 preparação: projeto, input, tela de teste de controles.
- [ ] M1 base de luta: dois lutadores genéricos, movimento, normais, hit, KO, câmera, F1/F2.
- [ ] M2 dados e Ivad completo, barra de poder, projéteis e invocações.
- [ ] M3 fluxo completo: entrada, menu, seleções, luta, vitória, pausa.
- [ ] M4 Haluho, God Slayer, Oãoj, Keitchoueitchou, Xing Zhang.
- [ ] M5 três mapas.
- [ ] M6 polimento e otimização.
