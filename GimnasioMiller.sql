-- Creación de la base de datos
CREATE DATABASE Gimnasio;
USE Gimnasio;

-- Tabla de Planes
CREATE TABLE Planes (
    id_plan INT PRIMARY KEY,
    tipo VARCHAR(50) NOT NULL,
    precio DECIMAL(10,2) NOT NULL,
    duracion_meses INT NOT NULL
);

-- Tabla de Clientes
CREATE TABLE Clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefono VARCHAR(15),
    fecha_registro DATE NOT NULL,
    id_plan INT,
    FOREIGN KEY (id_plan) REFERENCES Planes(id_plan)
);

-- Tabla de Entrenadores
CREATE TABLE Entrenadores (
    id_entrenador INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    especialidad VARCHAR(100),
    telefono VARCHAR(15),
    email VARCHAR(100) UNIQUE
);

-- Tabla de Clases
CREATE TABLE Clases (
    id_clase INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    horario TIME NOT NULL,
    id_entrenador INT,
    FOREIGN KEY (id_entrenador) REFERENCES Entrenadores(id_entrenador)
);

-- Tabla de Pagos
CREATE TABLE Pagos (
    id_pago INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT,
    monto DECIMAL(10,2) NOT NULL,
    fecha_pago DATE NOT NULL,
    FOREIGN KEY (id_cliente) REFERENCES Clientes(id_cliente)
);

-- Tabla de Asistencias
CREATE TABLE Asistencias (
    id_asistencia INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT NOT NULL,
    id_clase INT NOT NULL,
    fecha_asistencia DATE NOT NULL DEFAULT (CURRENT_DATE),
    FOREIGN KEY (id_cliente) REFERENCES Clientes(id_cliente) ON DELETE CASCADE,
    FOREIGN KEY (id_clase) REFERENCES Clases(id_clase) ON DELETE CASCADE
);



-- 1 VISTAS

-- 1.1 Vista Clientes Activos
CREATE OR REPLACE VIEW clientes_activos AS
SELECT c.id_cliente, c.nombre, c.email, c.telefono, pl.tipo AS tipo_plan
FROM Clientes c
JOIN Planes pl ON c.id_plan = pl.id_plan
WHERE pl.duracion_meses > 0;

SELECT * FROM clientes_activos;

-- 1.2 Vista Asistencia por Clase
CREATE OR REPLACE VIEW asistencia_por_clase AS
SELECT cl.id_clase, cl.nombre AS nombre_clase, COUNT(a.id_cliente) AS total_asistencias
FROM Clases cl
LEFT JOIN Asistencias a ON cl.id_clase = a.id_clase
GROUP BY cl.id_clase, cl.nombre;

SELECT * FROM asistencia_por_clase;



-- 2 FUNCIONES

-- 2.1 Función para saber qué plan tiene un cliente en específico ingresando su id_cliente
DELIMITER $$
CREATE FUNCTION obtener_plan_cliente(p_id_cliente INT) 
RETURNS VARCHAR(50) DETERMINISTIC
BEGIN
    DECLARE v_tipo VARCHAR(50);

    SELECT p.tipo
    INTO v_tipo
    FROM Clientes c
    JOIN Planes p ON c.id_plan = p.id_plan
    WHERE c.id_cliente = p_id_cliente
    LIMIT 1;

    RETURN v_tipo;
END $$
DELIMITER ;

SELECT obtener_plan_cliente(1);


-- 2.2 Función para contar la cantidad de clientes por ID de plan
DELIMITER $$
CREATE FUNCTION cantidad_clientes_por_plan(p_id_plan INT) 
RETURNS INT DETERMINISTIC
BEGIN
    DECLARE v_cantidad INT DEFAULT 0;

    SELECT COUNT(*) 
    INTO v_cantidad
    FROM Clientes 
    WHERE id_plan = p_id_plan;

    RETURN v_cantidad;
END $$

DELIMITER ;

SELECT cantidad_clientes_por_plan(2);


-- 2.3 Función para calcular total de ingresos en un periodo de tiempo
DELIMITER $$
CREATE FUNCTION total_ingresos(fecha_inicio DATE, fecha_fin DATE) 
RETURNS DECIMAL(10,2) DETERMINISTIC
BEGIN
    DECLARE total DECIMAL(10,2);
    SELECT IFNULL(SUM(monto), 0) INTO total FROM Pagos 
    WHERE fecha_pago BETWEEN fecha_inicio AND fecha_fin;
    RETURN total;
END $$

DELIMITER ;

SELECT total_ingresos('2025-01-21', NOW());


-- 3 STORED PROCEDURES

-- 3.1 Stored Procedure para registrar pagos nuevos
DELIMITER $$
CREATE PROCEDURE sp_registrar_pagos(IN id_cliente INT, IN monto DECIMAL(10,2), IN fecha_pago DATE)
BEGIN
    INSERT INTO Pagos (id_cliente, monto, fecha_pago) VALUES (id_cliente, monto, fecha_pago);
END $$
DELIMITER ;

call sp_registrar_pagos(2, 500000.00, '2025-03-02');


-- 3.2 Stored Procedure para registrar asistencias
DELIMITER $$
CREATE PROCEDURE sp_registrar_asistencia(
    IN p_id_cliente INT,
    IN p_id_clase INT,
    IN p_fecha_asistencia DATE
)
BEGIN
    -- Verificar si el cliente existe
    IF NOT EXISTS (SELECT 1 FROM Clientes WHERE id_cliente = p_id_cliente) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Cliente no encontrado';
    END IF;
    
    -- Verificar si la clase existe
    IF NOT EXISTS (SELECT 1 FROM Clases WHERE id_clase = p_id_clase) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: Clase no encontrada';
    END IF;

    -- Insertar la asistencia en la tabla
    INSERT INTO Asistencias (id_cliente, id_clase, fecha_asistencia)
    VALUES (p_id_cliente, p_id_clase, p_fecha_asistencia);
END $$

DELIMITER ;

call sp_registrar_asistencia(2, 3, CURDATE());

-- 4 TRIGGERS

-- 4.1 Trigger para registrar logs de asistencias
-- Creación de la tabla para los logs
CREATE TABLE IF NOT EXISTS logs_asistencias (
    id_log INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT,
    id_clase INT,
    fecha_asistencia DATE,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    mensaje VARCHAR(255)
);

-- Creación del trigger after insert para las asistencias
DELIMITER $$
CREATE TRIGGER after_insert_asistencia
AFTER INSERT ON asistencias
FOR EACH ROW
BEGIN
    INSERT INTO logs_asistencias (id_cliente, id_clase, fecha_asistencia, mensaje)
    VALUES (NEW.id_cliente, NEW.id_clase, NEW.fecha_asistencia, 'Nueva asistencia registrada');
END $$

DELIMITER ;



-- 5 INSERCIÓN DE DATOS PARA LAS TABLAS
INSERT INTO Planes (id_plan, tipo, duracion_meses, precio) VALUES
(1, 'Mensual', 1, 30000.00),
(2, 'Trimestral', 3, 85000.00),
(3, 'Semestral', 6, 150000.00),
(4, 'Anual', 12, 280000.00),
(5, 'Expirado', 0, 0);

INSERT INTO Clientes (id_cliente, nombre, email, telefono, fecha_registro, id_plan) VALUES
(1, 'Juan Pérez', 'juan.perez@gmail.com', '3513837458','2025-02-01', 1),
(2, 'María González', 'maria.gonzalez@gmail.com', '3513933882','2024-12-20', 2),
(3, 'Pedro Alvarado', 'pedro.alvarado@gmail.com', '3517643215','2024-07-04', 4),
(4, 'Matías Cetreno', 'matias.cetreno@gmail.com', '3518722556','2024-09-11', 3),
(5, 'Ignacio Miller', 'ignacio.miller@gmail.com', '3514944857','2023-04-30', 5);

INSERT INTO Pagos (id_pago, id_cliente, monto, fecha_pago) VALUES
(1, 3, 280000.00, '2024-09-04'),
(2, 2, 85000.00, '2025-01-20');

INSERT INTO Clases (id_clase, nombre, horario) VALUES
(1, 'Yoga', '08:00:00'),
(2, 'Crossfit', '18:00:00'),
(3, 'Musculación', '12:00:00');

INSERT INTO Asistencias (id_cliente, id_clase, fecha_asistencia) VALUES
(1, 1, '2025-02-20'),
(2, 2, '2025-02-21'),
(3, 3, '2025-02-22'),
(2, 3, '2025-02-19');

INSERT INTO Entrenadores (nombre, especialidad, telefono, email) VALUES
('Carlos Mendoza', 'Crossfit', '3511234567', 'carlos.mendoza@gmail.com'),
('Lucía Fernández', 'Yoga', '3512345678', 'lucia.fernandez@gmail.com'),
('Javier Torres', 'Musculación', '3515678901', 'javier.torres@gmail.com');