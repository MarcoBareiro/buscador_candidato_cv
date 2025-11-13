-- ============================================
-- Script de inicialización para evaluaciones de CV
-- ============================================

-- Tabla principal de candidatos
INSERT INTO candidato (
    persona_nombre_apellido, 
    persona_correo, 
    estado, 
    observacion, 
    usuario_insert
) VALUES (
    'Carolina Bujaico', 
    'carolrosa95@hotmail.com', 
    'activo', 
    null, 
    'sistema'
);


INSERT INTO candidato_evaluacion (
    candidato_id,
    estado,
    puesto_requerido,
    proyecto,
    observacion,
    usuario_insert
) VALUES (
    (SELECT id FROM candidato WHERE persona_correo = 'carolrosa95@hotmail.com'),
    'pendiente_entrevista',
    'Desarrollador Backend',
    'Entidad del Gobierno',
    null,
    'sistema'
);