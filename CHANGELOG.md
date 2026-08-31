## 1.5.0
- El check va VERDE si el comando salio bien, ROJO si fallo (con el codigo de error)
- La hora y el tiempo de ejecucion tienen colores propios y distintivos
- Segmentos nuevos en el prompt: RAM y CPU (snapshot por comando)
- Medidor EN VIVO de RAM/CPU/reloj en la barra de WezTerm (refresca solo cada
  ~3s desde WezTerm, no frena el Enter ni toca lo que estas tecleando)
- La bateria cambia de color segun la carga: verde (lleno), amarillo, rojo (bajo)
- Iconos arreglados: RAM, CPU, bateria y carpeta ahora usan glyphs validos de la
  Nerd Font (el de RAM era un tofu)
- Si la ruta es muy larga se acorta con `...` (agnoster_short)
- Los comandos internos (__settheme al cambiar tema, etc.) ya no ensucian el
  historial (filtro en atuin)
- Instalacion en Windows: ahora usa winget (nativo, firmado, sin tocar execution
  policy) y funciona en equipos corporativos bloqueados donde scoop no arranca;
  scoop queda de respaldo si winget no esta

## 1.4.0
- Separadores en triangulo (powerline clasico), puntas redondas en extremos
- Fix: el prompt se ve bien desde el primer arranque en un equipo nuevo

## 1.3.0
- Tema nuevo: Monokai Dark Soda (verde lima, magenta, naranja)

## 1.2.0
- Panel de comandos al abrir: ves que podes ejecutar de un vistazo
- Comando `help`: muestra la lista completa de comandos y atajos
- Changelog al actualizar: te muestra que trae cada version nueva

## 1.1.0
- El prompt ahora cambia de color con el tema (Ctrl+Shift+. para ciclar)
- 12 temas: indigo, dracula, catppuccin, nord, tokyo-night, gruvbox y mas
- Segmentos nuevos: bateria y root/admin
- El tiempo de ejecucion aparece solo si el comando tardo (>500ms)
- El check y el error se leen bien en los 12 temas (contraste verificado)
- Auto-update: te avisa y actualiza sin perder tu tema ni tu config

## 1.0.0
- Setup inicial: WezTerm + oh-my-posh + atuin + zoxide + eza
- Prompt indigo con bordes redondeados
- cd inteligente, Ctrl+F buscador de carpetas
- Deteccion de version y aviso de update
