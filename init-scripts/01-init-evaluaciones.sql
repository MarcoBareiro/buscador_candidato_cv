-- ============================================
-- Script de inicialización para evaluaciones de CV
-- ============================================

-- Tabla principal de candidatos
CREATE TABLE candidato (
    id SERIAL PRIMARY KEY,
    persona_nombre_apellido VARCHAR(255) NOT NULL,
    persona_correo VARCHAR(255) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'activo' CHECK (estado IN ('activo', 'contratado', 'rechazado')),
    observacion TEXT,
    usuario_insert VARCHAR(100) NOT NULL,
    usuario_update VARCHAR(100),
    fecha_insert TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de evaluaciones de candidatos
CREATE TABLE candidato_evaluacion (
    id SERIAL PRIMARY KEY,
    candidato_id INTEGER NOT NULL,
    estado VARCHAR(30) NOT NULL DEFAULT 'pendiente_entrevista' CHECK (estado IN ('pendiente_entrevista', 'entrevistado')),
    puesto_requerido VARCHAR(100) NOT NULL,
    proyecto VARCHAR(100) NOT NULL,
    evaluacion_rrhh TEXT,
    evaluacion_tecnico TEXT,
    evaluacion_fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observacion TEXT,
    usuario_insert VARCHAR(100) NOT NULL,
    usuario_update VARCHAR(100),
    fecha_insert TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Clave foránea
    CONSTRAINT fk_candidato_evaluacion_candidato 
        FOREIGN KEY (candidato_id) 
        REFERENCES candidato(id) 
        ON DELETE CASCADE
);

-- Índices para la tabla candidato
CREATE INDEX idx_candidato_correo ON candidato(persona_correo);
CREATE INDEX idx_candidato_estado ON candidato(estado);
CREATE INDEX idx_candidato_fecha_insert ON candidato(fecha_insert);
CREATE UNIQUE INDEX uk_candidato_correo ON candidato(persona_correo);

-- Índices para la tabla candidato_evaluacion
CREATE INDEX idx_candidato_evaluacion_candidato_id ON candidato_evaluacion(candidato_id);
CREATE INDEX idx_candidato_evaluacion_estado ON candidato_evaluacion(estado);
CREATE INDEX idx_candidato_evaluacion_puesto ON candidato_evaluacion(puesto_requerido);
CREATE INDEX idx_candidato_evaluacion_proyecto ON candidato_evaluacion(proyecto);
CREATE INDEX idx_candidato_evaluacion_fecha_insert ON candidato_evaluacion(fecha_insert);

-- Trigger para actualizar automáticamente fecha_update en candidato
CREATE OR REPLACE FUNCTION update_candidato_fecha_update()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_update = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_candidato_fecha_update
    BEFORE UPDATE ON candidato
    FOR EACH ROW
    EXECUTE FUNCTION update_candidato_fecha_update();

-- Trigger para actualizar automáticamente fecha_update en candidato_evaluacion
CREATE OR REPLACE FUNCTION update_candidato_evaluacion_fecha_update()
RETURNS TRIGGER AS $$
BEGIN
    NEW.fecha_update = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_candidato_evaluacion_fecha_update
    BEFORE UPDATE ON candidato_evaluacion
    FOR EACH ROW
    EXECUTE FUNCTION update_candidato_evaluacion_fecha_update();