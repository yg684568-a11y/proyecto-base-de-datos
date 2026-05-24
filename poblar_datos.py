import random
from datetime import datetime, timedelta
from faker import Faker

fake = Faker('es_MX')

# DATOS  REALISTAS

DEPARTAMENTOS = ['Lácteos', 'Carnes', 'Verduras', 'Panadería', 'Bebidas',
                 'Limpieza', 'Higiene', 'Congelados', 'Botanas', 'Cereales']

PRODUCTOS_BASE = [
    ('Leche Lala Entera 1L', 'Lácteos', 25.50, False),
    ('Leche Alpura Light 1L', 'Lácteos', 27.00, False),
    ('Queso Oaxaca Lala 400g', 'Lácteos', 89.00, False),
    ('Yogurt Danone Fresa', 'Lácteos', 18.50, False),
    ('Crema Lala 200ml', 'Lácteos', 22.00, False),
    ('Pechuga de Pollo kg', 'Carnes', 119.00, True),
    ('Carne Molida Res kg', 'Carnes', 145.00, True),
    ('Chorizo FUD 500g', 'Carnes', 65.00, False),
    ('Jamón Kir 200g', 'Carnes', 48.00, False),
    ('Salchicha FUD kg', 'Carnes', 89.00, True),
    ('Jitomate kg', 'Verduras', 28.00, True),
    ('Cebolla kg', 'Verduras', 22.00, True),
    ('Lechuga pieza', 'Verduras', 18.00, False),
    ('Papa kg', 'Verduras', 25.00, True),
    ('Chile Serrano kg', 'Verduras', 45.00, True),
    ('Pan Bimbo Blanco', 'Panadería', 42.00, False),
    ('Pan Bimbo Integral', 'Panadería', 48.00, False),
    ('Bimbo Medianoche 8pk', 'Panadería', 35.00, False),
    ('Marinela Gansito 6pk', 'Panadería', 55.00, False),
    ('Pan de Caja Wonder', 'Panadería', 38.00, False),
    ('Coca-Cola 2L', 'Bebidas', 35.00, False),
    ('Pepsi 2L', 'Bebidas', 33.00, False),
    ('Agua Epura 1.5L', 'Bebidas', 18.00, False),
    ('Jugo Del Valle 1L', 'Bebidas', 28.00, False),
    ('Gatorade 600ml', 'Bebidas', 22.00, False),
    ('Detergente Ariel 1kg', 'Limpieza', 95.00, False),
    ('Fabuloso 1L', 'Limpieza', 42.00, False),
    ('Ajax Polvo 500g', 'Limpieza', 28.00, False),
    ('Pinol 1L', 'Limpieza', 38.00, False),
    ('Suavitel 1L', 'Limpieza', 55.00, False),
    ('Shampoo Head Shoulders', 'Higiene', 89.00, False),
    ('Jabón Dove 3pk', 'Higiene', 65.00, False),
    ('Pasta Colgate 100ml', 'Higiene', 38.00, False),
    ('Desodorante Axe', 'Higiene', 72.00, False),
    ('Papel Higiénico Regio 4pk', 'Higiene', 48.00, False),
    ('Pizza Digiorno', 'Congelados', 129.00, False),
    ('Helado Holanda 1L', 'Congelados', 85.00, False),
    ('Nuggets Mc Cain 500g', 'Congelados', 95.00, False),
    ('Papas Ore-Ida 500g', 'Congelados', 79.00, False),
    ('Burrito Congelado', 'Congelados', 45.00, False),
    ('Sabritas Original 45g', 'Botanas', 18.00, False),
    ('Doritos Nacho 65g', 'Botanas', 22.00, False),
    ('Ruffles Queso 45g', 'Botanas', 18.00, False),
    ('Palomitas Chip 200g', 'Botanas', 35.00, False),
    ('Maiz Tostado 100g', 'Botanas', 15.00, False),
    ('Corn Flakes Kelloggs', 'Cereales', 75.00, False),
    ('Avena Quaker 500g', 'Cereales', 45.00, False),
    ('Granola Nature Valley', 'Cereales', 85.00, False),
    ('Frijoles Costeña 560g', 'Cereales', 32.00, False),
    ('Arroz SOS 1kg', 'Cereales', 28.00, False),
]

PROVEEDORES_BASE = [
    ('Lala S.A. de C.V.', 'LAL930201AB1', 30),
    ('Bimbo S.A. de C.V.', 'BIM971105CD2', 45),
    ('Sabritas S.A. de C.V.', 'SAB880312EF3', 30),
    ('Kellogg de México', 'KEL910623GH4', 60),
    ('Nestlé México', 'NES850715IJ5', 30),
    ('Coca-Cola FEMSA', 'CCF920430KL6', 15),
    ('Alpura S.A. de C.V.', 'ALP940821MN7', 30),
    ('FUD Sigma Alimentos', 'SIG880610OP8', 45),
    ('Unilever México', 'UNI901205QR9', 60),
    ('P&G México', 'PAG950318ST0', 30),
]

TURNOS = ['Matutino', 'Vespertino', 'Nocturno']
MODULOS = ['Punto de Venta', 'Inventario', 'Recursos Humanos', 'Finanzas', 'Administración']
ACCIONES = ['INSERT', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT']
ESTADOS = ['Pendiente', 'Recibido', 'Cancelado']

# GENERADORES

def gen_barcode():
    return ''.join([str(random.randint(0, 9)) for _ in range(13)])

def gen_fecha_pasada(dias=365):
    return datetime.now() - timedelta(days=random.randint(1, dias))

def gen_fecha_futura(dias=180):
    return datetime.now() + timedelta(days=random.randint(1, dias))

# ============================================================
# MYSQL - cajas_ventas_db
# ============================================================

def poblar_mysql():
    import mysql.connector
    conn = mysql.connector.connect(
        host='localhost', port=3306,
        user='root', password='root1234',
        database='cajas_ventas_db'
    )
    cur = conn.cursor()

    print("Poblando MySQL...")

    # 100 Clientes
    clientes_ids = []
    for _ in range(100):
        nombre = fake.name()
        telefono = fake.numerify('55########')
        puntos = round(random.uniform(0, 500), 2)
        cur.execute("INSERT INTO clientes (nombre_completo, telefono, puntos_monedero) VALUES (%s,%s,%s)",
                    (nombre, telefono, puntos))
        clientes_ids.append(cur.lastrowid)

    # 50 Productos
    productos_ids = []
    for nombre, depto, precio, pesable in PRODUCTOS_BASE:
        barcode = gen_barcode()
        cur.execute("INSERT INTO productos (codigo_barras, nombre, departamento, precio_venta, es_pesable) VALUES (%s,%s,%s,%s,%s)",
                    (barcode, nombre.upper(), depto, precio, pesable))
        productos_ids.append(cur.lastrowid)

    # 100 Ventas con detalles
    for _ in range(100):
        cliente_id = random.choice(clientes_ids)
        fecha = gen_fecha_pasada(90)
        cur.execute("INSERT INTO ventas (id_cliente, fecha_hora, total_pagado) VALUES (%s,%s,%s)",
                    (cliente_id, fecha, 0))
        venta_id = cur.lastrowid

        num_productos = random.randint(1, 5)
        for _ in range(num_productos):
            prod_id = random.choice(productos_ids)
            cur.execute("SELECT precio_venta, es_pesable FROM productos WHERE id_producto=%s", (prod_id,))
            precio, pesable = cur.fetchone()
            cantidad = round(random.uniform(0.1, 3.0), 3) if pesable else random.randint(1, 5)
            subtotal = round(cantidad * float(precio), 2)
            cur.execute("INSERT INTO detalle_ventas (id_venta, id_producto, cantidad, subtotal) VALUES (%s,%s,%s,%s)",
                        (venta_id, prod_id, cantidad, subtotal))
            cur.execute("UPDATE ventas SET total_pagado = total_pagado + %s WHERE id_venta = %s",
                        (subtotal, venta_id))

    conn.commit()
    cur.close()
    conn.close()
    print("  ✅ MySQL: 100 clientes, 50 productos, 100 ventas con detalles")

# SQL SERVER - bodega_inventario_db

def poblar_sqlserver():
    import pyodbc
    conn = pyodbc.connect(
        'DRIVER={ODBC Driver 17 for SQL Server};'
        'SERVER=localhost,1433;'
        'DATABASE=bodega_inventario_db;'
        'UID=sa;PWD=SqlServer1234!'
    )
    cur = conn.cursor()

    print("Poblando SQL Server...")

    # 10 Proveedores
    prov_ids = []
    for razon, rfc, dias in PROVEEDORES_BASE:
        cur.execute("INSERT INTO proveedores (razon_social, rfc_proveedor, dias_credito) VALUES (?,?,?)",
                    razon, rfc, dias)
        cur.execute("SELECT @@IDENTITY")
        prov_ids.append(int(cur.fetchone()[0]))

    # 100 Registros de stock
    for _ in range(100):
        id_prod_ref = random.randint(1, 50)
        id_prov = random.choice(prov_ids)
        cantidad = round(random.uniform(0, 200), 2)
        caducidad = gen_fecha_futura(180).date()
        cur.execute("INSERT INTO almacen_stock (id_producto_ref, id_proveedor, cantidad_disponible, fecha_caducidad_proxima) VALUES (?,?,?,?)",
                    id_prod_ref, id_prov, cantidad, caducidad)

    # 100 Órdenes de compra
    for _ in range(100):
        id_prov = random.choice(prov_ids)
        fecha = gen_fecha_pasada(365)
        monto = round(random.uniform(500, 50000), 2)
        estado = random.choice(ESTADOS)
        cur.execute("INSERT INTO ordenes_compra (id_proveedor, fecha_orden, monto_total, estado_entrega) VALUES (?,?,?,?)",
                    id_prov, fecha, monto, estado)

    conn.commit()
    cur.close()
    conn.close()
    print("  ✅ SQL Server: 10 proveedores, 100 stock, 100 órdenes")

# POSTGRESQL - corporativo_finanzas_db

def poblar_postgres():
    import psycopg2
    conn = psycopg2.connect(
        host='localhost', port=5432,
        user='postgres', password='postgres1234',
        dbname='corporativo_finanzas_db'
    )
    cur = conn.cursor()

    print("Poblando PostgreSQL...")

    # 20 Cajeros
    cajeros_ids = []
    for i in range(20):
        nombre = fake.name()
        turno = random.choice(TURNOS)
        caja = random.randint(1, 10)
        cur.execute("INSERT INTO empleados_cajeros (nombre, turno, caja_asignada) VALUES (%s,%s,%s) RETURNING num_empleado",
                    (nombre, turno, caja))
        cajeros_ids.append(cur.fetchone()[0])

    # 100 Cortes de caja
    for _ in range(100):
        emp = random.choice(cajeros_ids)
        fecha = gen_fecha_pasada(90).date()
        calculado = round(random.uniform(3000, 20000), 2)
        entregado = round(calculado + random.uniform(-800, 800), 2)
        diferencia = round(entregado - calculado, 2)
        cur.execute("INSERT INTO cortes_diarios (num_empleado, fecha, monto_calculado, monto_entregado, diferencia) VALUES (%s,%s,%s,%s,%s)",
                    (emp, fecha, calculado, entregado, diferencia))

    # 100 Logs de auditoría
    import json
    for _ in range(100):
        usuario = fake.user_name()
        modulo = random.choice(MODULOS)
        accion = random.choice(ACCIONES)
        fecha = gen_fecha_pasada(90)
        nivel = random.choice(['info', 'warning', 'critico'])
        detalles = json.dumps({
            'usuario': usuario,
            'ip_terminal': fake.ipv4(),
            'nivel': nivel,
            'descripcion': fake.sentence()
        })
        cur.execute("INSERT INTO log_auditoria (usuario, modulo, accion, fecha, detalles) VALUES (%s,%s,%s,%s,%s)",
                    (usuario, modulo, accion, fecha, detalles))

    conn.commit()
    cur.close()
    conn.close()
    print("   PostgreSQL: 20 cajeros, 100 cortes, 100 logs")

# MAIN

if __name__ == '__main__':
    print("=" * 50)
    print("  Iniciando población masiva de datos")
    print("=" * 50)

    try:
        poblar_mysql()
    except Exception as e:
        print(f"   Error MySQL: {e}")

    try:
        poblar_sqlserver()
    except Exception as e:
        print(f"   Error SQL Server: {e}")

    try:
        poblar_postgres()
    except Exception as e:
        print(f"   Error PostgreSQL: {e}")

    print("=" * 50)
    print("   Proceso terminado")
    print("  Total estimado: 750+ registros")
    print("=" * 50)
