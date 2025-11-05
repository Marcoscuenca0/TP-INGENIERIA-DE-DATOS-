-- create database HotelBahiaSerena;
CREATE DATABASE HotelBahiaSerena;

use HotelBahiaSerena;

CREATE TABLE CLIENTE (
  id_cliente       INT IDENTITY(1,1) PRIMARY KEY,
  nombre           NVARCHAR(60)  NOT NULL,
  apellido         NVARCHAR(60)  NOT NULL,
  email            NVARCHAR(120) NOT NULL,
  telefono         NVARCHAR(40)  NULL,
  doc_tipo         NVARCHAR(15)  NOT NULL,
  doc_nro          NVARCHAR(30)  NOT NULL,
  estado           VARCHAR(10)   NOT NULL
                CHECK (estado IN ('Activo','Inactivo')),
);
GO

-- Categotias
CREATE TABLE CATEGORIA (
  id_categoria   INT IDENTITY(1,1) PRIMARY KEY,
  categoria      NVARCHAR(40) NOT NULL,      -- Estandar / Superior / Suite
  capacidad      INT NOT NULL CHECK (capacidad > 0)
);
GO

-- Habitaciones
CREATE TABLE HABITACION (
  id_hab        INT IDENTITY(1,1) PRIMARY KEY,
  codigo_unico  NVARCHAR(30) NOT NULL,
  id_categoria  INT NOT NULL,
  piso          INT NOT NULL,
  vista         NVARCHAR(20) NOT NULL,       -- Mar/Jardin/Interna...
  estado        VARCHAR(15)  NOT NULL
               CHECK (estado IN ('Disponible','FueraServicio','Inactiva')),
  CONSTRAINT FK_HAB_categoria
    FOREIGN KEY (id_categoria) REFERENCES CATEGORIA(id_categoria)
);
GO

-- Mantenimiento
CREATE TABLE MANTENIMIENTO (
  id_mant     INT IDENTITY(1,1) PRIMARY KEY,
  id_hab      INT NOT NULL,
  fecha_ini   DATETIME2(0) NOT NULL,
  fecha_fin   DATETIME2(0) NULL,
  motivo      NVARCHAR(120) NOT NULL,
  estado      VARCHAR(12) NOT NULL
            CHECK (estado IN ('Programado','EnCurso','Cerrado')),
  CONSTRAINT FK_MANT_hab
    FOREIGN KEY (id_hab) REFERENCES HABITACION(id_hab)
);
GO

-- Temporada
CREATE TABLE TEMPORADA (
  id_temp      INT IDENTITY(1,1) PRIMARY KEY,
  nombre       NVARCHAR(30) NOT NULL,    -- Alta / Media / Baja
  fecha_desde  DATE NOT NULL,
  fecha_hasta  DATE NOT NULL,
  CONSTRAINT CK_TEMPORADA_rango CHECK (fecha_desde <= fecha_hasta)
);
GO

-- Tarifa por Temporada y Categoria
CREATE TABLE TARIFA_CAT_TEMP (
  id_tarifa     INT IDENTITY(1,1) PRIMARY KEY,
  id_categoria  INT NOT NULL,
  id_temp       INT NOT NULL,
  precio_noche  DECIMAL(12,2) NOT NULL CHECK (precio_noche >= 0),
  CONSTRAINT FK_TARIFA_cat  FOREIGN KEY (id_categoria) REFERENCES CATEGORIA(id_categoria),
  CONSTRAINT FK_TARIFA_temp FOREIGN KEY (id_temp)      REFERENCES TEMPORADA(id_temp),
  CONSTRAINT UQ_TARIFA_cat_temp UNIQUE (id_categoria, id_temp)
);
GO

-- Sercios Adicionales 
CREATE TABLE SERVICIO (
  id_servicio   INT IDENTITY(1,1) PRIMARY KEY,
  nombre        NVARCHAR(60) NOT NULL,
  descripcion   NVARCHAR(200) NULL,
  costo         DECIMAL(12,2) NOT NULL CHECK (costo >= 0),
  precio        DECIMAL(12,2) NOT NULL CHECK (precio >= 0),
  activo        BIT NOT NULL DEFAULT (1)
);
GO

-- Cupo de Servicios por Dia
CREATE TABLE CUPO_SERVICIO_DIA (
  id_cupo      INT IDENTITY(1,1) PRIMARY KEY,
  id_servicio  INT NOT NULL,
  fecha        DATE NOT NULL,
  cupo_max     INT  NOT NULL CHECK (cupo_max >= 0),
  CONSTRAINT FK_CUPO_serv  FOREIGN KEY (id_servicio) REFERENCES SERVICIO(id_servicio),
);
GO

-- Reserva
CREATE TABLE RESERVA (
  id_reserva              INT IDENTITY(1,1) PRIMARY KEY,
  id_cliente              INT NOT NULL,
  id_hab                  INT NOT NULL,
  fecha_reserva           DATETIME2(0) NOT NULL,
  check_in                DATE NOT NULL,
  check_out               DATE NOT NULL,
  precio_noche_aplicado   DECIMAL(12,2) NOT NULL CHECK (precio_noche_aplicado >= 0),
  noches                  INT NOT NULL CHECK (noches >= 0),         -- derivable
  subtotal_habitacion     DECIMAL(12,2) NOT NULL DEFAULT (0),       -- derivable
  total                   DECIMAL(12,2) NOT NULL DEFAULT (0),
  estado                  VARCHAR(12) NOT NULL
                        CHECK (estado IN ('Activa','Cancelada','NoShow','Finalizada')),
  estado_pago             VARCHAR(10) NOT NULL DEFAULT ('Pendiente')
                        CHECK (estado_pago IN ('Pendiente','Parcial','Pagado','Cancelado')),
  saldo                   DECIMAL(12,2) NOT NULL DEFAULT (0),
  CONSTRAINT CK_RESERVA_fechas CHECK (check_in <= check_out),
  CONSTRAINT FK_RESERVA_cli FOREIGN KEY (id_cliente) REFERENCES CLIENTE(id_cliente),
  CONSTRAINT FK_RESERVA_hab FOREIGN KEY (id_hab)     REFERENCES HABITACION(id_hab)
);
GO

-- Tabla intermedia entre Reserva y Servicio
CREATE TABLE RESERVA_SERVICIO (
  id_reserva            INT NOT NULL,
  id_servicio           INT NOT NULL,
  fecha                 DATE NOT NULL,
  cantidad              INT NOT NULL CHECK (cantidad > 0),
  precio_unit_aplicado  DECIMAL(12,2) NOT NULL CHECK (precio_unit_aplicado >= 0),
  subtotal              DECIMAL(12,2) NOT NULL,
  CONSTRAINT PK_RESERVA_SERVICIO PRIMARY KEY (id_reserva, id_servicio, fecha),
  CONSTRAINT FK_RS_res  FOREIGN KEY (id_reserva)  REFERENCES RESERVA(id_reserva),
  CONSTRAINT FK_RS_srv  FOREIGN KEY (id_servicio) REFERENCES SERVICIO(id_servicio)
);
GO

-- Medios de Pago
CREATE TABLE dbo.MEDIO_PAGO (
  id_medio       INT IDENTITY(1,1) PRIMARY KEY,
  nombre         NVARCHAR(40) NOT NULL,     -- Efectivo/Tarjeta/Transferencia
);
GO

-- Pago
CREATE TABLE PAGO (
  id_pago        INT IDENTITY(1,1) PRIMARY KEY,
  id_reserva     INT NOT NULL,
  id_medio       INT NOT NULL,
  fecha          DATETIME2(0) NOT NULL,
  monto          DECIMAL(12,2) NOT NULL CHECK (monto <> 0),
  moneda         CHAR(3) NOT NULL DEFAULT ('ARS'),
  estado         VARCHAR(10) NOT NULL
                 CHECK (estado IN ('Pendiente','Aprobado','Rechazado')),
  CONSTRAINT FK_PAGO_res   FOREIGN KEY (id_reserva) REFERENCES RESERVA(id_reserva),
  CONSTRAINT FK_PAGO_medio FOREIGN KEY (id_medio)   REFERENCES MEDIO_PAGO(id_medio)
);
GO


USE HotelBahiaSerena;
GO

-- CLIENTES
INSERT INTO dbo.CLIENTE (nombre, apellido, email, telefono, doc_tipo, doc_nro, estado)
VALUES 
('Ana',  'García',  'ana.garcia@mail.com',  '1155550001', 'DNI', '30111222', 'Activo'),
('Bruno','Pérez',   'bruno.perez@mail.com', '1155550002', 'DNI', '28999888', 'Activo'),
('Carla','López',   'carla.lopez@mail.com', '1155550003', 'DNI', '27666111', 'Inactivo');

-- CATEGORÍAS
INSERT INTO dbo.CATEGORIA (categoria, capacidad)
VALUES 
('Estandar', 2),
('Superior', 3),
('Suite',    4);

-- HABITACIONES (una fuera de servicio para probar)
INSERT INTO dbo.HABITACION (codigo_unico, id_categoria, piso, vista, estado)
VALUES
('101A', 1, 1, 'Mar',     'Disponible'),
('102B', 1, 1, 'Jardin',  'Disponible'),
('201C', 2, 2, 'Interna', 'Disponible'),
('202D', 2, 2, 'Mar',     'Disponible'),
('301E', 3, 3, 'Mar',     'FueraServicio');

-- TEMPORADAS (ajustadas para cubrir noviembre/diciembre 2025)
INSERT INTO dbo.TEMPORADA (nombre, fecha_desde, fecha_hasta)
VALUES
('Alta',  '2025-12-15', '2026-02-28'),
('Media', '2025-11-01', '2025-12-14'),
('Baja',  '2025-03-01', '2025-10-31');

-- TARIFAS por CATEGORÍA y TEMPORADA (simples)
-- Estandar
INSERT INTO dbo.TARIFA_CAT_TEMP (id_categoria, id_temp, precio_noche)
SELECT 1, id_temp, CASE nombre WHEN 'Alta' THEN 90000 WHEN 'Media' THEN 70000 ELSE 50000 END
FROM dbo.TEMPORADA;

-- Superior
INSERT INTO dbo.TARIFA_CAT_TEMP (id_categoria, id_temp, precio_noche)
SELECT 2, id_temp, CASE nombre WHEN 'Alta' THEN 120000 WHEN 'Media' THEN 95000 ELSE 75000 END
FROM dbo.TEMPORADA;

-- Suite
INSERT INTO dbo.TARIFA_CAT_TEMP (id_categoria, id_temp, precio_noche)
SELECT 3, id_temp, CASE nombre WHEN 'Alta' THEN 180000 WHEN 'Media' THEN 140000 ELSE 110000 END
FROM dbo.TEMPORADA;

-- SERVICIOS
INSERT INTO dbo.SERVICIO (nombre, descripcion, costo, precio, activo)
VALUES
('Spa',           'Acceso al circuito de aguas', 15000, 30000, 1),
('Traslado',      'Aeropuerto-Hotel',             8000,  15000, 1),
('Desayuno',      'Desayuno buffet',              3000,   6000, 1),
('Late Check-out','Extensión hasta 18hs',        10000,  20000, 1);

-- CUPO por día (ejemplos)
-- Spa: 10 cupos el 2025-11-10 y 2025-11-11
INSERT INTO dbo.CUPO_SERVICIO_DIA (id_servicio, fecha, cupo_max)
SELECT id_servicio, '2025-11-10', 10 FROM dbo.SERVICIO WHERE nombre='Spa';
INSERT INTO dbo.CUPO_SERVICIO_DIA (id_servicio, fecha, cupo_max)
SELECT id_servicio, '2025-11-11', 10 FROM dbo.SERVICIO WHERE nombre='Spa';

-- Desayuno suele ser amplio (50)
INSERT INTO dbo.CUPO_SERVICIO_DIA (id_servicio, fecha, cupo_max)
SELECT id_servicio, '2025-11-10', 50 FROM dbo.SERVICIO WHERE nombre='Desayuno';

-- MEDIOS DE PAGO
INSERT INTO dbo.MEDIO_PAGO (nombre)
VALUES ('Efectivo'), ('Tarjeta'), ('Transferencia');

--TRIGGER EVITA CREAR NUEVOS DUPLICADOS
GO
CREATE TRIGGER trg_RESERVA
ON dbo.RESERVA
AFTER INSERT
AS
BEGIN
	IF EXISTS (
	SELECT 1
	FROM inserted i
	JOIN dbo.RESERVA r
	ON r.id_cliente = i.id_cliente
	AND r.id_hab = i.id_hab
	AND r.check_in = i.check_in
	AND r.id_reserva <> i.id_reserva
	)
	BEGIN
		RAISERROR ('Error de duplicados', 16,1);
		ROLLBACK TRANSACTION;
	END
END;
GO

--TRIGGER EVITA CREAR DUPLICADOS POR EDICION
GO
CREATE TRIGGER trg_RESERVA2
ON dbo.RESERVA
AFTER UPDATE
AS
BEGIN
	IF EXISTS (
	SELECT 1
	FROM inserted i
	JOIN dbo.RESERVA r
	ON r.id_cliente = i.id_cliente
	AND r.id_hab = i.id_hab
	AND r.check_in = i.check_in
	AND r.id_reserva <> i.id_reserva
	)
	BEGIN
		RAISERROR ('Error de duplicados', 16,1);
		ROLLBACK TRANSACTION;
	END
END;
GO

