-- SQL Server - bodega_inventario_db - DDL

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'bodega_inventario_db')
    CREATE DATABASE bodega_inventario_db;
GO

USE bodega_inventario_db;
GO

CREATE TABLE proveedores (
    id_proveedor    INT IDENTITY(1,1) PRIMARY KEY,
    razon_social    NVARCHAR(150) NOT NULL,
    rfc_proveedor   NVARCHAR(20) NOT NULL,
    dias_credito    INT DEFAULT 30
);
GO

CREATE TABLE almacen_stock (
    id_stock                INT IDENTITY(1,1) PRIMARY KEY,
    id_producto_ref         INT NOT NULL,
    id_proveedor            INT NOT NULL,
    cantidad_disponible     DECIMAL(10,3) DEFAULT 0,
    fecha_caducidad_proxima DATE,
    FOREIGN KEY (id_proveedor) REFERENCES proveedores(id_proveedor)
);
GO

CREATE TABLE ordenes_compra (
    id_orden        INT IDENTITY(1,1) PRIMARY KEY,
    id_proveedor    INT NOT NULL,
    fecha_orden     DATETIME DEFAULT GETDATE(),
    monto_total     DECIMAL(10,2) DEFAULT 0,
    estado_entrega  NVARCHAR(30) DEFAULT 'Pendiente',
    FOREIGN KEY (id_proveedor) REFERENCES proveedores(id_proveedor)
);
GO



-- TRIGGERS SQL Server

-- 6. TRG_Stock_Negativo
CREATE OR ALTER TRIGGER TRG_Stock_Negativo
ON almacen_stock
AFTER UPDATE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE cantidad_disponible < 0)
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR('El stock no puede ser negativo.', 16, 1);
    END
END;
GO

-- 7. TRG_Impide_Baja_Proveedor
CREATE OR ALTER TRIGGER TRG_Impide_Baja_Proveedor
ON proveedores
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM ordenes_compra oc INNER JOIN deleted d ON oc.id_proveedor = d.id_proveedor)
    BEGIN
        RAISERROR('No se puede eliminar un proveedor con órdenes registradas.', 16, 1);
    END
    ELSE
    BEGIN
        DELETE FROM proveedores WHERE id_proveedor IN (SELECT id_proveedor FROM deleted);
    END
END;
GO

-- 8. TRG_Valida_RFC_Prov
CREATE OR ALTER TRIGGER TRG_Valida_RFC_Prov
ON proveedores
AFTER INSERT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE LEN(rfc_proveedor) < 12)
    BEGIN
        ROLLBACK TRANSACTION;
        RAISERROR('El RFC del proveedor debe tener al menos 12 caracteres.', 16, 1);
    END
END;
GO

-- 9. TRG_Alerta_Caducidad
CREATE OR ALTER TRIGGER TRG_Alerta_Caducidad
ON almacen_stock
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted
        WHERE fecha_caducidad_proxima <= DATEADD(DAY, 30, GETDATE())
    )
    BEGIN
        RAISERROR('ALERTA: Existen productos proximos a caducar en menos de 30 dias.', 10, 1) WITH NOWAIT;
    END
END;
GO

-- 10. TRG_Monto_Orden
CREATE OR ALTER TRIGGER TRG_Monto_Orden
ON ordenes_compra
INSTEAD OF INSERT
AS
BEGIN
    INSERT INTO ordenes_compra (id_proveedor, fecha_orden, monto_total, estado_entrega)
    SELECT
        id_proveedor,
        ISNULL(fecha_orden, GETDATE()),
        CASE WHEN monto_total < 0 THEN 0 ELSE monto_total END,
        'Pendiente'
    FROM inserted;
END;
GO

-- CONSULTAS SQL Server (31-60)

-- 31. Todos los proveedores
SELECT * FROM proveedores;

-- 32. Todo el inventario
SELECT * FROM almacen_stock;

-- 33. Todas las órdenes de compra
SELECT * FROM ordenes_compra;

-- 34. Contar lotes en bodega
SELECT COUNT(*) AS total_lotes FROM almacen_stock;

-- 35. Total órdenes pendientes
SELECT COUNT(*) AS pendientes FROM ordenes_compra WHERE estado_entrega = 'Pendiente';

-- 36. Proveedor con más días de crédito
SELECT TOP 1 * FROM proveedores ORDER BY dias_credito DESC;

-- 37. Stock con cantidad < 15
SELECT * FROM almacen_stock WHERE cantidad_disponible < 15;

-- 38. Proveedores locales (RFC empieza con 'MEX')
SELECT * FROM proveedores WHERE rfc_proveedor LIKE 'MEX%';

-- 39. Monto total de órdenes
SELECT SUM(monto_total) AS monto_total FROM ordenes_compra;

-- 40. Proveedores Nestlé
SELECT * FROM proveedores WHERE razon_social LIKE '%Nestlé%';

-- 41. Top 5 productos con mayor stock
SELECT TOP 5 * FROM almacen_stock ORDER BY cantidad_disponible DESC;

-- 42. Órdenes en estado Recibido
SELECT * FROM ordenes_compra WHERE estado_entrega = 'Recibido';

-- 43. Longitud de razón social
SELECT razon_social, LEN(razon_social) AS longitud FROM proveedores;

-- 44. Órdenes por proveedor
SELECT id_proveedor, COUNT(*) AS total_ordenes FROM ordenes_compra GROUP BY id_proveedor;

-- 45. Stock con caducidad este mes
SELECT * FROM almacen_stock
WHERE MONTH(fecha_caducidad_proxima) = MONTH(GETDATE())
AND YEAR(fecha_caducidad_proxima) = YEAR(GETDATE());

-- 46. Órdenes del año pasado
SELECT * FROM ordenes_compra WHERE YEAR(fecha_orden) = YEAR(GETDATE()) - 1;

-- 47. Estados de entrega distintos
SELECT DISTINCT estado_entrega FROM ordenes_compra;

-- 48. Stock ordenado de menor a mayor
SELECT * FROM almacen_stock ORDER BY cantidad_disponible ASC;

-- 49. Proveedores en mayúsculas
SELECT UPPER(razon_social) AS razon_social_mayus FROM proveedores;

-- 50. Órdenes con IVA 16%
SELECT id_orden, monto_total, monto_total * 1.16 AS monto_con_iva FROM ordenes_compra;

-- 51. Proveedores con más de 2 órdenes
SELECT id_proveedor, COUNT(*) AS total FROM ordenes_compra GROUP BY id_proveedor HAVING COUNT(*) > 2;

-- 52. Stock total por proveedor
SELECT id_proveedor, SUM(cantidad_disponible) AS total_stock FROM almacen_stock GROUP BY id_proveedor;

-- 53. Proveedores con al menos una orden
SELECT * FROM proveedores WHERE id_proveedor IN (SELECT DISTINCT id_proveedor FROM ordenes_compra);

-- 54. Proveedores sin órdenes
SELECT * FROM proveedores WHERE id_proveedor NOT IN (SELECT DISTINCT id_proveedor FROM ordenes_compra);

-- 55. Stock por debajo del promedio
SELECT * FROM almacen_stock WHERE cantidad_disponible < (SELECT AVG(cantidad_disponible) FROM almacen_stock);

-- 56. Primeros 3 caracteres del RFC
SELECT razon_social, SUBSTRING(rfc_proveedor, 1, 3) AS inicio_rfc FROM proveedores;

-- 57. IDs de productos distintos en bodega
SELECT COUNT(DISTINCT id_producto_ref) AS productos_distintos FROM almacen_stock;

-- 58. Lotes en 0
SELECT * FROM almacen_stock WHERE cantidad_disponible = 0;

-- 59. Suma de órdenes pendientes
SELECT SUM(monto_total) AS total_pendiente FROM ordenes_compra WHERE estado_entrega = 'Pendiente';

-- 60. Proveedores con RFC que termina en 'A'
SELECT * FROM proveedores WHERE rfc_proveedor LIKE '%A';

-- 10 JOINs SQL Server

-- JOIN 11: ID producto, stock y razón social
SELECT s.id_producto_ref, s.cantidad_disponible, p.razon_social
FROM almacen_stock s
INNER JOIN proveedores p ON s.id_proveedor = p.id_proveedor;

-- JOIN 12: Proveedores y total de stock surtido
SELECT p.id_proveedor, p.razon_social, COALESCE(SUM(s.cantidad_disponible), 0) AS total_surtido
FROM proveedores p
LEFT JOIN almacen_stock s ON p.id_proveedor = s.id_proveedor
GROUP BY p.id_proveedor, p.razon_social;

-- JOIN 13: Órdenes pendientes con proveedor
SELECT o.id_orden, o.fecha_orden, o.monto_total, p.razon_social
FROM ordenes_compra o
INNER JOIN proveedores p ON o.id_proveedor = p.id_proveedor
WHERE o.estado_entrega = 'Pendiente';

-- JOIN 14: Proveedores sin stock
SELECT p.id_proveedor, p.razon_social
FROM proveedores p
LEFT JOIN almacen_stock s ON p.id_proveedor = s.id_proveedor
WHERE s.id_stock IS NULL;

-- JOIN 15: Órdenes por proveedor
SELECT p.razon_social, COUNT(o.id_orden) AS total_ordenes
FROM proveedores p
LEFT JOIN ordenes_compra o ON p.id_proveedor = o.id_proveedor
GROUP BY p.razon_social;

-- JOIN 16: Estado de orden y días de crédito
SELECT o.id_orden, o.estado_entrega, p.dias_credito
FROM ordenes_compra o
INNER JOIN proveedores p ON o.id_proveedor = p.id_proveedor;

-- JOIN 17: Lotes por proveedor (RIGHT JOIN)
SELECT p.razon_social, COUNT(s.id_stock) AS total_lotes
FROM almacen_stock s
RIGHT JOIN proveedores p ON s.id_proveedor = p.id_proveedor
GROUP BY p.razon_social;

-- JOIN 18: Stock caducado con proveedor
SELECT s.id_stock, s.fecha_caducidad_proxima, p.razon_social
FROM almacen_stock s
INNER JOIN proveedores p ON s.id_proveedor = p.id_proveedor
WHERE s.fecha_caducidad_proxima < GETDATE();

-- JOIN 19: Proveedores RFC con 'C' y su stock
SELECT p.razon_social, p.rfc_proveedor, s.cantidad_disponible
FROM proveedores p
INNER JOIN almacen_stock s ON p.id_proveedor = s.id_proveedor
WHERE p.rfc_proveedor LIKE 'C%';

-- JOIN 20: Proveedores sin órdenes
SELECT p.id_proveedor, p.razon_social
FROM proveedores p
LEFT JOIN ordenes_compra o ON p.id_proveedor = o.id_proveedor
WHERE o.id_orden IS NULL;
