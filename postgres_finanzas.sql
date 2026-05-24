-- PostgreSQL - corporativo_finanzas_db - DDL

CREATE TABLE IF NOT EXISTS empleados_cajeros (
    num_empleado    SERIAL PRIMARY KEY,
    nombre          VARCHAR(150) NOT NULL,
    turno           VARCHAR(20) NOT NULL,
    caja_asignada   INT NOT NULL
);

CREATE TABLE IF NOT EXISTS cortes_diarios (
    id_corte            SERIAL PRIMARY KEY,
    num_empleado        INT NOT NULL,
    fecha               DATE DEFAULT CURRENT_DATE,
    monto_calculado     DECIMAL(10,2) NOT NULL,
    monto_entregado     DECIMAL(10,2) NOT NULL,
    diferencia          DECIMAL(10,2) DEFAULT 0,
    FOREIGN KEY (num_empleado) REFERENCES empleados_cajeros(num_empleado)
);

CREATE TABLE IF NOT EXISTS log_auditoria (
    id_log      SERIAL PRIMARY KEY,
    usuario     VARCHAR(100) NOT NULL,
    modulo      VARCHAR(100),
    accion      VARCHAR(50),
    fecha       TIMESTAMP DEFAULT NOW(),
    detalles    JSONB
);

-- TRIGGERS PostgreSQL

-- 11. TRG_Cortes_Inmutables
CREATE OR REPLACE FUNCTION fn_cortes_inmutables()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Los cortes de caja son inmutables y no pueden modificarse ni eliminarse.';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER TRG_Cortes_Inmutables
BEFORE UPDATE OR DELETE ON cortes_diarios
FOR EACH ROW EXECUTE FUNCTION fn_cortes_inmutables();

-- 12. TRG_Valida_JSON_Auditoria
CREATE OR REPLACE FUNCTION fn_valida_json_auditoria()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT (NEW.detalles ? 'usuario') THEN
        RAISE EXCEPTION 'El JSON de auditoría debe contener la llave "usuario".';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER TRG_Valida_JSON_Auditoria
BEFORE INSERT ON log_auditoria
FOR EACH ROW EXECUTE FUNCTION fn_valida_json_auditoria();

-- 13. TRG_Calcula_Diferencia
CREATE OR REPLACE FUNCTION fn_calcula_diferencia()
RETURNS TRIGGER AS $$
BEGIN
    NEW.diferencia := NEW.monto_entregado - NEW.monto_calculado;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER TRG_Calcula_Diferencia
BEFORE INSERT ON cortes_diarios
FOR EACH ROW EXECUTE FUNCTION fn_calcula_diferencia();

-- 14. TRG_Aviso_Faltante
CREATE OR REPLACE FUNCTION fn_aviso_faltante()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.diferencia < -500 THEN
        RAISE NOTICE 'Faltante crítico reportado a gerencia: %', NEW.diferencia;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER TRG_Aviso_Faltante
AFTER INSERT ON cortes_diarios
FOR EACH ROW EXECUTE FUNCTION fn_aviso_faltante();

-- 15. TRG_Auditoria_Intocable
CREATE OR REPLACE FUNCTION fn_auditoria_intocable()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'Los registros de auditoría financiera son inmutables por ley.';
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER TRG_Auditoria_Intocable
BEFORE DELETE ON log_auditoria
FOR EACH ROW EXECUTE FUNCTION fn_auditoria_intocable();

-- CONSULTAS PostgreSQL (61-90)

-- 61. Todos los cajeros
SELECT * FROM empleados_cajeros;

-- 62. Todos los cortes diarios
SELECT * FROM cortes_diarios;

-- 63. Todo el log de auditoría
SELECT * FROM log_auditoria;

-- 64. Total dinero entregado
SELECT SUM(monto_entregado) AS total_entregado FROM cortes_diarios;

-- 65. Diferencia promedio
SELECT AVG(diferencia) AS diferencia_promedio FROM cortes_diarios;

-- 66. Cajero de la caja 1
SELECT * FROM empleados_cajeros WHERE caja_asignada = 1;

-- 67. Registros en log de auditoría
SELECT COUNT(*) AS total_logs FROM log_auditoria;

-- 68. Cortes por empleado
SELECT num_empleado, COUNT(*) AS total_cortes FROM cortes_diarios GROUP BY num_empleado;

-- 69. Monto calculado por turno
SELECT ec.turno, SUM(cd.monto_calculado) AS total_calculado
FROM cortes_diarios cd
INNER JOIN empleados_cajeros ec ON cd.num_empleado = ec.num_empleado
GROUP BY ec.turno;

-- 70. Logs con acción DELETE
SELECT * FROM log_auditoria WHERE accion = 'DELETE';

-- 71. Valor de ip_terminal del JSON
SELECT id_log, detalles->>'ip_terminal' AS ip_terminal FROM log_auditoria;

-- 72. Cortes del día de hoy
SELECT * FROM cortes_diarios WHERE fecha = CURRENT_DATE;

-- 73. Cortes con diferencia negativa
SELECT * FROM cortes_diarios WHERE diferencia < 0;

-- 74. Cajeros del turno Vespertino
SELECT * FROM empleados_cajeros WHERE turno = 'Vespertino';

-- 75. Top 3 cortes con mayor diferencia positiva
SELECT * FROM cortes_diarios WHERE diferencia > 0 ORDER BY diferencia DESC LIMIT 3;

-- 76. Cortes por fecha
SELECT fecha, COUNT(*) AS total_cortes FROM cortes_diarios GROUP BY fecha;

-- 77. Cortes con monto entregado entre $5,000 y $15,000
SELECT * FROM cortes_diarios WHERE monto_entregado BETWEEN 5000 AND 15000;

-- 78. Logs del módulo Punto de Venta
SELECT * FROM log_auditoria WHERE modulo = 'Punto de Venta';

-- 79. Cajeros en mayúsculas
SELECT UPPER(nombre) AS nombre_mayus FROM empleados_cajeros;

-- 80. Cortes ordenados de más reciente a más antiguo
SELECT * FROM cortes_diarios ORDER BY fecha DESC;

-- 81. Cortes con diferencia exactamente $0
SELECT * FROM cortes_diarios WHERE diferencia = 0;

-- 82. Logs agrupados por módulo
SELECT modulo, COUNT(*) AS total FROM log_auditoria GROUP BY modulo;

-- 83. Corte con el faltante más fuerte
SELECT * FROM cortes_diarios WHERE diferencia = (SELECT MIN(diferencia) FROM cortes_diarios);

-- 84. Cajeros que superan el promedio de monto entregado
SELECT ec.nombre, SUM(cd.monto_entregado) AS total_entregado
FROM cortes_diarios cd
INNER JOIN empleados_cajeros ec ON cd.num_empleado = ec.num_empleado
GROUP BY ec.num_empleado, ec.nombre
HAVING SUM(cd.monto_entregado) > (SELECT AVG(monto_entregado) FROM cortes_diarios);

-- 85. Longitud del campo JSON
SELECT id_log, LENGTH(detalles::TEXT) AS longitud_json FROM log_auditoria;

-- 86. 10 logs más recientes
SELECT * FROM log_auditoria ORDER BY fecha DESC LIMIT 10;

-- 87. Empleados distintos con cortes
SELECT COUNT(DISTINCT num_empleado) AS cajeros_con_cortes FROM cortes_diarios;

-- 88. Logs del mes actual
SELECT * FROM log_auditoria WHERE EXTRACT(MONTH FROM fecha) = EXTRACT(MONTH FROM NOW())
AND EXTRACT(YEAR FROM fecha) = EXTRACT(YEAR FROM NOW());

-- 89. Suma total entregada por mes
SELECT EXTRACT(MONTH FROM fecha) AS mes, SUM(monto_entregado) AS total
FROM cortes_diarios GROUP BY mes ORDER BY mes;

-- 90. Logs con nivel crítico en JSON
SELECT * FROM log_auditoria WHERE detalles->>'nivel' = 'critico';
