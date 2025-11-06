--Función escalar que permite calcular el margen precio-costo de un servicio 
CREATE OR ALTER FUNCTION calcularMargen (@servicio VARCHAR(50))--Indicamos nombre del servicio a calcular.
RETURNS DECIMAL(10, 2) AS
BEGIN
–Declaración de variables
	DECLARE @margen DECIMAL (10,2);
	DECLARE @costo DECIMAL (10,2);
	DECLARE @precio DECIMAL (10,2);
–Le asignamos a la variable el valor de la columna que coincida con el nombre del servicio.
	SELECT @costo = ISNULL(costo, 0) FROM SERVICIO WHERE nombre = @servicio;
	SELECT @precio = ISNULL(precio, 0) FROM SERVICIO WHERE nombre = @servicio;
–Le asignamos a margen el resultado de precio-costo
	SELECT @margen = @precio - @costo;
	
	RETURN @margen;
END;
GO

–Testeo de la funcion escalar calcularMargen.
SELECT * FROM SERVICIO;
SELECT dbo.calcularMargen('Spa') AS "Margen Spa";
SELECT dbo.calcularMargen('Traslado') AS "Margen Traslado";
SELECT dbo.calcularMargen('Desayuno') AS "Margen Desayuno";
SELECT dbo.calcularMargen('Late Check-out') AS "Margen Late Check-out";
GO

–-View que nos permite ver una tabla con reservas de habitaciones que estén repetidas.
--AVISO: Para que esto funcione, se debe de borrar el constraint de UniqueID dentro de reservas.
CREATE OR ALTER VIEW habitacionesRepetidas AS
SELECT r.id_cliente, c.nombre, r.id_hab, r.check_in, COUNT(*) AS vecesRepetidas –Seleccionamos id del cliente, nombre, id de la habitación y date del check-in y creamos un contador para las veces que aparece repetida la reserva.

FROM RESERVA r
JOIN CLIENTE c ON r.id_cliente = c.id_cliente --Buscamos por id_cliente 
GROUP BY r.id_cliente, c.nombre, r.id_hab, r.check_in --Agrupamos por valores identicos
HAVING COUNT(*) > 1; --Si aparecen mas de una vez, los mostrara en la tabla.
GO
