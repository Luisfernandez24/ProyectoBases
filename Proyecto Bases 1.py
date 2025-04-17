import sys
import os
import json
import psycopg2
from PyQt5.QtWidgets import (
    QApplication, QWidget, QLabel, QLineEdit, QComboBox,
    QPushButton, QVBoxLayout, QMessageBox, QSpacerItem,
    QSizePolicy, QGraphicsView, QGraphicsScene,
    QGraphicsPixmapItem, QGraphicsTextItem, QHBoxLayout
)
from PyQt5.QtGui import QFont, QPalette, QColor, QPixmap
from PyQt5.QtCore import Qt, QPropertyAnimation, QPointF, QObject, pyqtProperty

# Clase proxy para animar un QGraphicsPixmapItem
class AnimadorObjeto(QObject):
    def _init_(self, item):
        super()._init_()
        self._item = item

    def get_pos(self):
        return self._item.pos()

    def set_pos(self, pos):
        self._item.setPos(pos)

    pos = pyqtProperty(QPointF, fget=get_pos, fset=set_pos)

# Función para escalar las coordenadas
def escalar_coordenadas(ciudades, factor_x=0.95, factor_y=0.95):
    return {nombre: [int(x * factor_x), int(y * factor_y)] for nombre, (x, y) in ciudades.items()}

# =========================
# BACKEND - CONEXIÓN
# =========================
def conectar():
    return psycopg2.connect(
        host="aws-0-us-east-1.pooler.supabase.com",
        dbname="postgres",
        user="postgres.fepneluuwqvozpgmeeaz",
        password="proyectobases1",
        port=5432
    )

def obtener_productos_de_bruma():
    conn = conectar()
    cur = conn.cursor()
    cur.execute("""
        SELECT p.id_producto, p.nombre
        FROM productos p
        JOIN ciudad_productos_producidos cpp ON p.id_producto = cpp.id_producto
        WHERE cpp.id_ciudad = 1
        ORDER BY p.nombre;
    """)
    productos = cur.fetchall()
    cur.close()
    conn.close()
    return productos

def iniciar_partida(nombre_jugador, id_producto):
    conn = conectar()
    cur = conn.cursor()
    try:
        id_ciudad = 1  # Bruma
        cur.execute("INSERT INTO jugadores (nombre, ciudad_actual, monedas_oro) VALUES (%s, %s, 150) RETURNING id_jugador;", (nombre_jugador, id_ciudad))
        id_jugador = cur.fetchone()[0]

        cur.execute("INSERT INTO personajes (nombre, tipo, id_jugador, ciudad_ubicacion) VALUES ('Kiran', 'Kiran', %s, %s);", (id_jugador, id_ciudad))

        cur.execute("INSERT INTO inventario_productos (id_jugador, id_producto, cantidad) VALUES (%s, %s, 5) ON CONFLICT (id_jugador, id_producto) DO UPDATE SET cantidad = inventario_productos.cantidad + 5;", (id_jugador, id_producto))

        cur.execute("SELECT id_producto FROM productos WHERE LOWER(nombre) = 'vasijas';")
        vasijas = cur.fetchone()
        if vasijas:
            id_vasijas = vasijas[0]
            cur.execute("INSERT INTO inventario_productos (id_jugador, id_producto, cantidad) VALUES (%s, %s, 50);", (id_jugador, id_vasijas))

        conn.commit()
        return True, id_jugador
    except Exception as e:
        conn.rollback()
        return False, str(e)
    finally:
        cur.close()
        conn.close()

# =========================
# MAPA INTERACTIVO
# =========================
class MapaConCiudades(QWidget):
    def _init_(self, ruta_imagen_mapa, ruta_imagen_personaje, ruta_json_coords):
        super()._init_()
        self.setWindowTitle("🗺 Mapa de Kiran")
        self.setGeometry(100, 100, 1000, 700)

        layout_principal = QVBoxLayout()
        self.setLayout(layout_principal)

        self.scene = QGraphicsScene()
        self.view = QGraphicsView(self.scene)
        layout_principal.addWidget(self.view)

        # Cargar mapa
        mapa_pixmap = QPixmap(ruta_imagen_mapa)
        self.scene.addPixmap(mapa_pixmap)

        # Leer coordenadas de ciudades y aplicar escalado
        with open(ruta_json_coords, "r", encoding="utf-8") as f:
            original_coords = json.load(f)
            self.ciudades = escalar_coordenadas(original_coords, 0.95, 0.95)

        # Mostrar personaje PNG en Bruma
        self.personaje = None
        if os.path.exists(ruta_imagen_personaje):
            self.personaje = QGraphicsPixmapItem(QPixmap(ruta_imagen_personaje).scaled(36, 36, Qt.KeepAspectRatio, Qt.SmoothTransformation))
            self.scene.addItem(self.personaje)
            self.proxy = AnimadorObjeto(self.personaje)
            self.mover_a_ciudad("Bruma")
        else:
            print("❌ Imagen del personaje no encontrada.")

        # Menú de ciudades y botón Ir
        self.selector_ciudad = QComboBox()
        self.selector_ciudad.addItems(sorted(self.ciudades.keys()))

        self.boton_ir = QPushButton("Ir")
        self.boton_ir.clicked.connect(self.ir_a_ciudad)

        layout_controles = QHBoxLayout()
        layout_controles.addWidget(QLabel("📍 Ir a ciudad:"))
        layout_controles.addWidget(self.selector_ciudad)
        layout_controles.addWidget(self.boton_ir)
        layout_principal.addLayout(layout_controles)

    def mover_a_ciudad(self, nombre_ciudad):
        if nombre_ciudad in self.ciudades:
            x, y = self.ciudades[nombre_ciudad]
            if self.proxy:
                self.animacion = QPropertyAnimation(self.proxy, b"pos")
                self.animacion.setDuration(1000)
                self.animacion.setEndValue(QPointF(x, y))
                self.animacion.finished.connect(lambda: QMessageBox.information(self, "Movimiento completado", f"Kiran llegó a {nombre_ciudad} ✨"))
                self.animacion.start()
        else:
            QMessageBox.warning(self, "Ciudad no encontrada", f"No se encontró la ciudad '{nombre_ciudad}'.")

    def ir_a_ciudad(self):
        ciudad_destino = self.selector_ciudad.currentText()
        self.mover_a_ciudad(ciudad_destino)

# =========================
# INTERFAZ DE INICIO
# =========================
class VentanaInicio(QWidget):
    def _init_(self):
        super()._init_()
        self.setWindowTitle("🌍 Kiran: Iniciar Partida")
        self.setGeometry(200, 200, 450, 350)

        fuente_normal = QFont("Arial", 12)
        self.label_nombre = QLabel("👤 Nombre del jugador:")
        self.label_nombre.setFont(fuente_normal)
        self.input_nombre = QLineEdit()
        self.input_nombre.setFont(fuente_normal)

        self.label_producto = QLabel("📦 Producto inicial:")
        self.label_producto.setFont(fuente_normal)
        self.combo_productos = QComboBox()
        self.combo_productos.setFont(fuente_normal)

        self.boton_iniciar = QPushButton("🚀 Iniciar Partida")
        self.boton_iniciar.setFont(QFont("Arial", 12, QFont.Bold))
        self.boton_iniciar.setStyleSheet("background-color: #2e8b57; color: white; padding: 10px; border-radius: 8px;")
        self.boton_iniciar.clicked.connect(self.iniciar_partida)

        layout = QVBoxLayout()
        layout.setSpacing(15)
        layout.addSpacerItem(QSpacerItem(10, 10, QSizePolicy.Minimum, QSizePolicy.Expanding))
        layout.addWidget(self.label_nombre)
        layout.addWidget(self.input_nombre)
        layout.addWidget(self.label_producto)
        layout.addWidget(self.combo_productos)
        layout.addWidget(self.boton_iniciar)
        layout.addSpacerItem(QSpacerItem(10, 10, QSizePolicy.Minimum, QSizePolicy.Expanding))
        self.setLayout(layout)

        paleta = QPalette()
        paleta.setColor(QPalette.Window, QColor("#f0f5f9"))
        self.setAutoFillBackground(True)
        self.setPalette(paleta)

        self.productos = obtener_productos_de_bruma()
        for id_, nombre in self.productos:
            self.combo_productos.addItem(nombre, id_)

    def iniciar_partida(self):
        nombre = self.input_nombre.text().strip()
        id_producto = self.combo_productos.currentData()

        if not nombre:
            QMessageBox.warning(self, "Faltan datos", "⚠ Ingresá el nombre del jugador.")
            return

        exito, resultado = iniciar_partida(nombre, id_producto)
        if exito:
            QMessageBox.information(self, "¡Éxito!", "Partida creada correctamente. Mostrando mapa...")
            self.input_nombre.clear()

            # Rutas relativas a la carpeta 'assets'
            ruta_base = os.path.dirname(_file_)
            ruta_mapa = os.path.join(ruta_base, "assets", "Mapa.png")
            ruta_personaje = os.path.join(ruta_base, "assets", "Personaje.png")
            ruta_json = os.path.join(ruta_base, "assets", "coordenadas_ciudades.json")

            self.mapa = MapaConCiudades(ruta_mapa, ruta_personaje, ruta_json)
            self.mapa.show()
        else:
            QMessageBox.critical(self, "Error", f"❌ No se pudo iniciar la partida:\n{resultado}")

# MAIN
if _name_ == "_main_":
    app = QApplication(sys.argv)
    ventana = VentanaInicio()
    ventana.show()
    sys.exit(app.exec_())
