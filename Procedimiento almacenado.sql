USE HotelBahiaSerena;
GO

-- Crear o modificar el procedimiento
CREATE OR ALTER PROCEDURE RegistrarReserva
-- Datos solicitados
    @id_cliente INT,
    @id_hab INT,
    @check_in DATE,
    @check_out DATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE 
    -- Datos intermedios
        @estado_cliente VARCHAR(15),
        @estado_hab VARCHAR(15),
        @id_categoria INT,
        @id_temp INT,
        @precio_noche DECIMAL(12,2),
        @noches INT,
        @subtotal DECIMAL(12,2);

    -- Checkear existencia del cliente o que este activo
    SELECT @estado_cliente = estado
    FROM CLIENTE
    WHERE id_cliente = @id_cliente;

    IF @estado_cliente IS NULL
    BEGIN
        PRINT 'Error: el cliente no existe';
        RETURN;
    END;

    IF @estado_cliente <> 'Activo'
    BEGIN
        PRINT 'Error: el cliente no está activo.';
        RETURN;
    END;

    -- Ver que la habitación exista
    SELECT @estado_hab = estado, @id_categoria = id_categoria
    FROM HABITACION
    WHERE id_hab = @id_hab;

    IF @estado_hab IS NULL
    BEGIN
        PRINT 'Error: la habitación no existe.';
        RETURN;
    END;

    -- Ver si la habitación esta disponible
    IF @estado_hab <> 'Disponible'
    BEGIN
        PRINT 'Error: la habitación no está disponible.';
        RETURN;
    END;

    -- Evitar que la reserva se duplique
    IF EXISTS (
        SELECT 1 
        FROM RESERVA
        WHERE id_cliente = @id_cliente
          AND id_hab = @id_hab
          AND check_in = @check_in
    ) -- Busca una reserva que cumpla las mismas caracteristicas (id cliente, id de habitacion y fecha de check-in)
    BEGIN
        PRINT 'Error: la reserva ya existe y no fue creada para evitar duplicadas.';
        RETURN;
    END;

    -- Revisa que exista una temporada valida para poder calcular más tarde el valor de la reserva.
    SELECT TOP 1 @id_temp = id_temp
    FROM TEMPORADA
    WHERE @check_in BETWEEN fecha_desde AND fecha_hasta;

    IF @id_temp IS NULL
    BEGIN
        PRINT 'Error: no existe temporada valida para esa fecha.';
        RETURN;
    END;

    -- Revisar y buscar la tarifa que aplica a la categoria de habitación y la temporada de la reserva.
    SELECT TOP 1 @precio_noche = precio_noche
    FROM TARIFA_CAT_TEMP
    WHERE id_categoria = @id_categoria AND id_temp = @id_temp;

    IF @precio_noche IS NULL
    BEGIN
        PRINT 'Error: no existe tarifa para esa categoría en la temporada.';
        RETURN;
    END;

    -- Calcular noches y subtotal
    SET @noches = DATEDIFF(DAY, @check_in, @check_out);
    SET @subtotal = @precio_noche * @noches;

    -- Insertar en la tabla reserva una nueva fila con los datos proporcionados
    INSERT INTO RESERVA (
        id_cliente, id_hab, fecha_reserva, check_in, check_out,
        precio_noche_aplicado, noches, subtotal_habitacion, total, estado
    ) -- Datos que van en una reserva
    VALUES (
        @id_cliente, @id_hab, SYSDATETIME(), @check_in, @check_out,
        @precio_noche, @noches, @subtotal, @subtotal, 'Activa'
    ); -- Datos tomados que iran en la tabla

    -- Actualizar habitación para que no aparezca disponible
    UPDATE HABITACION
    SET estado = 'FueraServicio'
    WHERE id_hab = @id_hab;

    PRINT 'Reserva registrada correctamente.';
END;
GO