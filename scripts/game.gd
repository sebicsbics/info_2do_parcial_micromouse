extends Node2D

# Controlador principal: carga el laberinto, coloca al ratón y hace avanzar
# el cerebro un paso por tick del paso_timer. El núcleo (laberinto, sensado,
# movimiento, vista de dios) ya está resuelto; los huecos del parcial están
# marcados con "TODO (PARCIAL · ...)".

# Laberintos incluidos: 01_entrenamiento (8x8, perfecto: el wall-follower lo
# resuelve), 02_clasico y 03_clasico (16x16 con ciclos y meta central, estilo
# competencia: el wall-follower NO basta).
@export_file("*.maz") var archivo_laberinto: String = "res://mazes/01_entrenamiento.maz"
# Marca esta casilla (en el Inspector del nodo Game) para usar tu cerebro.
@export var usar_cerebro_estudiante: bool = false

const ORIGEN := Vector2(28, 44)
# La vista de dios dispone de ~608 px; la celda se adapta al tamaño del
# laberinto (38 px en los 16x16, más grande en los de entrenamiento).
var tam_celda := 38.0

var laberinto: Laberinto
var cerebro = null

@onready var vista_dios: VistaLaberinto = $vista_dios
@onready var vista_mapa_raton: VistaLaberinto = $vista_mapa_raton
@onready var raton: Raton = $raton
@onready var paso_timer: Timer = $paso_timer

# === ESTADO DE LA CORRIDA ===
signal pasos_cambiados(pasos: int)
signal visitadas_cambiadas(cantidad: int)
signal fase_cambiada(nombre: String)
signal tiempo_cambiado(segundos: float)

var _pasos: int = 0
var _visitadas: int = 0
var _tiempo: float = 0.0
var _celdas_visitadas: Dictionary = {}


func _ready() -> void:
	laberinto = Laberinto.desde_archivo(archivo_laberinto)
	tam_celda = minf(56.0, 608.0 / maxf(laberinto.ancho, laberinto.alto))
	vista_dios.configurar(laberinto, ORIGEN, tam_celda)
	raton.configurar(laberinto, ORIGEN, tam_celda)
	if usar_cerebro_estudiante:
		cerebro = CerebroEstudiante.new()
		cerebro.preparar(laberinto.ancho, laberinto.alto, laberinto.metas,
				laberinto.inicio)
	else:
		cerebro = CerebroWallFollower.new()
	_celdas_visitadas[raton.celda] = true
	fase_cambiada.emit("EXPLORANDO")
	# TODO (PARCIAL · M2): configura vista_mapa_raton con el laberinto que TU
	# cerebro descubre (Laberinto.vacio + poner_pared al sensar) y redibuja
	# cada vez que aprenda una pared. Distingue visitadas / no visitadas.


func _process(delta: float) -> void:
	if not paso_timer.is_stopped():
		_tiempo += delta
		tiempo_cambiado.emit(_tiempo)


func _on_paso_timer_timeout() -> void:
	if raton.ocupado():
		return
	cerebro.paso(raton)
	_pasos = raton.pasos
	pasos_cambiados.emit(_pasos)
	if not _celdas_visitadas.has(raton.celda):
		_celdas_visitadas[raton.celda] = true
		_visitadas = _celdas_visitadas.size()
		visitadas_cambiadas.emit(_visitadas)
	if laberinto.es_meta(raton.celda):
		_meta_alcanzada()


func _meta_alcanzada() -> void:
	paso_timer.stop()
	print("¡Meta alcanzada en ", raton.pasos, " pasos!")
	# TODO (PARCIAL · B3): esto debe ser una máquina de estados explícita
	# (EXPLORANDO → META → VOLVIENDO → SPEED_RUN → FIN), con pantalla final
	# (pasos de exploración vs. pasos del speed run) y opción de reiniciar.
	# TODO (PARCIAL · B4): sonido de meta (assets/sounds/meta.wav). Conecta
	# también raton.choque a un sonido de choque y cada avance a un tic.
	# TODO (PARCIAL · M3): aquí continúa el ciclo: volver al inicio y ejecutar
	# el speed run sobre el mapa descubierto, dibujando ambas rutas.
	# TODO (PARCIAL · M4): guarda el récord (mejores pasos) de ESTE laberinto
	# en user:// y muéstralo; añade un selector para cambiar de laberinto sin
	# tocar código.


# --- Botones del panel (ya conectados en el editor; cuerpos por hacer) ---

func _on_boton_pausa_pressed() -> void:
	if paso_timer.is_stopped():
		paso_timer.start()
		$ui/hud/margen/columna/botones/boton_pausa.text = "Pausa"
	else:
		paso_timer.stop()
		$ui/hud/margen/columna/botones/boton_pausa.text = "Reanudar"


func _on_boton_paso_pressed() -> void:
	if paso_timer.is_stopped():
		_on_paso_timer_timeout()


func _on_boton_velocidad_pressed() -> void:
	var velocidades := [0.12, 0.06, 0.03]
	var etiquetas := ["Vel x1", "Vel x2", "Vel x4"]
	var idx := velocidades.find(paso_timer.wait_time)
	idx = (idx + 1) % velocidades.size()
	paso_timer.wait_time = velocidades[idx]
	raton.duracion_paso = velocidades[idx] * 0.8
	$ui/hud/margen/columna/botones/boton_velocidad.text = etiquetas[idx]


func _on_boton_reiniciar_pressed() -> void:
	paso_timer.stop()
	raton.configurar(laberinto, ORIGEN, tam_celda)
	if usar_cerebro_estudiante:
		cerebro = CerebroEstudiante.new()
		cerebro.preparar(laberinto.ancho, laberinto.alto, laberinto.metas, laberinto.inicio)
	else:
		cerebro = CerebroWallFollower.new()
	_pasos = 0
	_visitadas = 0
	_tiempo = 0.0
	_celdas_visitadas = {raton.celda: true}
	pasos_cambiados.emit(0)
	visitadas_cambiadas.emit(1)
	tiempo_cambiado.emit(0.0)
	fase_cambiada.emit("EXPLORANDO")
	$ui/hud/margen/columna/botones/boton_pausa.text = "Pausa"
	paso_timer.start()
