-- 1) Insertar el XML Schema en SQL Developer
BEGIN
DBMS_XMLSCHEMA.REGISTERSCHEMA(SCHEMAURL=>'donacion.xsd',
schemadoc=> '<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
<xs:element name="donacion" type="TipoDonacion">
    <xs:key name="ClaveDNI">
        <xs:selector xpath= "xs:inversor"/>
        <xs:field xpath="xs:dni"/>
    </xs:key>
    <xs:unique name="UProyecto">
        <xs:selector xpath= "xs:proyecto"/>
        <xs:field xpath="xs:nombre_p"/>
    </xs:unique>
    <xs:keyref name="RefInversor" refer="ClaveDNI">
        <xs:selector xpath="xs:donativo"/>
        <xs:field xpath="xs:dni"/>
    </xs:keyref>
</xs:element>

<xs:complexType name="TipoDonacion">
    <xs:sequence>
	    <xs:element name="proyecto" type="TipoProyecto" maxOccurs="unbounded"/>
	    <xs:element name="inversor" type="TipoInversor" maxOccurs="unbounded"/>
	    <xs:element name="donativo" type="TipoDonativo" maxOccurs="unbounded"/>
    </xs:sequence>
</xs:complexType>

<xs:simpleType name="listAreas">
	<xs:list itemType="xs:string"/>
</xs:simpleType>

<xs:complexType name="TipoProyecto">
	<xs:sequence>
		<xs:element name="nombre_p" type="xs:string"/>
		<xs:element name="rating" type="xs:string"/>
		<xs:element name="area" type="listAreas"/>
	</xs:sequence>
    <xs:attribute name="estado" use="required" type="xs:string"/>
</xs:complexType>

<xs:complexType name="TipoInversor">
	<xs:sequence>
		<xs:element name="nombre_i" type="xs:string"/>
		<xs:element name="dni" type="xs:string"/>
		<xs:element name="saldo" type="xs:decimal"/>
	</xs:sequence>
</xs:complexType>

<xs:complexType name="TipoDonativo">
	<xs:sequence>
		<xs:element name="nombre_p" type="xs:string"/>
		<xs:element name="dni" type="xs:string"/>
		<xs:element name="cantidad" type="xs:decimal"/>
	</xs:sequence>
</xs:complexType>

</xs:schema>',

local=>true, gentypes=>false, genbean=>false, gentables=>false, force=>false, options=>dbms_xmlschema.register_binaryxml, owner=>user);

commit;
END;

-- 2) Creación de la Tabla
CREATE TABLE DONACION_TAB (
	ID NUMBER PRIMARY KEY,
	DONACION XMLTYPE
)
XMLTYPE COLUMN DONACION STORE AS BINARY XML
XMLSCHEMA "donacion.xsd" ELEMENT "donacion";

-- 3) Insertar datos en la tabla:
INSERT INTO DONACION_TAB VALUES(1,
'<?xml version="1.0" encoding="UTF-8"?>
<donacion xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<proyecto estado="en financiacion">
		<nombre_p>ReBur</nombre_p>
        <rating>A</rating>
        <area>Agricultura Turismo</area>
	</proyecto>
	<proyecto estado="financiado">
		<nombre_p>Circle Zero</nombre_p>
        <rating>B</rating>
        <area>Robotica</area>
	</proyecto>

	<inversor>
		<nombre_i>Lucia Perez</nombre_i>
        <dni>15151515E</dni>
        <saldo>23000</saldo>
	</inversor>
	<inversor>
		<nombre_i>Antonio Garcia</nombre_i>
        <dni>16161616F</dni>
        <saldo>1568</saldo>
	</inversor>

	<donativo>
		<nombre_p>ReBur</nombre_p>
        <dni>15151515E</dni>
		<cantidad>10000</cantidad>
	</donativo>
	<donativo>
		<nombre_p>Circle Zero</nombre_p>
        <dni>16161616F</dni>
		<cantidad>500</cantidad>
	</donativo>
</donacion>'
);

INSERT INTO DONACION_TAB VALUES(2,
'<?xml version="1.0" encoding="UTF-8"?>
<donacion xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<proyecto estado="en financiacion">
		<nombre_p>ALVE</nombre_p>
        <rating>C</rating>
        <area>TIC</area>
	</proyecto>
	<proyecto estado="en financiacion">
		<nombre_p>VAINSA</nombre_p>
        <rating>B</rating>
        <area>Cocina</area>
	</proyecto>

	<inversor>
		<nombre_i>Diego Rodríguez</nombre_i>
        <dni>99994568Y</dni>
        <saldo>20000</saldo>
	</inversor>
	<inversor>
		<nombre_i>Sergio Martínez</nombre_i>
        <dni>18194574J</dni>
        <saldo>15000</saldo>
	</inversor>

	<donativo>
		<nombre_p>ALVE</nombre_p>
        <dni>99994568Y</dni>
		<cantidad>200</cantidad>
	</donativo>
	<donativo>
		<nombre_p>VAINSA</nombre_p>
        <dni>18194574J</dni>
		<cantidad>150</cantidad>
	</donativo>
</donacion>'
);

-- 4) Indexar la tabla
CREATE INDEX IDX_DONACION ON DONACION_TAB(donacion) INDEXTYPE IS XDB.XMLINDEX;

-- 5) Consultas Xpath
-- Javier
-- Consulta 1: El nombre de los proyectos que están financiados
CREATE VIEW proy_financiados AS
    SELECT EXTRACT(DONACION, 'donacion/proyecto[@estado="financiado"]/nombre_p/text()') AS FINANCIADO
    FROM DONACION_TAB
    WHERE ID = 1;

-- Consulta 2: el nombre de los inversores que tienen más saldo que Antonio Garcia
CREATE VIEW saldo_gt_Antonio_Garcia AS
    SELECT EXTRACT(DONACION, '//inversor[saldo > //inversor[nombre_i = "Antonio Garcia"]/saldo/text()]/nombre_i/text()') AS INVERSOR_GT
    FROM DONACION_TAB
    WHERE ID = 1;

-- Yasín
-- Consulta 1: Nombre de los proyectos donde Sergio Martínez ha hecho un donativo
CREATE VIEW DONATIVOS_SERGIO AS	
	SELECT EXTRACT(DONACION, '//donativo [dni = //inversor [nombre_i = "Sergio Martínez"]/dni/text()]/nombre_p/text()') AS PROYECTO
    FROM DONACION_TAB
    WHERE ID = 2;

-- Consulta 2: Nombre de los proyectos que han recibido más de 100 euros de donativo.
CREATE VIEW DONATIVOS_MAYORES_100 AS	
	SELECT EXTRACT(DONACION, '//donativo [cantidad > 100]/nombre_p/text()') AS PROYECTO
    FROM DONACION_TAB
    WHERE ID = 2;

-- 6) Consultas XQuery
-- Javier
-- Consulta 1: Las áreas de los proyectos con rating "A"
CREATE VIEW RATING_AREAS AS
	SELECT XMLQUERY('for $i in //proyecto
	                 where $i/rating = "A"
	                 return $i/area'
	        PASSING DONACION RETURNING CONTENT
	) AS PROYECTOS_A
	FROM DONACION_TAB
	WHERE ID = 1;

-- Consulta 2: Sumar y mostrar (let) la cantidad total donada al proyecto "ReBur"
CREATE VIEW DONACION_TOTAL_ReBur AS
	SELECT XMLQUERY('for $i in /donacion
	                 let $don := $i//cantidad[..[nombre_p="ReBur"]]
	                 return <donacion_total>{sum($don)}</donacion_total>'
	        PASSING DONACION RETURNING CONTENT
	) AS DONACION_ReBur
	FROM DONACION_TAB
	WHERE ID = 1;

-- Yasín
-- Consulta 1: Mostrar los proyectos cuya área es TIC
CREATE VIEW PROYECTOS_TIC AS	
	SELECT XMLQUERY('for $i in //proyecto
    	             where $i/area = "TIC"
        	         return $i/nombre_p/text()'
       	PASSING DONACION RETURNING CONTENT) AS PROYECTOS
	FROM DONACION_TAB
	WHERE ID = 2;    

-- Consulta 2: Suma de todas las donaciones.
CREATE VIEW TOTAL_DONACIONES AS	
	SELECT XMLQUERY('for $i in //donacion
    	             let $don := $i//cantidad
					 let $sum := sum($don)
        	         return $sum'
       	PASSING DONACION RETURNING CONTENT) AS TOTAL_DONACIONES
	FROM DONACION_TAB
	WHERE ID = 2;  

-- 7) 1 inserción, 1 modificación y 1 borrado de elementos
-- Javier
-- Inserción
UPDATE DONACION_TAB
SET DONACION = APPENDCHILDXML(DONACION, '/donacion',
    xmltype(
        '<donativo>
            <nombre_p>ReBur</nombre_p>
            <dni>16161616F</dni>
		    <cantidad>600</cantidad>
         </donativo>'
    )
)
WHERE ID = 1;

-- Yasín
-- Inserción
UPDATE DONACION_TAB
SET DONACION = APPENDCHILDXML(DONACION, '/donacion',
    xmltype(
        '<donativo>
			<nombre_p>ALVE</nombre_p>
        	<dni>18194574J</dni>
			<cantidad>150</cantidad>
		</donativo>'
    )
)
WHERE ID = 2;

-- Javier
-- Modificación
UPDATE DONACION_TAB
SET DONACION = UPDATEXML(DONACION, '/donacion/donativo[nombre_p="ReBur"][2]/cantidad/text()', 700)
WHERE ID = 1;

-- Yasín
-- Modificación
UPDATE DONACION_TAB
SET DONACION = UPDATEXML(DONACION, '/donacion/donativo[nombre_p="ALVE"][2]/cantidad/text()', 200)
WHERE ID = 2;

-- Javier
-- Borrado
UPDATE DONACION_TAB
SET DONACION = DELETEXML(DONACION, '/donacion/donativo[nombre_p="ReBur"][2]')
WHERE ID = 1;

-- Yasín
-- Borrado
UPDATE DONACION_TAB
SET DONACION = DELETEXML(DONACION, '/donacion/donativo[nombre_p="ALVE"][2]')
WHERE ID = 2;
