use HotelBahiaSerena
go

select * from HABITACION
CREATE TABLE ALERTA (
  id_alerta INT IDENTITY(1,1) PRIMARY KEY,
  id_hab INT NOT NULL,
  fecha_alerta DATETIME DEFAULT(GETDATE()),
  estado NVARCHAR(15),
  mensaje NVARCHAR(200),
  CONSTRAINT FK_ALERTA_hab FOREIGN KEY (id_hab) REFERENCES HABITACION(id_hab)
);
GO
CREATE OR ALTER PROCEDURE GenerarAlertasHabitaciones
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @id_hab INT,
            @estado VARCHAR(15);

    -- Limpieza del cursor en caso de que exista antes
    IF CURSOR_STATUS('global','hab_cursor') >= -1
    BEGIN
        CLOSE hab_cursor;
        DEALLOCATE hab_cursor;
    END

    DECLARE hab_cursor CURSOR FOR
        SELECT id_hab, estado
        FROM HABITACION;

    OPEN hab_cursor;

    FETCH NEXT FROM hab_cursor INTO @id_hab, @estado;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF (@estado = 'FueraServicio')
        BEGIN
            -- Inserta solo si la alerta NO se registró ya
            IF NOT EXISTS (
                SELECT 1
                FROM ALERTA
                WHERE id_hab = @id_hab
                  AND estado = 'FueraServicio'
            )
            BEGIN
                INSERT INTO ALERTA (id_hab, estado, mensaje)
                VALUES (@id_hab, @estado, 'Habitación fuera de servicio detectada');
            END
        END;

        FETCH NEXT FROM hab_cursor INTO @id_hab, @estado;
    END;

    --CLOSE hab_cursor;
    --DEALLOCATE hab_cursor;
END
GO
SELECT * FROM ALERTA