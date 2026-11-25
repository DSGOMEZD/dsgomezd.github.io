import plsqlBulk from "./plsql-bulk.mjs";
import plsqlDinamico from "./plsql-dinamico.mjs";
import mongoPatrones from "./mongo-patrones.mjs";
import mongoGeo from "./mongo-geo.mjs";
import etlFundamentos from "./etl-fundamentos.mjs";
import etlCalidad from "./etl-calidad.mjs";
import etlDw from "./etl-dw.mjs";

// Versión corta: de cada deck solo se publican estas diapositivas (índices).
// El resto del contenido queda en el archivo por si se quiere ampliar luego.
const corta = (deck, keep) => ({ ...deck, slides: keep.map((i) => deck.slides[i]) });

export default [
  corta(plsqlBulk, [0, 1, 3, 5, 6, 10, 11]),
  corta(plsqlDinamico, [0, 1, 4, 6, 7, 10, 11]),
  corta(mongoPatrones, [0, 2, 3, 6, 7, 10, 11]),
  corta(mongoGeo, [0, 2, 4, 6, 7, 9, 10]),
  corta(etlFundamentos, [0, 2, 3, 6, 8, 10, 11]),
  corta(etlCalidad, [0, 2, 4, 5, 6, 9, 10]),
  corta(etlDw, [0, 2, 4, 7, 8, 10, 11]),
];
