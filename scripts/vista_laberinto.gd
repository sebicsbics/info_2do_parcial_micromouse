class_name VistaLaberinto
extends Node2D

# Dibuja un Laberinto con _draw(): rejilla tenue, paredes, inicio y metas.
#
# La "vista de dios" (el laberinto real completo) ya viene configurada desde
# game.gd. Para la mecánica M2 puedes reutilizar esta misma clase sobre el
# nodo "vista_mapa_raton": mantén un Laberinto.vacio() con las paredes que tu
# cerebro va descubriendo, llama configurar() una vez y queue_redraw() cada
# vez que aprendas algo. Lo que esta vista NO hace (y te toca a ti) es
# distinguir celdas visitadas / no visitadas — puedes extender esta clase o
# dibujar encima desde otro nodo.

var laberinto: Laberinto = null
var origen := Vector2.ZERO
var tam := 32.0
var visitadas: Dictionary = {}

@export var color_paredes := Color(0.92, 0.92, 0.95)
@export var color_rejilla := Color(0.22, 0.22, 0.28)
@export var color_meta := Color(0.25, 0.65, 0.30, 0.45)
@export var color_inicio := Color(0.25, 0.45, 0.85, 0.45)
@export var color_visitada := Color(0.35, 0.35, 0.45, 0.6)
@export var color_no_visitada := Color(0.15, 0.15, 0.20, 0.6)
@export var grosor_pared := 3.0


func configurar(laberinto_: Laberinto, origen_: Vector2, tam_: float) -> void:
	laberinto = laberinto_
	origen = origen_
	tam = tam_
	queue_redraw()


func celda_a_pixel(celda: Vector2i) -> Vector2:
	# centro de la celda en píxeles
	return origen + (Vector2(celda) + Vector2(0.5, 0.5)) * tam


func _draw() -> void:
	if laberinto == null:
		return
	if not visitadas.is_empty():
		for fila in laberinto.alto:
			for col in laberinto.ancho:
				var celda := Vector2i(col, fila)
				var color := color_visitada if visitadas.has(celda) else color_no_visitada
				draw_rect(Rect2(origen + Vector2(celda) * tam, Vector2(tam, tam)), color)
	# rejilla tenue de fondo
	for col in laberinto.ancho + 1:
		draw_line(origen + Vector2(col * tam, 0),
				origen + Vector2(col * tam, laberinto.alto * tam), color_rejilla, 1.0)
	for fila in laberinto.alto + 1:
		draw_line(origen + Vector2(0, fila * tam),
				origen + Vector2(laberinto.ancho * tam, fila * tam), color_rejilla, 1.0)
	# inicio y metas
	var rect_inicio = Rect2(origen + Vector2(laberinto.inicio) * tam, Vector2(tam, tam))
	draw_rect(rect_inicio, color_inicio)
	for meta in laberinto.metas:
		draw_rect(Rect2(origen + Vector2(meta) * tam, Vector2(tam, tam)), color_meta)
	# paredes
	for fila in laberinto.alto:
		for col in laberinto.ancho:
			var celda = Vector2i(col, fila)
			var esquina = origen + Vector2(celda) * tam
			if laberinto.tiene_pared(celda, Laberinto.NORTE):
				draw_line(esquina, esquina + Vector2(tam, 0), color_paredes, grosor_pared)
			if laberinto.tiene_pared(celda, Laberinto.OESTE):
				draw_line(esquina, esquina + Vector2(0, tam), color_paredes, grosor_pared)
			# bordes sur y este solo en la última fila / columna
			if fila == laberinto.alto - 1 and laberinto.tiene_pared(celda, Laberinto.SUR):
				draw_line(esquina + Vector2(0, tam), esquina + Vector2(tam, tam),
						color_paredes, grosor_pared)
			if col == laberinto.ancho - 1 and laberinto.tiene_pared(celda, Laberinto.ESTE):
				draw_line(esquina + Vector2(tam, 0), esquina + Vector2(tam, tam),
						color_paredes, grosor_pared)
