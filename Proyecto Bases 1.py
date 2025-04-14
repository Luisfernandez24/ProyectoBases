import psycopg2
from psycopg2.extras import RealDictCursor
import random
import logging
import pygame
import sys

# Configuración de logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Configuración de conexión
DB_CONFIG = {
    "dbname": "kiran_game",
    "user": "kiran_app",
    "password": "kiran2025",
    "host": "localhost",
    "port": "5433"
}

try:
    conn = psycopg2.connect(**DB_CONFIG)
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    cursor.execute("SELECT * FROM ciudades")  # Prueba: lee una tabla
    ciudades = cursor.fetchall()

    print("✅ Conectado a PostgreSQL. Ciudades encontradas:")
    for ciudad in ciudades:
        print(ciudad)

    cursor.close()
    conn.close()
except Exception as e:
    print("❌ Error al conectar:", e)

# Backend: KiranGame
class KiranGame:
    def _init_(self):
        try:
            self.conn = psycopg2.connect(**DB_CONFIG)
            self.cursor = self.conn.cursor(cursor_factory=RealDictCursor)
            logger.info("Conexión a la base de datos establecida.")
        except psycopg2.Error as e:
            logger.error(f"Error al conectar a la base de datos: {e}")
            raise

    def _del_(self):
        self.cursor.close()
        self.conn.close()
        logger.info("Conexión a la base de datos cerrada.")

    def _transaccion(func):
        def wrapper(self, *args, **kwargs):
            try:
                result = func(self, *args, **kwargs)
                self.conn.commit()
                return result
            except (psycopg2.Error, ValueError) as e:
                self.conn.rollback()
                logger.error(f"Error en {func._name_}: {e}")
                return None
        return wrapper

    def _get_ciudad_actual(self, id_jugador):
        try:
            self.cursor.execute("SELECT ciudad_actual FROM jugadores WHERE id_jugador = %s", (id_jugador,))
            return self.cursor.fetchone()['ciudad_actual']
        except psycopg2.Error as e:
            logger.error(f"Error al obtener ciudad actual: {e}")
            return None

    def _validar_ciudad(self, ciudad):
        try:
            self.cursor.execute("SELECT nombre FROM ciudades WHERE nombre = %s", (ciudad,))
            if not self.cursor.fetchone():
                raise ValueError(f"Ciudad {ciudad} no existe")
            return True
        except psycopg2.Error as e:
            logger.error(f"Error al validar ciudad: {e}")
            return False

    def _validar_cantidad_positiva(self, cantidad, nombre="cantidad"):
        if cantidad <= 0:
            raise ValueError(f"La {nombre} debe ser positiva")

    def _log_bitacora(self, id_jugador, accion, responsable):
        try:
            self.cursor.execute("""
                INSERT INTO bitacora (fecha_hora, accion, responsable, id_partida) 
                VALUES (NOW(), %s, %s, (SELECT id_partida FROM partidas WHERE id_jugador = %s AND estado = 'En curso'))
            """, (accion, responsable, id_jugador))
            return True
        except psycopg2.Error as e:
            logger.error(f"Error al registrar en bitácora: {e}")
            return False

    @_transaccion
    def iniciar_partida(self, id_jugador, ciudad_inicial):
        if not self._validar_ciudad(ciudad_inicial):
            raise ValueError(f"Ciudad {ciudad_inicial} no existe")
        self.cursor.execute("""
            INSERT INTO partidas (id_jugador, fecha_inicio, estado) 
            VALUES (%s, NOW(), 'En curso')
        """, (id_jugador,))
        self.cursor.execute("""
            UPDATE jugadores SET ciudad_actual = %s WHERE id_jugador = %s
        """, (ciudad_inicial, id_jugador))
        self.cursor.execute("""
            INSERT INTO inventarios (id_jugador, producto, cantidad, camellos, vasijas) 
            VALUES (%s, 'Seda', 5, 25, 50)
        """, (id_jugador,))
        self.cursor.execute("""
            INSERT INTO personajes (nombre, id_jugador, ciudad_ubicacion) 
            VALUES ('Kiran', %s, %s)
        """, (id_jugador, ciudad_inicial))
        self.cursor.execute("""
            INSERT INTO personaje_habilidades (id_personaje, habilidad)
            SELECT id_personaje, 'Comercio' FROM personajes WHERE id_jugador = %s AND nombre = 'Kiran'
        """, (id_jugador,))
        self._log_bitacora(id_jugador, f"Inicio de partida en {ciudad_inicial}", "Sistema")
        logger.info(f"Partida iniciada para jugador {id_jugador} en {ciudad_inicial}")
        return True

    @_transaccion
    def iniciar_viaje(self, id_jugador, id_ruta, tamano_caravana, tipo_transporte):
        if tipo_transporte not in ['tierra', 'mar']:
            raise ValueError("Tipo de transporte debe ser 'tierra' o 'mar'")
        self._validar_cantidad_positiva(tamano_caravana, "tamaño de caravana")
        self.cursor.execute("""
            SELECT origen FROM rutas WHERE id_ruta = %s AND (distancia_%s IS NOT NULL)
        """, (id_ruta, tipo_transporte))
        ruta = self.cursor.fetchone()
        if not ruta:
            raise ValueError(f"Ruta {id_ruta} no existe o no soporta {tipo_transporte}")
        ciudad_actual = self._get_ciudad_actual(id_jugador)
        if ciudad_actual != ruta['origen']:
            raise ValueError(f"Debes estar en {ruta['origen']} para iniciar esta ruta")

        self.cursor.execute("""
            SELECT * FROM calcular_recursos_viaje(%s, %s, %s)
        """, (id_ruta, tamano_caravana, tipo_transporte))
        recursos = self.cursor.fetchall()
        self.cursor.execute("""
            SELECT monedas_oro FROM jugadores WHERE id_jugador = %s
        """, (id_jugador,))
        monedas = self.cursor.fetchone()['monedas_oro']
        costo_total = sum(r['cantidad'] for r in recursos) * 10
        if monedas < costo_total:
            raise ValueError("No tienes suficientes monedas para este viaje")

        self.cursor.execute("""
            SELECT camellos, vasijas FROM inventarios WHERE id_jugador = %s AND producto = 'Seda'
        """, (id_jugador,))
        inventario = self.cursor.fetchone()
        if not inventario or inventario['camellos'] < 25 or inventario['vasijas'] < 50:
            raise ValueError("No hay suficientes camellos o vasijas")

        self.cursor.execute("""
            INSERT INTO caravanas (id_jugador, tamano, estado, ruta_actual) 
            VALUES (%s, %s, 'En viaje', %s) RETURNING id_caravana
        """, (id_jugador, tamano_caravana, id_ruta))
        id_caravana = self.cursor.fetchone()['id_caravana']

        for recurso in recursos:
            self.cursor.execute("""
                INSERT INTO caravana_recursos (id_caravana, recurso, cantidad) 
                VALUES (%s, %s, %s)
            """, (id_caravana, recurso['recurso'], recurso['cantidad']))

        self.cursor.execute("""
            UPDATE inventarios SET camellos = camellos - 25, vasijas = vasijas - 50 
            WHERE id_jugador = %s AND producto = 'Seda'
        """, (id_jugador,))
        self.cursor.execute("""
            UPDATE jugadores SET monedas_oro = monedas_oro - %s WHERE id_jugador = %s
        """, (costo_total, id_jugador))
        self._log_bitacora(id_jugador, f"Viaje iniciado en ruta {id_ruta}", "Jugador")
        logger.info(f"Viaje iniciado: caravana {id_caravana} para jugador {id_jugador}")
        return id_caravana

    @_transaccion
    def simular_evento_aleatorio(self, id_caravana, dia_actual):
        self.cursor.execute("""
            SELECT estado, id_jugador FROM caravanas WHERE id_caravana = %s
        """, (id_caravana,))
        caravana = self.cursor.fetchone()
        if not caravana or caravana['estado'] != 'En viaje':
            return None

        self.cursor.execute("""
            SELECT id_evento, tipo, efecto, probabilidad FROM eventos
        """)
        eventos = self.cursor.fetchall()
        evento_seleccionado = random.choices(
            eventos + [{'id_evento': None, 'tipo': 'Ninguno', 'efecto': 'Ninguno', 'probabilidad': 0.7}],
            weights=[float(e['probabilidad']) if e['id_evento'] else 0.7 for e in eventos + [{'id_evento': None}]],
            k=1
        )[0]

        if not evento_seleccionado['id_evento']:
            return None

        self.cursor.execute("""
            INSERT INTO caravana_evento (id_caravana, id_evento, dia_ocurrencia) 
            VALUES (%s, %s, %s)
        """, (id_caravana, evento_seleccionado['id_evento'], dia_actual))
        self._log_bitacora(caravana['id_jugador'], f"Evento: {evento_seleccionado['tipo']}", "Sistema")

        if 'Aumenta tiempo' in evento_seleccionado['efecto']:
            self.cursor.execute("""
                UPDATE caravanas SET dias_transcurridos = dias_transcurridos + 2 
                WHERE id_caravana = %s
            """, (id_caravana,))
        elif 'Pierde' in evento_seleccionado['efecto']:
            self.cursor.execute("""
                UPDATE caravana_recursos SET cantidad = cantidad * 0.9 
                WHERE id_caravana = %s
            """, (id_caravana,))
        elif 'Reduce tiempo' in evento_seleccionado['efecto']:
            self.cursor.execute("""
                UPDATE caravanas SET dias_transcurridos = GREATEST(dias_transcurridos - 1, 0) 
                WHERE id_caravana = %s
            """, (id_caravana,))

        logger.info(f"Evento simulado: {evento_seleccionado['tipo']} en caravana {id_caravana}")
        return {'id_evento': evento_seleccionado['id_evento'], 'efecto': evento_seleccionado['efecto']}

    @_transaccion
    def comprar_producto(self, id_jugador, producto, cantidad):
        self._validar_cantidad_positiva(cantidad)
        ciudad = self._get_ciudad_actual(id_jugador)
        self.cursor.execute("""
            SELECT producto FROM ciudad_productos_producidos WHERE ciudad_nombre = %s AND producto = %s
        """, (ciudad, producto))
        if not self.cursor.fetchone():
            raise ValueError(f"{producto} no se produce en {ciudad}")
        self.cursor.execute("""
            SELECT ph.habilidad FROM personajes p 
            JOIN personaje_habilidades ph ON p.id_personaje = ph.id_personaje 
            WHERE p.id_jugador = %s AND ph.habilidad = 'Comercio'
        """, (id_jugador,))
        descuento = 0.9 if self.cursor.fetchone() else 1.0  # 10% descuento con Comercio
        self.cursor.execute("""
            SELECT precio_actual FROM precios_ajustados WHERE ciudad = %s AND producto = %s
        """, (ciudad, producto))
        precio = self.cursor.fetchone()['precio_actual'] * cantidad * descuento
        estado = self.obtener_estado_jugador(id_jugador)
        if estado['monedas_oro'] < precio:
            raise ValueError("No tienes suficientes monedas")
        self.cursor.execute("""
            INSERT INTO inventarios (id_jugador, producto, cantidad) 
            VALUES (%s, %s, %s) 
            ON CONFLICT (id_jugador, producto) 
            DO UPDATE SET cantidad = inventarios.cantidad + %s
        """, (id_jugador, producto, cantidad, cantidad))
        self.cursor.execute("""
            UPDATE jugadores SET monedas_oro = monedas_oro - %s WHERE id_jugador = %s
        """, (precio, id_jugador))
        logger.info(f"Compra realizada: {cantidad} de {producto} por jugador {id_jugador}")
        return {'success': True, 'monedas_oro': estado['monedas_oro'] - precio}

    @_transaccion
    def vender_producto(self, id_jugador, producto, cantidad):
        self._validar_cantidad_positiva(cantidad)
        self.cursor.execute("""
            SELECT cantidad FROM inventarios WHERE id_jugador = %s AND producto = %s
        """, (id_jugador, producto))
        inv = self.cursor.fetchone()
        if not inv or inv['cantidad'] < cantidad:
            raise ValueError("Cantidad insuficiente para vender")
        ciudad = self._get_ciudad_actual(id_jugador)
        self.cursor.execute("""
            SELECT producto FROM ciudad_productos_deseados WHERE ciudad_nombre = %s AND producto = %s
        """, (ciudad, producto))
        if not self.cursor.fetchone():
            raise ValueError(f"{producto} no es deseado en {ciudad}")
        self.cursor.execute("""
            SELECT ph.habilidad FROM personajes p 
            JOIN personaje_habilidades ph ON p.id_personaje = ph.id_personaje 
            WHERE p.id_jugador = %s AND ph.habilidad = 'Negociación'
        """, (id_jugador,))
        aumento = 1.1 if self.cursor.fetchone() else 1.0  # 10% más con Negociación
        self.cursor.execute("""
            SELECT precio_actual FROM precios_ajustados WHERE ciudad = %s AND producto = %s
        """, (ciudad, producto))
        ganancia = self.cursor.fetchone()['precio_actual'] * cantidad * aumento
        self.cursor.execute("""
            UPDATE inventarios SET cantidad = cantidad - %s 
            WHERE id_jugador = %s AND producto = %s
        """, (cantidad, id_jugador, producto))
        self.cursor.execute("""
            UPDATE jugadores SET monedas_oro = monedas_oro + %s WHERE id_jugador = %s
        """, (ganancia, id_jugador))
        estado = self.obtener_estado_jugador(id_jugador)
        logger.info(f"Venta realizada: {cantidad} de {producto} por jugador {id_jugador}")
        return {'success': True, 'monedas_oro': estado['monedas_oro'] + ganancia}

    @_transaccion
    def finalizar_viaje(self, id_caravana):
        self.cursor.execute("""
            SELECT dias_transcurridos, ruta_actual, estado, id_jugador 
            FROM caravanas WHERE id_caravana = %s
        """, (id_caravana,))
        caravana = self.cursor.fetchone()
        if not caravana or caravana['estado'] != 'En viaje':
            raise ValueError("La caravana no está en viaje o no existe")

        self.cursor.execute("""
            SELECT destino, CASE WHEN distancia_tierra IS NOT NULL THEN distancia_tierra ELSE distancia_mar END * 7 AS dias_necesarios 
            FROM rutas WHERE id_ruta = %s
        """, (caravana['ruta_actual'],))
        ruta = self.cursor.fetchone()
        dias_necesarios = ruta['dias_necesarios']

        self.cursor.execute("""
            SELECT SUM(cantidad) AS agua FROM caravana_recursos 
            WHERE id_caravana = %s AND recurso = 'Agua'
        """, (id_caravana,))
        agua_restante = self.cursor.fetchone()['agua'] or 0

        estado = 'Completada' if caravana['dias_transcurridos'] >= dias_necesarios and agua_restante > 0 else 'Fallida'
        self.cursor.execute("""
            UPDATE caravanas SET estado = %s WHERE id_caravana = %s
        """, (estado, id_caravana))
        self.cursor.execute("""
            UPDATE inventarios SET camellos = camellos + 25, vasijas = vasijas + 50 
            WHERE id_jugador = %s AND producto = 'Seda'
        """, (caravana['id_jugador'],))
        self._log_bitacora(caravana['id_jugador'], f"Viaje {estado}", "Sistema")
        if estado == 'Completada':
            self.cursor.execute("""
                UPDATE jugadores SET ciudad_actual = %s WHERE id_jugador = %s
            """, (ruta['destino'], caravana['id_jugador']))
        logger.info(f"Viaje finalizado: caravana {id_caravana} con estado {estado}")
        return {'estado': estado, 'nueva_ciudad': ruta['destino'] if estado == 'Completada' else None}

    @_transaccion
    def avanzar_tiempo(self, id_jugador, semanas):
        self._validar_cantidad_positiva(semanas, "semanas")
        self.cursor.execute("""
            UPDATE jugadores SET semanas_transcurridas = semanas_transcurridas + %s 
            WHERE id_jugador = %s AND semanas_transcurridas + %s <= 156
        """, (semanas, id_jugador, semanas))
        if self.cursor.rowcount == 0:
            raise ValueError("Límite de 3 años alcanzado")
        logger.info(f"Tiempo avanzado: {semanas} semanas para jugador {id_jugador}")
        return True

    def mostrar_inventario(self, id_jugador):
        try:
            self.cursor.execute("""
                SELECT producto, cantidad, camellos, vasijas 
                FROM inventarios WHERE id_jugador = %s
            """, (id_jugador,))
            inventario = self.cursor.fetchall()
            logger.info(f"Inventario consultado para jugador {id_jugador}")
            return inventario
        except psycopg2.Error as e:
            logger.error(f"Error al mostrar inventario: {e}")
            return None

    @_transaccion
    def guardar_partida(self, id_partida):
        self.cursor.execute("SELECT id_partida FROM partidas WHERE id_partida = %s AND estado = 'En curso'", (id_partida,))
        if not self.cursor.fetchone():
            raise ValueError("No hay partida activa con ese ID")
        self.cursor.execute("""
            INSERT INTO bitacora (fecha_hora, accion, responsable, id_partida) 
            VALUES (NOW(), 'Partida guardada manualmente', 'Jugador', %s)
        """, (id_partida,))
        logger.info(f"Partida guardada: {id_partida}")
        return True

    @_transaccion
    def finalizar_partida(self, id_partida):
        self.cursor.execute("""
            UPDATE partidas SET estado = 'Finalizada', puntuacion = (
                SELECT monedas_oro FROM jugadores WHERE id_jugador = (
                    SELECT id_jugador FROM partidas WHERE id_partida = %s
                )
            ) WHERE id_partida = %s AND estado = 'En curso'
        """, (id_partida, id_partida))
        if self.cursor.rowcount == 0:
            raise ValueError("No hay partida activa para finalizar")
        logger.info(f"Partida finalizada: {id_partida}")
        return True

    def obtener_estado_jugador(self, id_jugador):
        try:
            self.cursor.execute("""
                SELECT monedas_oro, ciudad_actual, semanas_transcurridas 
                FROM jugadores WHERE id_jugador = %s
            """, (id_jugador,))
            estado = self.cursor.fetchone()
            logger.info(f"Estado consultado para jugador {id_jugador}")
            return estado
        except psycopg2.Error as e:
            logger.error(f"Error al obtener estado del jugador: {e}")
            return None

    def obtener_ciudades(self):
        try:
            self.cursor.execute("SELECT nombre, tiene_puertos, tiene_ciudades_alejadas FROM ciudades")
            ciudades = self.cursor.fetchall()
            logger.info("Ciudades consultadas")
            return ciudades
        except psycopg2.Error as e:
            logger.error(f"Error al obtener ciudades: {e}")
            return None

    def obtener_rutas(self):
        try:
            self.cursor.execute("SELECT id_ruta, origen, destino, distancia_tierra, distancia_mar FROM rutas")
            rutas = self.cursor.fetchall()
            logger.info("Rutas consultadas")
            return rutas
        except psycopg2.Error as e:
            logger.error(f"Error al obtener rutas: {e}")
            return None

    def obtener_precios_y_productos(self, id_jugador):
        try:
            ciudad = self._get_ciudad_actual(id_jugador)
            self.cursor.execute("""
                SELECT pa.producto, pa.precio_actual, 
                       CASE WHEN cpp.producto IS NOT NULL THEN 'Producido' ELSE 'No producido' END AS producido,
                       CASE WHEN cpd.producto IS NOT NULL THEN 'Deseado' ELSE 'No deseado' END AS deseado
                FROM precios_ajustados pa
                LEFT JOIN ciudad_productos_producidos cpp ON pa.ciudad = cpp.ciudad_nombre AND pa.producto = cpp.producto
                LEFT JOIN ciudad_productos_deseados cpd ON pa.ciudad = cpd.ciudad_nombre AND pa.producto = cpd.producto
                WHERE pa.ciudad = %s
            """, (ciudad,))
            productos = self.cursor.fetchall()
            logger.info(f"Precios y productos consultados para {ciudad}")
            return productos
        except psycopg2.Error as e:
            logger.error(f"Error al obtener precios y productos: {e}")
            return None

    def obtener_estado_caravana(self, id_caravana):
        try:
            self.cursor.execute("""
                SELECT c.dias_transcurridos, c.estado, r.origen, r.destino, 
                       cr.recurso, cr.cantidad 
                FROM caravanas c
                JOIN rutas r ON c.ruta_actual = r.id_ruta
                LEFT JOIN caravana_recursos cr ON c.id_caravana = cr.id_caravana
                WHERE c.id_caravana = %s
            """, (id_caravana,))
            estado = self.cursor.fetchall()
            logger.info(f"Estado consultado para caravana {id_caravana}")
            return estado
        except psycopg2.Error as e:
            logger.error(f"Error al obtener estado de caravana: {e}")
            return None

    def obtener_eventos_caravana(self, id_caravana):
        try:
            self.cursor.execute("""
                SELECT e.tipo, e.efecto, ce.dia_ocurrencia 
                FROM caravana_evento ce
                JOIN eventos e ON ce.id_evento = e.id_evento
                WHERE ce.id_caravana = %s
                ORDER BY ce.dia_ocurrencia
            """, (id_caravana,))
            eventos = self.cursor.fetchall()
            logger.info(f"Eventos consultados para caravana {id_caravana}")
            return eventos
        except psycopg2.Error as e:
            logger.error(f"Error al obtener eventos de caravana: {e}")
            return None

    def obtener_personajes(self, id_jugador):
        try:
            self.cursor.execute("""
                SELECT p.nombre, p.ciudad_ubicacion, ph.habilidad
                FROM personajes p
                LEFT JOIN personaje_habilidades ph ON p.id_personaje = ph.id_personaje
                WHERE p.id_jugador = %s
            """, (id_jugador,))
            personajes = self.cursor.fetchall()
            logger.info(f"Personajes consultados para jugador {id_jugador}")
            return personajes
        except psycopg2.Error as e:
            logger.error(f"Error al obtener personajes: {e}")
            return None

    def obtener_bitacora(self, id_partida):
        try:
            self.cursor.execute("""
                SELECT fecha_hora, accion, responsable 
                FROM bitacora 
                WHERE id_partida = %s 
                ORDER BY fecha_hora
            """, (id_partida,))
            bitacora = self.cursor.fetchall()
            logger.info(f"Bitácora consultada para partida {id_partida}")
            return bitacora
        except psycopg2.Error as e:
            logger.error(f"Error al obtener bitácora: {e}")
            return None

    def obtener_logros(self, id_jugador):
        try:
            self.cursor.execute("""
                SELECT l.nombre, l.beneficio, 
                       CASE WHEN lp.id_personaje IS NOT NULL THEN 'Desbloqueado' ELSE 'Bloqueado' END AS estado,
                       lp.fecha_obtencion
                FROM logros l
                LEFT JOIN logro_personaje lp ON l.id_logro = lp.id_logro 
                AND lp.id_personaje IN (SELECT id_personaje FROM personajes WHERE id_jugador = %s)
                WHERE l.id_logro NOT IN (SELECT id_logro FROM logro_rutas_requeridas)
                OR EXISTS (
                    SELECT 1 FROM logro_rutas_requeridas lr 
                    JOIN caravanas c ON (c.ruta_actual IN (
                        SELECT id_ruta FROM rutas WHERE origen = lr.ciudad OR destino = lr.ciudad
                    )) 
                    WHERE c.id_jugador = %s AND c.estado = 'Completada' AND lr.id_logro = l.id_logro
                )
            """, (id_jugador, id_jugador))
            logros = self.cursor.fetchall()
            logger.info(f"Logros consultados para jugador {id_jugador}")
            return logros
        except psycopg2.Error as e:
            logger.error(f"Error al obtener logros: {e}")
            return None

    @_transaccion
    def agregar_personaje(self, id_jugador, nombre, ciudad_ubicacion):
        if not self._validar_ciudad(ciudad_ubicacion):
            raise ValueError(f"Ciudad {ciudad_ubicacion} no existe")
        self.cursor.execute("""
            INSERT INTO personajes (nombre, id_jugador, ciudad_ubicacion) 
            VALUES (%s, %s, %s) RETURNING id_personaje
        """, (nombre, id_jugador, ciudad_ubicacion))
        id_personaje = self.cursor.fetchone()['id_personaje']
        habilidad = "Comercio" if nombre == "Kiran" else "Exploración" if nombre == "Leena" else "Negociación"
        self.cursor.execute("""
            INSERT INTO personaje_habilidades (id_personaje, habilidad) 
            VALUES (%s, %s)
        """, (id_personaje, habilidad))
        logger.info(f"Personaje {nombre} agregado para jugador {id_jugador}")
        return True

    @_transaccion
    def buscar_leena(self, id_jugador):
        ciudad_actual = self._get_ciudad_actual(id_jugador)
        self.cursor.execute("""
            SELECT nombre FROM personajes WHERE id_jugador = %s AND nombre = 'Leena'
        """, (id_jugador,))
        if self.cursor.fetchone():
            return True
        probabilidad_base = 0.3
        self.cursor.execute("""
            SELECT ph.habilidad FROM personajes p 
            JOIN personaje_habilidades ph ON p.id_personaje = ph.id_personaje 
            WHERE p.id_jugador = %s AND ph.habilidad = 'Exploración'
        """, (id_jugador,))
        probabilidad = probabilidad_base + 0.1 if self.cursor.fetchone() else probabilidad_base  # +10% con Exploración
        if random.random() < probabilidad:
            self.agregar_personaje(id_jugador, "Leena", ciudad_actual)
            logger.info(f"Leena encontrada en {ciudad_actual} por jugador {id_jugador}")
            return True
        logger.info(f"Leena no encontrada en {ciudad_actual}")
        return False

    @_transaccion
    def desbloquear_logro(self, id_jugador, nombre_logro):
        self.cursor.execute("SELECT id_logro FROM logros WHERE nombre = %s", (nombre_logro,))
        logro = self.cursor.fetchone()
        if not logro:
            raise ValueError(f"Logro {nombre_logro} no existe")
        id_logro = logro['id_logro']
        self.cursor.execute("""
            SELECT COUNT(*) FROM logro_rutas_requeridas WHERE id_logro = %s
        """, (id_logro,))
        rutas_requeridas = self.cursor.fetchone()['count']
        if rutas_requeridas > 0:
            self.cursor.execute("""
                SELECT COUNT(DISTINCT c.ruta_actual) 
                FROM caravanas c 
                JOIN rutas r ON c.ruta_actual = r.id_ruta 
                JOIN logro_rutas_requeridas lr ON r.origen = lr.ciudad OR r.destino = lr.ciudad 
                WHERE c.id_jugador = %s AND c.estado = 'Completada' AND lr.id_logro = %s
            """, (id_jugador, id_logro))
            rutas_completadas = self.cursor.fetchone()['count']
            if rutas_completadas < rutas_requeridas:
                raise ValueError("No se han completado todas las rutas requeridas")
        self.cursor.execute("""
            INSERT INTO logro_personaje (id_logro, id_personaje)
            SELECT %s, id_personaje FROM personajes WHERE id_jugador = %s AND nombre = 'Kiran'
            ON CONFLICT DO NOTHING
        """, (id_logro, id_jugador))
        logger.info(f"Logro {nombre_logro} desbloqueado para jugador {id_jugador}")
        return True

# Frontend: GameFrontend
pygame.init()

WIDTH, HEIGHT = 800, 600
WINDOW = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Kiran: Mercader de Leyendas")

WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
GRAY = (150, 150, 150)
RED = (255, 0, 0)
FONT = pygame.font.SysFont("Arial", 24)

# Coordenadas ficticias para ciudades (puedes usar datos reales del SQL)
CIUDADES = {
    "Bruma": (100, 100),
    "Solara": (300, 200),
    "Puerto Azul": (500, 300),
    "Arenas": (200, 400)
}

RUTAS = [
    {"origen": "Bruma", "destino": "Solara"},
    {"origen": "Solara", "destino": "Puerto Azul"},
    {"origen": "Puerto Azul", "destino": "Arenas"}
]

class GameFrontend:
    def _init_(self):
        self.game = KiranGame()
        self.id_jugador = 1
        self.game.iniciar_partida(self.id_jugador, "Bruma")
        self.menu_options = [
            "Iniciar Viaje", "Comprar Producto", "Vender Producto", "Avanzar Tiempo",
            "Mostrar Inventario", "Salir"
        ]
        self.selected_option = 0
        self.show_inventory = False

    def draw_map(self):
        WINDOW.fill(WHITE)
        for ruta in RUTAS:
            pygame.draw.line(WINDOW, GRAY, CIUDADES[ruta["origen"]], CIUDADES[ruta["destino"]], 2)
        for ciudad, pos in CIUDADES.items():
            pygame.draw.circle(WINDOW, RED, pos, 10)
            label = FONT.render(ciudad, True, BLACK)
            WINDOW.blit(label, (pos[0] - label.get_width() // 2, pos[1] - 30))

    def draw_menu(self):
        for i, option in enumerate(self.menu_options):
            color = BLACK if i != self.selected_option else RED
            text = FONT.render(option, True, color)
            WINDOW.blit(text, (50, 50 + i * 40))

    def draw_inventory(self):
        if self.show_inventory:
            inventario = self.game.mostrar_inventario(self.id_jugador)
            if inventario:
                for i, item in enumerate(inventario):
                    text = FONT.render(f"{item['producto']}: {item['cantidad']}", True, BLACK)
                    WINDOW.blit(text, (400, 50 + i * 40))

    def handle_menu_selection(self):
        option = self.menu_options[self.selected_option]
        if option == "Iniciar Viaje":
            rutas = self.game.obtener_rutas()
            if rutas:
                id_ruta = rutas[0]['id_ruta']  # Simplificación: usa la primera ruta
                id_caravana = self.game.iniciar_viaje(self.id_jugador, id_ruta, 10, 'tierra')
                if id_caravana:
                    print(f"Viaje iniciado: {id_caravana}")
                    self.game.simular_evento_aleatorio(id_caravana, 5)
                    resultado = self.game.finalizar_viaje(id_caravana)
                    print(f"Viaje finalizado: {resultado}")
        elif option == "Comprar Producto":
            productos = self.game.obtener_precios_y_productos(self.id_jugador)
            if productos:
                producto = productos[0]['producto']  # Simplificación: usa el primero
                resultado = self.game.comprar_producto(self.id_jugador, producto, 1)
                print(f"Compra: {resultado}")
        elif option == "Vender Producto":
            productos = self.game.obtener_precios_y_productos(self.id_jugador)
            if productos:
                producto = productos[0]['producto']  # Simplificación: usa el primero
                resultado = self.game.vender_producto(self.id_jugador, producto, 1)
                print(f"Venta: {resultado}")
        elif option == "Avanzar Tiempo":
            self.game.avanzar_tiempo(self.id_jugador, 1)
            print("Tiempo avanzado")
        elif option == "Mostrar Inventario":
            self.show_inventory = not self.show_inventory
        elif option == "Salir":
            pygame.quit()
            sys.exit()

    def run(self):
        clock = pygame.time.Clock()
        while True:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    pygame.quit()
                    sys.exit()
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_UP:
                        self.selected_option = (self.selected_option - 1) % len(self.menu_options)
                    elif event.key == pygame.K_DOWN:
                        self.selected_option = (self.selected_option + 1) % len(self.menu_options)
                    elif event.key == pygame.K_RETURN:
                        self.handle_menu_selection()

            self.draw_map()
            self.draw_menu()
            self.draw_inventory()

            estado = self.game.obtener_estado_jugador(self.id_jugador)
            ciudad_text = FONT.render(f"Ciudad: {estado['ciudad_actual']} | Oro: {estado['monedas_oro']}", True, BLACK)
            WINDOW.blit(ciudad_text, (50, HEIGHT - 50))

            pygame.display.flip()
            clock.tick(60)

if __name__ == "__main__":

    frontend = GameFrontend()
    frontend.run()