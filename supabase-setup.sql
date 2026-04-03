-- ================================================================
-- MESA DE MEDIOS USS — Supabase Setup
-- Ejecutá esto en el SQL Editor de tu proyecto Supabase
-- ================================================================

-- 1. Crear tabla
CREATE TABLE IF NOT EXISTS contenidos (
  id         UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre     TEXT        NOT NULL,
  semana     DATE,
  medios     JSONB       DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER set_updated_at
  BEFORE UPDATE ON contenidos
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 3. Habilitar Row Level Security
ALTER TABLE contenidos ENABLE ROW LEVEL SECURITY;

-- 4. Políticas de acceso público (todos pueden leer y escribir con el link)
CREATE POLICY "Acceso público de lectura"
  ON contenidos FOR SELECT USING (true);

CREATE POLICY "Acceso público de inserción"
  ON contenidos FOR INSERT WITH CHECK (true);

CREATE POLICY "Acceso público de actualización"
  ON contenidos FOR UPDATE USING (true);

CREATE POLICY "Acceso público de eliminación"
  ON contenidos FOR DELETE USING (true);

-- 5. Habilitar Realtime para la tabla
ALTER PUBLICATION supabase_realtime ADD TABLE contenidos;

-- ================================================================
-- DATOS INICIALES (los 7 contenidos actuales del Excel)
-- ================================================================
INSERT INTO contenidos (nombre, semana, medios) VALUES
(
  'Nuevo Rector',
  '2026-03-30',
  '{
    "mailing":"si / Claudia","sitio_web":"si / Felipe","whatsapp":"si / Claudia",
    "fondo_pantalla":"no","pantallas":"si / Claudia","rrss":"si / Felipe",
    "lt_publirreportaje":"pd","lt_conversatorio":"pd","lt_columna":"pd",
    "lt_huinchas":"pd","lt_digital_papel":"pd","duna":"si / Nata",
    "dinamo_entrevista":"si","t13_entrevista1":"si","t13_entrevista2":"si",
    "biobio":"pd"
  }'
),
(
  'AQAS',
  '2026-03-23',
  '{
    "mailing":"si / Claudia","sitio_web":"si / Felipe","whatsapp":"si / Claudia",
    "fondo_pantalla":"si / Claudia","firmas":"si / Rodrigo",
    "pantallas":"si / Claudia","rrss":"si / Felipe","radio":"si / Rodrigo"
  }'
),
(
  'Inicio Año Académico',
  '2026-03-23',
  '{
    "mailing":"si / Claudia","sitio_web":"si / Felipe","whatsapp":"si / Claudia",
    "pantallas":"si / Claudia","rrss":"si / Felipe"
  }'
),
(
  'Decretadas',
  '2026-03-30',
  '{}'
),
(
  'Congreso VcM',
  '2026-03-30',
  '{
    "mailing":"si / Claudia","sitio_web":"si / Felipe","whatsapp":"si / Claudia",
    "pantallas":"si / Claudia","rrss":"si / Felipe",
    "lt_publirreportaje":"si / Seba"
  }'
),
(
  'Campaña Institucional - Contribución Territorio (teaser)',
  '2026-04-06',
  '{
    "sitio_web":"si / Felipe","fondo_pantalla":"si / Claudia",
    "pantallas":"si / Claudia","rrss":"si / Felipe",
    "radio":"si / Rodrigo","tv":"si","via_publica":"si / Rodrigo","avisos":"si / Rodrigo"
  }'
),
(
  'Feria del Libro',
  '2026-04-06',
  '{
    "mailing":"si / Claudia","sitio_web":"si / Felipe","whatsapp":"si / Claudia",
    "pantallas":"si / Claudia","rrss":"si / Felipe",
    "lt_publirreportaje":"si / Seba"
  }'
);
