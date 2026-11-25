// Taller MQL - MongoDB (sample_mflix)
// Integrantes: Mariana Durán Piñeros y avid Santiago Gomez Durán
// ============================================================
// PARTE A - CONSULTAS (find)
// ============================================================

// Punto 1: busca las películas de Drama estrenadas entre 2000 y 2010 con rating de 8 o más,
// y muestra solo las 10 mejores (de mayor a menor rating).
use('sample_mflix');
db.getCollection('movies').find(
  { genres: "Drama", year: { $gte: 2000, $lte: 2010 }, "imdb.rating": { $gte: 8 } },
  { _id: 0, title: 1, year: 1, "imdb.rating": 1 }
).sort({ "imdb.rating": -1 }).limit(10);

// Punto 1: cuenta cuántas películas cumplen el mismo filtro en total, sin el límite de 10.
db.getCollection('movies').countDocuments(
  { genres: "Drama", year: { $gte: 2000, $lte: 2010 }, "imdb.rating": { $gte: 8 } }
);

// Punto 2: busca las películas donde actúa Tom Hanks pero que no dirigió Steven Spielberg.
use('sample_mflix');
db.getCollection('movies').find(
  { cast: "Tom Hanks", directors: { $ne: "Steven Spielberg" } },
  { _id: 0, title: 1, year: 1, directors: 1 }
);

// Punto 3: busca las películas que tienen exactamente 3 géneros y entre ellos están Comedy y Romance.
use('sample_mflix');
db.getCollection('movies').find(
  { genres: { $all: ["Comedy", "Romance"], $size: 3 } },
  { _id: 0, title: 1, genres: 1 }
);

// Punto 4: busca las películas que no tienen el campo rated, o que lo tienen como UNRATED o NOT RATED.
use('sample_mflix');
db.getCollection('movies').find(
  {
    $or: [
      { rated: { $exists: false } },
      { rated: { $in: ["UNRATED", "NOT RATED"] } }
    ]
  },
  { _id: 0, title: 1, rated: 1 }
);

// Punto 4: cuenta cuántas películas cumplen esa condición.
use('sample_mflix');
db.getCollection('movies').countDocuments(
  {
    $or: [
      { rated: { $exists: false } },
      { rated: { $in: ["UNRATED", "NOT RATED"] } }
    ]
  }
);

// Punto 5: busca los títulos que empiezan por "The" y terminan en "Man", sin importar mayúsculas o minúsculas.
use('sample_mflix');
db.getCollection('movies').find(
  {
    $and: [
      { title: { $regex: /^The/i } },
      { title: { $regex: /Man$/i } }
    ]
  },
  { _id: 0, title: 1, year: 1 }
);

// ============================================================
// PARTE B - AGREGACIÓN (aggregate)
// ============================================================

// Punto 6: agrupa las películas por género y calcula cuántas hay, el rating promedio y el rating máximo.
// Solo deja los géneros con más de 500 películas y los ordena por promedio, del más alto al más bajo.
// (Primero se quitan los ratings vacíos "" para que no dañen el promedio.)
use('sample_mflix');
db.getCollection('movies').aggregate([
  { $match: { "imdb.rating": { $type: "number" } } },
  { $unwind: "$genres" },
  { $group: {
      _id: "$genres",
      totalPeliculas: { $sum: 1 },
      ratingPromedio: { $avg: "$imdb.rating" },
      ratingMaximo: { $max: "$imdb.rating" }
  } },
  { $match: { totalPeliculas: { $gt: 500 } } },
  { $project: {
      _id: 0,
      genero: "$_id",
      totalPeliculas: 1,
      ratingPromedio: { $round: ["$ratingPromedio", 2] },
      ratingMaximo: 1
  } },
  { $sort: { ratingPromedio: -1 } }
]);

// Punto 7: saca los 5 directores con más películas de rating 7.5 o más (mínimo 5 películas),
// y muestra el director, cuántas tiene y máximo 3 títulos.
use('sample_mflix');
db.getCollection('movies').aggregate([
  { $match: { "imdb.rating": { $gte: 7.5 } } },
  { $unwind: "$directors" },
  { $group: { _id: "$directors", cantidad: { $sum: 1 }, titulos: { $push: "$title" } } },
  { $match: { cantidad: { $gte: 5 } } },
  { $sort: { cantidad: -1 } },
  { $limit: 5 },
  { $project: { _id: 0, director: "$_id", cantidad: 1, titulos: { $slice: ["$titulos", 3] } } }
]);

// Punto 8: cuenta cuántas películas hay en cada década, desde 1950 en adelante.
use('sample_mflix');
db.getCollection('movies').aggregate([
  { $match: { year: { $gte: 1950 } } },
  { $group: {
      _id: { $subtract: ["$year", { $mod: ["$year", 10] }] },
      totalPeliculas: { $sum: 1 }
  } },
  { $sort: { _id: 1 } },
  { $project: { _id: 0, decada: { $concat: [{ $toString: "$_id" }, "s"] }, totalPeliculas: 1 } }
]);

// Punto 9: saca las 10 películas con más comentarios y muestra su título, año y cuántos comentarios tiene.
// Primero cuenta los comentarios y después busca los datos de la película con $lookup.
use('sample_mflix');
db.getCollection('comments').aggregate([
  { $group: { _id: "$movie_id", totalComentarios: { $sum: 1 } } },
  { $sort: { totalComentarios: -1 } },
  { $limit: 10 },
  { $lookup: { from: "movies", localField: "_id", foreignField: "_id", as: "pelicula" } },
  { $unwind: "$pelicula" },
  { $project: { _id: 0, titulo: "$pelicula.title", anio: "$pelicula.year", totalComentarios: 1 } },
  { $sort: { totalComentarios: -1 } }
]);

// Punto 10: lista los usuarios (por email) que han hecho más de 250 comentarios,
// con la fecha de su primer comentario y la de su último comentario.
use('sample_mflix');
db.getCollection('comments').aggregate([
  { $group: {
      _id: "$email",
      totalComentarios: { $sum: 1 },
      primerComentario: { $min: "$date" },
      ultimoComentario: { $max: "$date" }
  } },
  { $match: { totalComentarios: { $gt: 250 } } },
  { $project: { _id: 0, email: "$_id", totalComentarios: 1, primerComentario: 1, ultimoComentario: 1 } },
  { $sort: { totalComentarios: -1 } }
]);

// ============================================================
// PARTE C - ESCRITURA E ÍNDICES
// ============================================================

// Punto 11: crea una colección nueva llamada peliculas_pareja con las películas de 2015
// y les agrega una categoría según su rating: Alta (7.5 o más), Media (6 o más) o Baja (el resto).
use('sample_mflix');
db.getCollection('movies').aggregate([
  { $match: { year: 2015, "imdb.rating": { $type: "number" } } },
  { $project: {
      title: 1,
      genres: 1,
      rating: "$imdb.rating",
      categoria: {
        $switch: {
          branches: [
            { case: { $gte: ["$imdb.rating", 7.5] }, then: "Alta" },
            { case: { $gte: ["$imdb.rating", 6] }, then: "Media" }
          ],
          default: "Baja"
        }
      }
  } },
  { $out: "peliculas_pareja" }
]);

// Punto 12: a las películas de categoría Media les agrega el campo revisado: true
// y les sube el rating en 0.1. El resultado muestra matchedCount y modifiedCount.
use('sample_mflix');
db.getCollection('peliculas_pareja').updateMany(
  { categoria: "Media" },
  { $set: { revisado: true }, $inc: { rating: 0.1 } }
);

// Punto 13: borra las películas de categoría Baja. El resultado muestra cuántas se borraron (deletedCount).
use('sample_mflix');
db.getCollection('peliculas_pareja').deleteMany({ categoria: "Baja" });

// Punto 14: mide la consulta del punto 1 SIN índice. Aquí se ver COLLSCAN.
use('sample_mflix');
db.getCollection('movies').find(
  { genres: "Drama", year: { $gte: 2000, $lte: 2010 }, "imdb.rating": { $gte: 8 } },
  { _id: 0, title: 1, year: 1, "imdb.rating": 1 }
).sort({ "imdb.rating": -1 }).limit(10).explain("executionStats");

// Punto 14: crea el índice compuesto siguiendo ESR:
// primero genres (igualdad), luego imdb.rating (orden) y al final year (rango).
use('sample_mflix');
db.getCollection('movies').createIndex(
  { genres: 1, "imdb.rating": -1, year: 1 },
  { name: "idx_genero_rating_year" }
);

// Punto 14: mide la misma consulta CON el índice. Aquí se ve IXSCAN.
use('sample_mflix');
db.getCollection('movies').find(
  { genres: "Drama", year: { $gte: 2000, $lte: 2010 }, "imdb.rating": { $gte: 8 } },
  { _id: 0, title: 1, year: 1, "imdb.rating": 1 }
).sort({ "imdb.rating": -1 }).limit(10).explain("executionStats");

// Punto 14: elimina el índice que se creó, como pide el enunciado.
use('sample_mflix');
db.getCollection('movies').dropIndex("idx_genero_rating_year");