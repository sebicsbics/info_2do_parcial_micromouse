extends Node2D

@export_file("*.maz") var archivo_laberinto: String = "res://mazes/01_entrenamiento.maz"
@export var usar_cerebro_estudiante: bool = false

const ORIGEN := Vector2(28, 44)
var tam_celda := 38.0

enum Fase { EXPLORANDO, FIN }

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

var _fase: Fase = Fase.EXPLORANDO
var _pasos: int = 0
var _visitadas: int = 0
var _tiempo: float = 0.0
var _celdas_visitadas: Dictionary = {}
var _pantalla_final: CanvasLayer = null
var _pasos_exploracion: int = 0
var _cerebro_fase_anterior = null

var _sfx_paso: AudioStreamPlayer
var _sfx_choque: AudioStreamPlayer
var _sfx_meta: AudioStreamPlayer


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
	_sfx_paso = _crear_sfx("res://assets/sounds/paso.wav")
	_sfx_choque = _crear_sfx("res://assets/sounds/choque.wav")
	_sfx_meta = _crear_sfx("res://assets/sounds/meta.wav")
	raton.paso_terminado.connect(func(): _sfx_paso.play())
	raton.choque.connect(func(): _sfx_choque.play())
	if usar_cerebro_estudiante:
		var ce := cerebro as CerebroEstudiante
		vista_mapa_raton.configurar(ce.mapa, ORIGEN, tam_celda)


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
	if usar_cerebro_estudiante:
		var ce := cerebro as CerebroEstudiante
		vista_mapa_raton.visitadas = ce.visitadas
		vista_mapa_raton.queue_redraw()
		if ce.fase != _cerebro_fase_anterior:
			_cerebro_fase_anterior = ce.fase
			match ce.fase:
				CerebroEstudiante.Fase.VOLVIENDO:
					_pasos_exploracion = _pasos
					fase_cambiada.emit("VOLVIENDO")
				CerebroEstudiante.Fase.SPEED_RUN:
					vista_dios.ruta_a = ce.ruta_exploracion
					vista_dios.ruta_b = ce.ruta_speed_run
					vista_dios.queue_redraw()
					fase_cambiada.emit("SPEED RUN")
				CerebroEstudiante.Fase.LISTO:
					_meta_alcanzada()
	elif laberinto.es_meta(raton.celda):
		_meta_alcanzada()


func _crear_sfx(ruta: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = load(ruta)
	add_child(player)
	return player


func _meta_alcanzada() -> void:
	_fase = Fase.FIN
	paso_timer.stop()
	fase_cambiada.emit("FIN")
	_sfx_meta.play()
	_mostrar_pantalla_final()


func _mostrar_pantalla_final() -> void:
	_pantalla_final = CanvasLayer.new()
	add_child(_pantalla_final)

	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.7)
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pantalla_final.add_child(fondo)

	var caja := VBoxContainer.new()
	caja.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	caja.alignment = BoxContainer.ALIGNMENT_CENTER
	_pantalla_final.add_child(caja)

	var titulo := Label.new()
	titulo.text = "¡Meta alcanzada!"
	caja.add_child(titulo)

	var pasos_lbl := Label.new()
	pasos_lbl.text = "Pasos de exploración: %d" % _pasos_exploracion
	caja.add_child(pasos_lbl)

	if usar_cerebro_estudiante:
		var ce := cerebro as CerebroEstudiante
		var pasos_sr := Label.new()
		pasos_sr.text = "Pasos de speed run: %d" % ce.ruta_speed_run.size()
		caja.add_child(pasos_sr)

	var tiempo_lbl := Label.new()
	tiempo_lbl.text = "Tiempo: %.1f s" % _tiempo
	caja.add_child(tiempo_lbl)

	var btn := Button.new()
	btn.text = "Reiniciar"
	btn.pressed.connect(_on_boton_reiniciar_pressed)
	caja.add_child(btn)


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
	if _pantalla_final:
		_pantalla_final.queue_free()
		_pantalla_final = null
	paso_timer.stop()
	raton.configurar(laberinto, ORIGEN, tam_celda)
	if usar_cerebro_estudiante:
		cerebro = CerebroEstudiante.new()
		cerebro.preparar(laberinto.ancho, laberinto.alto, laberinto.metas, laberinto.inicio)
	else:
		cerebro = CerebroWallFollower.new()
	_fase = Fase.EXPLORANDO
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
