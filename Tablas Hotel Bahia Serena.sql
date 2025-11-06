
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
                CHECK (estado IN ('Activo','Inactivo'))
);
GO

-- Categorias
CREATE TABLE CATEGORIA (
  id_categoria   INT IDENTITY(1,1) PRIMARY KEY,
  categoria      NVARCHAR(40) NOT NULL      -- Estandar / Superior / Suite
  
);
GO

-- Habitaciones
CREATE TABLE HABITACION (
  id_hab        INT IDENTITY(1,1) PRIMARY KEY,
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
  temporada       NVARCHAR(30) NOT NULL,    -- Alta / Media / Baja
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
  tarifa_noche  DECIMAL(12,2) NOT NULL CHECK (tarifa_noche >= 0),

  CONSTRAINT FK_TARIFA_cat  FOREIGN KEY (id_categoria) REFERENCES CATEGORIA(id_categoria),
  CONSTRAINT FK_TARIFA_temp FOREIGN KEY (id_temp)      REFERENCES TEMPORADA(id_temp),
  CONSTRAINT UQ_TARIFA_cat_temp UNIQUE (id_categoria, id_temp)
);
GO

--Servicios adicionales
CREATE TABLE SERVICIO (
  id_servicio   INT IDENTITY(1,1) PRIMARY KEY,
  servicio      NVARCHAR(60) NOT NULL,
  costo         DECIMAL(12,2) NOT NULL CHECK (costo >= 0),
  precio        DECIMAL(12,2) NOT NULL CHECK (precio >= 0),
  cupo_diario   INT NOT NULL CHECK (cupo_diario >= 0),
  activo        BIT NOT NULL DEFAULT (1)
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


-- Tabla CUPO_SERVICIO_DIA
CREATE TABLE CUPO_SERVICIO_DIA (
  id_cupo_servicio_reserva INT IDENTITY(1,1) PRIMARY KEY,
  id_reserva   INT NOT NULL,
  id_servicio  INT NOT NULL,
  CONSTRAINT FK_CUPO_reserva FOREIGN KEY (id_reserva) REFERENCES RESERVA(id_reserva),
  CONSTRAINT FK_CUPO_servicio FOREIGN KEY (id_servicio) REFERENCES SERVICIO(id_servicio)
);
GO

CREATE TABLE RESERVA_HABITACION (
  id_res_hab INT IDENTITY(1,1) PRIMARY KEY,
  id_reserva INT NOT NULL,
  id_hab INT NOT NULL,
  fecha_checkin DATE NOT NULL,
  fecha_checkout DATE NOT NULL,
  precio_noche DECIMAL(12,2) NOT NULL CHECK (precio_noche >= 0),
  noches INT NOT NULL CHECK (noches >= 0),
  subtotal DECIMAL(12,2) NOT NULL CHECK (subtotal >= 0),
  CONSTRAINT FK_RESHAB_reserva FOREIGN KEY (id_reserva) REFERENCES RESERVA(id_reserva),
  CONSTRAINT FK_RESHAB_hab FOREIGN KEY (id_hab) REFERENCES HABITACION(id_hab)
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

CREATE TABLE FACTURA (
  id_factura INT IDENTITY(1,1) PRIMARY KEY,
  id_reserva INT NULL,
  id_cliente_factura INT NOT NULL,
  fecha_emision DATETIME2(0) NOT NULL DEFAULT (SYSUTCDATETIME()),
  nro_comprobante NVARCHAR(30) NOT NULL,
  moneda CHAR(3) NOT NULL DEFAULT ('ARS'),
  total_facturado DECIMAL(12,2) NOT NULL CHECK (total_facturado >= 0),
  estado VARCHAR(20) NOT NULL CHECK (estado IN ('Borrador','Emitida','Anulada','PagadaParcial','PagadaTotal')),
  CONSTRAINT FK_FACTURA_reserva FOREIGN KEY (id_reserva) REFERENCES RESERVA(id_reserva),
  CONSTRAINT FK_FACTURA_cliente FOREIGN KEY (id_cliente_factura) REFERENCES CLIENTE(id_cliente),
  CONSTRAINT UQ_FACTURA_nro UNIQUE (nro_comprobante)
);
GO

CREATE TABLE FACTURA_DETALLE (
  id_detalle INT IDENTITY(1,1) PRIMARY KEY,
  id_factura INT NOT NULL,
  id_reserva INT NULL,
  id_res_hab INT NULL,
  id_servicio INT NULL,
  descripcion NVARCHAR(200) NOT NULL,
  cantidad INT NOT NULL CHECK (cantidad > 0),
  precio_unit DECIMAL(12,2) NOT NULL CHECK (precio_unit >= 0),
  subtotal AS (CAST(cantidad AS DECIMAL(12,2)) * precio_unit) PERSISTED,
  CONSTRAINT FK_DET_factura FOREIGN KEY (id_factura) REFERENCES FACTURA(id_factura),
  CONSTRAINT FK_DET_reserva FOREIGN KEY (id_reserva) REFERENCES RESERVA(id_reserva),
  CONSTRAINT FK_DET_reshab FOREIGN KEY (id_res_hab) REFERENCES RESERVA_HABITACION(id_res_hab),
  CONSTRAINT FK_DET_servicio FOREIGN KEY (id_servicio) REFERENCES SERVICIO(id_servicio)
);
GO

CREATE TABLE ALERTA (
  id_alerta INT IDENTITY(1,1) PRIMARY KEY,
  id_hab INT NOT NULL,
  fecha_alerta DATETIME DEFAULT(GETDATE()),
  estado NVARCHAR(15),
  mensaje NVARCHAR(200),
  CONSTRAINT FK_ALERTA_hab FOREIGN KEY (id_hab) REFERENCES HABITACION(id_hab)
);
GO


USE HotelBahiaSerena;
GO

-- CLIENTES
INSERT INTO CLIENTE (nombre, apellido, email, telefono, doc_tipo, doc_nro, estado)
VALUES 
('Ana',  'Garcia',  'ana.garcia@mail.com',  '1155550001', 'DNI', '30111222', 'Activo'),
('Bruno','Perez',   'bruno.perez@mail.com', '1155550002', 'DNI', '28999888', 'Activo'),
('Carla','Lopez',   'carla.lopez@mail.com', '1155550003', 'DNI', '27666111', 'Inactivo');

-- CATEGORIAS
INSERT INTO CATEGORIA (categoria)
VALUES 
('Estandar'),
('Superior'),
('Suite');

-- HABITACIONES (una fuera de servicio para probar)
INSERT INTO HABITACION (id_categoria, piso, vista, estado)
VALUES
( 1, 1, 'Mar',     'Disponible'),
( 1, 1, 'Jardin',  'Disponible'),
( 2, 2, 'Interna', 'Disponible'),
( 2, 2, 'Mar',     'Disponible'),
(3, 3, 'Mar',     'FueraServicio');

-- TEMPORADAS (ajustadas para cubrir noviembre/diciembre 2025)
INSERT INTO TEMPORADA (temporada, fecha_desde, fecha_hasta)
VALUES
('Alta',  '2025-12-15', '2026-02-28'),
('Media', '2025-11-01', '2025-12-14'),
('Baja',  '2025-03-01', '2025-10-31');

-- TARIFAS por CATEGORIA y TEMPORADA (simples)
-- Estandar
INSERT INTO TARIFA_CAT_TEMP (id_categoria, id_temp, tarifa_noche)
SELECT 1, id_temp, 
       CASE temporada WHEN 'Alta' THEN 90000 WHEN 'Media' THEN 70000 ELSE 50000 END
FROM TEMPORADA;

-- Superior
INSERT INTO TARIFA_CAT_TEMP (id_categoria, id_temp, tarifa_noche)
SELECT 2, id_temp,
       CASE temporada WHEN 'Alta' THEN 120000 WHEN 'Media' THEN 95000 ELSE 75000 END
FROM TEMPORADA;
-- Suite
INSERT INTO TARIFA_CAT_TEMP (id_categoria, id_temp, tarifa_noche)
SELECT 3, id_temp,
       CASE temporada WHEN 'Alta' THEN 180000 WHEN 'Media' THEN 140000 ELSE 110000 END
FROM TEMPORADA;

-- SERVICIOS
INSERT INTO SERVICIO (servicio, costo, precio, cupo_diario, activo)
VALUES
('Spa', 15000, 30000, 10, 1),
('Traslado', 8000, 15000, 20, 1),
('Desayuno', 3000, 6000, 50, 1),
('Late Check-out', 10000, 20000, 5, 1);


--TRIGGER EVITA CREAR NUEVOS DUPLICADOS
GO
CREATE TRIGGER trg_RESERVA
ON RESERVA
AFTER INSERT
AS
BEGIN
	IF EXISTS (
	SELECT 1
	FROM inserted i
	JOIN RESERVA r
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
ON RESERVA
AFTER UPDATE
AS
BEGIN
	IF EXISTS (
	SELECT 1
	FROM inserted i
	JOIN RESERVA r
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
