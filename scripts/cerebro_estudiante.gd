class_name CerebroEstudiante
extends RefCounted

var ancho: int = 0
var alto: int = 0
var metas: Array[Vector2i] = []
var inicio: Vector2i = Vector2i.ZERO

var mapa: Laberinto
var visitadas: Dictionary = {}


func preparar(ancho_: int, alto_: int, metas_: Array[Vector2i],
		inicio_: Vector2i = Vector2i.ZERO) -> void:
	ancho = ancho_
	alto = alto_
	metas = metas_
	inicio = inicio_
	mapa = Laberinto.vacio(ancho, alto)
	visitadas = {}


func paso(raton: Raton) -> void:
	_anotar_paredes(raton)
	visitadas[raton.celda] = true
	var distancias = _flood_fill(metas)
	var rumbo_destino = _mejor_vecina(raton.celda, raton.rumbo, distancias)
	if rumbo_destino == raton.rumbo:
		raton.avanzar()
	elif (rumbo_destino - raton.rumbo + 4) % 4 == 1:
		raton.girar_derecha()
	else:
		raton.girar_izquierda()


func _anotar_paredes(raton: Raton) -> void:
	var c := raton.celda
	var r := raton.rumbo
	if raton.pared_frente():
		mapa.poner_pared(c, r)
	if raton.pared_izquierda():
		mapa.poner_pared(c, (r + 3) % 4)
	if raton.pared_derecha():
		mapa.poner_pared(c, (r + 1) % 4)


func _flood_fill(objetivos: Array[Vector2i]) -> Array:
	var dist = []
	for _f in alto:
		var fila = []
		fila.resize(ancho)
		fila.fill(INF)
		dist.append(fila)
	var cola: Array[Vector2i] = []
	for meta in objetivos:
		dist[meta.y][meta.x] = 0
		cola.append(meta)
	var i := 0
	while i < cola.size():
		var celda: Vector2i = cola[i]
		i += 1
		for dir in 4:
			if mapa.tiene_pared(celda, dir):
				continue
			var vecina: Vector2i = celda + Laberinto.DELTAS[dir]
			if not mapa.en_rango(vecina):
				continue
			if dist[vecina.y][vecina.x] == INF:
				dist[vecina.y][vecina.x] = dist[celda.y][celda.x] + 1
				cola.append(vecina)
	return dist


func _mejor_vecina(celda: Vector2i, rumbo_actual: int, distancias: Array) -> int:
	var mejor_rumbo := rumbo_actual
	var mejor_dist := INF
	for dir in 4:
		if mapa.tiene_pared(celda, dir):
			continue
		var vecina: Vector2i = celda + Laberinto.DELTAS[dir]
		if not mapa.en_rango(vecina):
			continue
		if distancias[vecina.y][vecina.x] < mejor_dist:
			mejor_dist = distancias[vecina.y][vecina.x]
			mejor_rumbo = dir
	return mejor_rumbo
