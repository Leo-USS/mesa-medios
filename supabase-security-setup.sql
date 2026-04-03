-- ================================================================
-- MESA DE MEDIOS USS — Security Setup
-- Ejecutá esto en el SQL Editor de Supabase
-- ================================================================

-- ── 1. Tabla de usuarios autorizados ────────────────────────────
CREATE TABLE IF NOT EXISTS usuarios_autorizados (
  email      TEXT PRIMARY KEY,
  nombre     TEXT,
  activo     BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE usuarios_autorizados ENABLE ROW LEVEL SECURITY;

-- Cada usuario autenticado solo puede ver su propio registro
CREATE POLICY "Ver propio registro"
  ON usuarios_autorizados FOR SELECT
  TO authenticated
  USING (lower(email) = lower(auth.email()));

-- ── 2. Insertar emails autorizados ──────────────────────────────
INSERT INTO usuarios_autorizados (email, nombre) VALUES
  ('barbara.ruiz@uss.cl',        'Barbara Ruiz'),
  ('pablo.arayam@uss.cl',        'Pablo Araya'),
  ('leonardo.munoz@uss.cl',      'Leonardo Muñoz'),
  ('antonia.cordero@uss.cl',     'Antonia Cordero'),
  ('yaritza.ross@uss.cl',        'Yaritza Ross'),
  ('natalie.traverso@uss.cl',    'Natalie Traverso'),
  ('esteban.lopez@uss.cl',       'Esteban Lopez'),
  ('felipe.morales@uss.cl',      'Felipe Morales'),
  ('viviana.castillo@uss.cl',    'Viviana Castillo'),
  ('claudia.olave@uss.cl',       'Claudia Olave'),
  ('maria.melej@uss.cl',         'Maria Melej'),
  ('magdalena.ferrer@uss.cl',    'Magdalena Ferrer'),
  ('sebastian.fuentesf@uss.cl',  'Sebastian Fuentes'),
  ('cristobal.valenzuela@uss.cl','Cristobal Valenzuela')
ON CONFLICT (email) DO NOTHING;

-- ── 3. Tabla de logs de actividad ───────────────────────────────
CREATE TABLE IF NOT EXISTS logs (
  id               UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_email       TEXT        NOT NULL,
  user_nombre      TEXT,
  accion           TEXT        NOT NULL, -- LOGIN, AGREGAR, MODIFICAR, ELIMINAR
  contenido_id     UUID,
  contenido_nombre TEXT,
  detalle          TEXT,
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE logs ENABLE ROW LEVEL SECURITY;

-- Solo usuarios autorizados pueden insertar y leer logs
CREATE POLICY "Insertar logs"
  ON logs FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM usuarios_autorizados
      WHERE lower(email) = lower(auth.email()) AND activo = true
    )
  );

CREATE POLICY "Leer logs"
  ON logs FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM usuarios_autorizados
      WHERE lower(email) = lower(auth.email()) AND activo = true
    )
  );

-- ── 4. Actualizar RLS de contenidos ─────────────────────────────
-- Eliminar políticas públicas anteriores
DROP POLICY IF EXISTS "Acceso público de lectura"      ON contenidos;
DROP POLICY IF EXISTS "Acceso público de inserción"    ON contenidos;
DROP POLICY IF EXISTS "Acceso público de actualización" ON contenidos;
DROP POLICY IF EXISTS "Acceso público de eliminación"  ON contenidos;

-- Helper function para verificar si el usuario está autorizado
CREATE OR REPLACE FUNCTION is_authorized()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM usuarios_autorizados
    WHERE lower(email) = lower(auth.email()) AND activo = true
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- Nuevas políticas: solo usuarios autorizados
CREATE POLICY "Lectura autorizada"
  ON contenidos FOR SELECT TO authenticated
  USING (is_authorized());

CREATE POLICY "Inserción autorizada"
  ON contenidos FOR INSERT TO authenticated
  WITH CHECK (is_authorized());

CREATE POLICY "Actualización autorizada"
  ON contenidos FOR UPDATE TO authenticated
  USING (is_authorized());

CREATE POLICY "Eliminación autorizada"
  ON contenidos FOR DELETE TO authenticated
  USING (is_authorized());

-- ── 5. Realtime para logs ────────────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE logs;
