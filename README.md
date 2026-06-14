# info_2do_parcial_micromouse

Proyecto base del segundo parcial (pista B: simulador micromouse).
Abre esta carpeta en Godot 4.6 y presiona Play. El enunciado completo está
en [enunciado.md](enunciado.md).

## Cómo correr

1. Abrir la carpeta en Godot 4.6
2. Presionar `F5` (escena principal: `scenes/game.tscn`)
3. Para usar el cerebro con flood-fill, marcar *Usar Cerebro Estudiante* en el Inspector del nodo `Game`

## Mecánicas implementadas

- **B1** Telemetría en vivo (pasos, visitadas, cronómetro, fase)
- **B2** Controles: pausa/reanudar, paso a paso, ciclo de velocidad, reiniciar
- **B3** Máquina de estados (EXPLORANDO → FIN) con pantalla final
- **B4** Efectos de sonido: paso, choque, meta
- **M1** Cerebro con flood-fill: mapa propio, sensado, exploración guiada
- **M2** Mapa dual: vista derecha con celdas visitadas/no visitadas en vivo
- **M3** Speed run: regresa al inicio y ejecuta la ruta óptima sin sensar, ambas rutas dibujadas
- **M4** Selector de laberintos data-driven y récord por laberinto persistido en `user://`

## Recursos externos

- [Computerphile — Micromouse & Flood Fill](https://www.youtube.com/watch?v=ZMQbHMgK2rw)
