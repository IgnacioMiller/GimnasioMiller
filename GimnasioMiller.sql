-- Creación de la base de datos
CREATE DATABASE GimnasioMiller;
USE GimnasioMiller;

-- Tabla de planes
CREATE TABLE Planes (
    id_plan INT AUTO_INCREMENT PRIMARY KEY,
    tipo VARCHAR(50) NOT NULL,
    precio DECIMAL(10,2) NOT NULL,
    duracion_meses INT NOT NULL
);

-- Tabla de Clientes
CREATE TABLE Clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefono VARCHAR(15) NOT NULL,
    fecha_registro DATE NOT NULL,
    id_plan INT,
    FOREIGN KEY (id_plan) REFERENCES Planes(id_plan)
);

-- Tabla de Entrenadores
CREATE TABLE Entrenadores (
    id_entrenador INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    especialidad VARCHAR(20),
    telefono VARCHAR(15) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL
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
    id_cliente INT,
    id_clase INT,
    fecha DATE NOT NULL,
    FOREIGN KEY (id_cliente) REFERENCES Clientes(id_cliente),
    FOREIGN KEY (id_clase) REFERENCES Clases(id_clase)
);
