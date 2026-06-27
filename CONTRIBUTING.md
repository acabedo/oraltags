# Cómo contribuir a Oraltags

¡Gracias por tu interés! Esta guía resume cómo reportar problemas, pedir soporte y contribuir.

## Reportar problemas (bugs) o pedir soporte

- Usa el **issue tracker** del repositorio: <https://github.com/acabedo/oraltags/issues>.
- Antes de abrir uno nuevo, busca si ya existe.
- Para un bug, incluye: versión de R y del sistema operativo, pasos para reproducirlo,
  qué esperabas y qué ocurrió, y el mensaje de error completo si lo hay.

## Proponer mejoras o nuevas funcionalidades

- Abre un *issue* describiendo la idea y el caso de uso antes de implementarla, para
  acordar el enfoque.

## Contribuir código (Pull Requests)

1. Haz un *fork* y crea una rama descriptiva.
2. Sigue el estilo del código existente.
3. Añade o actualiza pruebas en `tests/testthat/` para la lógica que cambies.
4. Asegúrate de que la suite pasa (ver abajo) y de que `etiquetador_oral.R` parsea.
5. Abre el *Pull Request* describiendo el cambio.

## Ejecutar las pruebas

```r
testthat::test_dir("tests/testthat", stop_on_failure = TRUE)
```

Comprobación de que la app carga sin errores de sintaxis:

```r
parse("etiquetador_oral.R")
```

## Licencia

Al contribuir, aceptas que tu aportación se distribuya bajo la licencia del proyecto
(**GPL-3.0**).
