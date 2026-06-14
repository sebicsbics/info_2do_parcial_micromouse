extends PanelContainer

@onready var fase_label: Label = $margen/columna/fase_label
@onready var pasos_label: Label = $margen/columna/pasos_label
@onready var visitadas_label: Label = $margen/columna/visitadas_label
@onready var tiempo_label: Label = $margen/columna/tiempo_label
@onready var record_label: Label = $margen/columna/record_label


func _ready() -> void:
	var game: Node2D = get_parent().get_parent()
	game.pasos_cambiados.connect(update_pasos)
	game.visitadas_cambiadas.connect(update_visitadas)
	game.fase_cambiada.connect(update_fase)
	game.tiempo_cambiado.connect(update_tiempo)


func update_fase(nombre: String) -> void:
	fase_label.text = "fase: " + nombre


func update_pasos(pasos: int) -> void:
	pasos_label.text = "pasos: " + str(pasos)


func update_visitadas(cantidad: int) -> void:
	visitadas_label.text = "visitadas: " + str(cantidad)


func update_tiempo(segundos: float) -> void:
	tiempo_label.text = "tiempo: %.1f s" % segundos


func update_record(pasos: int) -> void:
	# TODO (PARCIAL · M4): mejor marca guardada para el laberinto actual.
	record_label.text = "récord: " + str(pasos)
