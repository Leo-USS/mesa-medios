-- ================================================================
-- Mesa Editorial USS — Schema + RLS + Realtime + Seed Data
-- Ejecutar en Supabase SQL Editor
-- ================================================================

-- Crear tabla
CREATE TABLE IF NOT EXISTS mesa_editorial_acciones (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  eje         TEXT        NOT NULL,
  tipo        TEXT,
  tema        TEXT,
  accion      TEXT,
  tipo_accion TEXT,
  fecha       DATE,
  responsable TEXT,
  status      TEXT        NOT NULL DEFAULT 'Pendiente',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Row Level Security
ALTER TABLE mesa_editorial_acciones ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Usuarios autorizados pueden hacer todo" ON mesa_editorial_acciones;

CREATE POLICY "Usuarios autorizados pueden hacer todo"
  ON mesa_editorial_acciones
  FOR ALL
  USING (
    auth.jwt() ->> 'email' IN (
      SELECT email FROM usuarios_autorizados WHERE activo = true
    )
  );

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE mesa_editorial_acciones;

-- Trigger para updated_at automático
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_mesa_editorial_updated_at ON mesa_editorial_acciones;
CREATE TRIGGER update_mesa_editorial_updated_at
  BEFORE UPDATE ON mesa_editorial_acciones
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ================================================================
-- SEED DATA: 56 registros desde Dashboard USS Semana 30 abril
-- ================================================================

INSERT INTO mesa_editorial_acciones (eje, tipo, tema, accion, tipo_accion, fecha, responsable, status) VALUES

-- DISCUSIÓN PAÍS (13 registros)
('Discusión País', 'AO', 'Encuesta Chile Nos Habla-Seguridad', 'Medios de comunicación', 'Externo', '2026-03-30', 'Viviana', 'En desarrollo'),
('Discusión País', 'AO', 'Encuesta Chile Nos Habla-Seguridad', 'Canales USS', NULL, NULL, 'Viviana', 'En desarrollo'),
('Discusión País', 'AO', 'Encuesta Chile Nos Habla-Seguridad', 'Difusión en medios propios', 'Interna-Externa', '2026-03-30', 'TBC', 'Pendiente'),
('Discusión País', 'Ancla', 'Informe Cescro Persecución Crimen Organizado', 'Diseño informes y minuta', 'Interna', '2026-04-01', 'Yaritza', 'En desarrollo'),
('Discusión País', 'Ancla', 'Informe Cescro Persecución Crimen Organizado', 'Landing page, entrega maqueta', 'Interna', '2026-03-30', 'Yaritza', 'Completado'),
('Discusión País', 'Ancla', 'Informe Cescro Persecución Crimen Organizado', 'Desarrollo de comunicado de prensa y bases de datos', 'Interna', '2026-04-02', 'Viviana', 'En desarrollo'),
('Discusión País', 'Ancla', 'Informe Cescro Persecución Crimen Organizado', 'Datos Cescro para presentación (PPT)', 'Interna', '2026-03-31', 'Yaritza', 'En desarrollo'),
('Discusión País', 'Soporte', 'Informe Cescro Persecución Crimen Organizado', 'Seguimiento solicitud reunión ministra Steinert', 'Interna', '2026-03-31', 'Yaritza', 'En desarrollo'),
('Discusión País', 'AO', 'Caso inspectora asesinada en Calama', 'Gestión columna de opinión e Índice de Bienestar Docente', 'Externo', '2026-03-30', 'Viviana', 'En desarrollo'),
('Discusión País', 'AO', 'Presentación Informe Tasa Máxima Convencional', 'Definición de espacio en Campus Los Leones', 'Externo', '2026-03-30', 'María Ignacia', 'Pendiente'),
('Discusión País', 'AO', 'Día Mundial del Autismo', 'Gestión vocerías prensa sobre Ley Tea y PIE', 'Externo', '2026-03-30', 'Viviana', 'Pendiente'),
('Discusión País', 'AO', 'Educación financiera', 'Participación Alejandro Weber en CAB Equifax', NULL, '2026-04-16', 'Yaritza', 'En desarrollo'),
('Discusión País', 'AO', 'Educación financiera', 'Presentación a prensa Informe Deuda Morosa USS-Equifax', 'Externa-Interno', '2026-04-20', 'Yaritza-Viviana', 'Pendiente'),

-- ORGULLO USS (8 registros)
('Orgullo USS', 'Ancla', 'Nuevo rector', 'Video saludo', 'Interna', '2026-04-01', 'Claudia', 'Pendiente'),
('Orgullo USS', 'Ancla', 'Nuevo rector', 'Entrevista para web', 'Interna', '2026-03-31', 'Natalie', 'Pendiente'),
('Orgullo USS', 'Ancla', 'Nuevo rector', 'Entrevista El Mercurio', 'Interna', NULL, 'Extend', 'Pendiente'),
('Orgullo USS', 'Ancla', 'Nuevo rector', 'Teaser', 'Interno', '2026-03-30', 'Felipe', 'Pendiente'),
('Orgullo USS', 'Ancla', 'AQAS', 'Publireportaje 12 de abril', 'Externo', '2026-04-12', 'Natalie', 'Pendiente'),
('Orgullo USS', 'AO', 'Nombramiento Seremi Valdivia', 'Redes sociales y web', 'Interno', '2026-03-31', 'Natalie', 'Pendiente'),
('Orgullo USS', 'AO', 'Nombramiento Seremi Concepción', 'Redes sociales y web', 'Interno', '2026-03-31', 'Natalie', 'Pendiente'),
('Orgullo USS', 'AO', 'Club Deportivo vs Estados Unidos', 'Redes sociales, web, alianza', 'Interno y Externo', '2026-04-01', 'Natalie', 'Pendiente'),

-- SALUD (7 registros)
('Salud', 'AO', 'Año Académico Clínica BUPA', 'Cobertura en terreno', 'Interno', '2026-03-31', 'Esteban', 'Pendiente'),
('Salud', 'AO', 'Año Académico Clínica BUPA', 'Redes sociales y web', 'Interno', '2026-03-31', 'Esteban', 'Pendiente'),
('Salud', 'Ancla', 'Congreso Fronteras en Innovación', 'RRSS, web e inicio oficial del Congreso (Teletón)', 'Interno', '2026-03-26', 'Esteban', 'Pendiente'),
('Salud', 'AO', 'Concurso de Políticas Públicas IPSUSS', 'Redes sociales y web', 'Interno', '2026-04-01', 'Esteban', 'Pendiente'),
('Salud', 'AO', 'Virus respiratorios y estrategias MINSAL', 'Gestión de Prensa', 'Externo', '2026-03-30', 'Cristóbal', 'Pendiente'),
('Salud', 'AO', 'Análisis cáncer IPSUSS', 'Gestión de Prensa', 'Externo', '2026-03-30', 'Esteban - Cristóbal', 'Pendiente'),
('Salud', 'AO', 'Baja natalidad en Chile', 'Gestión de Prensa', 'Externo', '2026-03-30', 'Esteban - Cristóbal', 'Pendiente'),

-- INVESTIGACIÓN (7 registros)
('Investigación', 'Soporte', 'Decretadas', 'Comunicado Actividad', 'Interno', '2026-04-01', 'Sebastián / Marconi', 'Completado'),
('Investigación', 'Soporte', 'Decretadas', 'RRSS Actividad Lanzamiento', 'Interno', '2026-04-01', 'Sebastián / Marconi', 'En desarrollo'),
('Investigación', 'Soporte', 'Decretadas', 'LinkedIn Lanzamiento', 'Interno', '2026-04-01', 'Sebastián / Marconi', 'Pendiente'),
('Investigación', 'Soporte', 'Decretadas', 'Comunicado Conjunto USS/UAI/UNAB', 'Externo', '2026-04-06', 'Sebastián', 'Pendiente'),
('Investigación', 'Soporte', 'Decretadas', 'Columna de opinión', 'Externo', '2026-04-06', 'Sebastián', 'Pendiente'),
('Investigación', 'Soporte', 'Decretadas', 'RRSS Actividades Nacional', 'Externo', '2026-04-08', 'Sebastián', 'Pendiente'),
('Investigación', 'Soporte', 'Aquasur y Pérez-Acle', 'Nota en LinkedIn', 'Interno', '2026-03-30', 'Felipe', 'En desarrollo'),

-- VINCULACIÓN CON EL MEDIO (21 registros)
('Vinculación con el Medio', 'Ancla', '3ra Feria del Libro USS', 'Landing de la Feria', 'Interna', '2026-03-27', 'Sebastián', 'Completado'),
('Vinculación con el Medio', 'Ancla', '3ra Feria del Libro USS', 'Mailing invitación inauguración', 'Interna', '2026-03-30', 'Sebastián', 'Completado'),
('Vinculación con el Medio', 'Ancla', '3ra Feria del Libro USS', 'Intranet', 'Interna', '2026-03-30', 'Sebastián', 'En desarrollo'),
('Vinculación con el Medio', 'Ancla', '3ra Feria del Libro USS', 'Pantalla en los campus', 'Interna', '2026-03-27', 'Sebastián', 'Completado'),
('Vinculación con el Medio', 'Ancla', '3ra Feria del Libro USS', 'Landing USS Banner', 'Interna', '2026-03-27', 'Sebastián', 'Completado'),
('Vinculación con el Medio', 'Ancla', '3ra Feria del Libro USS', 'Reel de Instagram', 'Interna', '2026-03-30', 'Sebastián', 'En desarrollo'),
('Vinculación con el Medio', 'Ancla', '3ra Feria del Libro USS', 'TikTok', 'Interna', '2026-03-30', 'Sebastián', 'En desarrollo'),
('Vinculación con el Medio', 'Ancla', '3ra Feria del Libro USS', 'Nota web Inauguración', 'Interna', '2026-04-09', 'Sebastián', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', '3ra Feria del Libro USS', 'Instagram inauguración', 'Interna', '2026-04-09', 'Sebastián', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', '3ra Feria del Libro USS', 'Gestión de Prensa', 'Externo', '2026-04-06', 'Sebastián', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', '3ra Feria del Libro USS', 'Paid Media / La Tercera', 'Externo', '2026-04-06', 'Sebastián', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', '3ra Feria del Libro USS', 'Nota web Balance', 'Interno', '2026-04-13', 'Sebastián', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', 'Congreso Vinculación con el Medio', 'Columna de opinión', 'Externo', '2026-03-30', 'Jeran', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', 'Congreso Vinculación con el Medio', 'Entrevistas en Radio', 'Externo', '2026-03-30', 'Jeran', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', 'Congreso Vinculación con el Medio', 'Comunicados de Prensa Local', 'Externo', '2026-04-13', 'Jeran', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', 'Congreso Vinculación con el Medio', 'Comunicados de Prensa Nacional', 'Externo', '2026-04-13', 'Sebastián', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', 'Congreso Vinculación con el Medio', 'Sociales Congreso', 'Externo', '2026-04-13', 'Jeran', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', 'Congreso Vinculación con el Medio', 'RRSS Lanzamiento Campaña', 'Interno', '2026-03-29', 'Jeran', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', 'Congreso Vinculación con el Medio', 'RRSS Dinámicas de Interacción', 'Interno', '2026-04-06', 'Jeran', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', 'Congreso Vinculación con el Medio', 'RRSS Presentación Takeovers', 'Interno', '2026-04-13', 'Jeran', 'Pendiente'),
('Vinculación con el Medio', 'Ancla', 'Congreso Vinculación con el Medio', 'RRSS Minuto a minuto', 'Interno', '2026-04-23', 'Jeran', 'Pendiente');

-- Verificar inserción
SELECT eje, COUNT(*) as total FROM mesa_editorial_acciones GROUP BY eje ORDER BY eje;
