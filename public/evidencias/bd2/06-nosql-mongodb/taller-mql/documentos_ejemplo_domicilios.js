// Documento de ejemplo por cada colección del Caso 1.

// Caso 1: restaurantes

{
  _id: ObjectId("665f1c2e8a1b2c3d4e5f6a01"),
  nombre: "Sabor Cartagenero",
  tipoCocina: "Colombiana",
  ciudad: "Bogotá",
  barrio: "Chicó Norte",
  direccion: "Calle 85 # 15-20",
  calificacion: { promedio: 4.6, totalResenas: 52340, suma: 240764 },
  resenasRecientes: [
    { resenaId: ObjectId("665f1c2e8a1b2c3d4e5f7001"), nombre: "Laura", apellido: "Martínez",
      puntaje: 5, comentario: "Todo llegó caliente y muy rico.", fecha: ISODate("2026-11-06T02:10:00Z") },
    { resenaId: ObjectId("665f1c2e8a1b2c3d4e5f7002"), nombre: "Andrés", apellido: "Rojas",
      puntaje: 4, comentario: "Buena porción, pero se demoró un poco.", fecha: ISODate("2026-11-06T01:35:00Z") },
    { resenaId: ObjectId("665f1c2e8a1b2c3d4e5f7003"), nombre: "Sofía", apellido: "Herrera",
      puntaje: 5, comentario: "Excelente sazón.", fecha: ISODate("2026-11-06T00:58:00Z") }
  ]
}

// Caso 1: menus

{
  _id: ObjectId("665f1c2e8a1b2c3d4e5f6b01"),
  restauranteId: ObjectId("665f1c2e8a1b2c3d4e5f6a01"),
  nombre: "Almuerzo",
  items: [
    { platoId: ObjectId("665f1c2e8a1b2c3d4e5f6c01"), nombre: "Bandeja paisa",
      descripcion: "Frijoles, arroz, carne molida, chicharrón, huevo y plátano maduro.",
      categoria: "Plato fuerte", precio: 32000, disponible: true,
      atributos: [
        { clave: "tamano", valor: "grande" },
        { clave: "nivelPicante", valor: "medio" },
        { clave: "aptoVegano", valor: "no" },
        { clave: "adiciones", valor: "huevo extra, aguacate" }
      ] },
    { platoId: ObjectId("665f1c2e8a1b2c3d4e5f6c02"), nombre: "Jugo de lulo",
      descripcion: "Jugo natural en agua o en leche.",
      categoria: "Bebida", precio: 8000, disponible: true,
      atributos: [
        { clave: "tamano", valor: "mediano" },
        { clave: "aptoVegano", valor: "si" }
      ] }
  ]
}

// Caso 1: clientes

{
  _id: ObjectId("665f1c2e8a1b2c3d4e5f6d01"),
  nombre: "Laura",
  apellido: "Martínez",
  correo: "laura.martinez@example.com",
  telefono: "3001234567",
  fechaRegistro: ISODate("2025-03-14T15:22:00Z"),
  direcciones: [
    { alias: "Casa", barrio: "La Soledad", direccion: "Carrera 7 # 45-10", ciudad: "Bogotá", principal: true },
    { alias: "Oficina", barrio: "Chicó Norte", direccion: "Calle 100 # 19-61", ciudad: "Bogotá", principal: false }
  ]
}

// Caso 1: repartidores

{
  _id: ObjectId("665f1c2e8a1b2c3d4e5f6e01"),
  nombre: "Carlos",
  apellido: "Gómez",
  telefono: "3109876543",
  tipoVehiculo: "Moto",
  placa: "ABC12D",
  estado: "disponible"
}

// Caso 1: pedidos

{
  _id: ObjectId("665f1c2e8a1b2c3d4e5f6f01"),
  fecha: ISODate("2026-11-06T00:42:10Z"),
  estado: "entregado",
  clienteId: ObjectId("665f1c2e8a1b2c3d4e5f6d01"),
  restauranteId: ObjectId("665f1c2e8a1b2c3d4e5f6a01"),
  restauranteNombre: "Sabor Cartagenero",
  repartidorId: ObjectId("665f1c2e8a1b2c3d4e5f6e01"),
  direccionEntrega: { barrio: "La Soledad", direccion: "Carrera 7 # 45-10", ciudad: "Bogotá" },
  items: [
    { platoId: ObjectId("665f1c2e8a1b2c3d4e5f6c01"), nombre: "Bandeja paisa", precio: 32000, cantidad: 2, subtotal: 64000 },
    { platoId: ObjectId("665f1c2e8a1b2c3d4e5f6c02"), nombre: "Jugo de lulo", precio: 8000, cantidad: 2, subtotal: 16000 }
  ],
  costoDomicilio: 5000,
  total: 85000,
  metodoPago: "tarjeta"
}

// Caso 1: resenas

{
  _id: ObjectId("665f1c2e8a1b2c3d4e5f7001"),
  restauranteId: ObjectId("665f1c2e8a1b2c3d4e5f6a01"),
  clienteId: ObjectId("665f1c2e8a1b2c3d4e5f6d01"),
  pedidoId: ObjectId("665f1c2e8a1b2c3d4e5f6f01"),
  nombre: "Laura",
  apellido: "Martínez",
  puntaje: 5,
  comentario: "Todo llegó caliente y muy rico.",
  fecha: ISODate("2026-11-06T02:10:00Z")
}


// Caso 2: sensores

{
  _id: "SEN-0001",
  localidad: "Chapinero",
  modelo: "AQ-200",
  estado: "activo",
  schema_version: 2
}

// Caso 2: lecturas_bucket (versión 2, con co2)

{
  _id: ObjectId("6730a1b2c3d4e5f607182930"),
  sensor_id: "SEN-0001",
  localidad: "Chapinero",
  inicio: ISODate("2026-11-10T08:00:00Z"),
  fin: ISODate("2026-11-10T09:00:00Z"),
  schema_version: 2,
  n_lecturas: 3,
  n_alertas: 1,
  tiene_alerta: true,
  mediciones: [
    { ts: ISODate("2026-11-10T08:00:00Z"), pm25: 30.2, pm10: 55.1, temp: 14.5, hum: 72, co2: 415 },
    { ts: ISODate("2026-11-10T08:01:00Z"), pm25: 38.4, pm10: 60.3, temp: 14.6, hum: 71, co2: 420 },
    { ts: ISODate("2026-11-10T08:02:00Z"), pm25: 35.0, pm10: 58.0, temp: 14.6, hum: 71, co2: 418 }
  ],
  resumen: {
    pm25: { suma: 103.6, promedio: 34.53, max: 38.4, min: 30.2 }
  }
}

// Caso 2: lecturas_bucket (versión 1, sin co2)

{
  _id: ObjectId("6730a1b2c3d4e5f607182929"),
  sensor_id: "SEN-0002",
  localidad: "Usaquén",
  inicio: ISODate("2025-03-04T14:00:00Z"),
  fin: ISODate("2025-03-04T15:00:00Z"),
  schema_version: 1,
  n_lecturas: 2,
  n_alertas: 0,
  tiene_alerta: false,
  mediciones: [
    { ts: ISODate("2025-03-04T14:00:00Z"), pm25: 20.5, pm10: 41.0, temp: 15.1, hum: 68 },
    { ts: ISODate("2025-03-04T14:01:00Z"), pm25: 22.0, pm10: 43.2, temp: 15.1, hum: 68 }
  ],
  resumen: {
    pm25: { suma: 42.5, promedio: 21.25, max: 22.0, min: 20.5 }
  }
}

// Caso 2: alertas

{
  _id: ObjectId("6730a1b2c3d4e5f607182931"),
  sensor_id: "SEN-0001",
  localidad: "Chapinero",
  ts: ISODate("2026-11-10T08:01:00Z"),
  valor: 38.4,
  umbral: 37
}
