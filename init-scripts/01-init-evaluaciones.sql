-- ============================================
-- Script de inicialización para evaluaciones de CV
-- ============================================

-- Extensión para generar UUIDs (opcional pero útil)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. TABLA PRINCIPAL: evaluaciones_candidatos
-- ============================================
CREATE TABLE IF NOT EXISTS evaluaciones_candidatos (
    id SERIAL PRIMARY KEY,
    correo_candidato VARCHAR(255) NOT NULL,
    estado VARCHAR(50) NOT NULL CHECK (estado IN (
        'interesado',
        'muy_interesado',
        'contactado',
        'entrevistado',
        'descartado',
        'en_proceso',
        'oferta_enviada',
        'contratado'
    )),
    observacion TEXT,
    calificacion_numerica INT CHECK (calificacion_numerica BETWEEN 1 AND 5),
    usuario_evaluador VARCHAR(255),
    metadata JSONB DEFAULT '{}', -- Para datos adicionales flexibles
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Índices para mejorar performance
CREATE INDEX idx_eval_correo ON evaluaciones_candidatos(correo_candidato);
CREATE INDEX idx_eval_estado ON evaluaciones_candidatos(estado);
CREATE INDEX idx_eval_usuario ON evaluaciones_candidatos(usuario_evaluador);
CREATE INDEX idx_eval_created ON evaluaciones_candidatos(created_at);
CREATE INDEX idx_eval_calificacion ON evaluaciones_candidatos(calificacion_numerica);

-- Índice para búsquedas por correo + estado (combinado)
CREATE INDEX idx_eval_correo_estado ON evaluaciones_candidatos(correo_candidato, estado);

-- ============================================
-- 2. TABLA DE HISTORIAL: historial_evaluaciones
-- ============================================
CREATE TABLE IF NOT EXISTS historial_evaluaciones (
    id SERIAL PRIMARY KEY,
    evaluacion_id INT REFERENCES evaluaciones_candidatos(id) ON DELETE CASCADE,
    correo_candidato VARCHAR(255) NOT NULL,
    estado_anterior VARCHAR(50),
    estado_nuevo VARCHAR(50) NOT NULL,
    observacion_anterior TEXT,
    observacion_nueva TEXT,
    calificacion_anterior INT,
    calificacion_nueva INT,
    usuario VARCHAR(255),
    fecha_cambio TIMESTAMP DEFAULT NOW()
);

-- Índices para historial
CREATE INDEX idx_hist_evaluacion ON historial_evaluaciones(evaluacion_id);
CREATE INDEX idx_hist_correo ON historial_evaluaciones(correo_candidato);
CREATE INDEX idx_hist_fecha ON historial_evaluaciones(fecha_cambio);

-- ============================================
-- 3. TABLA DE TAGS: tags_candidatos
-- ============================================
CREATE TABLE IF NOT EXISTS tags_candidatos (
    id SERIAL PRIMARY KEY,
    correo_candidato VARCHAR(255) NOT NULL,
    tag VARCHAR(100) NOT NULL,
    color VARCHAR(20) DEFAULT 'blue', -- Para UI: blue, green, red, yellow, etc.
    created_by VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    
    -- Un candidato no puede tener el mismo tag duplicado
    UNIQUE(correo_candidato, tag)
);

-- Índices para tags
CREATE INDEX idx_tags_correo ON tags_candidatos(correo_candidato);
CREATE INDEX idx_tags_tag ON tags_candidatos(tag);

-- ============================================
-- 4. FUNCIÓN: Trigger para actualizar updated_at
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger a evaluaciones_candidatos
CREATE TRIGGER update_evaluaciones_updated_at
    BEFORE UPDATE ON evaluaciones_candidatos
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 5. FUNCIÓN: Trigger para registrar historial automáticamente
-- ============================================
CREATE OR REPLACE FUNCTION registrar_historial_evaluacion()
RETURNS TRIGGER AS $$
BEGIN
    -- Solo registrar si hubo cambios en campos importantes
    IF (OLD.estado IS DISTINCT FROM NEW.estado) OR 
       (OLD.observacion IS DISTINCT FROM NEW.observacion) OR
       (OLD.calificacion_numerica IS DISTINCT FROM NEW.calificacion_numerica) THEN
        
        INSERT INTO historial_evaluaciones (
            evaluacion_id,
            correo_candidato,
            estado_anterior,
            estado_nuevo,
            observacion_anterior,
            observacion_nueva,
            calificacion_anterior,
            calificacion_nueva,
            usuario
        ) VALUES (
            NEW.id,
            NEW.correo_candidato,
            OLD.estado,
            NEW.estado,
            OLD.observacion,
            NEW.observacion,
            OLD.calificacion_numerica,
            NEW.calificacion_numerica,
            NEW.usuario_evaluador
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger a evaluaciones_candidatos
CREATE TRIGGER trigger_historial_evaluacion
    AFTER UPDATE ON evaluaciones_candidatos
    FOR EACH ROW
    EXECUTE FUNCTION registrar_historial_evaluacion();

-- ============================================
-- 6. VISTAS ÚTILES PARA REPORTES
-- ============================================

-- Vista: Última evaluación de cada candidato
CREATE OR REPLACE VIEW v_ultima_evaluacion_candidato AS
SELECT DISTINCT ON (correo_candidato)
    id,
    correo_candidato,
    estado,
    observacion,
    calificacion_numerica,
    usuario_evaluador,
    created_at,
    updated_at
FROM evaluaciones_candidatos
ORDER BY correo_candidato, updated_at DESC;

-- Vista: Resumen por estado
CREATE OR REPLACE VIEW v_resumen_estados AS
SELECT 
    estado,
    COUNT(*) as total_candidatos,
    AVG(calificacion_numerica)::NUMERIC(3,2) as calificacion_promedio,
    COUNT(DISTINCT usuario_evaluador) as evaluadores
FROM v_ultima_evaluacion_candidato
GROUP BY estado
ORDER BY total_candidatos DESC;

-- Vista: Candidatos con múltiples evaluaciones
CREATE OR REPLACE VIEW v_candidatos_reevaluados AS
SELECT 
    correo_candidato,
    COUNT(*) as num_evaluaciones,
    MAX(updated_at) as ultima_actualizacion,
    array_agg(DISTINCT estado ORDER BY estado) as estados_historicos
FROM evaluaciones_candidatos
GROUP BY correo_candidato
HAVING COUNT(*) > 1
ORDER BY num_evaluaciones DESC;

-- ============================================
-- 7. DATOS DE EJEMPLO (OPCIONAL - Comentar si no quieres)
-- ============================================
/*
INSERT INTO evaluaciones_candidatos (correo_candidato, estado, observacion, calificacion_numerica, usuario_evaluador)
VALUES 
    ('ejemplo1@test.com', 'interesado', 'Buen perfil técnico, experiencia relevante', 4, 'reclutador@empresa.com'),
    ('ejemplo2@test.com', 'muy_interesado', 'Candidato excepcional para senior', 5, 'reclutador@empresa.com'),
    ('ejemplo3@test.com', 'descartado', 'No cumple años de experiencia requeridos', 2, 'reclutador@empresa.com');

INSERT INTO tags_candidatos (correo_candidato, tag, color, created_by)
VALUES
    ('ejemplo1@test.com', 'urgente', 'red', 'reclutador@empresa.com'),
    ('ejemplo2@test.com', 'senior_plus', 'gold', 'reclutador@empresa.com'),
    ('ejemplo2@test.com', 'proyecto_x', 'blue', 'reclutador@empresa.com');
*/

-- ============================================
-- 8. COMENTARIOS EN TABLAS (Documentación)
-- ============================================
COMMENT ON TABLE evaluaciones_candidatos IS 'Tabla principal para almacenar evaluaciones de candidatos';
COMMENT ON TABLE historial_evaluaciones IS 'Historial de cambios en evaluaciones de candidatos';
COMMENT ON TABLE tags_candidatos IS 'Tags personalizados para categorizar candidatos';

COMMENT ON COLUMN evaluaciones_candidatos.metadata IS 'Campo JSONB flexible para almacenar datos adicionales sin modificar schema';
COMMENT ON COLUMN evaluaciones_candidatos.calificacion_numerica IS 'Calificación del 1 al 5, donde 5 es excelente';

-- ============================================
-- FIN DEL SCRIPT
-- ============================================

-- Confirmar creación exitosa
DO $$ 
BEGIN
    RAISE NOTICE '✅ Base de datos inicializada correctamente';
    RAISE NOTICE '📊 Tablas creadas: evaluaciones_candidatos, historial_evaluaciones, tags_candidatos';
    RAISE NOTICE '🔍 Vistas creadas: v_ultima_evaluacion_candidato, v_resumen_estados, v_candidatos_reevaluados';
    RAISE NOTICE '⚡ Triggers configurados para: historial automático y updated_at';
END $$;
```

## 📋 Pasos para implementar:

### 1. Estructura de carpetas
```
tu-proyecto/
├── docker-compose.yml
├── init-scripts/
│   └── 01-init-evaluaciones.sql
└── n8n_data/