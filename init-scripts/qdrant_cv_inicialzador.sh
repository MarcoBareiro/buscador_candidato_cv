#!/bin/bash

# ============================================
# SCRIPT DE INICIALIZACIÓN QDRANT
# ============================================
# Ejecutar este script después de levantar los contenedores
# para crear la colección inicial

echo "🚀 Inicializando Qdrant para RAG..."

# Esperar a que Qdrant esté disponible
echo "⏳ Esperando a que Qdrant esté listo..."
until curl -s http://localhost:6333/health > /dev/null; do
  echo "   Qdrant no disponible, esperando..."
  sleep 2
done
echo "✅ Qdrant está disponible"

# Verificar si la colección ya existe
echo ""
echo "🔍 Verificando si la colección existe..."
COLLECTION_EXISTS=$(curl -s http://localhost:6333/collections/curriculums_rag | grep -o '"result"' || echo "")

if [ -n "$COLLECTION_EXISTS" ]; then
  echo "⚠️  La colección 'curriculums_rag' ya existe"
  echo "¿Deseas eliminarla y recrearla? (s/n)"
  read -r response
  if [[ "$response" =~ ^([sS])$ ]]; then
    echo "🗑️  Eliminando colección existente..."
    curl -X DELETE http://localhost:6333/collections/curriculums_rag
    sleep 1
  else
    echo "✅ Usando colección existente"
    exit 0
  fi
fi

# Crear la colección
echo ""
echo "📦 Creando colección 'curriculums_rag'..."
RESPONSE=$(curl -s -X PUT http://localhost:6333/collections/curriculums_rag \
  -H "Content-Type: application/json" \
  -d '{
    "vectors": {
      "size": 1024,
      "distance": "Cosine"
    },
    "optimizers_config": {
      "default_segment_number": 2,
      "indexing_threshold": 20000
    },
    "hnsw_config": {
      "m": 16,
      "ef_construct": 100
    }
  }')

# Verificar resultado
if echo "$RESPONSE" | grep -q '"result":true'; then
  echo "✅ Colección creada exitosamente"
  echo ""
  echo "📊 Detalles de la colección:"
  curl -s http://localhost:6333/collections/curriculums_rag | jq '.'
else
  echo "❌ Error al crear la colección"
  echo "$RESPONSE"
  exit 1
fi

echo ""
echo "🎉 Inicialización completada!"
echo ""
echo "📝 Próximos pasos:"
echo "   1. Importa el workflow en n8n"
echo "   2. Configura las credenciales de Cloudflare"
echo "   3. Ejecuta el flujo con un documento de prueba"