PGDMP      "                }         
   kiran_game    13.20    17.4 �    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                           false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                           false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                           false            �           1262    33424 
   kiran_game    DATABASE     p   CREATE DATABASE kiran_game WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en-US';
    DROP DATABASE kiran_game;
                     postgres    false            �           0    0    DATABASE kiran_game    ACL     /   GRANT ALL ON DATABASE kiran_game TO kiran_app;
                        postgres    false    3253                        2615    2200    public    SCHEMA     2   -- *not* creating schema, since initdb creates it
 2   -- *not* dropping schema, since initdb creates it
                     postgres    false            �           0    0    SCHEMA public    ACL     Q   REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;
                        postgres    false    4            �            1255    34064 <   calcular_recursos_viaje(integer, integer, character varying)    FUNCTION     k  CREATE FUNCTION public.calcular_recursos_viaje(p_id_ruta integer, p_tamano_caravana integer, p_tipo_transporte character varying) RETURNS TABLE(id_recurso integer, cantidad integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_distancia INTEGER;
BEGIN
    IF p_tipo_transporte = 'tierra' THEN
        SELECT distancia_tierra INTO v_distancia FROM rutas WHERE id_ruta = p_id_ruta;
    ELSIF p_tipo_transporte = 'mar' THEN
        SELECT distancia_mar INTO v_distancia FROM rutas WHERE id_ruta = p_id_ruta;
    ELSE
        RAISE EXCEPTION 'Tipo de transporte no válido: %', p_tipo_transporte;
    END IF;

    IF v_distancia IS NULL THEN
        RAISE EXCEPTION 'Ruta % no soporta transporte por %', p_id_ruta, p_tipo_transporte;
    END IF;

    RETURN QUERY
    SELECT id_recurso, 
        CASE nombre 
            WHEN 'Agua' THEN v_distancia * p_tamano_caravana * 2
            WHEN 'Comida' THEN v_distancia * p_tamano_caravana
            WHEN 'Herramientas' THEN (v_distancia * p_tamano_caravana / 2)::INTEGER
            ELSE 0
        END
    FROM recursos
    WHERE nombre IN ('Agua', 'Comida', 'Herramientas');
END;
$$;
 �   DROP FUNCTION public.calcular_recursos_viaje(p_id_ruta integer, p_tamano_caravana integer, p_tipo_transporte character varying);
       public               postgres    false    4            �            1255    34133    registrar_historial_precio()    FUNCTION     �   CREATE FUNCTION public.registrar_historial_precio() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO historial_precios (ciudad, id_producto, precio)
    VALUES (NEW.ciudad, NEW.id_producto, NEW.precio_actual);
    RETURN NEW;
END;
$$;
 3   DROP FUNCTION public.registrar_historial_precio();
       public               postgres    false    4            �            1259    33911    bitacora    TABLE     �   CREATE TABLE public.bitacora (
    id_bitacora integer NOT NULL,
    fecha_hora timestamp without time zone,
    accion text,
    responsable character varying(50),
    id_partida integer
);
    DROP TABLE public.bitacora;
       public         heap r       postgres    false    4            �           0    0    TABLE bitacora    ACL     e   GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.bitacora TO kiran_app;
          public               postgres    false    222            �            1259    33909    bitacora_id_bitacora_seq    SEQUENCE     �   CREATE SEQUENCE public.bitacora_id_bitacora_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.bitacora_id_bitacora_seq;
       public               postgres    false    222    4            �           0    0    bitacora_id_bitacora_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.bitacora_id_bitacora_seq OWNED BY public.bitacora.id_bitacora;
          public               postgres    false    221            �           0    0 !   SEQUENCE bitacora_id_bitacora_seq    ACL     D   GRANT ALL ON SEQUENCE public.bitacora_id_bitacora_seq TO kiran_app;
          public               postgres    false    221            �            1259    33894    caravana_evento    TABLE     �   CREATE TABLE public.caravana_evento (
    id_caravana integer NOT NULL,
    id_evento integer NOT NULL,
    dia_ocurrencia integer NOT NULL
);
 #   DROP TABLE public.caravana_evento;
       public         heap r       postgres    false    4            �           0    0    TABLE caravana_evento    ACL     l   GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.caravana_evento TO kiran_app;
          public               postgres    false    220            �            1259    33871    caravana_recursos    TABLE     �   CREATE TABLE public.caravana_recursos (
    id_caravana integer NOT NULL,
    id_recurso integer NOT NULL,
    cantidad integer
);
 %   DROP TABLE public.caravana_recursos;
       public         heap r       postgres    false    4            �           0    0    TABLE caravana_recursos    ACL     n   GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.caravana_recursos TO kiran_app;
          public               postgres    false    217            �            1259    33854 	   caravanas    TABLE     �   CREATE TABLE public.caravanas (
    id_caravana integer NOT NULL,
    id_jugador integer,
    tamano integer,
    estado character varying(20),
    ruta_actual integer,
    dias_transcurridos integer DEFAULT 0
);
    DROP TABLE public.caravanas;
       public         heap r       postgres    false    4            �           0    0    TABLE caravanas    ACL     f   GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.caravanas TO kiran_app;
          public               postgres    false    216            �            1259    33852    caravanas_id_caravana_seq    SEQUENCE     �   CREATE SEQUENCE public.caravanas_id_caravana_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE public.caravanas_id_caravana_seq;
       public               postgres    false    4    216            �           0    0    caravanas_id_caravana_seq    SEQUENCE OWNED BY     W   ALTER SEQUENCE public.caravanas_id_caravana_seq OWNED BY public.caravanas.id_caravana;
          public               postgres    false    215            �           0    0 "   SEQUENCE caravanas_id_caravana_seq    ACL     E   GRANT ALL ON SEQUENCE public.caravanas_id_caravana_seq TO kiran_app;
          public               postgres    false    215            �            1259    34104    ciudad_eventos    TABLE     �   CREATE TABLE public.ciudad_eventos (
    ciudad_nombre character varying(50) NOT NULL,
    id_evento integer NOT NULL,
    tipo character varying(10)
);
 "   DROP TABLE public.ciudad_eventos;
       public         heap r       postgres    false    4            �           0    0    TABLE ciudad_eventos    ACL     k   GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.ciudad_eventos TO kiran_app;
          public               postgres    false    236            �            1259    34015    ciudad_productos_deseados    TABLE     �   CREATE TABLE public.ciudad_productos_deseados (
    ciudad_nombre character varying(50) NOT NULL,
    id_producto integer NOT NULL
);
 -   DROP TABLE public.ciudad_productos_deseados;
       public         heap r       postgres    false    4            �           0    0    TABLE ciudad_productos_deseados    ACL     v   GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.ciudad_productos_deseados TO kiran_app;
          public               postgres    false    231            �            1259    34000    ciudad_productos_producidos    TABLE     �   CREATE TABLE public.ciudad_productos_producidos (
    ciudad_nombre character varying(50) NOT NULL,
    id_producto integer NOT NULL
);
 /   DROP TABLE public.ciudad_productos_producidos;
       public         heap r       postgres    false    4            �           0    0 !   TABLE ciudad_productos_producidos    ACL     x   GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.ciudad_productos_producidos TO kiran_app;
          public               postgres    false    230            �            1259    33796    ciudades    TABLE     �   CREATE TABLE public.ciudades (
    nombre character varying(50) NOT NULL,
    tiene_puertos boolean,
    tiene_ciudades_alejadas boolean
);
    DROP TABLE public.ciudades;
       public         heap r       postgres    false    4            �           0    0    TABLE ciudades    ACL     e   GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.ciudades TO kiran_app;
          public               postgres    false    208            �            1259    33888    eventos    TABLE     �   CREATE TABLE public.eventos (
    id_evento integer NOT NULL,
    tipo character varying(50),
    efecto character varying(100),
    probabilidad numeric(3,2)
);
    DROP TABLE public.eventos;
       public         heap r       postgres    false    4            �           0    0    TABLE eventos    ACL     d   GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.eventos TO kiran_app;
          public               postgres    false    219            �            1259    33886    eventos_id_evento_seq    SEQUENCE     �   CREATE SEQUENCE public.eventos_id_evento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.eventos_id_evento_seq;
       public               postgres    false    4    219            �           0    0    eventos_id_evento_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.eventos_id_evento_seq OWNED BY public.eventos.id_evento;
          public               postgres    false    218            �           0    0    SEQUENCE eventos_id_evento_seq    ACL     A   GRANT ALL ON SEQUENCE public.eventos_id_evento_seq TO kiran_app;
          public               postgres    false    218            �            1259    33749    habilidades    TABLE        CREATE TABLE public.habilidades (
    id_habilidad integer NOT NULL,
    nombre character varying(50),
    descripcion text
);
    DROP TABLE public.habilidades;
       public         heap r       postgres    false    4            �           0    0    TABLE habilidades    ACL     h   GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.habilidades TO kiran_app;
          public               postgres    false    201            �            1259    33747    habilidades_id_habilidad_seq    SEQUENCE     �   CREATE SEQUENCE public.habilidades_id_habilidad_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE public.habilidades_id_habilidad_seq;
       public               postgres    false    4    201            �           0    0    habilidades_id_habilidad_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE public.habilidades_id_habilidad_seq OWNED BY public.habilidades.id_habilidad;
          public               postgres    false    200            �           0    0 %   SEQUENCE habilidades_id_habilidad_seq    ACL     H   GRANT ALL ON SEQUENCE public.habilidades_id_habilidad_seq TO kiran_app;
          public               postgres    false    200            �            1259    34047    historial_precios    TABLE     �   CREATE TABLE public.historial_precios (
    id_historial integer NOT NULL,
    ciudad character varying(50),
    id_producto integer,
    precio integer,
    fecha timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
 %   DROP TABLE public.historial_precios;
       public         heap r       postgres    false    4            �           0    0    TABLE historial_precios    ACL     n   GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.historial_precios TO kiran_app;
          public               postgres    false    234            �            1259    34045 "   historial_precios_id_historial_seq    SEQUENCE     �   CREATE SEQUENCE public.historial_precios_id_historial_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 9   DROP SEQUENCE public.historial_precios_id_historial_seq;
       public               postgres    false    4    234            �           0    0 "   historial_precios_id_historial_seq    SEQUENCE OWNED BY     i   ALTER SEQUENCE public.historial_precios_id_historial_seq OWNED BY public.historial_precios.id_historial;
          public               postgres    false    233            �           0    0 +   SEQUENCE historial_precios_id_historial_seq    ACL     N   GRANT ALL ON SEQUENCE public.historial_precios_id_historial_seq TO kiran_app;
          public               postgres    false    233            �            1259    33834    inventarios    TABLE     �   CREATE TABLE public.inventarios (
    id_inventario integer NOT NULL,
    id_jugador integer,
    id_producto integer,
    cantidad integer,
    camellos integer,
    vasijas integer
);
    DROP TABLE public.inventarios;
       public         heap r       postgres    false    4            �           0    0    TABLE inventarios    ACL     h   GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.inventarios TO kiran_app;
          public               postgres    false    214            �            1259    33832    inventarios_id_inventario_seq    SEQUENCE     �   CREATE SEQUENCE public.inventarios_id_inventario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 4   DROP SEQUENCE public.inventarios_id_inventario_seq;
       public               postgres    false    214    4            �           0    0    inventarios_id_inventario_seq    SEQUENCE OWNED BY     _   ALTER SEQUENCE public.inventarios_id_inventario_seq OWNED BY public.inventarios.id_inventario;
          public               postgres    false    213            �           0    0 &   SEQUENCE inventarios_id_inventario_seq    ACL     I   GRANT ALL ON SEQUENCE public.inventarios_id_inventario_seq TO kiran_app;
          public               postgres    false    213            �            1259    33788 	   jugadores    TABLE     �   CREATE TABLE public.jugadores (
    id_jugador integer NOT NULL,
    monedas_oro integer DEFAULT 1000,
    ciudad_actual character varying(50),
    semanas_transcurridas integer DEFAULT 0
);
    DROP TABLE public.jugadores;
       public         heap r       postgres    false    4            �           0    0    TABLE jugadores    ACL     f   GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.jugadores TO kiran_app;
          public               postgres    false    207            �            1259    33786    jugadores_id_jugador_seq    SEQUENCE     �   CREATE SEQUENCE public.jugadores_id_jugador_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.jugadores_id_jugador_seq;
       public               postgres    false    4    207            �           0    0    jugadores_id_jugador_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.jugadores_id_jugador_seq OWNED BY public.jugadores.id_jugador;
          public               postgres    false    206            �           0    0 !   SEQUENCE jugadores_id_jugador_seq    ACL     D   GRANT ALL ON SEQUENCE public.jugadores_id_jugador_seq TO kiran_app;
          public               postgres    false    206            �            1259    33969    logro_personaje    TABLE     �   CREATE TABLE public.logro_personaje (
    id_logro integer NOT NULL,
    id_personaje integer NOT NULL,
    fecha_obtencion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
 #   DROP TABLE public.logro_personaje;
       public         heap r       postgres    false    4            �           0    0    TABLE logro_personaje    ACL     l   GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.logro_personaje TO kiran_app;
          public               postgres    false    228            �            1259    33985    logro_rutas_requeridas    TABLE     y   CREATE TABLE public.logro_rutas_requeridas (
    id_logro integer NOT NULL,
    ciudad character varying(50) NOT NULL
);
 *   DROP TABLE public.logro_rutas_requeridas;
       public         heap r       postgres    false    4            �           0    0    TABLE logro_rutas_requeridas    ACL     s   GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.logro_rutas_requeridas TO kiran_app;
          public               postgres    false    229            �            1259    33960    logros    TABLE     t   CREATE TABLE public.logros (
    id_logro integer NOT NULL,
    nombre character varying(50),
    beneficio text
);
    DROP TABLE public.logros;
       public         heap r       postgres    false    4            �           0    0    TABLE logros    ACL     c   GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.logros TO kiran_app;
          public               postgres    false    227            �            1259    33958    logros_id_logro_seq    SEQUENCE     �   CREATE SEQUENCE public.logros_id_logro_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.logros_id_logro_seq;
       public               postgres    false    227    4            �           0    0    logros_id_logro_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE public.logros_id_logro_seq OWNED BY public.logros.id_logro;
          public               postgres    false    226            �           0    0    SEQUENCE logros_id_logro_seq    ACL     ?   GRANT ALL ON SEQUENCE public.logros_id_logro_seq TO kiran_app;
          public               postgres    false    226            �            1259    33821    partidas    TABLE     �   CREATE TABLE public.partidas (
    id_partida integer NOT NULL,
    id_jugador integer,
    fecha_inicio timestamp without time zone,
    estado character varying(20),
    puntuacion integer
);
    DROP TABLE public.partidas;
       public         heap r       postgres    false    4            �           0    0    TABLE partidas    ACL     e   GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.partidas TO kiran_app;
          public               postgres    false    212            �            1259    33819    partidas_id_partida_seq    SEQUENCE     �   CREATE SEQUENCE public.partidas_id_partida_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.partidas_id_partida_seq;
       public               postgres    false    212    4            �           0    0    partidas_id_partida_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.partidas_id_partida_seq OWNED BY public.partidas.id_partida;
          public               postgres    false    211            �           0    0     SEQUENCE partidas_id_partida_seq    ACL     C   GRANT ALL ON SEQUENCE public.partidas_id_partida_seq TO kiran_app;
          public               postgres    false    211            �            1259    33943    personaje_habilidades    TABLE     t   CREATE TABLE public.personaje_habilidades (
    id_personaje integer NOT NULL,
    id_habilidad integer NOT NULL
);
 )   DROP TABLE public.personaje_habilidades;
       public         heap r       postgres    false    4            �           0    0    TABLE personaje_habilidades    ACL     r   GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.personaje_habilidades TO kiran_app;
          public               postgres    false    225            �            1259    33927 
   personajes    TABLE     �   CREATE TABLE public.personajes (
    id_personaje integer NOT NULL,
    nombre character varying(50),
    id_jugador integer,
    ciudad_ubicacion character varying(50)
);
    DROP TABLE public.personajes;
       public         heap r       postgres    false    4            �           0    0    TABLE personajes    ACL     g   GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.personajes TO kiran_app;
          public               postgres    false    224            �            1259    33925    personajes_id_personaje_seq    SEQUENCE     �   CREATE SEQUENCE public.personajes_id_personaje_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 2   DROP SEQUENCE public.personajes_id_personaje_seq;
       public               postgres    false    4    224            �           0    0    personajes_id_personaje_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE public.personajes_id_personaje_seq OWNED BY public.personajes.id_personaje;
          public               postgres    false    223            �           0    0 $   SEQUENCE personajes_id_personaje_seq    ACL     G   GRANT ALL ON SEQUENCE public.personajes_id_personaje_seq TO kiran_app;
          public               postgres    false    223            �            1259    34030    precios_ajustados    TABLE     �   CREATE TABLE public.precios_ajustados (
    ciudad character varying(50) NOT NULL,
    id_producto integer NOT NULL,
    precio_actual integer
);
 %   DROP TABLE public.precios_ajustados;
       public         heap r       postgres    false    4            �           0    0    TABLE precios_ajustados    ACL     n   GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.precios_ajustados TO kiran_app;
          public               postgres    false    232            �            1259    33775 	   productos    TABLE     |   CREATE TABLE public.productos (
    id_producto integer NOT NULL,
    nombre character varying(50),
    descripcion text
);
    DROP TABLE public.productos;
       public         heap r       postgres    false    4            �           0    0    TABLE productos    ACL     f   GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.productos TO kiran_app;
          public               postgres    false    205            �            1259    33773    productos_id_producto_seq    SEQUENCE     �   CREATE SEQUENCE public.productos_id_producto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE public.productos_id_producto_seq;
       public               postgres    false    4    205            �           0    0    productos_id_producto_seq    SEQUENCE OWNED BY     W   ALTER SEQUENCE public.productos_id_producto_seq OWNED BY public.productos.id_producto;
          public               postgres    false    204            �           0    0 "   SEQUENCE productos_id_producto_seq    ACL     E   GRANT ALL ON SEQUENCE public.productos_id_producto_seq TO kiran_app;
          public               postgres    false    204            �            1259    33762    recursos    TABLE     z   CREATE TABLE public.recursos (
    id_recurso integer NOT NULL,
    nombre character varying(50),
    descripcion text
);
    DROP TABLE public.recursos;
       public         heap r       postgres    false    4            �           0    0    TABLE recursos    ACL     e   GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.recursos TO kiran_app;
          public               postgres    false    203            �            1259    33760    recursos_id_recurso_seq    SEQUENCE     �   CREATE SEQUENCE public.recursos_id_recurso_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.recursos_id_recurso_seq;
       public               postgres    false    203    4            �           0    0    recursos_id_recurso_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.recursos_id_recurso_seq OWNED BY public.recursos.id_recurso;
          public               postgres    false    202            �           0    0     SEQUENCE recursos_id_recurso_seq    ACL     C   GRANT ALL ON SEQUENCE public.recursos_id_recurso_seq TO kiran_app;
          public               postgres    false    202            �            1259    34070    reloj    TABLE     �   CREATE TABLE public.reloj (
    id_partida integer NOT NULL,
    semana_actual integer DEFAULT 0,
    ultima_actualizacion timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);
    DROP TABLE public.reloj;
       public         heap r       postgres    false    4            �           0    0    TABLE reloj    ACL     b   GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.reloj TO kiran_app;
          public               postgres    false    235            �            1259    33803    rutas    TABLE     �   CREATE TABLE public.rutas (
    id_ruta integer NOT NULL,
    origen character varying(50),
    destino character varying(50),
    distancia_tierra integer,
    distancia_mar integer
);
    DROP TABLE public.rutas;
       public         heap r       postgres    false    4            �           0    0    TABLE rutas    ACL     b   GRANT SELECT,INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE public.rutas TO kiran_app;
          public               postgres    false    210            �            1259    33801    rutas_id_ruta_seq    SEQUENCE     �   CREATE SEQUENCE public.rutas_id_ruta_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.rutas_id_ruta_seq;
       public               postgres    false    210    4            �           0    0    rutas_id_ruta_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.rutas_id_ruta_seq OWNED BY public.rutas.id_ruta;
          public               postgres    false    209            �           0    0    SEQUENCE rutas_id_ruta_seq    ACL     =   GRANT ALL ON SEQUENCE public.rutas_id_ruta_seq TO kiran_app;
          public               postgres    false    209            �           2604    33914    bitacora id_bitacora    DEFAULT     |   ALTER TABLE ONLY public.bitacora ALTER COLUMN id_bitacora SET DEFAULT nextval('public.bitacora_id_bitacora_seq'::regclass);
 C   ALTER TABLE public.bitacora ALTER COLUMN id_bitacora DROP DEFAULT;
       public               postgres    false    221    222    222            �           2604    33857    caravanas id_caravana    DEFAULT     ~   ALTER TABLE ONLY public.caravanas ALTER COLUMN id_caravana SET DEFAULT nextval('public.caravanas_id_caravana_seq'::regclass);
 D   ALTER TABLE public.caravanas ALTER COLUMN id_caravana DROP DEFAULT;
       public               postgres    false    216    215    216            �           2604    33891    eventos id_evento    DEFAULT     v   ALTER TABLE ONLY public.eventos ALTER COLUMN id_evento SET DEFAULT nextval('public.eventos_id_evento_seq'::regclass);
 @   ALTER TABLE public.eventos ALTER COLUMN id_evento DROP DEFAULT;
       public               postgres    false    219    218    219            �           2604    33752    habilidades id_habilidad    DEFAULT     �   ALTER TABLE ONLY public.habilidades ALTER COLUMN id_habilidad SET DEFAULT nextval('public.habilidades_id_habilidad_seq'::regclass);
 G   ALTER TABLE public.habilidades ALTER COLUMN id_habilidad DROP DEFAULT;
       public               postgres    false    201    200    201            �           2604    34050    historial_precios id_historial    DEFAULT     �   ALTER TABLE ONLY public.historial_precios ALTER COLUMN id_historial SET DEFAULT nextval('public.historial_precios_id_historial_seq'::regclass);
 M   ALTER TABLE public.historial_precios ALTER COLUMN id_historial DROP DEFAULT;
       public               postgres    false    234    233    234            �           2604    33837    inventarios id_inventario    DEFAULT     �   ALTER TABLE ONLY public.inventarios ALTER COLUMN id_inventario SET DEFAULT nextval('public.inventarios_id_inventario_seq'::regclass);
 H   ALTER TABLE public.inventarios ALTER COLUMN id_inventario DROP DEFAULT;
       public               postgres    false    214    213    214            �           2604    33791    jugadores id_jugador    DEFAULT     |   ALTER TABLE ONLY public.jugadores ALTER COLUMN id_jugador SET DEFAULT nextval('public.jugadores_id_jugador_seq'::regclass);
 C   ALTER TABLE public.jugadores ALTER COLUMN id_jugador DROP DEFAULT;
       public               postgres    false    207    206    207            �           2604    33963    logros id_logro    DEFAULT     r   ALTER TABLE ONLY public.logros ALTER COLUMN id_logro SET DEFAULT nextval('public.logros_id_logro_seq'::regclass);
 >   ALTER TABLE public.logros ALTER COLUMN id_logro DROP DEFAULT;
       public               postgres    false    227    226    227            �           2604    33824    partidas id_partida    DEFAULT     z   ALTER TABLE ONLY public.partidas ALTER COLUMN id_partida SET DEFAULT nextval('public.partidas_id_partida_seq'::regclass);
 B   ALTER TABLE public.partidas ALTER COLUMN id_partida DROP DEFAULT;
       public               postgres    false    212    211    212            �           2604    33930    personajes id_personaje    DEFAULT     �   ALTER TABLE ONLY public.personajes ALTER COLUMN id_personaje SET DEFAULT nextval('public.personajes_id_personaje_seq'::regclass);
 F   ALTER TABLE public.personajes ALTER COLUMN id_personaje DROP DEFAULT;
       public               postgres    false    224    223    224            �           2604    33778    productos id_producto    DEFAULT     ~   ALTER TABLE ONLY public.productos ALTER COLUMN id_producto SET DEFAULT nextval('public.productos_id_producto_seq'::regclass);
 D   ALTER TABLE public.productos ALTER COLUMN id_producto DROP DEFAULT;
       public               postgres    false    205    204    205            �           2604    33765    recursos id_recurso    DEFAULT     z   ALTER TABLE ONLY public.recursos ALTER COLUMN id_recurso SET DEFAULT nextval('public.recursos_id_recurso_seq'::regclass);
 B   ALTER TABLE public.recursos ALTER COLUMN id_recurso DROP DEFAULT;
       public               postgres    false    203    202    203            �           2604    33806    rutas id_ruta    DEFAULT     n   ALTER TABLE ONLY public.rutas ALTER COLUMN id_ruta SET DEFAULT nextval('public.rutas_id_ruta_seq'::regclass);
 <   ALTER TABLE public.rutas ALTER COLUMN id_ruta DROP DEFAULT;
       public               postgres    false    210    209    210            �          0    33911    bitacora 
   TABLE DATA                 public               postgres    false    222   ��       �          0    33894    caravana_evento 
   TABLE DATA                 public               postgres    false    220   ��       �          0    33871    caravana_recursos 
   TABLE DATA                 public               postgres    false    217   ��       �          0    33854 	   caravanas 
   TABLE DATA                 public               postgres    false    216   �       �          0    34104    ciudad_eventos 
   TABLE DATA                 public               postgres    false    236   (�       �          0    34015    ciudad_productos_deseados 
   TABLE DATA                 public               postgres    false    231   B�       �          0    34000    ciudad_productos_producidos 
   TABLE DATA                 public               postgres    false    230   ��       �          0    33796    ciudades 
   TABLE DATA                 public               postgres    false    208   J�       �          0    33888    eventos 
   TABLE DATA                 public               postgres    false    219   ��       �          0    33749    habilidades 
   TABLE DATA                 public               postgres    false    201   m�       �          0    34047    historial_precios 
   TABLE DATA                 public               postgres    false    234   2�       �          0    33834    inventarios 
   TABLE DATA                 public               postgres    false    214   ��       �          0    33788 	   jugadores 
   TABLE DATA                 public               postgres    false    207   ��       �          0    33969    logro_personaje 
   TABLE DATA                 public               postgres    false    228   '�       �          0    33985    logro_rutas_requeridas 
   TABLE DATA                 public               postgres    false    229   A�       �          0    33960    logros 
   TABLE DATA                 public               postgres    false    227   ��       �          0    33821    partidas 
   TABLE DATA                 public               postgres    false    212   C       �          0    33943    personaje_habilidades 
   TABLE DATA                 public               postgres    false    225   ]       �          0    33927 
   personajes 
   TABLE DATA                 public               postgres    false    224   w       �          0    34030    precios_ajustados 
   TABLE DATA                 public               postgres    false    232   �       �          0    33775 	   productos 
   TABLE DATA                 public               postgres    false    205   Y      �          0    33762    recursos 
   TABLE DATA                 public               postgres    false    203   .      �          0    34070    reloj 
   TABLE DATA                 public               postgres    false    235   �      �          0    33803    rutas 
   TABLE DATA                 public               postgres    false    210   �      �           0    0    bitacora_id_bitacora_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.bitacora_id_bitacora_seq', 1, false);
          public               postgres    false    221            �           0    0    caravanas_id_caravana_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.caravanas_id_caravana_seq', 1, false);
          public               postgres    false    215            �           0    0    eventos_id_evento_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.eventos_id_evento_seq', 3, true);
          public               postgres    false    218            �           0    0    habilidades_id_habilidad_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.habilidades_id_habilidad_seq', 3, true);
          public               postgres    false    200            �           0    0 "   historial_precios_id_historial_seq    SEQUENCE SET     P   SELECT pg_catalog.setval('public.historial_precios_id_historial_seq', 2, true);
          public               postgres    false    233            �           0    0    inventarios_id_inventario_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.inventarios_id_inventario_seq', 1, false);
          public               postgres    false    213            �           0    0    jugadores_id_jugador_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.jugadores_id_jugador_seq', 1, false);
          public               postgres    false    206            �           0    0    logros_id_logro_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.logros_id_logro_seq', 2, true);
          public               postgres    false    226            �           0    0    partidas_id_partida_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.partidas_id_partida_seq', 1, false);
          public               postgres    false    211            �           0    0    personajes_id_personaje_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.personajes_id_personaje_seq', 1, false);
          public               postgres    false    223            �           0    0    productos_id_producto_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.productos_id_producto_seq', 4, true);
          public               postgres    false    204            �           0    0    recursos_id_recurso_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.recursos_id_recurso_seq', 3, true);
          public               postgres    false    202            �           0    0    rutas_id_ruta_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.rutas_id_ruta_seq', 3, true);
          public               postgres    false    209            �           2606    33919    bitacora bitacora_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.bitacora
    ADD CONSTRAINT bitacora_pkey PRIMARY KEY (id_bitacora);
 @   ALTER TABLE ONLY public.bitacora DROP CONSTRAINT bitacora_pkey;
       public                 postgres    false    222            �           2606    33898 $   caravana_evento caravana_evento_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.caravana_evento
    ADD CONSTRAINT caravana_evento_pkey PRIMARY KEY (id_caravana, id_evento, dia_ocurrencia);
 N   ALTER TABLE ONLY public.caravana_evento DROP CONSTRAINT caravana_evento_pkey;
       public                 postgres    false    220    220    220            �           2606    33875 (   caravana_recursos caravana_recursos_pkey 
   CONSTRAINT     {   ALTER TABLE ONLY public.caravana_recursos
    ADD CONSTRAINT caravana_recursos_pkey PRIMARY KEY (id_caravana, id_recurso);
 R   ALTER TABLE ONLY public.caravana_recursos DROP CONSTRAINT caravana_recursos_pkey;
       public                 postgres    false    217    217            �           2606    33860    caravanas caravanas_pkey 
   CONSTRAINT     _   ALTER TABLE ONLY public.caravanas
    ADD CONSTRAINT caravanas_pkey PRIMARY KEY (id_caravana);
 B   ALTER TABLE ONLY public.caravanas DROP CONSTRAINT caravanas_pkey;
       public                 postgres    false    216            �           2606    34108 "   ciudad_eventos ciudad_eventos_pkey 
   CONSTRAINT     v   ALTER TABLE ONLY public.ciudad_eventos
    ADD CONSTRAINT ciudad_eventos_pkey PRIMARY KEY (ciudad_nombre, id_evento);
 L   ALTER TABLE ONLY public.ciudad_eventos DROP CONSTRAINT ciudad_eventos_pkey;
       public                 postgres    false    236    236            �           2606    34019 8   ciudad_productos_deseados ciudad_productos_deseados_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.ciudad_productos_deseados
    ADD CONSTRAINT ciudad_productos_deseados_pkey PRIMARY KEY (ciudad_nombre, id_producto);
 b   ALTER TABLE ONLY public.ciudad_productos_deseados DROP CONSTRAINT ciudad_productos_deseados_pkey;
       public                 postgres    false    231    231            �           2606    34004 <   ciudad_productos_producidos ciudad_productos_producidos_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.ciudad_productos_producidos
    ADD CONSTRAINT ciudad_productos_producidos_pkey PRIMARY KEY (ciudad_nombre, id_producto);
 f   ALTER TABLE ONLY public.ciudad_productos_producidos DROP CONSTRAINT ciudad_productos_producidos_pkey;
       public                 postgres    false    230    230            �           2606    33800    ciudades ciudades_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.ciudades
    ADD CONSTRAINT ciudades_pkey PRIMARY KEY (nombre);
 @   ALTER TABLE ONLY public.ciudades DROP CONSTRAINT ciudades_pkey;
       public                 postgres    false    208            �           2606    33893    eventos eventos_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.eventos
    ADD CONSTRAINT eventos_pkey PRIMARY KEY (id_evento);
 >   ALTER TABLE ONLY public.eventos DROP CONSTRAINT eventos_pkey;
       public                 postgres    false    219            �           2606    33759 "   habilidades habilidades_nombre_key 
   CONSTRAINT     _   ALTER TABLE ONLY public.habilidades
    ADD CONSTRAINT habilidades_nombre_key UNIQUE (nombre);
 L   ALTER TABLE ONLY public.habilidades DROP CONSTRAINT habilidades_nombre_key;
       public                 postgres    false    201            �           2606    33757    habilidades habilidades_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY public.habilidades
    ADD CONSTRAINT habilidades_pkey PRIMARY KEY (id_habilidad);
 F   ALTER TABLE ONLY public.habilidades DROP CONSTRAINT habilidades_pkey;
       public                 postgres    false    201            �           2606    34053 (   historial_precios historial_precios_pkey 
   CONSTRAINT     p   ALTER TABLE ONLY public.historial_precios
    ADD CONSTRAINT historial_precios_pkey PRIMARY KEY (id_historial);
 R   ALTER TABLE ONLY public.historial_precios DROP CONSTRAINT historial_precios_pkey;
       public                 postgres    false    234            �           2606    33841 2   inventarios inventarios_id_jugador_id_producto_key 
   CONSTRAINT     �   ALTER TABLE ONLY public.inventarios
    ADD CONSTRAINT inventarios_id_jugador_id_producto_key UNIQUE (id_jugador, id_producto);
 \   ALTER TABLE ONLY public.inventarios DROP CONSTRAINT inventarios_id_jugador_id_producto_key;
       public                 postgres    false    214    214            �           2606    33839    inventarios inventarios_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY public.inventarios
    ADD CONSTRAINT inventarios_pkey PRIMARY KEY (id_inventario);
 F   ALTER TABLE ONLY public.inventarios DROP CONSTRAINT inventarios_pkey;
       public                 postgres    false    214            �           2606    33795    jugadores jugadores_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.jugadores
    ADD CONSTRAINT jugadores_pkey PRIMARY KEY (id_jugador);
 B   ALTER TABLE ONLY public.jugadores DROP CONSTRAINT jugadores_pkey;
       public                 postgres    false    207            �           2606    33974 $   logro_personaje logro_personaje_pkey 
   CONSTRAINT     v   ALTER TABLE ONLY public.logro_personaje
    ADD CONSTRAINT logro_personaje_pkey PRIMARY KEY (id_logro, id_personaje);
 N   ALTER TABLE ONLY public.logro_personaje DROP CONSTRAINT logro_personaje_pkey;
       public                 postgres    false    228    228            �           2606    33989 2   logro_rutas_requeridas logro_rutas_requeridas_pkey 
   CONSTRAINT     ~   ALTER TABLE ONLY public.logro_rutas_requeridas
    ADD CONSTRAINT logro_rutas_requeridas_pkey PRIMARY KEY (id_logro, ciudad);
 \   ALTER TABLE ONLY public.logro_rutas_requeridas DROP CONSTRAINT logro_rutas_requeridas_pkey;
       public                 postgres    false    229    229            �           2606    33968    logros logros_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.logros
    ADD CONSTRAINT logros_pkey PRIMARY KEY (id_logro);
 <   ALTER TABLE ONLY public.logros DROP CONSTRAINT logros_pkey;
       public                 postgres    false    227            �           2606    33826    partidas partidas_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.partidas
    ADD CONSTRAINT partidas_pkey PRIMARY KEY (id_partida);
 @   ALTER TABLE ONLY public.partidas DROP CONSTRAINT partidas_pkey;
       public                 postgres    false    212            �           2606    33947 0   personaje_habilidades personaje_habilidades_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.personaje_habilidades
    ADD CONSTRAINT personaje_habilidades_pkey PRIMARY KEY (id_personaje, id_habilidad);
 Z   ALTER TABLE ONLY public.personaje_habilidades DROP CONSTRAINT personaje_habilidades_pkey;
       public                 postgres    false    225    225            �           2606    33932    personajes personajes_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.personajes
    ADD CONSTRAINT personajes_pkey PRIMARY KEY (id_personaje);
 D   ALTER TABLE ONLY public.personajes DROP CONSTRAINT personajes_pkey;
       public                 postgres    false    224            �           2606    34034 (   precios_ajustados precios_ajustados_pkey 
   CONSTRAINT     w   ALTER TABLE ONLY public.precios_ajustados
    ADD CONSTRAINT precios_ajustados_pkey PRIMARY KEY (ciudad, id_producto);
 R   ALTER TABLE ONLY public.precios_ajustados DROP CONSTRAINT precios_ajustados_pkey;
       public                 postgres    false    232    232            �           2606    33785    productos productos_nombre_key 
   CONSTRAINT     [   ALTER TABLE ONLY public.productos
    ADD CONSTRAINT productos_nombre_key UNIQUE (nombre);
 H   ALTER TABLE ONLY public.productos DROP CONSTRAINT productos_nombre_key;
       public                 postgres    false    205            �           2606    33783    productos productos_pkey 
   CONSTRAINT     _   ALTER TABLE ONLY public.productos
    ADD CONSTRAINT productos_pkey PRIMARY KEY (id_producto);
 B   ALTER TABLE ONLY public.productos DROP CONSTRAINT productos_pkey;
       public                 postgres    false    205            �           2606    33772    recursos recursos_nombre_key 
   CONSTRAINT     Y   ALTER TABLE ONLY public.recursos
    ADD CONSTRAINT recursos_nombre_key UNIQUE (nombre);
 F   ALTER TABLE ONLY public.recursos DROP CONSTRAINT recursos_nombre_key;
       public                 postgres    false    203            �           2606    33770    recursos recursos_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.recursos
    ADD CONSTRAINT recursos_pkey PRIMARY KEY (id_recurso);
 @   ALTER TABLE ONLY public.recursos DROP CONSTRAINT recursos_pkey;
       public                 postgres    false    203            �           2606    34076    reloj reloj_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.reloj
    ADD CONSTRAINT reloj_pkey PRIMARY KEY (id_partida);
 :   ALTER TABLE ONLY public.reloj DROP CONSTRAINT reloj_pkey;
       public                 postgres    false    235            �           2606    33808    rutas rutas_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.rutas
    ADD CONSTRAINT rutas_pkey PRIMARY KEY (id_ruta);
 :   ALTER TABLE ONLY public.rutas DROP CONSTRAINT rutas_pkey;
       public                 postgres    false    210                       2620    34134 %   precios_ajustados tr_historial_precio    TRIGGER     �   CREATE TRIGGER tr_historial_precio AFTER UPDATE ON public.precios_ajustados FOR EACH ROW EXECUTE FUNCTION public.registrar_historial_precio();
 >   DROP TRIGGER tr_historial_precio ON public.precios_ajustados;
       public               postgres    false    237    232            �           2606    33920 !   bitacora bitacora_id_partida_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.bitacora
    ADD CONSTRAINT bitacora_id_partida_fkey FOREIGN KEY (id_partida) REFERENCES public.partidas(id_partida);
 K   ALTER TABLE ONLY public.bitacora DROP CONSTRAINT bitacora_id_partida_fkey;
       public               postgres    false    3012    222    212            �           2606    33899 0   caravana_evento caravana_evento_id_caravana_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.caravana_evento
    ADD CONSTRAINT caravana_evento_id_caravana_fkey FOREIGN KEY (id_caravana) REFERENCES public.caravanas(id_caravana);
 Z   ALTER TABLE ONLY public.caravana_evento DROP CONSTRAINT caravana_evento_id_caravana_fkey;
       public               postgres    false    3018    220    216            �           2606    33904 .   caravana_evento caravana_evento_id_evento_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.caravana_evento
    ADD CONSTRAINT caravana_evento_id_evento_fkey FOREIGN KEY (id_evento) REFERENCES public.eventos(id_evento);
 X   ALTER TABLE ONLY public.caravana_evento DROP CONSTRAINT caravana_evento_id_evento_fkey;
       public               postgres    false    3022    219    220            �           2606    33876 4   caravana_recursos caravana_recursos_id_caravana_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.caravana_recursos
    ADD CONSTRAINT caravana_recursos_id_caravana_fkey FOREIGN KEY (id_caravana) REFERENCES public.caravanas(id_caravana);
 ^   ALTER TABLE ONLY public.caravana_recursos DROP CONSTRAINT caravana_recursos_id_caravana_fkey;
       public               postgres    false    3018    217    216            �           2606    33881 3   caravana_recursos caravana_recursos_id_recurso_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.caravana_recursos
    ADD CONSTRAINT caravana_recursos_id_recurso_fkey FOREIGN KEY (id_recurso) REFERENCES public.recursos(id_recurso);
 ]   ALTER TABLE ONLY public.caravana_recursos DROP CONSTRAINT caravana_recursos_id_recurso_fkey;
       public               postgres    false    203    217    3000            �           2606    33861 #   caravanas caravanas_id_jugador_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.caravanas
    ADD CONSTRAINT caravanas_id_jugador_fkey FOREIGN KEY (id_jugador) REFERENCES public.jugadores(id_jugador);
 M   ALTER TABLE ONLY public.caravanas DROP CONSTRAINT caravanas_id_jugador_fkey;
       public               postgres    false    216    3006    207            �           2606    33866 $   caravanas caravanas_ruta_actual_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.caravanas
    ADD CONSTRAINT caravanas_ruta_actual_fkey FOREIGN KEY (ruta_actual) REFERENCES public.rutas(id_ruta);
 N   ALTER TABLE ONLY public.caravanas DROP CONSTRAINT caravanas_ruta_actual_fkey;
       public               postgres    false    210    216    3010                       2606    34109 0   ciudad_eventos ciudad_eventos_ciudad_nombre_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.ciudad_eventos
    ADD CONSTRAINT ciudad_eventos_ciudad_nombre_fkey FOREIGN KEY (ciudad_nombre) REFERENCES public.ciudades(nombre);
 Z   ALTER TABLE ONLY public.ciudad_eventos DROP CONSTRAINT ciudad_eventos_ciudad_nombre_fkey;
       public               postgres    false    208    3008    236                       2606    34114 ,   ciudad_eventos ciudad_eventos_id_evento_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.ciudad_eventos
    ADD CONSTRAINT ciudad_eventos_id_evento_fkey FOREIGN KEY (id_evento) REFERENCES public.eventos(id_evento);
 V   ALTER TABLE ONLY public.ciudad_eventos DROP CONSTRAINT ciudad_eventos_id_evento_fkey;
       public               postgres    false    236    219    3022            �           2606    34020 F   ciudad_productos_deseados ciudad_productos_deseados_ciudad_nombre_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.ciudad_productos_deseados
    ADD CONSTRAINT ciudad_productos_deseados_ciudad_nombre_fkey FOREIGN KEY (ciudad_nombre) REFERENCES public.ciudades(nombre);
 p   ALTER TABLE ONLY public.ciudad_productos_deseados DROP CONSTRAINT ciudad_productos_deseados_ciudad_nombre_fkey;
       public               postgres    false    3008    231    208                        2606    34025 D   ciudad_productos_deseados ciudad_productos_deseados_id_producto_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.ciudad_productos_deseados
    ADD CONSTRAINT ciudad_productos_deseados_id_producto_fkey FOREIGN KEY (id_producto) REFERENCES public.productos(id_producto);
 n   ALTER TABLE ONLY public.ciudad_productos_deseados DROP CONSTRAINT ciudad_productos_deseados_id_producto_fkey;
       public               postgres    false    205    3004    231            �           2606    34005 J   ciudad_productos_producidos ciudad_productos_producidos_ciudad_nombre_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.ciudad_productos_producidos
    ADD CONSTRAINT ciudad_productos_producidos_ciudad_nombre_fkey FOREIGN KEY (ciudad_nombre) REFERENCES public.ciudades(nombre);
 t   ALTER TABLE ONLY public.ciudad_productos_producidos DROP CONSTRAINT ciudad_productos_producidos_ciudad_nombre_fkey;
       public               postgres    false    3008    230    208            �           2606    34010 H   ciudad_productos_producidos ciudad_productos_producidos_id_producto_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.ciudad_productos_producidos
    ADD CONSTRAINT ciudad_productos_producidos_id_producto_fkey FOREIGN KEY (id_producto) REFERENCES public.productos(id_producto);
 r   ALTER TABLE ONLY public.ciudad_productos_producidos DROP CONSTRAINT ciudad_productos_producidos_id_producto_fkey;
       public               postgres    false    3004    230    205                       2606    34054 /   historial_precios historial_precios_ciudad_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.historial_precios
    ADD CONSTRAINT historial_precios_ciudad_fkey FOREIGN KEY (ciudad) REFERENCES public.ciudades(nombre);
 Y   ALTER TABLE ONLY public.historial_precios DROP CONSTRAINT historial_precios_ciudad_fkey;
       public               postgres    false    3008    208    234                       2606    34059 4   historial_precios historial_precios_id_producto_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.historial_precios
    ADD CONSTRAINT historial_precios_id_producto_fkey FOREIGN KEY (id_producto) REFERENCES public.productos(id_producto);
 ^   ALTER TABLE ONLY public.historial_precios DROP CONSTRAINT historial_precios_id_producto_fkey;
       public               postgres    false    205    234    3004            �           2606    33842 '   inventarios inventarios_id_jugador_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.inventarios
    ADD CONSTRAINT inventarios_id_jugador_fkey FOREIGN KEY (id_jugador) REFERENCES public.jugadores(id_jugador);
 Q   ALTER TABLE ONLY public.inventarios DROP CONSTRAINT inventarios_id_jugador_fkey;
       public               postgres    false    3006    207    214            �           2606    33847 (   inventarios inventarios_id_producto_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.inventarios
    ADD CONSTRAINT inventarios_id_producto_fkey FOREIGN KEY (id_producto) REFERENCES public.productos(id_producto);
 R   ALTER TABLE ONLY public.inventarios DROP CONSTRAINT inventarios_id_producto_fkey;
       public               postgres    false    214    3004    205            �           2606    33975 -   logro_personaje logro_personaje_id_logro_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.logro_personaje
    ADD CONSTRAINT logro_personaje_id_logro_fkey FOREIGN KEY (id_logro) REFERENCES public.logros(id_logro);
 W   ALTER TABLE ONLY public.logro_personaje DROP CONSTRAINT logro_personaje_id_logro_fkey;
       public               postgres    false    227    228    3032            �           2606    33980 1   logro_personaje logro_personaje_id_personaje_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.logro_personaje
    ADD CONSTRAINT logro_personaje_id_personaje_fkey FOREIGN KEY (id_personaje) REFERENCES public.personajes(id_personaje);
 [   ALTER TABLE ONLY public.logro_personaje DROP CONSTRAINT logro_personaje_id_personaje_fkey;
       public               postgres    false    228    224    3028            �           2606    33995 9   logro_rutas_requeridas logro_rutas_requeridas_ciudad_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.logro_rutas_requeridas
    ADD CONSTRAINT logro_rutas_requeridas_ciudad_fkey FOREIGN KEY (ciudad) REFERENCES public.ciudades(nombre);
 c   ALTER TABLE ONLY public.logro_rutas_requeridas DROP CONSTRAINT logro_rutas_requeridas_ciudad_fkey;
       public               postgres    false    3008    208    229            �           2606    33990 ;   logro_rutas_requeridas logro_rutas_requeridas_id_logro_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.logro_rutas_requeridas
    ADD CONSTRAINT logro_rutas_requeridas_id_logro_fkey FOREIGN KEY (id_logro) REFERENCES public.logros(id_logro);
 e   ALTER TABLE ONLY public.logro_rutas_requeridas DROP CONSTRAINT logro_rutas_requeridas_id_logro_fkey;
       public               postgres    false    229    227    3032            �           2606    33827 !   partidas partidas_id_jugador_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.partidas
    ADD CONSTRAINT partidas_id_jugador_fkey FOREIGN KEY (id_jugador) REFERENCES public.jugadores(id_jugador);
 K   ALTER TABLE ONLY public.partidas DROP CONSTRAINT partidas_id_jugador_fkey;
       public               postgres    false    212    3006    207            �           2606    33953 =   personaje_habilidades personaje_habilidades_id_habilidad_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.personaje_habilidades
    ADD CONSTRAINT personaje_habilidades_id_habilidad_fkey FOREIGN KEY (id_habilidad) REFERENCES public.habilidades(id_habilidad);
 g   ALTER TABLE ONLY public.personaje_habilidades DROP CONSTRAINT personaje_habilidades_id_habilidad_fkey;
       public               postgres    false    201    225    2996            �           2606    33948 =   personaje_habilidades personaje_habilidades_id_personaje_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.personaje_habilidades
    ADD CONSTRAINT personaje_habilidades_id_personaje_fkey FOREIGN KEY (id_personaje) REFERENCES public.personajes(id_personaje);
 g   ALTER TABLE ONLY public.personaje_habilidades DROP CONSTRAINT personaje_habilidades_id_personaje_fkey;
       public               postgres    false    224    3028    225            �           2606    33938 +   personajes personajes_ciudad_ubicacion_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.personajes
    ADD CONSTRAINT personajes_ciudad_ubicacion_fkey FOREIGN KEY (ciudad_ubicacion) REFERENCES public.ciudades(nombre);
 U   ALTER TABLE ONLY public.personajes DROP CONSTRAINT personajes_ciudad_ubicacion_fkey;
       public               postgres    false    208    224    3008            �           2606    33933 %   personajes personajes_id_jugador_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.personajes
    ADD CONSTRAINT personajes_id_jugador_fkey FOREIGN KEY (id_jugador) REFERENCES public.jugadores(id_jugador);
 O   ALTER TABLE ONLY public.personajes DROP CONSTRAINT personajes_id_jugador_fkey;
       public               postgres    false    3006    224    207                       2606    34035 /   precios_ajustados precios_ajustados_ciudad_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.precios_ajustados
    ADD CONSTRAINT precios_ajustados_ciudad_fkey FOREIGN KEY (ciudad) REFERENCES public.ciudades(nombre);
 Y   ALTER TABLE ONLY public.precios_ajustados DROP CONSTRAINT precios_ajustados_ciudad_fkey;
       public               postgres    false    3008    232    208                       2606    34040 4   precios_ajustados precios_ajustados_id_producto_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.precios_ajustados
    ADD CONSTRAINT precios_ajustados_id_producto_fkey FOREIGN KEY (id_producto) REFERENCES public.productos(id_producto);
 ^   ALTER TABLE ONLY public.precios_ajustados DROP CONSTRAINT precios_ajustados_id_producto_fkey;
       public               postgres    false    205    232    3004                       2606    34077    reloj reloj_id_partida_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.reloj
    ADD CONSTRAINT reloj_id_partida_fkey FOREIGN KEY (id_partida) REFERENCES public.partidas(id_partida);
 E   ALTER TABLE ONLY public.reloj DROP CONSTRAINT reloj_id_partida_fkey;
       public               postgres    false    3012    212    235            �           2606    33814    rutas rutas_destino_fkey    FK CONSTRAINT     ~   ALTER TABLE ONLY public.rutas
    ADD CONSTRAINT rutas_destino_fkey FOREIGN KEY (destino) REFERENCES public.ciudades(nombre);
 B   ALTER TABLE ONLY public.rutas DROP CONSTRAINT rutas_destino_fkey;
       public               postgres    false    210    3008    208            �           2606    33809    rutas rutas_origen_fkey    FK CONSTRAINT     |   ALTER TABLE ONLY public.rutas
    ADD CONSTRAINT rutas_origen_fkey FOREIGN KEY (origen) REFERENCES public.ciudades(nombre);
 A   ALTER TABLE ONLY public.rutas DROP CONSTRAINT rutas_origen_fkey;
       public               postgres    false    208    3008    210            �   
   x���          �   
   x���          �   
   x���          �   
   x���          �   
   x���          �   v   x���v
Q���W((M��L�K�,MIL�/(�O)M.�/�OI-NML�/Vs�	uV�Pw**�MT�Q0Ҵ��$˄����"��dP�ZT���XU�4Ǆls�R���F��� 8PZ	      �   r   x���v
Q���W((M��L�K�,MIL�/(�O)M.�/��2S��}B]�4ԝ�Js�u5��<�4#8?'�d������+8V�� M2��$ǢԼ�b�!&@C�� ą]�      �   l   x���v
Q���W((M��L�K�,MILI-Vs�	uV�Pw**�MT�QHK�)N�Q()*Mմ��$Fkp~Nb�^0E���Ԣ�|Ǫ�u��$�X���X��r.. �M�      �   �   x�����0F�>���Đ�����Ġt/�M������2����$�ɑm�t�v�Ú��L%nh��oϦ��8A18�U�:���euDxY���ߪ*ߣz'�0*��v!K=!�S�aG����g�w����[Ͷ�v�ӄߝ"w2���K      �   �   x���1
�@�>��F� b��
�" �h?����Yv�^���,�����ˋ*+kȋzvh�V�36��[�pLw���i2�x+9�%��vPd@��Z
����d9�g�(�m}��5�P�ǝG!:�� X'ͻ5J�J�w�����x	[����t���N����G��:0Q���gx      �   y   x���v
Q���W((M��L���,.�/�L̉/(JM��/Vs�	uV�0�QPw**�MT�Q �M�|##S]]KCK+cC+Cc=C3CCuMk.OR�7���X2�1!l> ��3Y      �   
   x���          �   B   x���v
Q���W((M��L��*MOL�/J-Vs�	uV�0�Q0400�Q����Q0д��� H�      �   
   x���          �   J   x���v
Q���W((M��L���O/ʏ/*-I,�/J-,M-�LI,Vs�	uV�0�QPw,J�K,V״��� ��"      �   �   x����
�0E�~�]�
"�թC��Vh��3y�H�W�T�)��3��r.�S7]������i�[�vV/��t�:��-�3q�^�dd���y��<������ءد��1����P�&+��xh�i�����[ֳbD��$���Ѓ�ϛ�H�}J�=�      �   
   x���          �   
   x���          �   
   x���          �   �   x���v
Q���W((M��L�+(JM��/�O�*-.IL�/Vs�	uV�Pw**�MT�Q0�Q05д��$K�� #��(X���h9n��I,�z݌�@��P��wC
�|oL����Ԣ�|Ǫ�H�Sj0,)5� ���X���X	r"�߈���nLV0µ�@3 �A      �   �   x���Aj�0нO�wN��v�U(^�$�N�SiI#$;4��z���x�a���?�eDOH˧w�)e�����c�v6Ϗh���;�'L.�rǍ�d���Y)�î�װ[庒�8*�~�h]�Xo���{vF�D���F����_<s������2��K�e�@y5���)�Q�<�G��[�`)�� H���f���o�      �   �   x���1�0�὿�*���NE
����顑$-����'š�7�W�Myi���3�n�Z� ��t+Nײ��fEy���֬�C4h��,�Ȏ�@��i�=u'�!_�j���Cou��і݈en{�G�թ��!��(�;��Io�4^��,{��a�      �   
   x���          �   s   x���v
Q���W((M��L�+*-I,Vs�	uV�0�QPw**�MT2��s�@,S�PMk.OB!�S(M-*�Wp�*�r�u��1�C��cQj^b1�e4h ͭ:I     