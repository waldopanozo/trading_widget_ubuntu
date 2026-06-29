# Contributing

**English** | Español abajo

Thank you for considering a contribution to **Desktop Panel Conky**!

## How to contribute

1. Fork the repository.
2. Clone your fork and create a branch: `git checkout -b feature/my-improvement`
3. Run `./scripts/install.sh` and verify the widget works on **Ubuntu + GNOME Wayland**.
4. Keep changes focused — one feature or fix per pull request.
5. Update **both** `README.md` and `README.es.md` if behavior or setup changes.
6. Open a pull request with a clear description and screenshots if UI changes.

## Ideas welcome

- Additional timezone presets for trading hubs (London, Tokyo, New York)
- More crypto pairs or fiat tickers
- Better network interface auto-detection on reconnect
- Support for other desktop environments (with documented limitations)

## Code style

- Shell scripts: `bash` with `set -euo pipefail` where appropriate
- Python: standard library + Pillow only
- User-visible strings in English (translations via docs)
- Comments in English

## Reporting bugs

Include:

- Ubuntu version and GNOME version
- `echo $XDG_SESSION_TYPE`
- Relevant lines from `~/.cache/panel-escritorio-conky/launch.log`
- Steps to reproduce

---

# Contribuir

**Español** | English above

¡Gracias por considerar contribuir a **Panel Escritorio Conky**!

## Cómo contribuir

1. Haz fork del repositorio.
2. Clona tu fork y crea una rama: `git checkout -b feature/mi-mejora`
3. Ejecuta `./scripts/install.sh` y verifica que el widget funcione en **Ubuntu + GNOME Wayland**.
4. Mantén cambios enfocados — una funcionalidad o fix por pull request.
5. Actualiza **ambos** `README.md` y `README.es.md` si cambia el comportamiento o la instalación.
6. Abre un pull request con descripción clara y capturas si hay cambios visuales.

## Ideas bienvenidas

- Presets de zonas horarias para hubs de trading (Londres, Tokio, Nueva York)
- Más pares crypto o tickers fiat
- Mejor detección de interfaz de red al reconectar
- Soporte para otros entornos de escritorio (con limitaciones documentadas)

## Estilo de código

- Scripts shell: `bash` con `set -euo pipefail` donde aplique
- Python: solo biblioteca estándar + Pillow
- Textos visibles al usuario en inglés (traducciones en la documentación)
- Comentarios en inglés

## Reportar bugs

Incluye:

- Versión de Ubuntu y GNOME
- `echo $XDG_SESSION_TYPE`
- Líneas relevantes de `~/.cache/panel-escritorio-conky/launch.log`
- Pasos para reproducir
