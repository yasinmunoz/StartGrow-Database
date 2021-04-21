------------------------------------- IMPLEMENTACIÓN DDL ---------------------------------------
--------------------------------------- USUARIO ------------------------------------------------
-- Tipo USUARIO
create or replace type Usuario_objtyp as object (
    idUsuario number,
	nombre varchar2 (15),
    apellido1 varchar2 (20),
    apellido2 varchar2 (20),
    nif char (9),
    telefono char (9),
    email varchar2 (75),
    domicilio varchar2 (50),
    municipio varchar2 (20),
    codpost varchar2 (10),
    pais varchar2 (30),
    contraseña varchar2 (30),
    cuentaBanco char (24),

    member procedure cambiarContraseña  (nuevaContraseña in varchar2),
    order member function ordenar (v_usuario in Usuario_objtyp) return integer
) not INSTANTIABLE not FINAL;

/

-- Tabla USUARIO
create table Usuario_objtab of Usuario_objtyp (
    idUsuario primary key,
    check (apellido1 is not null),
    check (apellido2 is not null),
    nif unique,
    check (telefono is not null),
    check (email is not null),
    check (domicilio is not null),
    check (municipio is not null),
    check (codpost is not null),
    check (pais is not null),
    check (contraseña is not null),
    check (cuentaBanco is not null)
);

/

---------------------------------------  SOLICITUD ------------------------------------------------------
-- Tipo SOLICITUD
create or replace type Solicitud_objtyp as object (
	idSolicitud number,
    estadoSolicitud varchar2 (15),
    nombre varchar2 (40),
    fechaSolicitud date,
    comentario varchar2 (500),

    member procedure cambiarEstado (estado in varchar2),
    order member function ordenar (v_solicitud in Solicitud_objtyp) return integer
);

/

-- Tabla SOLICITUD
create table Solicitud_objtab of Solicitud_objtyp (
    idSolicitud primary key,
    check (UPPER(estadoSolicitud) in ('ACEPTADA','RECHAZADA','EN CURSO')),
    check (nombre is not null),
    check (fechaSolicitud is not null),
    check (comentario is not null)
);

/

-- Tabla anidada de SOLICITUDES para EMPLEADO y PROMOTOR
create type Solicitud_ntabtyp as table of ref Solicitud_objtyp;

/

------------------------------------------ RETORNO -------------------------------------------------------------
-- Tipo RETORNO
create type Retorno_objtyp as object (
	idRetorno number,
    reembolso numeric (7,2),

    order member function ordenar (v_retorno in Retorno_objtyp) return integer
);

/

-- Tabla RETORNO
create table Retorno_objtab of Retorno_objtyp (
    idRetorno primary key,
    check (reembolso > 0)
);

/

-- Tabla anidada de RETORNOS para INVERSION
create type Retorno_ntabtyp as table of ref Retorno_objtyp;

/

----------------------------------------- INVERSION ----------------------------------------------------------
-- Tipo INVERSION
create or replace type Inversion_objtyp as object (
	idInversion number,
    estadoInversion varchar2 (20),
    capInvertido numeric (12,2),
    retorno Retorno_ntabtyp,

    order member function ordenar (v_inversion in Inversion_objtyp) return integer
);

/

-- Tabla INVERSION
create table Inversion_objtab of Inversion_objtyp (
    idInversion primary key,
    check (UPPER(estadoInversion) in ('RECAUDACIÓN', 'FINALIZADA', 'EN CURSO')),
    check (capInvertido > 0)
)
nested table retorno store as Retornos_ntab;

/

alter table Retornos_ntab
add (scope for (column_value) is Retorno_objtab);

/

-- Tabla anidada de INVERSIONES para INVERSOR
create type Inversion_ntabtyp as table of ref Inversion_objtyp;

/

----------------------------------------- PROMOTOR ------------------------------------------------------------------
-- Tipo PROMOTOR
create or replace type Promotor_objtyp under Usuario_objtyp (
	actividad varchar2 (500),
    solicitud Solicitud_ntabtyp
);
/
----------------------------------------- EMPLEADO ------------------------------------------------------------------
-- Tipo Empleado
create or replace type Empleado_objtyp under Usuario_objtyp (
    salario numeric (6,2), -- al mes
    solicitud Solicitud_ntabtyp
);

/

-- Tabla anidada de EMPLEADOS para PUESTO
create type Empleado_ntabtyp as table of ref Empleado_objtyp;

/
------------------------------------------- INVERSOR -------------------------------------------------
-- Tipo INVERSOR
create or replace type Inversor_objtyp under Usuario_objtyp (
    saldo numeric (12,2),
    tarjetaCredito char (16),
    inversion Inversion_ntabtyp
);

/

-------------------------------------------- AREA ----------------------------------------------------------------
-- Tipo AREA
create or replace type Area_objtyp as object (
    idArea number,
    nombre varchar2 (20),

    order member function ordenar (v_area in Area_objtyp) return integer
);

/

-- Tabla AREA
create table Area_objtab of Area_objtyp (
    idArea primary key,
    check (nombre is not null)
);

/

-- Tabla anidada de AREAS para PROYECTO
create type Area_ntabtyp as table of ref Area_objtyp;

/

------------------------------------------------ PROYECTO -------------------------------------------------------------
-- Tipo PROYECTO
create or replace type Proyecto_objtyp as object (
	idProyecto number,
    idSolicitud ref Solicitud_objtyp,
    nombre varchar2 (30),    
    estadoProyecto varchar2 (20), --ENUM
    rating char (1), --ENUM
    plazoRetorno integer, -- en meses
    inversionMin integer,
    fechaExpiracion date,
    importeObjetivo numeric (12,2),
    rentabilidadEsperada numeric (4,2),
    rentabilidadFinal numeric (4,2), 
    numInversores integer,
    progreso integer,
    inversion Inversion_ntabtyp,
    area Area_ntabtyp,

    order member function ordenar (v_proyecto in Proyecto_objtyp) return integer
);

/

-- Tabla PROYECTO
create table Proyecto_objtab of Proyecto_objtyp (
    idProyecto primary key,
    idSolicitud references Solicitud_objtab,
    check (nombre is not null),
    check (UPPER(estadoProyecto) in ('FINANCIADO', 'CERRADO', 'EN FINANCIACIÓN')),
    check (rating in ('A', 'B', 'C', 'D')),
    check (plazoRetorno > 0),
    check (inversionMin > 0),
    check (fechaExpiracion is not null),
    check (importeObjetivo > 0),
    check (rentabilidadEsperada > 0),
    check (numInversores >= 0),
    check (progreso >= 0)
)
nested table inversion store as InversionesP_ntab,
nested table area store as Areas_ntab;

/

alter table InversionesP_ntab
add (scope for (column_value) is Inversion_objtab);

/

alter table Areas_ntab
add (scope for (column_value) is Area_objtab);

/

---------------------------------------------- PUESTO --------------------------------------------------------------
-- Tipo PUESTO
create type Puesto_objtyp as object (
    idPuesto number,
    nombre varchar2 (20),
    sueldoBase numeric (12,2),
    tasaIncremento number,
    empleado Empleado_ntabtyp,

    order member function ordenar (v_puesto in Puesto_objtyp) return integer
);

/

-- Tabla PUESTO
create table Puesto_objtab of Puesto_objtyp (
    idPuesto primary key,
    check (nombre is not null),
    check (sueldoBase > 0),
    check (sueldoBase is not null),
    check (tasaIncremento > 0),
    check (tasaIncremento is not null)
)
nested table empleado store as Empleados_ntab;

/

alter table Empleados_ntab
add (scope for (column_value) is Usuario_objtab);

/


------------------------------------------------------- SECUENCIAS ---------------------------------------------------------

CREATE SEQUENCE usuario_idusuario_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE solicitud_idsolicitud_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE proyecto_idproyecto_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE retorno_idretorno_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE inversion_idinversion_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE area_idarea_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE puesto_idpuesto_seq START WITH 1 INCREMENT BY 1;

----------------------------------------------------- INSERCIÓN DE DATOS --------------------------------------------------------------

-- SOLICITUD
insert into Solicitud_objtab values (
    Solicitud_objtyp (
        solicitud_idsolicitud_seq.nextval, 'ACEPTADA', 'Virtual Indie', '27/06/2019',
        'Nuestro modelo de negocio en Virtual Indie se basa en fabricar gafas de realidad virtual. Nuestro objetivo es que gracias a este proyecto podamos realizar un proceso de fabricación más barato y que eso sea lo que nos diferencie de nuestra competencia en el mercado actual.'
    )    
);


/

insert into Solicitud_objtab values (
    Solicitud_objtyp (
        solicitud_idsolicitud_seq.nextval, 'ACEPTADA', 'Electronics Medica SL', '19/02/2020', 
        'Hola, somos E-Medica. Necesitamos financiación por un valor de 500.000 euros en un plazo de un año. Para ello solicitamos poder recibirla con vosotros. Hemos adjuntado nuestro plan de negocio donde mostramos el capital del que disponemos y un plan de inversión explicando donde va a ir el dinero que solicitamos.'
    )
);

/

insert into Solicitud_objtab values (
    Solicitud_objtyp (
        solicitud_idsolicitud_seq.nextval, 'EN CURSO', 'Volava SA', '20/02/2020', 'Volava SA es una empresa que busca financiación para desarrollar un nuevo modelo innovador de helicopteros, que usen la energía eólica como su fuente de combustible. Aquí adjuntamos más detalles de esta tecnología para nuestros futuros inversores.'
    )
);

/

insert into Solicitud_objtab values (
    Solicitud_objtyp (
        solicitud_idsolicitud_seq.nextval, 'EN CURSO', 'Protos Education SA', '22/02/2020', 'Protos Education SA es una empresa que busca financiación para desarrollar una plataforma web educativa..'
    )
);

/

insert into Solicitud_objtab values (
    Solicitud_objtyp (
        solicitud_idsolicitud_seq.nextval, 'EN CURSO', 'SubSole Grocery SA', '24/02/2020', 'SubSole Grocery SA es una empresa que busca financiación para abrir un supermercado de comida orgánica.'
    )
);

/

insert into Solicitud_objtab values (
    Solicitud_objtyp (
        solicitud_idsolicitud_seq.nextval, 'EN CURSO', 'Green SA', '26/02/2020', 'Green SA es una empresa con un modelo de negocio Business-to-employee que se dedica a la consultoría sobre energía fotovoltáica.'
    )
);

/

insert into Solicitud_objtab values (
    Solicitud_objtyp (
        solicitud_idsolicitud_seq.nextval, 'EN CURSO', 'STC SA', '28/02/2020', 'STC SA es una empresa de seguridad que necesita financiación.'
    )
);

/

insert into Solicitud_objtab values (
    Solicitud_objtyp (
        solicitud_idsolicitud_seq.nextval, 'EN CURSO', 'KLANTEC SA', '02/03/2020', 'KLANTEC SA es una empresa de ingeniería que necesita financiación para abrir una sucursal en Francia.'
    )
);

/
insert into Solicitud_objtab values (
    Solicitud_objtyp (
        solicitud_idsolicitud_seq.nextval, 'EN CURSO', 'Juguetería LMC SA', '04/03/2020', 'Juguetería LMC SA es una empresa de comercio que necesita financiación para vender sus juguetes en internet.'
    )
);

/
insert into Solicitud_objtab values (
    Solicitud_objtyp (
        solicitud_idsolicitud_seq.nextval, 'EN CURSO', 'Marcos Carretero Logistica SL', '06/03/2020', 'Marcos Carretero logísitca SL es una empresa de transportes que necesita financiación para la compra de nuevos camiones híbridos.'
    )
);
/
-- USUARIO EMPLEADO
insert into Usuario_objtab values (
    Empleado_objtyp (
        usuario_idusuario_seq.nextval, 'Jesús', 'Buendía', 'Martínez', '47474747A', '684256875',
        'jesus.buendia@startgrow.com', 'C/La Almendra,26,1ºH', 'Albacete', '02001', 'España', '@1234',
        'ES3721001439539824252398', 1802.25, Solicitud_ntabtyp()
    )
);

/

insert into table (
    select treat (value(u) as Empleado_objtyp).solicitud
    from Usuario_objtab u
    where idUsuario = 1
)
values (
    (select ref(s) 
    from Solicitud_objtab s 
    where idSolicitud = 1)
);

/

insert into table (
    select treat (value(u) as Empleado_objtyp).solicitud
    from Usuario_objtab u
    where idUsuario = 1
)
values (
    (select ref(s) 
    from Solicitud_objtab s 
    where idSolicitud = 2)
);

/

insert into table (
    select treat (value(u) as Empleado_objtyp).solicitud
    from Usuario_objtab u
    where idUsuario = 1
)
values (
    (select ref(s) 
    from Solicitud_objtab s 
    where idSolicitud = 8)
);

/

insert into table (
    select treat (value(u) as Empleado_objtyp).solicitud
    from Usuario_objtab u
    where idUsuario = 1
)
values (
    (select ref(s) 
    from Solicitud_objtab s 
    where idSolicitud = 9)
);

/
insert into Usuario_objtab values (
    Empleado_objtyp (
        usuario_idusuario_seq.nextval, 'Damian', 'Sánchez', 'Torres', '12121212B', '784754855',
        'damian.sanchez@startgrow.com', 'C/La Nuez,27,5ºA', 'Madrid', '28001', 'España', '@1235', 
        'ES4204878989806946858819', 1965.78, Solicitud_ntabtyp()
    )
);

/

insert into table (
    select treat (value(u) as Empleado_objtyp).solicitud
    from Usuario_objtab u
    where idUsuario = 2
)
values (
    (select ref(s) 
    from Solicitud_objtab s 
    where idSolicitud = 3)
);

/

/

insert into table (
    select treat (value(u) as Empleado_objtyp).solicitud
    from Usuario_objtab u
    where idUsuario = 2
)
values (
    (select ref(s) 
    from Solicitud_objtab s 
    where idSolicitud = 4)
);

/


insert into table (
    select treat (value(u) as Empleado_objtyp).solicitud
    from Usuario_objtab u
    where idUsuario = 2
)
values (
    (select ref(s) 
    from Solicitud_objtab s 
    where idSolicitud = 5)
);

/

insert into Usuario_objtab values (
    Empleado_objtyp (
        usuario_idusuario_seq.nextval, 'José', 'García', 'Escribano', '37373737C', '604717593',
        'jose.garcia@startgrow.com', 'C/La Madriguera,28,2ºC', 'Cáceres', '10005', 'España', '@1236',
        'ES9829489001242528783468', 2113.46, Solicitud_ntabtyp()
    )
);
		
/

insert into table (
    select treat (value(u) as Empleado_objtyp).solicitud
    from Usuario_objtab u
    where idUsuario = 3
)
values (
    (select ref(s) 
    from Solicitud_objtab s 
    where idSolicitud = 6)
);

/

insert into table (
    select treat (value(u) as Empleado_objtyp).solicitud
    from Usuario_objtab u
    where idUsuario = 3
)
values (
    (select ref(s) 
    from Solicitud_objtab s 
    where idSolicitud = 7)
);

/

insert into table (
    select treat (value(u) as Empleado_objtyp).solicitud
    from Usuario_objtab u
    where idUsuario = 3
)
values (
    (select ref(s) 
    from Solicitud_objtab s 
    where idSolicitud = 10)
);

/
-- USUARIO PROMOTOR
insert into Usuario_objtab values (
    Promotor_objtyp (
        usuario_idusuario_seq.nextval, 'Florentino', 'Nieto', 'González', '27212721F', 
        '679323593', 'florentino.nieto@hotmail.com', 'C/Via Trajana,51,4ºA', 'Barcelona',
        '08020', 'España', '@1239', 'ES8937691103860937681045', 'Director Ejecutivo 
        de Virtual Indie y Protos.', Solicitud_ntabtyp()
    )
);

/

insert into table (
    select treat (value(u) as Promotor_objtyp).solicitud
    from Usuario_objtab u
    where idUsuario = 4
)
values (
    (select ref(s) 
    from Solicitud_objtab s 
    where idSolicitud = 1)
);

/

insert into table (
    select treat (value(u) as Promotor_objtyp).solicitud
    from Usuario_objtab u
    where idUsuario = 4
)
values (
    (select ref(s) 
    from Solicitud_objtab s 
    where idSolicitud = 4)
);

/

insert into Usuario_objtab values (
    Promotor_objtyp (
        usuario_idusuario_seq.nextval,'Jose','López','Ruiz','13131313C','656743672',
        'jose.lopez@hotmail.com','C/La Piña,2,2ºB', 'Valladolid','47001','España',
        '@1236', 'ES8104878129583112365513', 'Fundador de E-Medica junto con 3 socios.', 
        Solicitud_ntabtyp()
    )
);

/

insert into table (
    select treat (value(u) as Promotor_objtyp).solicitud
    from Usuario_objtab u
    where idUsuario = 5
)
values (
    (select ref(s) 
    from Solicitud_objtab s 
    where idSolicitud = 2)
);

/

insert into Usuario_objtab values (
    Promotor_objtyp (
        usuario_idusuario_seq.nextval,'María','Peña','Domingo','14141414D','705369712',
        'maria.peña@gmail.com','C/La Alcachofa,5,8ºA', 'Salamanca','37001','España','@1237',
        'ES8431909294989458517572','Director general de Volava. Mi función es dirigir la empresa 
        y buscar fuentes de financiación.', Solicitud_ntabtyp()
    )
);

/

insert into table (
    select treat (value(u) as Promotor_objtyp).solicitud
    from Usuario_objtab u
    where idUsuario = 6
)
values (
    (select ref(s) 
    from Solicitud_objtab s 
    where idSolicitud = 3)
);

/

insert into Usuario_objtab values (
    Promotor_objtyp (
        usuario_idusuario_seq.nextval,'Carmen','González','Pérez','47568239P','654782346',
        'carmen.gonzalez@hotmail.com','C/Fresas,13', 'Palma de Mallorca','07001','España','@1523',
        'ES1401287843663179595464','Gerente de Subsole. Mi función es dirigir la empresa y buscar fuentes de financiación.', Solicitud_ntabtyp()
    )
);

/

insert into table (
    select treat (value(u) as Promotor_objtyp).solicitud
    from Usuario_objtab u
    where idUsuario = 7
)
values (
    (select ref(s) 
    from Solicitud_objtab s 
    where idSolicitud = 5)
);

/

insert into Usuario_objtab values (
    Promotor_objtyp (
        usuario_idusuario_seq.nextval,'Pablo','Serrano','López','15268743H','659753852',
        'pablo.serrano@hotmail.com','C/Papaya,13', 'Ceuta','51001','España','@48563',
        'ES3800752811858695525358','Gerente de Green. Mi función es dirigir la empresa y buscar fuentes de financiación.', Solicitud_ntabtyp()
    )
);

/

insert into table (
    select treat (value(u) as Promotor_objtyp).solicitud
    from Usuario_objtab u
    where idUsuario = 8
)
values (
    (select ref(s) 
    from Solicitud_objtab s 
    where idSolicitud = 6)
);

/


insert into Usuario_objtab values (
    Promotor_objtyp (
        usuario_idusuario_seq.nextval,'Marta','Pérez','Canuto','47461589M','789486153',
        'marta.perez@hotmail.com','C/Mango,7', 'Ciudad Real','13001','España','@7703',
        'ES0704875448082543597181','Gerente de STC. Mi función es dirigir la empresa y buscar fuentes de financiación.', Solicitud_ntabtyp()
    )
);

/

insert into table (
    select treat (value(u) as Promotor_objtyp).solicitud
    from Usuario_objtab u
    where idUsuario = 9
)
values (
    (select ref(s) 
    from Solicitud_objtab s 
    where idSolicitud = 7)
);

/

insert into Usuario_objtab values (
    Promotor_objtyp (
        usuario_idusuario_seq.nextval,'Carlos','Herrera','Gómez','12457863P','705869421',
        'carlos.herrera@hotmail.com','C/Piña,72', 'Madrid','28010','España','@6613',
        'ES7621006394134282785264','Gerente de Klantec. Mi función es dirigir la empresa y buscar fuentes de financiación.', Solicitud_ntabtyp()
    )
);

/

insert into table (
    select treat (value(u) as Promotor_objtyp).solicitud
    from Usuario_objtab u
    where idUsuario = 10
)
values (
    (select ref(s) 
    from Solicitud_objtab s 
    where idSolicitud = 8)
);

/

insert into Usuario_objtab values (
    Promotor_objtyp (
        usuario_idusuario_seq.nextval,'Ana','Gómez','Ferreras','65413289K','648423987',
        'ana.gomez@hotmail.com','C/Pera,13', 'Madrid','28024','España','@13513',
        'ES7220951879156521431895','Gerente de Juguetería LMC. Mi función es dirigir la empresa y buscar fuentes de financiación.', Solicitud_ntabtyp()
    )
);

/

insert into table (
    select treat (value(u) as Promotor_objtyp).solicitud
    from Usuario_objtab u
    where idUsuario = 11
)
values (
    (select ref(s) 
    from Solicitud_objtab s 
    where idSolicitud = 9)
);

/

insert into Usuario_objtab values (
    Promotor_objtyp (
        usuario_idusuario_seq.nextval,'Marcos','Carretero','Pereza','06487391Y','729813465',
        'marco.carretero@hotmail.com','C/Yogurt,14', 'Barcelona','08007','España','@1813',
        'ES3701287351631963911425','Gerente de Marcos Carretero Logística SL. Mi función es dirigir la empresa y buscar fuentes de financiación.', Solicitud_ntabtyp()
    )
);

/

insert into table (
    select treat (value(u) as Promotor_objtyp).solicitud
    from Usuario_objtab u
    where idUsuario = 12
)
values (
    (select ref(s) 
    from Solicitud_objtab s 
    where idSolicitud = 10)
);

/
-- RETORNO
insert into Retorno_objtab values ( -- De inversor 1, inversión 1
    Retorno_objtyp (
        retorno_idretorno_seq.nextval, 5000.00
    )
);

/

insert into Retorno_objtab values ( -- De inversor 1, inversión 2
    Retorno_objtyp (
        retorno_idretorno_seq.nextval, 1572.00
    )
);

/

insert into Retorno_objtab values ( -- De inversor 2, inversión 3
    Retorno_objtyp (
        retorno_idretorno_seq.nextval, 6000.00
    )
);

/


-- INVERSIÓN
insert into Inversion_objtab values (   -- De inversor 1, de proyecto finalizado
    Inversion_objtyp (
        inversion_idinversion_seq.nextval, 'RECAUDACIÓN', 11589.00, Retorno_ntabtyp()
    )
);

/

insert into table (
    select retorno
    from Inversion_objtab
    where idInversion = 1
)
values (
    (select ref(r) 
    from Retorno_objtab r 
    where idRetorno = 1)
);

/

insert into Inversion_objtab values (   -- De inversor 1, de proyecto finalizado
    Inversion_objtyp (
        inversion_idinversion_seq.nextval, 'RECAUDACIÓN', 1572.00, Retorno_ntabtyp()
    )
);

/

insert into table (
    select retorno
    from Inversion_objtab
    where idInversion = 2
)
values (
    (select ref(r) 
    from Retorno_objtab r 
    where idRetorno = 2)
);

/

insert into Inversion_objtab values (   -- De inversor 2, de proyecto finalizado
    Inversion_objtyp (
        inversion_idinversion_seq.nextval, 'RECAUDACIÓN', 9615.00, Retorno_ntabtyp()
    )
);

/

insert into table (
    select retorno
    from Inversion_objtab
    where idInversion = 3
)
values (
    (select ref(r) 
    from Retorno_objtab r 
    where idRetorno = 3)
);

/

insert into Inversion_objtab values (   -- De inversor 3, de proyecto finalizado
    Inversion_objtyp (
        inversion_idinversion_seq.nextval, 'RECAUDACIÓN', 7903.00, Retorno_ntabtyp()
    )
);

/

insert into Inversion_objtab values ( -- De inversor 3, de proyecto 2
    Inversion_objtyp (
        inversion_idinversion_seq.nextval, 'EN CURSO', 7205.00, Retorno_ntabtyp()
    )
);

/


-- USUARIO INVERSOR
insert into Usuario_objtab values (
    Inversor_objtyp (
        usuario_idusuario_seq.nextval, 'Lucía', 'Pérez', 'Muñoz', '15151515E', '676296378',
        'lucia.perez@hotmail.com', 'C/La Fresa,12,2ºC', 'Palma de Mallorca', '07001', 'España', '@1238', 
        'ES7100751186435136997493', 23000.00, '5508940724815660', Inversion_ntabtyp()
    )
);

/

insert into table (
    select treat (value(u) as Inversor_objtyp).inversion
    from Usuario_objtab u
    where idUsuario = 13
)
values (
    (select ref(i) 
    from Inversion_objtab i 
    where idInversion = 1)
);

/

insert into table (
    select treat (value(u) as Inversor_objtyp).inversion
    from Usuario_objtab u
    where idUsuario = 13
)
values (
    (select ref(i) 
    from Inversion_objtab i 
    where idInversion = 2)
);

/

insert into Usuario_objtab values (
    Inversor_objtyp (
        usuario_idusuario_seq.nextval,'Antonio', 'García', 'Martínez', '16161616F', '688856969',
        'antonio.garcia@gmail.com', 'C/El Albaricoque,13,3D', 'Jaen', '23002 ', 'España', '@1239', 
        'ES7020802567486791854281', 1568.78, '5559156876003462', Inversion_ntabtyp()
    )
);

/

insert into table (
    select treat (value(u) as Inversor_objtyp).inversion
    from Usuario_objtab u
    where idUsuario = 14
)
values (
    (select ref(i)
    from Inversion_objtab i
    where idInversion = 3)
);

/

insert into Usuario_objtab values (
    Inversor_objtyp (
        usuario_idusuario_seq.nextval,'Josefa', 'López', 'González', '17171717G', '659875421',
        'josefa.lopez@hotmail.com', 'C/El Limón,17,4ºI', 'Sevilla', '41001', 'España', '@1230', 
        'ES9520806487214562472181', 2015.15, '5421301422139099', Inversion_ntabtyp()
    )
);

/

insert into table (
    select treat (value(u) as Inversor_objtyp).inversion
    from Usuario_objtab u
    where idUsuario = 15
)
values (
    (select ref(i)
    from Inversion_objtab i
    where idInversion = 4)
);

/

insert into table (
    select treat (value(u) as Inversor_objtyp).inversion
    from Usuario_objtab u
    where idUsuario = 15
)
values (
    (select ref(i)
    from Inversion_objtab i
    where idInversion = 5)
);

/

insert into Usuario_objtab values (
    Inversor_objtyp (
        usuario_idusuario_seq.nextval, 'Ana', 'Navarro', 'Serrano', '18181818H', '744896245',
        'ana.navarro@gmail.com', 'C/La Pera,5,1ºD', 'Oviedo', '33001', 'España', '@1231',
        'ES2531906198817219549159', 2657.16, '5313682450839689', Inversion_ntabtyp()
    )
);

/


-- AREA
insert into Area_objtab values (
    Area_objtyp (
        area_idarea_seq.nextval, 'TIC'
    )
);

/

insert into Area_objtab values (
    Area_objtyp (
        area_idarea_seq.nextval, 'Sanidad'
    )
);

/

insert into Area_objtab values (
    Area_objtyp (
        area_idarea_seq.nextval, 'Agricultura'
    )
);

/

insert into Area_objtab values (
    Area_objtyp (
        area_idarea_seq.nextval, 'Educación'
    )
);

/

insert into Area_objtab values (
    Area_objtyp (
        area_idarea_seq.nextval, 'Robótica'
    )
);

/

insert into Area_objtab values (
    Area_objtyp (
        area_idarea_seq.nextval, 'Cocina'
    )
);

/

insert into Area_objtab values (
    Area_objtyp (
        area_idarea_seq.nextval, 'Metalurgia'
    )
);

/

insert into Area_objtab values (
    Area_objtyp (
        area_idarea_seq.nextval, 'Transporte'
    )
);

/

insert into Area_objtab values (
    Area_objtyp (
        area_idarea_seq.nextval, 'Turismo'
    )
);

/


-- PROYECTO
insert into Proyecto_objtab
    select proyecto_idproyecto_seq.nextval, ref(s), 'VirtualI', 'FINANCIADO', 'C', 12, 26000.00, 
    '12/02/2020', 35000.00, 7.00, 6.00, 3, 100, Inversion_ntabtyp(), Area_ntabtyp()
    from Solicitud_objtab s
    where s.idSolicitud = 1;

/

insert into table (
    select inversion
    from Proyecto_objtab
    where idProyecto = 1
)
values (
    (select ref(i)
    from Inversion_objtab i
    where idInversion = 1)
);

/

insert into table (
    select inversion
    from Proyecto_objtab
    where idProyecto = 1
)
values (
    (select ref(i)
    from Inversion_objtab i
    where idInversion = 2)
);

/

insert into table (
    select inversion
    from Proyecto_objtab
    where idProyecto = 1
)
values (
    (select ref(i)
    from Inversion_objtab i
    where idInversion = 3)
);

/

insert into table (
    select inversion
    from Proyecto_objtab
    where idProyecto = 1
)
values (
    (select ref(i)
    from Inversion_objtab i
    where idInversion = 4)
);

/

insert into table (
    select area
    from Proyecto_objtab
    where idProyecto = 1
)
values (
    (select ref(a)
    from Area_objtab a
    where idArea = 1)
);

/

insert into Proyecto_objtab
    select proyecto_idproyecto_seq.nextval, ref(s), 'E-MEDICA', 'EN FINANCIACIÓN', 'A', 12, 1000, 
    '22/02/2021', 50000.00, 6.00, null, 0, 0, Inversion_ntabtyp(), Area_ntabtyp()
    from Solicitud_objtab s
    where s.idSolicitud = 2;

/

insert into table (
    select inversion
    from Proyecto_objtab
    where idProyecto = 2
)
values (
    (select ref(i)
    from Inversion_objtab i
    where idInversion = 5)
);

/

insert into table (
    select area
    from Proyecto_objtab
    where idProyecto = 2
)
values (
    (select ref(a)
    from Area_objtab a
    where idArea = 2)
);

/


-- PUESTO
insert into Puesto_objtab values (
    Puesto_objtyp (
        puesto_idpuesto_seq.nextval, 'Gerente', 2000.00, 1, Empleado_ntabtyp()
    )
);

/

insert into table (
    select empleado
    from Puesto_objtab
    where idPuesto = 1
)
values (
    (select treat (ref(e) as ref Empleado_objtyp)
    from Usuario_objtab e
    where idUsuario = 3)
);

/

insert into Puesto_objtab values (
    Puesto_objtyp (
        puesto_idpuesto_seq.nextval, 'Administrativo', 1800.00, 1, Empleado_ntabtyp()
    )
);

/

insert into table (
    select empleado
    from Puesto_objtab
    where idPuesto = 2
)
values (
    (select treat (ref(e) as ref Empleado_objtyp)
    from Usuario_objtab e
    where idUsuario = 1)
);

/

insert into table (
    select empleado
    from Puesto_objtab
    where idPuesto = 2
)
values (
    (select treat (ref(e) as ref Empleado_objtyp)
    from Usuario_objtab e
    where idUsuario = 2)
);

------------------------------------------------- TYPE BODYs ----------------------------------------------------------------------------

-- Funciones USUARIO
create or replace TYPE BODY usuario_objtyp AS 
    MEMBER PROCEDURE cambiarContraseña(nuevaContraseña in VARCHAR2) IS 
    BEGIN 
        IF self IS OF (usuario_objtyp) THEN            
            UPDATE usuario_objtab 
            SET contraseña = nuevaContraseña 
            WHERE idusuario = SELF.idusuario;
            DBMS_OUTPUT.PUT_LINE('La contraseña del usuario ha sido cambiada');
        end if;
    END;
    order member function ordenar (v_usuario in Usuario_objtyp) return integer is
    BEGIN
    if v_usuario.idUsuario < self.idUsuario then
        DBMS_OUTPUT.PUT_LINE('ID mayor.');
        return 1;
    else
        DBMS_OUTPUT.PUT_LINE('ID menor.');
        return 0;
    end if;
    END;
end;
/

-- Funciones SOLICITUD
create or replace type body Solicitud_objtyp as
    member procedure cambiarEstado (estado in varchar2) IS
    BEGIN
        update Solicitud_objtab 
        set estadoSolicitud = estado 
        where idSolicitud = self.idSolicitud;
        DBMS_OUTPUT.PUT_LINE('Estado de la solicitud actualizado.');
    END;

    order member function ordenar (v_solicitud in Solicitud_objtyp) return integer is
    BEGIN
    if v_solicitud.idSolicitud < self.idSolicitud then
        DBMS_OUTPUT.PUT_LINE('ID mayor.');
        return 1;
    else
        DBMS_OUTPUT.PUT_LINE('ID menor.');
        return 0;
    end if;
    END;
END;
/

-- Funciones RETORNO
create or replace type body Retorno_objtyp as
    order member function ordenar (v_retorno in Retorno_objtyp) return integer is
    BEGIN
    if v_retorno.idRetorno < self.idRetorno then
        DBMS_OUTPUT.PUT_LINE('ID mayor.');
        return 1;
    else
        DBMS_OUTPUT.PUT_LINE('ID menor.');
        return 0;
    end if;
    END;
END;

/

-- Funciones INVERSION
create or replace type body Inversion_objtyp as
    order member function ordenar (v_inversion in Inversion_objtyp) return integer is
    BEGIN
    if v_inversion.idInversion < self.idInversion then
        DBMS_OUTPUT.PUT_LINE('ID mayor.');
        return 1;
    else
        DBMS_OUTPUT.PUT_LINE('ID menor.');
        return 0;
    end if;
    END;
END;

/

-- Funciones AREA
create or replace type body Area_objtyp as
    order member function ordenar (v_area in Area_objtyp) return integer is
    BEGIN
    if v_area.idArea < self.idArea then
        DBMS_OUTPUT.PUT_LINE('ID mayor.');
        return 1;
    else
        DBMS_OUTPUT.PUT_LINE('ID menor.');
        return 0;
    end if;
    END;
END;

/

-- Funciones PROYECTO
create or replace type body Proyecto_objtyp as
    order member function ordenar (v_proyecto in Proyecto_objtyp) return integer is
    BEGIN
    if v_proyecto.idProyecto < self.idProyecto then
        DBMS_OUTPUT.PUT_LINE('ID mayor.');
        return 1;
    else
        DBMS_OUTPUT.PUT_LINE('ID menor.');
        return 0;
    end if;
    END;
END;

/

-- Funciones PUESTO
create or replace type body Puesto_objtyp as
    order member function ordenar (v_puesto in Puesto_objtyp) return integer is
    BEGIN
    if v_puesto.idPuesto < self.idPuesto then
        DBMS_OUTPUT.PUT_LINE('ID mayor.');
        return 1;
    else
        DBMS_OUTPUT.PUT_LINE('ID menor.');
        return 0;
    end if;
    END;
END;

/

--------------------------------------------------------------- BORRADO -----------------------------------------------------------------
drop table area_objtab cascade constraints;
drop table inversion_objtab cascade constraints;
drop table proyecto_objtab cascade constraints;
drop table puesto_objtab cascade constraints;
drop table retorno_objtab cascade constraints;
drop table solicitud_objtab cascade constraints;
drop table usuario_objtab cascade constraints;
drop table donacion_tab cascade constraints;

drop type area_ntabtyp force;
drop type area_objtyp force;
drop type empleado_ntabtyp force;
drop type empleado_objtyp force;
drop type inversion_ntabtyp force;
drop type inversion_objtyp force;
drop type inversor_objtyp force;
drop type promotor_objtyp force;
drop type proyecto_objtyp force;
drop type puesto_objtyp force;
drop type retorno_ntabtyp force;
drop type retorno_objtyp force;
drop type solicitud_ntabtyp force;
drop type solicitud_objtyp force;
drop type usuario_objtyp force;

drop sequence usuario_idusuario_seq;
drop sequence proyecto_idproyecto_seq;
drop sequence solicitud_idsolicitud_seq;
drop sequence retorno_idretorno_seq;
drop sequence inversion_idinversion_seq;
drop sequence area_idarea_seq;
drop sequence puesto_idpuesto_seq;

drop view vista_empleado;
drop view vista_inversor;
drop view vista_promotor;
drop view total_donaciones;

------------------------------------------- VISTAS IMPORTANTES -----------------------------------------------
-- Muestra todos los datos de los empleados de StartGrow (Yasín)
create view vista_empleado as
select t1.*,
       treat (value(t1) as empleado_objtyp).salario as salario,
       treat (value(t1) as empleado_objtyp).solicitud as solicitud
from usuario_objtab t1
where value(t1) is of (empleado_objtyp); 

/

-- Muestra todos los datos de los inversores de StartGrow (Yasín)
create view vista_inversor as
select t1.*,
    treat (value(t1) as Inversor_objtyp).saldo as saldo,
    treat (value(t1) as Inversor_objtyp).tarjetacredito as tarjetacredito,    
    treat (value(t1) as Inversor_objtyp).inversion as inversion   
from Usuario_objtab t1
where value (t1) is of (Inversor_objtyp);
 

/

-- Muestra todos los datos de los promotores de StartGrow (Yasín)
create view vista_promotor as
select idUsuario, nombre, apellido1, apellido2, nif, telefono, 
    email, domicilio, municipio, codpost, pais, contraseña, cuentaBanco,
    treat (value(u) as Promotor_objtyp).actividad as actividad,
    treat (value(u) as Promotor_objtyp).solicitud as solicitud
from Usuario_objtab u
WHERE VALUE(u) IS OF (Promotor_objtyp);  

/

-- Muestra todas las solicitudes gestionadas por Jesús Buendía (Yasín)
select s.column_value.idSolicitud as idSolicitud, u.nombre, u.apellido1,
s.column_value.nombre as nombre_solicitud
from vista_empleado u, table (u.solicitud) s
where nombre = 'Jesús' and apellido1 = 'Buendía';

/

-- Muestra todas las inversiones realizadas por todos los usuarios junto con sus reembolsos
select t1.nombre, t1.apellido1,
       t2.column_value.idInversion,
       t2.column_value.estadoinversion,
       t2.column_value.capInvertido,
       t3.column_value.idRetorno,
       t3.column_value.reembolso
from vista_inversor t1, 
     table(t1.inversion) t2, 
     table (t2.column_value.retorno) t3

----------------------------------------------- VISTAS -------------------------------------------------------
-- Mostrar el salario de los empleados con su nombre y apellidos (Yasín)
CREATE VIEW emp_view1 as
    SELECT treat (value (p) as Empleado_objtyp).nombre as nombre,
           treat (value (p) as Empleado_objtyp).apellido1 as apellido1,
           treat (value (p) as Empleado_objtyp).apellido2 as apellido2,
           treat (value (p) as Empleado_objtyp).salario as salario
    FROM usuario_objtab p
    WHERE VALUE(p) IS OF (Empleado_objtyp);

/

-- Mostrar los proyectos de menor riesgo y cuyo importe objetivo sea superior a 40000€ (Yasín)
CREATE VIEW proy_view1 as
    SELECT *
    FROM proyecto_objtab
    WHERE Rating ='A' and importeobjetivo > 40000;

/

-- Inversores que tengan tarjeta de crédito y más de 2000€ de saldo
CREATE VIEW inv_view1 as
    SELECT treat (value(p) as Inversor_objtyp).nombre as nombre,
       treat (value(p) as Inversor_objtyp).apellido1 as apellido1,
       treat (value(p) as Inversor_objtyp).apellido2 as apellido2
    FROM Usuario_objtab p
    WHERE (treat (value (p) as Inversor_objtyp).saldo) > 2000 
    and (treat (value (p) as Inversor_objtyp).tarjetaCredito) is not null;

/

-- Mostrar las inversiones que tienen un proyecto (Javier)
CREATE VIEW proy_view2 as
    SELECT P.idProyecto, DEREF(I.column_value).idInversion as IDINVERSION, DEREF(I.column_value).estadoInversion as ESTADOINVERSION, DEREF(I.column_value).capInvertido AS CAPINVERTIDO
    FROM Proyecto_objtab P, table(P.inversion) I;

/

-- Mostrar los empleados que ocupan el puesto de administrativo (Javier)
CREATE VIEW puesto_view1 as
    SELECT P.idPuesto, DEREF(E.column_value).nombre as nombre, 
    DEREF(E.column_value).apellido1 as apellido1, 
    DEREF(E.column_value).apellido2 as apellido2
    FROM Puesto_objtab P, table(P.empleado) E;

/

-- Mostrar las areas de un proyecto financiado (Javier)
CREATE VIEW pareas_view1 as
    SELECT P.nombre, DEREF(A.column_value).nombre as area
    FROM Proyecto_objtab P, table(P.area) A
    WHERE P.estadoProyecto = 'FINANCIADO';

-- Mostrar proyectos con más de una inversión

-- Mostrar los empleados que tienen asignada alguna solicitud
--select *
--from Usuario_objtab u
--where value(u) is of (Empleado_objtyp) and count(treat (value(u) as Empleado_objtyp)).solicitud > 1;

-- Ver las solicitudes que están en curso y el empleado que la gestiona
--select * --treat(value (u) as Empleado_objtyp).solicitud
--from Usuario_objtab u
--where value(u) is of (Empleado_objtyp) and treat (value (u) as Empleado_objtyp).solicitud.idSolicitud in
--(select idSolicitud
--from Solicitud_objtab s
--where s.estadoSolicitud = 'EN CURSO')


--------------------------------------PROCEDIMIENTOS ALMACENADOS (Yasín)-------------------------------------------
-- Impuesto Empleado. Recibe dos parámetros IN (solo lectura)
create or replace procedure taxempleado
  (empleado vista_empleado.idusuario%type,
  t number)
is  
  tax number;
  sal number;
begin
    select salario into sal
    from vista_empleado 
    where idusuario = empleado;

    tax := sal*t/100;
    dbms_output.put_line('SALARIO: '||sal);
    dbms_output.put_line('IMPUESTOS '||tax);
end;

set serveroutput on
begin
    taxempleado(1,10);
end;

--





---------------------------------------- PROCEDIMIENTOS ALMACENADOS (Javier) ---------------------------------------















------------------------------------------------- TRIGGERS (Yasín) -----------------------------------------------












-------------------------------------------------- TRIGGERS (Javier) ------------------------------------------------



















