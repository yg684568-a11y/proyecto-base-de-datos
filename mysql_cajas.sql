-- MySQL - cajas_ventas_db - DDL

CREATE DATABASE IF NOT EXISTS cajas_ventas_db;
USE cajas_ventas_db;

CREATE TABLE IF NOT EXISTS clientes (
    id_cliente      INT AUTO_INCREMENT PRIMARY KEY,
    nombre_completo VARCHAR(150) NOT NULL,
    telefono        VARCHAR(15),
    puntos_monedero DECIMAL(10,2) DEFAULT 0
);

CREATE TABLE IF NOT EXISTS productos (
    id_producto     INT AUTO_INCREMENT PRIMARY KEY,
    codigo_barras   VARCHAR(20) UNIQUE NOT NULL,
    nombre          VARCHAR(150) NOT NULL,
    departamento    VARCHAR(80) NOT NULL,
    precio_venta    DECIMAL(10,2) NOT NULL,
    es_pesable      BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS ventas (
    id_venta        INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente      INT,
    fecha_hora      DATETIME DEFAULT CURRENT_TIMESTAMP,
    total_pagado    DECIMAL(10,2) DEFAULT 0,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

CREATE TABLE IF NOT EXISTS detalle_ventas (
    id_detalle      INT AUTO_INCREMENT PRIMARY KEY,
    id_venta        INT NOT NULL,
    id_producto     INT NOT NULL,
    cantidad        DECIMAL(10,3) NOT NULL,
    subtotal        DECIMAL(10,2) DEFAULT 0,
    FOREIGN KEY (id_venta)    REFERENCES ventas(id_venta),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

-- TRIGGERS MySQL

DELIMITER $$

-- 1. TRG_Precio_Valido
CREATE TRIGGER TRG_Precio_Valido
BEFORE INSERT ON productos
FOR EACH ROW
BEGIN
    IF NEW.precio_venta <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El precio de venta debe ser mayor a 0';
    END IF;
END$$

-- 2. TRG_Suma_Puntos
CREATE TRIGGER TRG_Suma_Puntos
AFTER INSERT ON ventas
FOR EACH ROW
BEGIN
    IF NEW.id_cliente IS NOT NULL THEN
        UPDATE clientes
        SET puntos_monedero = puntos_monedero + (NEW.total_pagado * 0.05)
        WHERE id_cliente = NEW.id_cliente;
    END IF;
END$$

-- 3. TRG_Mayusculas_Producto
CREATE TRIGGER TRG_Mayusculas_Producto
BEFORE INSERT ON productos
FOR EACH ROW
BEGIN
    SET NEW.nombre = UPPER(NEW.nombre);
END$$

-- 4. TRG_Calcula_Subtotal
CREATE TRIGGER TRG_Calcula_Subtotal
BEFORE INSERT ON detalle_ventas
FOR EACH ROW
BEGIN
    DECLARE precio DECIMAL(10,2);
    SELECT precio_venta INTO precio FROM productos WHERE id_producto = NEW.id_producto;
    SET NEW.subtotal = NEW.cantidad * precio;
END$$

-- 5. TRG_Actualiza_Total
CREATE TRIGGER TRG_Actualiza_Total
AFTER INSERT ON detalle_ventas
FOR EACH ROW
BEGIN
    UPDATE ventas
    SET total_pagado = total_pagado + NEW.subtotal
    WHERE id_venta = NEW.id_venta;
END$$

DELIMITER ;

-- 90 CONSULTAS MySQL (1-30)

-- 1. Mostrar todos los productos
SELECT * FROM productos;

-- 2. Mostrar todos los clientes
SELECT * FROM clientes;

-- 3. Ventas del día de hoy
SELECT * FROM ventas WHERE DATE(fecha_hora) = CURDATE();

-- 4. Productos pesables
SELECT * FROM productos WHERE es_pesable = TRUE;

-- 5. Contar productos en Lácteos
SELECT COUNT(*) AS total_lacteos FROM productos WHERE departamento = 'Lácteos';

-- 6. Productos con precio > $100
SELECT * FROM productos WHERE precio_venta > 100;

-- 7. Producto más caro
SELECT * FROM productos ORDER BY precio_venta DESC LIMIT 1;

-- 8. Clientes con más de 200 puntos
SELECT * FROM clientes WHERE puntos_monedero > 200;

-- 9. Total de ventas realizadas
SELECT COUNT(*) AS total_ventas FROM ventas;

-- 10. Ventas mayores a $1,500
SELECT * FROM ventas WHERE total_pagado > 1500;

-- 11. Clientes cuyo nombre empiece con 'C'
SELECT * FROM clientes WHERE nombre_completo LIKE 'C%';

-- 12. Productos que contengan 'Bimbo'
SELECT * FROM productos WHERE nombre LIKE '%BIMBO%';

-- 13. Productos de Carnes o Verduras
SELECT * FROM productos WHERE departamento IN ('Carnes', 'Verduras');

-- 14. Ventas de la última semana
SELECT * FROM ventas WHERE fecha_hora BETWEEN DATE_SUB(NOW(), INTERVAL 7 DAY) AND NOW();

-- 15. Top 10 clientes por puntos
SELECT * FROM clientes ORDER BY puntos_monedero DESC LIMIT 10;

-- 16. Compras por cliente
SELECT id_cliente, COUNT(*) AS total_compras FROM ventas GROUP BY id_cliente;

-- 17. Departamentos distintos
SELECT DISTINCT departamento FROM productos;

-- 18. Productos a exactamente $25.50
SELECT * FROM productos WHERE precio_venta = 25.50;

-- 19. Departamentos con más de 10 productos
SELECT departamento, COUNT(*) AS total FROM productos GROUP BY departamento HAVING total > 10;

-- 20. Longitud del código de barras
SELECT nombre, codigo_barras, LENGTH(codigo_barras) AS longitud FROM productos;

-- 21. Nombres en mayúsculas
SELECT UPPER(nombre) AS nombre_mayus FROM productos;

-- 22. 5 ventas más recientes
SELECT * FROM ventas ORDER BY fecha_hora DESC LIMIT 5;

-- 23. Clientes con al menos una compra
SELECT * FROM clientes WHERE id_cliente IN (SELECT DISTINCT id_cliente FROM ventas WHERE id_cliente IS NOT NULL);

-- 24. Clientes que nunca han comprado
SELECT * FROM clientes WHERE id_cliente NOT IN (SELECT DISTINCT id_cliente FROM ventas WHERE id_cliente IS NOT NULL);

-- 25. Productos de Panadería (subconsulta)
SELECT * FROM productos WHERE departamento = (SELECT departamento FROM productos WHERE departamento = 'Panadería' LIMIT 1);

-- 26. Total de ventas por mes
SELECT MONTH(fecha_hora) AS mes, YEAR(fecha_hora) AS anio, COUNT(*) AS total FROM ventas GROUP BY anio, mes;

-- 27. Día de la venta
SELECT id_venta, DAY(fecha_hora) AS dia FROM ventas;

-- 28. Concatenar nombre y precio
SELECT CONCAT(nombre, ' - $', precio_venta) AS producto_precio FROM productos;

-- 29. Detalle con mayor cantidad
SELECT * FROM detalle_ventas ORDER BY cantidad DESC LIMIT 1;

-- 30. Total de ingresos del mes actual
SELECT SUM(total_pagado) AS ingresos_mes FROM ventas WHERE MONTH(fecha_hora) = MONTH(CURDATE()) AND YEAR(fecha_hora) = YEAR(CURDATE());

-- 10 JOINs MySQL

-- JOIN 1: ID venta, cantidad y nombre del producto
SELECT dv.id_venta, dv.cantidad, p.nombre
FROM detalle_ventas dv
INNER JOIN productos p ON dv.id_producto = p.id_producto;

-- JOIN 2: Clientes y suma de compras
SELECT c.id_cliente, c.nombre_completo, COALESCE(SUM(v.total_pagado), 0) AS total_gastado
FROM clientes c
LEFT JOIN ventas v ON c.id_cliente = v.id_cliente
GROUP BY c.id_cliente, c.nombre_completo;

-- JOIN 3: Triple - cliente, fecha y producto
SELECT c.nombre_completo, v.fecha_hora, p.nombre AS producto
FROM ventas v
INNER JOIN clientes c ON v.id_cliente = c.id_cliente
INNER JOIN detalle_ventas dv ON v.id_venta = dv.id_venta
INNER JOIN productos p ON dv.id_producto = p.id_producto;

-- JOIN 4: Productos nunca vendidos
SELECT p.id_producto, p.nombre
FROM productos p
LEFT JOIN detalle_ventas dv ON p.id_producto = dv.id_producto
WHERE dv.id_detalle IS NULL;

-- JOIN 5: Unidades vendidas por producto
SELECT p.nombre, SUM(dv.cantidad) AS unidades_vendidas
FROM detalle_ventas dv
INNER JOIN productos p ON dv.id_producto = p.id_producto
GROUP BY p.id_producto, p.nombre;

-- JOIN 6: Ventas con clientes por teléfono
SELECT v.id_venta, c.nombre_completo, c.telefono, v.total_pagado
FROM ventas v
INNER JOIN clientes c ON v.id_cliente = c.id_cliente
WHERE c.telefono LIKE '55%';

-- JOIN 7: Ventas con más de 5 unidades del mismo producto
SELECT dv.id_venta, p.nombre, dv.cantidad
FROM detalle_ventas dv
INNER JOIN productos p ON dv.id_producto = p.id_producto
WHERE dv.cantidad > 5;

-- JOIN 8: Clientes y ventas RIGHT JOIN
SELECT c.nombre_completo, v.id_venta, v.total_pagado
FROM clientes c
RIGHT JOIN ventas v ON c.id_cliente = v.id_cliente;

-- JOIN 9: Triple - cliente, producto y subtotal
SELECT c.nombre_completo, p.nombre AS producto, dv.subtotal
FROM detalle_ventas dv
INNER JOIN ventas v ON dv.id_venta = v.id_venta
INNER JOIN clientes c ON v.id_cliente = c.id_cliente
INNER JOIN productos p ON dv.id_producto = p.id_producto;

-- JOIN 10: Detalles solo de Lácteos
SELECT dv.id_detalle, p.nombre, dv.cantidad, dv.subtotal
FROM detalle_ventas dv
INNER JOIN productos p ON dv.id_producto = p.id_producto
WHERE p.departamento = 'Lácteos';
