-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 11-12-2024 a las 11:26:55
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `prueba6`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `actualizar_solicitud` (IN `p_id_solicitud` VARCHAR(255), IN `p_estado_solicitud` ENUM('PENDIENTE','VERIFICADA','PROCESADA','FINALIZADA'), IN `p_comentarios` TEXT)   BEGIN
    UPDATE solicitudes
    SET 
        estado_solicitud = IFNULL(p_estado_solicitud, estado_solicitud),
        comentarios = IFNULL(p_comentarios, comentarios)
    WHERE id_solicitud = p_id_solicitud;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `AddUser` (IN `p_nick_user` VARCHAR(100), IN `p_pass_user` VARCHAR(255), IN `p_email_user` VARCHAR(100), IN `p_tip_user` VARCHAR(50), IN `p_name_person` VARCHAR(100), IN `p_doc_person` INT, IN `p_dir_company` VARCHAR(255), IN `p_cell_company` VARCHAR(20), IN `p_desc_company` VARCHAR(255), IN `p_key_admin` VARCHAR(255))   BEGIN
    DECLARE id_user VARCHAR(255);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    -- Llamar al procedimiento para generar el id_user
    CALL GenerateUserId(p_tip_user, p_nick_user, p_email_user , id_user);

    -- Insertar en la tabla de usuarios
    INSERT INTO user (id_user, nick_user, pass_user, email_user, tip_user)
    VALUES (id_user, p_nick_user, p_pass_user, p_email_user, p_tip_user);

    -- Comprobar el tipo de usuario e insertar en la tabla correspondiente
    IF p_tip_user = 'person' THEN
        INSERT INTO userPerson (id_user, name_person, doc_person)
        VALUES (id_user, p_name_person, p_doc_person);
    ELSEIF p_tip_user = 'company' THEN
        INSERT INTO userCompany (id_user, dir_company, cell_company, desc_company)
        VALUES (id_user, p_dir_company, p_cell_company, p_desc_company);
    ELSEIF p_tip_user = 'admin' THEN
        INSERT INTO userAdmin (id_user, key_admin)
        VALUES (id_user, p_key_admin);
    END IF;

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `BuscarCampania` (IN `p_id_campania` VARCHAR(255))   BEGIN
    SELECT * FROM campania WHERE id_campania = p_id_campania;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `BuscarDonacion` (IN `p_id_donacion` VARCHAR(255), IN `p_tipo_donacion` VARCHAR(255), IN `p_estado_donacion` VARCHAR(255))   BEGIN
    SELECT * 
    FROM donaciones
    WHERE (p_id_donacion IS NULL OR id_donacion = p_id_donacion)
      AND (p_tipo_donacion IS NULL OR tipo_donacion = p_tipo_donacion)
      AND (p_estado_donacion IS NULL OR estado_donacion = p_estado_donacion);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `BuscarDonacionPorID` (IN `p_id_donacion` VARCHAR(255))   BEGIN
    SELECT * FROM donaciones WHERE id_donacion = p_id_donacion;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `CrearCampania` (IN `p_id_campania` VARCHAR(255), IN `p_descripcion` VARCHAR(255), IN `p_id_user` VARCHAR(255), IN `p_tipo_campania` VARCHAR(50), IN `p_monto_aporte` DECIMAL(10,2), IN `p_estado_campania` ENUM('ACTIVA','FINALIZADA','CANCELADA'), IN `p_meta_aporte` DECIMAL(10,2), IN `p_fecha_inicio` DATETIME, IN `p_fecha_fin` DATETIME)   BEGIN
    INSERT INTO campania (
        id_campania,
        descripcion,
        id_user,
        tipo_campania,
        monto_aporte,
        estado_campania,
        meta_aporte,
        fecha_inicio,
        fecha_fin
    ) VALUES (
        p_id_campania,
        p_descripcion,
        p_id_user,
        p_tipo_campania,
        p_monto_aporte,
        p_estado_campania,
        p_meta_aporte,
        p_fecha_inicio,
        p_fecha_fin
    );
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `CrearNotificacion` (IN `p_id_campania` VARCHAR(255), IN `p_id_user` VARCHAR(255), IN `p_mensaje` TEXT)   BEGIN
    INSERT INTO notificaciones (id_campania, id_user, mensaje, fecha_creacion)
    VALUES (p_id_campania, p_id_user, p_mensaje, NOW());
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `CrearNotificacionParaTodos` (IN `p_id_campania` VARCHAR(255), IN `p_mensaje` TEXT)   BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_id_user VARCHAR(255);

    -- Cursor para obtener todos los usuarios de la campaña (si p_id_campania no es NULL)
    DECLARE user_cursor CURSOR FOR
        SELECT id_user 
        FROM campania 
        WHERE id_campania = p_id_campania;

    -- Manejador para el cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    -- Si p_id_campania es NULL, insertamos una notificación general
    IF p_id_campania IS NULL THEN
        INSERT INTO notificaciones (id_campania, id_user, mensaje, fecha_creacion)
        VALUES (NULL, NULL, p_mensaje, NOW());
    ELSE
        -- Verificamos si existen usuarios para esa campaña
        OPEN user_cursor;
        read_loop: LOOP
            FETCH user_cursor INTO v_id_user;
            IF done THEN
                LEAVE read_loop;
            END IF;

            -- Insertar notificación para cada usuario de la campaña
            INSERT INTO notificaciones (id_campania, id_user, mensaje, fecha_creacion)
            VALUES (p_id_campania, v_id_user, p_mensaje, NOW());
        END LOOP;
        CLOSE user_cursor;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `crear_donacion` (IN `p_id_donacion` VARCHAR(255), IN `p_id_campania` VARCHAR(255), IN `p_id_user` VARCHAR(255), IN `p_tipo_donacion` ENUM('dinero','ropa','consumible'), IN `p_cantidad_donacion` DECIMAL(10,2), IN `p_fecha_donacion` DATETIME, IN `p_estado_donacion` ENUM('registrado','finalizado','cancelado'))   BEGIN
    -- Si el estado de donación es NULL, se establece 'registrado' como valor por defecto
    IF p_estado_donacion IS NULL THEN
        SET p_estado_donacion = 'registrado';
    END IF;

    -- Insertar la nueva donación
    INSERT INTO `donaciones` (
        `id_donacion`, 
        `id_campania`, 
        `id_user`, 
        `tipo_donacion`, 
        `cantidad_donacion`, 
        `fecha_donacion`, 
        `estado_donacion`
    ) VALUES (
        p_id_donacion, 
        p_id_campania, 
        p_id_user, 
        p_tipo_donacion, 
        p_cantidad_donacion, 
        p_fecha_donacion, 
        p_estado_donacion
    );
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `DeleteUser` (IN `p_id_user` VARCHAR(255))   BEGIN
    DECLARE user_type VARCHAR(50);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
    END;

    START TRANSACTION;

    -- Obtener el tipo de usuario antes de eliminar
    SELECT `tip_user` INTO user_type FROM `user` WHERE `id_user` = p_id_user;

    -- Verificar el tipo de usuario y eliminar solo en la subtabla correspondiente
    IF user_type = 'person' THEN
        DELETE FROM `userperson` WHERE `id_user` = p_id_user;
    ELSEIF user_type = 'company' THEN
        DELETE FROM `usercompany` WHERE `id_user` = p_id_user;
    ELSEIF user_type = 'admin' THEN
        DELETE FROM `useradmin` WHERE `id_user` = p_id_user;
    END IF;

    -- Eliminar el registro principal de la tabla `user`
    DELETE FROM `user` WHERE `id_user` = p_id_user;

    COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `EditarCampania` (IN `p_id_campania` VARCHAR(255), IN `p_descripcion` VARCHAR(255), IN `p_id_user` VARCHAR(255), IN `p_tipo_campania` VARCHAR(50), IN `p_monto_aporte` DECIMAL(10,2), IN `p_estado_campania` ENUM('ACTIVA','FINALIZADA','CANCELADA'), IN `p_meta_aporte` DECIMAL(10,2), IN `p_fecha_inicio` DATETIME, IN `p_fecha_fin` DATETIME)   BEGIN
    UPDATE campania
    SET
        descripcion = IFNULL(NULLIF(p_descripcion, ''), descripcion),  -- Si está vacío, no actualizar
        id_user = IFNULL(NULLIF(p_id_user, ''), id_user),     -- Lo mismo para id_usuario
        tipo_campania = IFNULL(NULLIF(p_tipo_campania, ''), tipo_campania),
        monto_aporte = IFNULL(NULLIF(p_monto_aporte, 0), monto_aporte),  -- No actualizar si es 0
        estado_campania = IFNULL(NULLIF(p_estado_campania, ''), estado_campania),
        meta_aporte = IFNULL(NULLIF(p_meta_aporte, 0), meta_aporte),
        fecha_inicio = IFNULL(NULLIF(p_fecha_inicio, ''), fecha_inicio),
        fecha_fin = IFNULL(NULLIF(p_fecha_fin, ''), fecha_fin)
    WHERE id_campania = p_id_campania;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `editar_donacion` (IN `p_id_donacion` VARCHAR(255), IN `p_id_campania` VARCHAR(255), IN `p_id_user` VARCHAR(255), IN `p_tipo_donacion` ENUM('dinero','ropa','consumible'), IN `p_cantidad_donacion` DECIMAL(10,2), IN `p_fecha_donacion` DATETIME, IN `p_estado_donacion` ENUM('registrado','finalizado','cancelado'))   BEGIN
    -- Actualizar los detalles de la donación solo si el valor no es NULL
    UPDATE `donaciones`
    SET 
        `id_campania` = IFNULL(p_id_campania, `id_campania`),
        `id_user` = IFNULL(p_id_user, `id_user`),
        `tipo_donacion` = IFNULL(p_tipo_donacion, `tipo_donacion`),
        `cantidad_donacion` = IFNULL(p_cantidad_donacion, `cantidad_donacion`),
        `fecha_donacion` = IFNULL(p_fecha_donacion, `fecha_donacion`),
        `estado_donacion` = IFNULL(p_estado_donacion, `estado_donacion`)
    WHERE `id_donacion` = p_id_donacion;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `EliminarCampania` (IN `p_id_campania` VARCHAR(255))   BEGIN
    DELETE FROM campania WHERE id_campania = p_id_campania;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `EliminarDonacion` (IN `p_id_donacion` VARCHAR(255))   BEGIN
    DELETE FROM donaciones WHERE id_donacion = p_id_donacion;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `FindUserById` (IN `p_id_user` VARCHAR(255))   BEGIN
    DECLARE tip_user VARCHAR(50);

    -- Obtener el tipo de usuario
    SELECT u.tip_user INTO tip_user
    FROM user u
    WHERE u.id_user = p_id_user;

    -- Dependiendo del tipo de usuario, se obtienen datos solo de la tabla correspondiente
    IF tip_user = 'person' THEN
        SELECT 
            u.id_user,
            u.nick_user,
            u.pass_user,
            u.email_user,
            up.name_person,
            up.doc_person,
            u.tip_user  -- Asegúrate de seleccionar tip_user
        FROM user u
        JOIN userPerson up ON u.id_user = up.id_user
        WHERE u.id_user = p_id_user;

    ELSEIF tip_user = 'company' THEN
        SELECT 
            u.id_user,
            u.nick_user,
            u.pass_user,
            u.email_user,
            uc.dir_company,
            uc.cell_company,
            uc.desc_company,
            u.tip_user  -- Asegúrate de seleccionar tip_user
        FROM user u
        JOIN userCompany uc ON u.id_user = uc.id_user
        WHERE u.id_user = p_id_user;

    ELSEIF tip_user = 'admin' THEN
        SELECT 
            u.id_user,
            u.nick_user,
            u.pass_user,
            u.email_user,
            ua.key_admin,
            u.tip_user  -- Asegúrate de seleccionar tip_user
        FROM user u
        JOIN userAdmin ua ON u.id_user = ua.id_user
        WHERE u.id_user = p_id_user;

    ELSE
        -- Si el tipo de usuario no coincide con ninguna categoría
        SELECT 'Tipo de usuario no válido o usuario no encontrado' AS mensaje;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `GenerateUserId` (IN `p_tip_user` VARCHAR(50), IN `p_nick_user` VARCHAR(100), IN `p_email_user` VARCHAR(100), OUT `p_id_user` VARCHAR(255))   BEGIN
    DECLARE year_suffix VARCHAR(3);
    DECLARE month_digit CHAR(1);
    DECLARE day_digit CHAR(1);
    DECLARE first_letter_nick CHAR(1);
    DECLARE last_letter_nick CHAR(1);
    DECLARE first_letter_email CHAR(1);

    -- Obtener los últimos 3 dígitos del año actual
    SET year_suffix = RIGHT(YEAR(CURDATE()), 3);

    -- Obtener el último dígito del mes
    SET month_digit = RIGHT(MONTH(CURDATE()), 1);

    -- Obtener el último dígito del día
    SET day_digit = RIGHT(DAY(CURDATE()), 1);

    -- Obtener la primera y última letra del nick_user
    SET first_letter_nick = UPPER(LEFT(p_nick_user, 1));
    SET last_letter_nick = UPPER(RIGHT(p_nick_user, 1));

    -- Obtener la primera letra del email_user
    SET first_letter_email = UPPER(LEFT(p_email_user, 1));

    -- Generar el id_user
    SET p_id_user = CONCAT(
        UPPER(LEFT(p_tip_user, 1)),  -- Primera letra del tipo de usuario
        year_suffix,                 -- Últimos 3 dígitos del año
        first_letter_nick,           -- Primera letra del nick
        last_letter_nick,            -- Última letra del nick
        first_letter_email,          -- Primera letra del email
        month_digit,                 -- Último dígito del mes
        day_digit                    -- Último dígito del día
    );

    -- Para depuración
    SELECT p_id_user AS generated_id_user;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `insertar_y_verificar_solicitud` (IN `p_id_donacion` VARCHAR(50))   BEGIN
    DECLARE estado_donacion_actual ENUM('registrado', 'finalizado', 'cancelado');

    -- Obtener el estado de la donación relacionada
    SELECT estado_donacion
    INTO estado_donacion_actual
    FROM donaciones
    WHERE id_donacion = p_id_donacion
    LIMIT 1;

    -- Insertar en solicitudes con estado inicial 'PENDIENTE'
    INSERT INTO solicitudes (id_solicitud, id_donacion, fecha_solicitud, estado_solicitud)
    VALUES (CONCAT('S', p_id_donacion), p_id_donacion, NOW(), 'PENDIENTE');

    -- Si el estado de la donación es 'registrado', actualizar el estado de la solicitud
    IF estado_donacion_actual = 'registrado' THEN
        UPDATE solicitudes
        SET estado_solicitud = 'VERIFICADA'
        WHERE id_donacion = p_id_donacion;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ListarCampanias` (IN `p_id_user` VARCHAR(255), IN `p_estado_campania` ENUM('Activa','Finalizada','Cancelada'))   BEGIN
    IF (p_id_user IS NULL OR p_id_user = '') AND (p_estado_campania IS NULL OR p_estado_campania = '') THEN
        -- Si no se proporciona ni id_user ni estado, listar todas las campañas
        SELECT * FROM campania;

    ELSEIF (p_id_user IS NOT NULL AND p_id_user <> '') AND (p_estado_campania IS NULL OR p_estado_campania = '') THEN
        -- Si se proporciona solo id_user, listar campañas de ese usuario
        SELECT * FROM campania WHERE id_user = p_id_user;

    ELSEIF (p_id_user IS NULL OR p_id_user = '') AND (p_estado_campania IS NOT NULL AND p_estado_campania <> '') THEN
        -- Si se proporciona solo estado_campania, listar campañas con ese estado
        SELECT * FROM campania WHERE estado_campania = p_estado_campania;

    ELSE
        -- Si se proporcionan ambos, id_user y estado_campania, filtrar por ambos
        SELECT * FROM campania WHERE id_user = p_id_user AND estado_campania = p_estado_campania;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ListarDonaciones` (IN `p_id_campania` VARCHAR(255))   BEGIN
    IF p_id_campania IS NULL OR p_id_campania = '' THEN
        -- Si no se proporciona un id_campania, listar todas las donaciones
        SELECT * FROM donaciones;
    ELSE
        -- Si se proporciona un id_campania, filtrar por id_campania
        SELECT * FROM donaciones WHERE id_campania = p_id_campania;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ListUsersByType` (IN `p_tip_user` VARCHAR(50))   BEGIN
    IF p_tip_user IS NULL THEN
        -- Listar todos los usuarios
        SELECT 
            u.id_user,
            u.nick_user,
            u.pass_user,
            u.email_user,
            u.tip_user,
            up.name_person,
            up.doc_person,
            uc.dir_company,
            uc.cell_company,
            uc.desc_company,
            ua.key_admin
        FROM user u
        LEFT JOIN userPerson up ON u.id_user = up.id_user
        LEFT JOIN userCompany uc ON u.id_user = uc.id_user
        LEFT JOIN userAdmin ua ON u.id_user = ua.id_user;
    ELSE
        -- Listar usuarios por tipo
        SELECT 
            u.id_user,
            u.nick_user,
            u.pass_user,
            u.email_user,
            u.tip_user,
            up.name_person,
            up.doc_person,
            uc.dir_company,
            uc.cell_company,
            uc.desc_company,
            ua.key_admin
        FROM user u
        LEFT JOIN userPerson up ON u.id_user = up.id_user
        LEFT JOIN userCompany uc ON u.id_user = uc.id_user
        LEFT JOIN userAdmin ua ON u.id_user = ua.id_user
        WHERE u.tip_user = p_tip_user;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `LoginUser` (IN `p_nick_user` VARCHAR(100), IN `p_pass_user` VARCHAR(255))   BEGIN
    DECLARE user_exists INT DEFAULT 0;
    DECLARE user_id VARCHAR(255);

    -- Verificar si el usuario existe y las credenciales son correctas
    SELECT COUNT(*) INTO user_exists
    FROM user
    WHERE nick_user = p_nick_user AND pass_user = p_pass_user;
    
    IF user_exists = 1 THEN
        -- Obtener el id_user del usuario autenticado
        SELECT id_user INTO user_id
        FROM user
        WHERE nick_user = p_nick_user AND pass_user = p_pass_user;
        
        -- Devolver el id_user
        SELECT user_id AS id_user;
    ELSE
        -- Si las credenciales no son correctas
        SELECT 'Usuario o contraseña incorrectos' AS mensaje;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ObtenerNotificacionesUsuario` (IN `p_id_user` VARCHAR(255))   BEGIN
    IF p_id_user IS NULL THEN
        -- Si p_id_user es NULL, obtenemos todas las notificaciones
        SELECT 
            n.id_notificacion,
            n.id_campania,
            n.id_user,
            n.mensaje,
            n.fecha_creacion
        FROM notificaciones n
        ORDER BY n.fecha_creacion DESC;
    ELSE
        -- Si p_id_user no es NULL, obtenemos las notificaciones del usuario y las campañas en las que ha donado
        SELECT DISTINCT 
            n.id_notificacion,
            n.id_campania,
            n.id_user,
            n.mensaje,
            n.fecha_creacion
        FROM notificaciones n
        LEFT JOIN donaciones d ON n.id_campania = d.id_campania
        WHERE n.id_user = p_id_user
           OR (d.id_user = p_id_user AND n.id_campania IS NOT NULL)
        ORDER BY n.fecha_creacion DESC;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `ObtenerUltimaCampaniaActivaPorUsuario` (IN `p_id_user` VARCHAR(255), OUT `p_id_campania` VARCHAR(255))   BEGIN
    -- Inicializar el parámetro de salida a NULL
    SET p_id_campania = NULL;

    -- Verificar si el usuario tiene alguna campaña activa
    IF EXISTS (SELECT 1 FROM campania WHERE id_user = p_id_user AND estado_campania = 'ACTIVA') THEN
        -- Obtener el id_campania de la última campaña activa (ordenada por fecha de inicio o fin, según corresponda)
        SELECT id_campania
        INTO p_id_campania
        FROM campania
        WHERE id_user = p_id_user AND estado_campania = 'ACTIVA'
        ORDER BY fecha_inicio DESC  -- O puedes usar fecha_fin, según lo que determines como "última"
        LIMIT 1;
    END IF;
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `UpdateUser` (IN `p_id_user` VARCHAR(255), IN `p_nick_user` VARCHAR(100), IN `p_pass_user` VARCHAR(255), IN `p_email_user` VARCHAR(100), IN `p_tip_user` VARCHAR(50), IN `p_name_person` VARCHAR(100), IN `p_doc_person` INT, IN `p_dir_company` VARCHAR(255), IN `p_cell_company` VARCHAR(20), IN `p_desc_company` VARCHAR(255), IN `p_key_admin` VARCHAR(255))   BEGIN
    DECLARE tip_user VARCHAR(50);

    -- Obtener el tipo de usuario
    SELECT tip_user INTO tip_user
    FROM user 
    WHERE id_user = p_id_user;

    -- Depuración
    SELECT 'Valor de tip_user:', tip_user;

    -- Actualizar en la tabla user
    UPDATE user 
    SET 
        nick_user = IFNULL(p_nick_user, nick_user),
        pass_user = IFNULL(p_pass_user, pass_user),
        email_user = IFNULL(p_email_user, email_user),
        tip_user = IFNULL(p_tip_user, tip_user)
    WHERE id_user = p_id_user;

    -- Dependiendo del tipo de usuario, actualizar en la tabla correspondiente
    IF tip_user = 'person' THEN
        UPDATE userPerson 
        SET 
            name_person = IFNULL(p_name_person, name_person), 
            doc_person = IFNULL(p_doc_person, doc_person) 
        WHERE id_user = p_id_user;

    ELSEIF tip_user = 'company' THEN
        UPDATE userCompany 
        SET 
            dir_company = IFNULL(p_dir_company, dir_company), 
            cell_company = IFNULL(p_cell_company, cell_company), 
            desc_company = IFNULL(p_desc_company, desc_company) 
        WHERE id_user = p_id_user;

    ELSEIF tip_user = 'admin' THEN
        UPDATE userAdmin 
        SET 
            key_admin = IFNULL(p_key_admin, key_admin) 
        WHERE id_user = p_id_user;
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `campania`
--

CREATE TABLE `campania` (
  `id_campania` varchar(255) NOT NULL,
  `descripcion` varchar(255) NOT NULL,
  `id_user` varchar(255) NOT NULL,
  `tipo_campania` varchar(50) NOT NULL,
  `monto_aporte` decimal(10,2) NOT NULL,
  `estado_campania` enum('ACTIVA','FINALIZADA','CANCELADA') DEFAULT 'ACTIVA',
  `meta_aporte` decimal(10,2) DEFAULT NULL,
  `fecha_inicio` datetime NOT NULL,
  `fecha_fin` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `campania`
--

INSERT INTO `campania` (`id_campania`, `descripcion`, `id_user`, `tipo_campania`, `monto_aporte`, `estado_campania`, `meta_aporte`, `fecha_inicio`, `fecha_fin`) VALUES
('DC1510598', 'reroinv', 'C024EZC15', 'DINERO', 4900.00, 'ACTIVA', 100000.00, '2024-01-01 00:00:00', '2024-03-31 00:00:00'),
('DC1510599', 'Recaudación de fondos', 'C024UFU29', 'ROPA', 19100.00, 'ACTIVA', 100000.00, '2024-05-09 00:00:00', '2024-12-22 00:00:00'),
('DC1510600', 'Recaudar alimentos', 'C024OMO29', 'CONSUMIBLE', 30500.00, 'ACTIVA', 80000.00, '2024-04-15 00:00:00', '2024-11-30 00:00:00');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `donaciones`
--

CREATE TABLE `donaciones` (
  `id_donacion` varchar(255) NOT NULL,
  `id_campania` varchar(255) NOT NULL,
  `id_user` varchar(255) NOT NULL,
  `tipo_donacion` enum('dinero','ropa','consumible') NOT NULL,
  `cantidad_donacion` decimal(10,2) NOT NULL,
  `fecha_donacion` datetime NOT NULL,
  `estado_donacion` enum('registrado','finalizado','cancelado') NOT NULL DEFAULT 'registrado'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `donaciones`
--

INSERT INTO `donaciones` (`id_donacion`, `id_campania`, `id_user`, `tipo_donacion`, `cantidad_donacion`, `fecha_donacion`, `estado_donacion`) VALUES
('1', 'DC1510598', 'A024YOA11', 'dinero', 1000.00, '2024-11-25 00:00:00', 'finalizado'),
('P0D2421', 'DC1510598', 'P024PXP23', 'dinero', 10.00, '2024-12-09 00:00:00', 'registrado'),
('P0D2422', 'DC1510598', 'P024PXP23', 'dinero', 120.00, '2024-12-10 00:00:00', 'registrado'),
('P0D2423', 'DC1510598', 'P024PXP23', 'dinero', 1000.00, '2024-12-10 00:00:00', 'registrado'),
('P0D2428', 'DC1510598', 'P024PXP23', 'dinero', 10.00, '2024-12-09 00:00:00', 'cancelado'),
('P0D2439', 'DC1510598', 'P024PXP23', 'dinero', 300.00, '2024-12-10 00:00:00', 'registrado'),
('P0D2469', 'DC1510598', 'P024PXP23', 'dinero', 30.00, '2024-12-10 00:00:00', 'registrado'),
('P0D2484', 'DC1510598', 'P024PXP23', 'dinero', 300.00, '2024-12-10 00:00:00', 'registrado'),
('P0D2494', 'DC1510598', 'P024PXP23', 'dinero', 140.00, '2024-12-10 00:00:00', 'cancelado'),
('P0R2450', 'DC1510599', 'P024PXP23', 'ropa', 100.00, '2024-12-09 00:00:00', 'cancelado'),
('P0R2475', 'DC1510599', 'P024PXP23', 'ropa', 100.00, '2024-12-10 00:00:00', 'cancelado');

--
-- Disparadores `donaciones`
--
DELIMITER $$
CREATE TRIGGER `after_donacion_insert` AFTER INSERT ON `donaciones` FOR EACH ROW BEGIN
    CALL insertar_y_verificar_solicitud(NEW.id_donacion);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `notificaciones`
--

CREATE TABLE `notificaciones` (
  `id_notificacion` int(11) NOT NULL,
  `id_campania` varchar(255) DEFAULT NULL,
  `id_user` varchar(255) DEFAULT NULL,
  `mensaje` text NOT NULL,
  `fecha_creacion` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `notificaciones`
--

INSERT INTO `notificaciones` (`id_notificacion`, `id_campania`, `id_user`, `mensaje`, `fecha_creacion`) VALUES
(1, '', '', 'holaatodos', '2024-12-11 05:15:14');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `solicitudes`
--

CREATE TABLE `solicitudes` (
  `id_solicitud` varchar(255) NOT NULL,
  `id_donacion` varchar(255) NOT NULL,
  `fecha_solicitud` datetime NOT NULL,
  `comentarios` text DEFAULT NULL,
  `estado_solicitud` enum('PENDIENTE','VERIFICADA','PROCESADA','FINALIZADA') DEFAULT 'PENDIENTE'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `solicitudes`
--

INSERT INTO `solicitudes` (`id_solicitud`, `id_donacion`, `fecha_solicitud`, `comentarios`, `estado_solicitud`) VALUES
('S1', '1', '2024-11-25 19:51:20', 'Procesada - Finalizada', 'FINALIZADA'),
('SP0D2421', 'P0D2421', '2024-12-09 21:19:02', NULL, 'VERIFICADA'),
('SP0D2422', 'P0D2422', '2024-12-10 02:05:08', NULL, 'VERIFICADA'),
('SP0D2423', 'P0D2423', '2024-12-10 19:59:58', NULL, 'VERIFICADA'),
('SP0D2428', 'P0D2428', '2024-12-09 21:25:13', 'Cancelada', 'FINALIZADA'),
('SP0D2439', 'P0D2439', '2024-12-10 16:26:11', NULL, 'VERIFICADA'),
('SP0D2469', 'P0D2469', '2024-12-10 16:29:36', NULL, 'VERIFICADA'),
('SP0D2484', 'P0D2484', '2024-12-10 19:59:10', NULL, 'VERIFICADA'),
('SP0D2494', 'P0D2494', '2024-12-10 02:08:07', 'Cancelada', 'FINALIZADA'),
('SP0R2450', 'P0R2450', '2024-12-09 23:34:58', 'Cancelada', 'FINALIZADA'),
('SP0R2475', 'P0R2475', '2024-12-10 16:34:42', 'Cancelada', 'FINALIZADA');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `user`
--

CREATE TABLE `user` (
  `id_user` varchar(255) NOT NULL,
  `nick_user` varchar(100) NOT NULL,
  `pass_user` varchar(255) NOT NULL,
  `email_user` varchar(100) NOT NULL,
  `tip_user` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `user`
--

INSERT INTO `user` (`id_user`, `nick_user`, `pass_user`, `email_user`, `tip_user`) VALUES
('A024ANA23', 'Admin', 'admin123', 'admin@gmail.com', 'admin'),
('A024YOA11', 'yato26', '2772', 'alp0@gmail.com', 'admin'),
('C024E1E23', 'empresa1', '123', 'Soy una empresa de donaciones', 'company'),
('C024EZC15', 'EmpresaXYZ', 'password123', 'contacto@empresa.com', 'company'),
('C024OMO29', 'Oxfam', 'oxfam123', 'oxfam-etico@gmail.com', 'company'),
('C024UFU29', 'UNICEF', 'unicef123', 'unicef-gobpe@gmail.com', 'company'),
('P024ARP24', 'AdrianUser', 'adri123', 'adri123@gmail.com', 'person'),
('P024DND24', 'dan', '2662', 'dan@GMAIL.COM', 'person'),
('P024KN920', 'kevin', '2222', '92949@gmail.com', 'person'),
('P024PXP23', 'Panlox', 'pablo123', 'panlox123@gmail.com', 'person');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `useradmin`
--

CREATE TABLE `useradmin` (
  `id_user` varchar(255) DEFAULT NULL,
  `key_admin` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `useradmin`
--

INSERT INTO `useradmin` (`id_user`, `key_admin`) VALUES
('A024YOA11', 'zzzz'),
('A024ANA23', 'Superadmin'),
('A024YOA11', 'zzzz');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usercompany`
--

CREATE TABLE `usercompany` (
  `id_user` varchar(255) DEFAULT NULL,
  `dir_company` varchar(255) NOT NULL,
  `cell_company` int(11) NOT NULL,
  `desc_company` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `usercompany`
--

INSERT INTO `usercompany` (`id_user`, `dir_company`, `cell_company`, `desc_company`) VALUES
('C024EZC15', 'Av. Principal 123, Ciudad', 987654321, 'Empresa dedicada a la tecnología'),
('C024E1E23', 'Av. 28 de julio', 962725143, 'Soy una empresa de donaciones'),
('C024UFU29', 'UNICEF, Melitón Porras 350, Lima 15074', 971514316, 'Empresa para para recaudar fondos y productos para la salud, la educación y el bienestar infantil en áreas necesitadas'),
('C024OMO29', 'Ca. Diego Ferré 365, Miraflores 15074', 961417242, 'Recaudar donaciones de dinero y productos para apoyar a comunidades en pobreza extrema y en situaciones de crisis'),
('C024EZC15', 'Av. Principal 123, Ciudad', 987654321, 'Empresa dedicada a la tecnología');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `userperson`
--

CREATE TABLE `userperson` (
  `id_user` varchar(255) DEFAULT NULL,
  `name_person` varchar(100) NOT NULL,
  `doc_person` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_spanish_ci;

--
-- Volcado de datos para la tabla `userperson`
--

INSERT INTO `userperson` (`id_user`, `name_person`, `doc_person`) VALUES
('P024PXP23', 'Pablo Boza', 71422079),
('P024ARP24', 'Adrian Torres', 71422079),
('P024DND24', 'daniel', 2222222),
('P024KN920', 'kev', 99999);

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `campania`
--
ALTER TABLE `campania`
  ADD PRIMARY KEY (`id_campania`),
  ADD KEY `id_user` (`id_user`);

--
-- Indices de la tabla `donaciones`
--
ALTER TABLE `donaciones`
  ADD PRIMARY KEY (`id_donacion`),
  ADD KEY `id_campania` (`id_campania`),
  ADD KEY `id_usuario` (`id_user`);

--
-- Indices de la tabla `notificaciones`
--
ALTER TABLE `notificaciones`
  ADD PRIMARY KEY (`id_notificacion`);

--
-- Indices de la tabla `solicitudes`
--
ALTER TABLE `solicitudes`
  ADD PRIMARY KEY (`id_solicitud`),
  ADD KEY `solicitudes_ibfk_2` (`id_donacion`);

--
-- Indices de la tabla `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`id_user`),
  ADD UNIQUE KEY `email_user` (`email_user`);

--
-- Indices de la tabla `useradmin`
--
ALTER TABLE `useradmin`
  ADD KEY `id_user` (`id_user`);

--
-- Indices de la tabla `usercompany`
--
ALTER TABLE `usercompany`
  ADD KEY `id_user` (`id_user`);

--
-- Indices de la tabla `userperson`
--
ALTER TABLE `userperson`
  ADD KEY `id_user` (`id_user`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `notificaciones`
--
ALTER TABLE `notificaciones`
  MODIFY `id_notificacion` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `campania`
--
ALTER TABLE `campania`
  ADD CONSTRAINT `campania_ibfk_1` FOREIGN KEY (`id_user`) REFERENCES `user` (`id_user`);

--
-- Filtros para la tabla `donaciones`
--
ALTER TABLE `donaciones`
  ADD CONSTRAINT `donaciones_ibfk_1` FOREIGN KEY (`id_campania`) REFERENCES `campania` (`id_campania`),
  ADD CONSTRAINT `donaciones_ibfk_2` FOREIGN KEY (`id_user`) REFERENCES `user` (`id_user`);

--
-- Filtros para la tabla `solicitudes`
--
ALTER TABLE `solicitudes`
  ADD CONSTRAINT `solicitudes_ibfk_2` FOREIGN KEY (`id_donacion`) REFERENCES `donaciones` (`id_donacion`);

--
-- Filtros para la tabla `useradmin`
--
ALTER TABLE `useradmin`
  ADD CONSTRAINT `useradmin_ibfk_1` FOREIGN KEY (`id_user`) REFERENCES `user` (`id_user`);

--
-- Filtros para la tabla `usercompany`
--
ALTER TABLE `usercompany`
  ADD CONSTRAINT `usercompany_ibfk_1` FOREIGN KEY (`id_user`) REFERENCES `user` (`id_user`);

--
-- Filtros para la tabla `userperson`
--
ALTER TABLE `userperson`
  ADD CONSTRAINT `userperson_ibfk_1` FOREIGN KEY (`id_user`) REFERENCES `user` (`id_user`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
