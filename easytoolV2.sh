#!/bin/bash

#	│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│
#	│            Script Easytool for Ubuntu              │
#	│              16.4.05 Xenial Xerus                  │
#	│            v1.1 / ffmpeg converter                 │
#	│▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│

#set -o
#set -x
#set -v
#set -e

#zenity --question --title "Alerta" --text "Se encontro Microsoft Windows instalado en tu sistema! Deseas eliminarlo?" 2>/dev/null
#zenity --notification --window-icon=update.png --text "¡Actualización del sistema necesaria!"
# --- Exit si da 0 (Error)
E_RUNERR=65
tput cup 0 0
# Define las dimenciones de la terminal.
N_COLS=`tput cols`
N_LINES=`tput lines`
# Chequeo de columnas y lineas de la terminal
if [ $N_COLS -lt 80 ] || [ $N_LINES -lt 24 ]; then
	clear;echo;echo
echo -e "  \t Tu Terminal usa ${N_COLS}-columnas X ${N_LINES}- Lineas."
echo -e "  \t `basename $0` Nesecita 80-columnas X 24-lineas, "
echo -e "  \t Resuelve el problema buscando en el menu :"
echo -e "  \t Editar/preferencias de perfil/general:Tamaño inicial del Terminal."
echo -e "  \t luego reinicia tu terminal y vuelve a iniciar `basename $0` "
echo
exit $E_RUNERR
fi

##-------- COLORES
GREEN="$(echo -e  "\033[32m")"
BLUE="$(echo -e "\033[34m")"
VIOLET="$(echo -e "\033[35m")"
WHITE="$(echo -e "\033[37m")"
YELLOW="$(echo -e "\033[33m")"
RED="$(echo -e "\033[31m")"
CYAN="$(echo -e "\033[36m")"
BLACK="$(echo -e "\033[30m")"
STOP="$(echo -e "\033[0m")"
## ------- COLORES EN NEGRITA
RED_BOLD="$(echo -e "\033[01;31m")"
BLUE_BOLD="$(echo -e "\033[01;34m")"
VIOLET_BOLD="$(echo -e "\033[01;35m")"
GREEN_BOLD="$(echo -e "\033[01;32m")"
YELLOW_BOLD="$(echo -e "\033[00;33m")"
BLACK_BOLD="$(echo -e "\033[01;30m")"
WHITE_BOLD="$(echo -e "\033[01;37m")"
DEFAULT_COL="$(echo -e "\033[01;30m")"

# -------- Variables generales
MAIL=pabloc.labarca@gmail.com
TIME="$(cmd=`date +"%H:%M:%S %F"`;echo -n -e "\033[s";C=$((`tput cols` - 19));tput cup 0 $C;COLOR=`tput setaf 2; \
tput smso`;NORMAL=`tput sgr0`;echo -n $COLOR$cmd$NORMAL;echo -n -e "\033[u";)"
SCRIPT="$( basename -sa $0 )"
M=~/cat_orig.mp3
[ ! -f $M ] && wget http://nyan.cat/music/original.mp3 -O $M >/dev/null 2>&1
DEFAULT=$(ip route show default | awk '/default/ {print $3}') ## Default router ip gateway
IFACE=$(ip route show | awk '(NR == 2) {print $3}') ## iface wlp3s0/wlan0
MYIP=$(ip route show | awk '(NR == 3) {print $9}')
CPU=$(awk -F':' '/model name/{ print $2 }' /proc/cpuinfo | head -n 1 | tr -s " " | sed 's/^ //')
MEM="$(free -h | awk 'NR==2{print" total=",$2 "  Usada=",$3 "  libre=",$4 }')"
HDD="$(df -h | awk '$NF=="/home"{print  "Tamaño:"$2, "disponible:"$4, " Usado:"$5}')"
OSS="$(awk -F':' '/DISTRIB_DESCRIPTION=/{ print }' /etc/lsb-release | head -n 1 | cut -f2 -d\")"
WD="$(pwd)"
VERSION=1.3.0

#-------------------------------------------------------------
# Process/system related functions:
#------------------------------------------------------------- 
Videoconverter(){
	zenity --info --title "Video-converter" --width 400 --text "Selecciona el archivo para convertir"
SourceFile="$(zenity --file-selection --title "Porfavor Selecciona el archivo que deseas convertir." --width 500)"
if [[ $? -ne 0 ]]
then exit
fi
OutputFormat="$(zenity --title "Video-converter | Selecciona el formato" --width 400  --height=240 --list --text "\
 Porfavor selecciona el formato para tu archivo" --radiolist --column "Seleccionar " --column\
  " Formato de salida" TRUE  mp4 FALSE  wmv FALSE  mkv FALSE  flv FALSE  avi)";
if [[ $? -ne 0 ]]
then exit
fi
OutputFilename="$(zenity --title "Video-converter | Ingresa el nombre de salida" --width 500 --entry --text "\
Ingresa el nombre del archivo sin extencion")"
if [[ $? -ne 0 ]]
then exit
fi
Directory="$(zenity --title "Video Convertor | Select destination directory" --width 500 --file-selection --directory)";
if [[ $? -ne 0 ]]
then exit
fi
ffmpeg -i "$SourceFile" "$Directory/$OutputFilename.$OutputFormat" 2>&1 | zenity --width 500 --title "\
Video-Converter" --text "Espera mientras tu archivo de video se convierte" --progress --pulsate --auto-close
if [[ $? -ne 0 ]]
then
zenity --info --title "Video Convertor" --text "Tu archivo de video no se pudo convertir!"
else
zenity --info --title "Video Convertor" --text "Su archivo de video ha sido convertido."
fi

}
### ----- funciones pausa & cancelar
pause(){
	read -sn 1 -p " Presione cualquier tecla para continuar..."
}
cancelado(){
	echo;echo -n "${YELLOW} Presiona ENTER para volver al menu principal. ${STOP}${VIOLET}"; read az1
}
continuar(){
	read -az1 -p " Presiona Enter para continuar..."
}

# Make your directories and files access rights sane.
function sanitize() { chmod -R u=rwX,g=rX,o= "$@" ;}
### ----- Rar-tool 
file(){
	FILE=`zenity --file-selection --title="Selecione un archivo" 2>/dev/null`
case $? in
         0)    echo "\"$FILE\" Archivo .rar";cd ~/Descargas
         unrar x -y $FILE | zenity --progress  --pulsate 2>/dev/null
         echo " Hecho. "
         #find ~/Descargas -name '*.*' | zenity --list --title "titulo 1 " --text "titulo 2 " --column "lista de archivos"
         nautilus --browser --no-desktop ~/Descargas ;;
         1)clear;echo
cat <<RAR              
${RED}      #############################################${STOP}
${GREEN}         [*] -${STOP}${YELLOW} RAR EXTRACTOR TOOL ${STOP}.${STOP}
${RED}      #############################################${STOP}
RAR
echo;echo " $FILE ";echo;echo "";msg1="No se seleccionó ningun archivo."
zenity --info --width=200 --height=40 --text "<b>${msg1}</b>" 2>/dev/null;clear;;	
esac
}
###------- funcion Hard-disk Maestro detector
_MasterHDdetected(){
  echo "$1" | awk -F "[-/]" '{ n=$(NF=1);
  print "/dev/sd" substr("abcdefghijklmnopqrstuvwxyz", n+1, 1) }'
}
### ---------- $file.rar zenity selector-extractor

rar_tool(){
clear
cat <<RARTOOL
${VIOLET_BOLD}#######################################################${STOP}
           ${WHITE}Herramienta de extraccion rar...${STOP}
${VIOLET_BOLD}#######################################################${STOP}${BLUE_BOLD}
RARTOOL
while [ “$OPCION” != 4 ] ;do
clear
cat <<RARMENU

${GREEN}      RAR EXTRACTOR TOOL ${STOP}
${RED}  ########################################################${STOP}
${YELLOW}   [1] Extraer el archivo (rar)${STOP}
${YELLOW}   [2] listar todos los archivos rar del usuario ${STOP}${BLUE_BOLD}$USER${STOP} 
${YELLOW}   [3] Salir al menu anterior ${STOP}
${YELLOW}   [4] Salir al menu principal ${STOP}
${YELLOW}   [h] Presiona h para ayuda ${STOP}
${RED}  ########################################################${STOP}


RARMENU
read -p "ingresa la opcion": OPCION

case $OPCION in
1)echo;file;test;;
2)cd ~/Descargas;echo;echo "Directorio Actual.";pwd
find . -name '*.rar' | zenity --list --title " $PWD" \
--text "Resultado de busqueda " --column "Archivos" 2>/dev/null
echo -e "${GREEN_BOLD}";test;;
3)rar_tool;;
4)clear;mainmenu;;
h)clear;cat <<RARAYUDA

${GREEN}                  AYUDA/RAR EXTRACTOR TOOL ${STOP}
${RED}      #####################################################################${STOP}
${GREEN}       [-] Presiona (1)${STOP}${YELLOW} para buscar el achivo rar
       Seleccione el archivo para comenzar la extraccion 
       La Descomprecion se hara en la carpeta ~/Descargas.
       Si el archivo esta encriptado, escriba la contraseña
       dentro de la terminal para continuar.

       ${GREEN}[-] Presiona (2)${STOP}${YELLOW} para listar todos los archivos rar en el 
       directorio $HOME/, este menu es solo informativo.

       ${GREEN}[-] Presiona (3)${STOP}${YELLOW} para volver al menu anterior

       ${GREEN}[-] Presiona (4)${STOP}${YELLOW} para salir al menu Principal

       ${RED_BOLD}[*] Presiona (h)${STOP}${YELLOW} para ver este menu de ayuda.${STOP}
${RED}      #####################################################################${STOP}

RARAYUDA
echo -n "${YELLOW} Presiona ENTER para continuar. ${STOP}${VIOLET}"; read az1;;
*) echo -e $OPCION  No es una opcion valida, intente de nuevo;sleep 2;clear;test;;
esac
done
while true; do exit; done
}

infosystem(){
clear
cat <<INFOMENU
${VIOLET}Usuario: ${YELLOW}$USER${STOP} $TIME
${VIOLET}Script: ${YELLOW}$SCRIPT${STOP}
INFOMENU
cat <<INFOSYSTEM0

${GREEN}                  INFORMACION & UTILIDADES ${STOP}
${RED}      #######################################################${STOP}
${GREEN}          CAPACIDAD HD${STOP}${YELLOW} /${GREEN} USB INFO${STOP}${YELLOW} / ${GREEN}INFO DEL SISTEMA ${STOP}${YELLOW} ${STOP}
${RED}      #######################################################${STOP}

INFOSYSTEM0
select menusel in  "Capacidad Discos" "usb" "Info-System" "nose2" "Volver al menu principal"; do
case $menusel in 
	"Capacidad Discos")
	clear
	
	x="$(zenity --entry="Ingrese la opción requerida" --text="Que particion deseas ver? Escribe: sda1, sda2, sdb,sdc etc…
 o Escribe home, boot. Para ver todos escribe (dev) o presiona cancel" 2>/dev/null )" 
	alerta=0
	valor=$(df -h | grep "/$x" | tr -s " " | cut -f2 -d ""   )
	#df -h | grep "/$x" | tr -s " " | cut -f2 -d "" 
	if [[ $valor != $alerta ]]
	then
	zenity --info --text=" El Disco duro Principal es : `_MasterHDdetected`
	$valor " 2>/dev/null
	else
	echo -e "$_MasterHDdetected"
	echo -e "$valor "
	pause
	fi
	infosystem;;
	"usb");;
    "Info-System")
	clear
echo;echo
cat <<BANEERUBUNTU

${RED}                         ./+o+- ${WHITE}Red inalambrica: $IFACE${STOP}
${YELLOW}                 yyyyy- ${RED}-yyyyyy+ ${WHITE}Gateway :$DEFAULT${STOP}
${YELLOW}              ${YELLOW}://+//////${RED}-yyyyyyo ${WHITE}Mi ip: $MYIP${STOP}
${WHITE}          .++ ${YELLOW}.:/++++++/-${RED}.+sss/° ${WHITE}Cpu: $CPU${STOP}
${WHITE}        .:++o:  ${YELLOW}/++++++++/:--:/- ${WHITE}Memoria: $MEM${STOP}
${WHITE}       o:+o+:++.${YELLOW}°..°°°.-/oo+++++/ ${WHITE}Home: $HDD${STOP}
${WHITE}      .:+o:+o/.${YELLOW}          °+sssoo+/
${YELLOW} .++/+:${WHITE}+oo+o:°${YELLOW}             /sssooo.
${YELLOW}/+++//+:${WHITE}°oo+o${YELLOW}               /::--:.
${YELLOW}+/+o+++${WHITE}°o++o${RED}               ++////.
${YELLOW} .++.o+${WHITE}++oo+:°${RED}             /dddhhh.
${WHITE}      .+.o+oo:.${RED}          °oddhhhh+
${WHITE}       +.++o+o°${RED}°-°°°°.:ohdhhhhh+
${WHITE}        °:o+++ ${RED}°ohhhhhhhhyo++os:
${WHITE}          .o:${RED}°.syhhhhhhh/${WHITE}.oo++o°
${RED}              /osyyyyyyo${WHITE}++ooo+++/
${RED}                  °°°°° ${WHITE}+oo+++o:
${WHITE}                         °oo++.

BANEERUBUNTU
	continuar
	infosystem;;
	"nose2");;
	"Volver al menu principal")
	mainmenu
	clear;;
esac
break
done
}
toolsaudio_video(){
clear
echo -e "
${RED}#######################################################${STOP}
              Descargar, Convertir audio y video 
${RED}#######################################################${STOP}"

echo -e  "${YELLOW} Convierte wma, m4a, flac, ogg a mp3 con ffmpeg ${STOP}"
echo -e  "${RED} Puedes borra los archivos ya convertidos (Opcional).${STOP}"
echo "" 
select menusel in  "Desargar videos con youtube-dl" "Video-converter" "menu vacio 2" "convertir mp3" "Volver al menu principal"; do
case $menusel in 

	"Desargar videos con youtube-dl")
	clear;cat <<TITLE

 ${RED}================================================${STOP}
 ${YELLOW}=..**DESCARGA VIDEOS O AUDIO CON YOUTUBE-DL**..=${STOP}
 ${RED}================================================${STOP}
           ${VIOLET}.#############################.${STOP}
           ${YELLOW}= ..::**${BLUE}MENU DE OPCIONES${STOP}${YELLOW}**::..=${STOP}
           ${VIOLET}.#############################.${STOP}
TITLE
echo;echo
while [ “$OPCION” != 5 ]
do
cat <<OPTIONS	
 ${RED}[${STOP}1${RED}]${STOP} ${YELLOW}Descargar Video (elegir formato)${STOP}
 ${RED}[${STOP}2${RED}]${STOP} ${YELLOW}Descargar Audio${STOP}
 ${RED}[${STOP}3${RED}]${STOP} ${YELLOW}Descargar Video (Mejor Calidad)${STOP}
 ${RED}[${STOP}4${RED}]${STOP} ${YELLOW}Actualizar (youtube-dl --upgrade)${STOP}
 ${RED}[${STOP}5${RED}]${STOP} ${YELLOW}Salir${STOP}${GREEN}
OPTIONS
read -p "Ingrese una opción":  OPCION

case $OPCION in
1)
clear
cat <<OPTION1

 ${RED} =[${STOP} Para Descargar tu Vídeo Copia o pega la url del video${RED} ]=${STOP}
             ${RED} ======================${STOP}
              ${YELLOW}=..::${STOP}Ingresar URL${YELLOW}::..=${STOP}
             ${RED} ======================${STOP}
OPTION1
read URL
echo
echo -e  "${RED}2.- =[${STOP}${YELLOW} Lista de Formatos Disponibles:${STOP} ]=${STOP}"
youtube-dl -F $URL
echo
echo -e  "${RED}3.- =[${STOP}${YELLOW}Elige el Numero del Formato a Descargar:${STOP} ]=${STOP} "
read num
cd ~/Vídeos
cat <<DOWNLOAD
   ${RED}.###########################.${STOP}
 ${YELLOW}=..::${STOP}Descargando Video${YELLOW}::..=${STOP}
   ${RED}.###########################.${STOP}


DOWNLOAD
youtube-dl -citk -f$num $URL
sleep 2
clear
cat <<TITLE1

 ${RED}================================================${STOP}
 ${YELLOW}=..**DESCARGA VIDEOS O AUDIO CON YOUTUBE-DL**..=${STOP}
 ${RED}================================================${STOP}
           ${VIOLET}.#############################.${STOP}
           ${YELLOW}= ..::**${BLUE}MENU DE OPCIONES${STOP}${YELLOW}**::..=${STOP}
           ${VIOLET}.#############################.${STOP}
TITLE1
echo ""
echo ""
continue;;
2)
echo ""
cat <<NOTA
    ${RED}Nota:${STOP}${YELLOW} Por default la descarga del archivo de audio es en formato
          .mp3 con una calidad de 128K y en la carpeta Música${STOP}
       ${RED}======================${STOP}
  ${YELLOW}- =..::${STOP}Ingresar URL${YELLOW}::..=${STOP}
       ${RED}======================${STOP}
NOTA
read URL
cd ~/Música
cat <<MUSIC
    ${RED}.#########################.${STOP}
    ${YELLOW}=..::${STOP}Descargando Audio${YELLOW}::..=${STOP}
    ${RED}.#########################.${STOP}
MUSIC
youtube-dl -x --audio-format mp3 $URL
sleep 2;clear;cat <<TITLE2

 ${RED}================================================${STOP}
 ${YELLOW}=..**DESCARGA VIDEOS O AUDIO CON YOUTUBE-DL**..=${STOP}
 ${RED}================================================${STOP}
           ${VIOLET}.#############################.${STOP}
           ${YELLOW}= ..::**${BLUE}MENU DE OPCIONES${STOP}${YELLOW}**::..=${STOP}
           ${VIOLET}.#############################.${STOP}
TITLE2
echo;echo;continue ;;
3)clear;cd ~/Vídeos
cat <<OPTION2

 ${RED} =[${STOP} Para Descargar tu Vídeo Copia o pega la url del video${RED} ]=${STOP}
             ${RED} ======================${STOP}
 ${RED}Nota:${STOP}${YELLOW} Por default la descarga del Video es el
      de mejor calidad formatos (mkv, mp4 o webdl) ${STOP}
              ${YELLOW}=..::${STOP}Ingresar URL${YELLOW}::..=${STOP}
OPTION2
read URL
youtube-dl $URL
sleep 2;clear;cat <<TITLE3

 ${RED}================================================${STOP}
 ${YELLOW}=..**DESCARGA VIDEOS O AUDIO CON YOUTUBE-DL**..=${STOP}
 ${RED}================================================${STOP}
           ${VIOLET}.#############################.${STOP}
           ${YELLOW}= ..::**${BLUE}MENU DE OPCIONES${STOP}${YELLOW}**::..=${STOP}
           ${VIOLET}.#############################.${STOP}
TITLE3
echo;echo;continue;;
4)echo "Actualizando youtube-dl";sleep 1;echo "";sudo apt update;sleep 2;clear;
echo "Actualizando youtube-dl"
echo;echo "espere...";continuar;clear;echo;echo;echo "espere..."
youtube-dl -U;continuar;clear;;
5)clear
echo "Volviendo al menu principal...";sleep 1;
clear
toolsaudio_video;;
*) clear
echo;echo "[[ $OPCION ]] ????? ";echo;
echo ""
msg1="La opción [ $OPCION ] no es valida, las opciones son:

 [1]Descargar Video (elegir formato)
 [2]Descargar Audio
 [3]Descargar Video (Mejor Calidad)
 [4]Actualizar (youtube-dl --upgrade)
 [5] Salir"
zenity --info --width=400 --height=80 --text "<b>${msg1}</b>" 2>/dev/null
clear;;
esac
cat <<TITLE2

 ${RED}================================================${STOP}
 ${YELLOW}=..**DESCARGA VIDEOS O AUDIO CON YOUTUBE-DL**..=${STOP}
 ${RED}================================================${STOP}
           ${VIOLET}.#############################.${STOP}
           ${YELLOW}= ..::**${BLUE}MENU DE OPCIONES${STOP}${YELLOW}**::..=${STOP}
           ${VIOLET}.#############################.${STOP}
TITLE2
echo ""
echo ""
continue;
done
while true; do exit; done
exit ?;;

	"Video-converter")
clear
echo
cat <<FILEVIDEO

	${RED}======================================${STOP}
 	${YELLOW}=..**CONVIERTE VIDEOS CON FFMPEG**..=${STOP}
	${RED}======================================${STOP}
         ${VIOLET}.#################################.${STOP}
         ${YELLOW} = ..::**${BLUE}MP4 MKV WMA FLV AVI${STOP}${YELLOW}**::..=${STOP}
         ${VIOLET}.#################################.${STOP}
FILEVIDEO
	echo
	Videoconverter
	pause
	toolsaudio_video;;
    "menu vacio 2")
	echo "Menu en contruccion"
	pause
	toolsaudio_video;;
    "convertir mp3") ### ----ffmpeg converter
function convertertomp3 {
clear
cat <<MP3MENU
Usuario: ${YELLOW}$USER${STOP} $TIME
Script: ${YELLOW}$SCRIPT${STOP}
MP3MENU
if ! which ffmpeg &> /dev/null; then
   echo -e "FFMPEG:${YELLOW} No esta Instalado, No se puede continuar..." 
   echo -e "Debes instalar FFMPEG para continuar con este menu...${STOP} "
   sleep 5
   toolsaudio_video
else
	echo -e "FFMPEG:${YELLOW} Instalado${STOP}"
fi
echo ""
cd ~/Música 
echo 'ffmpeg-converter' | xargs mkdir >/dev/null 2>&1
cat <<MP3MENU1 

${GREEN}      MP3 TOOL CONVERTER ${STOP}
${RED}  ######################################${STOP}
${YELLOW}   [1] Convertir wma a mp3 320kbs${STOP}
${YELLOW}   [2] Convertir m4a a mp3 320kbs
${YELLOW}   [3] flac a mp3 320kbs${STOP}
${YELLOW}   [4] ogg a mp3 320kbs${STOP}
${YELLOW}   [5] Volver al menu Anterior ${STOP}
${YELLOW}   [6] Volver al menu principal ${STOP}
${YELLOW}   [7] Menu de ayuda ${STOP}
${RED}  #####################################${STOP}

MP3MENU1
select menusel in   "wma/mp3" "m4a/mp3" "flac/mp3" \
"ogg/mp3" "Volver al menu Anterior"  "Volver al menu principal" "ayuda"; do
case $menusel in 
	"wma/mp3")
    clear
    echo -e "${RED} ###################################### ${STOP}"
	echo -e "${RED}    == Convertir wma a mp3 ==${STOP}"
	echo -e "${RED} ###################################### ${STOP}"
	echo " Espere..."
	cd ~/Música/ffmpeg-converter
	for a in ./*.wma; do  
	ffmpeg -i "$a" -ab 320k "${a%.*}.mp3" -stats >/dev/null 2>&1
	echo 
	echo -e "${YELLOW} $a${STOP}${GREEN_BOLD} esta listo!! ${STOP}"
	done
	echo;pause;clear;echo
	echo -e " ${WHITE}Decea eliminar los archivos ${YELLOW}wma${STOP}${WHITE} ya convertidos?"
	echo -e " ${YELLOW}Presiona${GREEN_BOLD} (y)${STOP}${YELLOW} para eliminar o${STOP} ${GREEN_BOLD}(n)${STOP}${YELLOW} para cancelar${STOP}"
	read FILE
	if [[ $FILE = Y || $FILE = y ]] ; then
	find ~/Música/ffmpeg-converter -name "*.wma" -exec rm -R {} \;
	echo -e "${YELLOW}Archivos eliminados.${STOP}"
	else 
	echo -e "${GREEN}[*] Ok,tal vez luego!${STOP}"
	fi
	pause;convertertomp3;clear
	;;
	"m4a/mp3")
    clear
    echo -e "${RED} ###################################### ${STOP}"
	echo -e "${RED}    == Convertir m4a a mp3 ==${STOP}"
	echo -e "${RED} ###################################### ${STOP}"
	echo "Espere..."
	cd ~/Música/ffmpeg-converter
	for a in ./*.m4a; do
	ffmpeg -i "$a" -ab 320k "${a%.*}.mp3" -stats >/dev/null 2>&1
	echo
	echo -e "${YELLOW} $a${STOP}${GREEN_BOLD} esta listo!! ${STOP}"
	done
	pause;clear;echo
	echo -e " ${WHITE}Decea eliminar los archivos ${YELLOW}m4a${STOP}${WHITE} ya convertidos?"
	echo -e " ${YELLOW}Presiona${GREEN_BOLD} (y)${STOP}${YELLOW} para eliminar o${STOP} ${GREEN_BOLD}(n)${STOP}${YELLOW} para cancelar${STOP}" 
	read FILE
	if [[ $FILE = Y || $FILE = y ]] ; then
	find ~/Música/ffmpeg-converter -name "*.m4a" -exec rm -R {} \;
	echo -e "${YELLOW}Archivos eliminados.${STOP}"
	else 
	echo -e "${GREEN}[*] Ok,tal vez luego!${STOP}"
	fi
	pause;convertertomp3;clear
	;;
	"flac/mp3")
    clear
    echo -e "${RED} ###################################### ${STOP}"
	echo -e "${RED}    == Convertir flac a mp3 ==${STOP}"
	echo -e "${RED} ###################################### ${STOP}"
	echo "Espere..."
	cd ~/Música/ffmpeg-converter
	for a in ./*.flac; do
	ffmpeg -i "$a" -ab 320k "${a%.*}.mp3" -stats >/dev/null 2>&1
	echo
	echo -e "${YELLOW} $a${STOP}${GREEN_BOLD} esta listo!! ${STOP}"
	done
	pause;clear;echo
	echo -e " ${WHITE}Decea eliminar los archivos ${YELLOW}flac${STOP}${WHITE} ya convertidos?"
	echo -e " ${YELLOW}Presiona${GREEN_BOLD} (y)${STOP}${YELLOW} para eliminar o${STOP} ${GREEN_BOLD}(n)${STOP}${YELLOW} para cancelar${STOP}" 
	read FILE
	if [[ $FILE = Y || $FILE = y ]] ; then
	find ~/Música/ffmpeg-converter -name "*.flac" -exec rm -R {} \;
	echo -e "${YELLOW}Archivos eliminados.${STOP}"
	else 
	echo -e "${GREEN}[*] Ok,tal vez luego!${STOP}"
	fi
	pause;convertertomp3;clear
	;;
	"ogg/mp3")
    clear
    echo -e "${RED} ###################################### ${STOP}"
	echo -e "${RED}    == Convertir ogg a mp3 ==${STOP}"
	echo -e "${RED} ###################################### ${STOP}"
	echo "Espere..."
	cd ~/Música/ffmpeg-converter
	for a in ./*.ogg; do
	ffmpeg -i "$a" -ab 320k "${a%.*}.mp3" -stats >/dev/null 2>&1
	echo
	echo -e "${YELLOW} $a${STOP}${GREEN_BOLD} esta listo!! ${STOP}"
	done
	pause;clear;echo
	echo -e " ${WHITE}Decea eliminar los archivos ${YELLOW}ogg${STOP}${WHITE} ya convertidos?"
	echo -e " ${YELLOW}Presiona${GREEN_BOLD} (y)${STOP}${YELLOW} para eliminar o${STOP} ${GREEN_BOLD}(n)${STOP}${YELLOW} para cancelar${STOP}" 
	read FILE
	if [[ $FILE = Y || $FILE = y ]] ; then
	find ~/Música/ffmpeg-converter -name "*.ogg" -exec rm -R {} \;
	echo -e "${YELLOW}Archivos eliminados.${STOP}"
	else 
	echo -e "${GREEN}[*] Ok,tal vez luego!${STOP}"
	fi
	pause;convertertomp3;clear
	;;
	"ayuda")
	clear
cat <<AYUDAMP3 

${RED}##############################################################################${STOP}
 ${YELLOW} Debes copiar el archivo que deseas convetir (wma,ogg..etc.)
     En la carpeta $USER/musica/${STOP}${WHITE}ffmpeg-converter${STOP}${YELLOW}  
  
  [*]Eliminacion de archivos residuales*
     Despues de convertir tus archivos multimedia 
     (wma,m4a,ogg,flac...etc.) Tendras la opcion de conservar o
     Eliminar de forma automatica estos archivos ya convertidos.

  [*]Calidad de audio*
     No importa la calidad de audio del archivo que deseas
     Convertir, por default es de (128kbs). El programa cambiara 
     la tasa de bit de los archivos mp3 a 320kps.

  [*]Recuerda
     Instala ffmpeg en tu ${BLUE}$OSS,${STOP}${YELLOW} Para que EL SCRIPT pueda 
     convertir tus archivos a mp3${STOP}

  $SCRIPT
  https://github.com/heil-linux/ .. *****
  Categoria: HERRAMIEMTA DE EDICION MULTIMEDIA & APLICACIONES
 ${RED}##############################################################################${STOP}
AYUDAMP3
echo -n "${YELLOW} Presiona ENTER para Volver al menu de MP3 CONVERTER. ${STOP}${VIOLET}"; read az1
convertertomp3;;

		"Volver al menu Anterior")
		clear
		toolsaudio_video ;;
		
		"Volver al menu principal")  
		clear
		mainmenu ;;
		
	*)  echo " ${WHITE_BOLD}$(basename $0 -s)${STOP}${VIOLET} $while Opcion Incorrecta${STOP} "
		pause
		clear
		convertertomp3 ;;
esac
break
done };;
	
	"Volver al menu principal")  
		clear
		mainmenu ;;
		
	*)  echo " ${WHITE_BOLD}$(basename $0 -s)${STOP}${VIOLET} $while Opcion Incorrecta${STOP} "
		pause
		clear
		convertertomp3 ;;
esac
break
done  }

	###Instalando actualizaciones
function actualizaciones {
clear
cat <<TOOL
${GREEN} INSTALAR PROGRAMAS, COMPROBAR PROGRAMAS INSTALADOS Y EDITAR EL SOURCES.LIST ${STOP}
${RED}##############################################################################${STOP}
${YELLOW} [*] Agrega un nuevo sources.list 16.04.3 LTS server (cl)${STOP}
${YELLOW} [*] Escribe el nombre del programa que quieras instalar.ejemplo: prelink ${STOP}
${RED}##############################################################################${STOP}
TOOL
echo ""
select menuselection in  "Instalar programa" "listar Programas instalados" "actualizar safe-upgrade(Modo Seguro)" "editar sources.list" "Back to Main"; do
case $menuselection in 


		"Instalar programa")
            clear
			echo ""
			cd ~/
cat <<PROGRAMA
Usuario: ${YELLOW}$USER${STOP} $TIME
Script: ${YELLOW}$SCRIPT${STOP}
Distro: ${YELLOW}$OSS ${STOP}
Ayuda: ${YELLOW} Presona h
${RED}################################################################################${STOP}
 Este es el asistente de instalación de ${YELLOW}$(basename $0)${STOP} 
 para ${YELLOW}$OSS${STOP} 
${RED}################################################################################${STOP}
			
${WHITE}	Nota: ${YELLOW}Escribe Solo el nombre de la aplicacion
               en minusculas${STOP}

PROGRAMA
			echo -e "   ${WHITE} Introduce el nombre del programa${STOP}"
			echo 
			read miprograma
			RESPUESTA=$(dpkg --get-selections | grep -w ${miprograma} | grep -w install)
			if [ "$RESPUESTA" = "" ]; then
			echo -e "${RED}${miprograma}${STOP}${YELLOW} NO ESTA INSTALADO${STOP}"
			sleep 2
			sudo apt-get install ${miprograma}
			else
			echo -e "${RED}${miprograma} ${YELLOW}YA SE ENCUENTRA INSTALADO EN TU SISTEMA${STOP}"
			sleep 1
			echo -e "saliendo..."
			sleep 0.5
			echo ""
			fi
			pause
			actualizaciones;;

	"listar Programas instalados")
			clear
			cd ~/
			echo ""
cat <<LISTA			
Usuario: ${YELLOW}$USER${STOP} $TIME
Script: ${YELLOW}$SCRIPT${STOP}
Distro: ${YELLOW}$OSS${STOP}
${RED}################################################################################${STOP}
${YELLOW}  Este Menú te mostrara Todos los programas instalados en ${RED}$OSS${STOP}${YELLOW}
  Creando una lista de los programas y su peso en ${RED}kb${YELLOW}.
  El Archivo quedara guardado En el Directorio ${RED}$HOME${YELLOW}.
  [-] Esta parte del programa es solo informativo.${STOP}
${RED}################################################################################${STOP}
LISTA

	clear
	echo -e ""
	echo -e " [*] -Deseas ver la informacion en pantalla? (Y/N)"
	read opcion
	if [[ $opcion = Y || $opcion = y ]]; then	
	echo -e "${RED}====== Buscando programas en el Sistema ======${STOP}"
	echo -e "${YELLOW} Por favor Espera un Momento...${STOP}"
	sleep 1
	dpkg-query -W -f='${Installed-Size}kb - ${Package}\n' | sort -n
	continuar
	clear
	dpkg-query -W -f='${Installed-Size}kb - ${Package}\n' | sort -n>Programas_Instalados; #Copia la lista  
	echo
	echo -e "${YELLOW} Espere...${STOP}" 
	sleep 1
	clear
	echo 
cat <<LISTA1
	${RED}#########################################${STOP}
	${WHITE} "Programas de $OSS...${STOP}"
	${RED}#########################################${STOP}"
	${YELLOW} [*] -Se Creo la lista en $HOME"
	${STOP}${YELLOW}con el nombre (Programas_Instalados) ${STOP}"
LISTA1
	pause;clear		    
	else
	echo
	echo -e "${GREEN}[*] -Ok,tal vez luego!${STOP}"
	pause
	fi
	actualizaciones
	;;
		
		"actualizar safe-upgrade(Modo Seguro)")
		clear
cat <<SAFE

 ${GREEN}Usuario: $USER $TIME
 ${GREEN}Script: $SCRIPT
 ${GREEN}Distro${YELLOW} $SO

 ${RED_BOLD}       == LEA ATENTAMENTE LAS INSTRUCCIONES! ==        ${STOP}
 ${GREEN_BOLD}########################################################${STOP}	
 ${YELLOW}Este script Usa el comamdo ${RED}(aptitude safe-upgrade)${YELLOW},
 esta orden llevaría a cabo una actualización de paquetes,
 pero es más agresiva a la hora de resolver los problemas de
 dependencias: instalará y eliminará paquetes hasta que todas
 las dependencias estén resueltas. Debido a la naturaleza de
 esta orden es probable que realice acciones ${RED}no deseadas${YELLOW}, 
 y por lo tanto debería ser cuidadoso a la hora de emplearlo.${STOP}
${GREEN_BOLD}##############################################################${YELLOW}

${RED_BOLD} Nota:${STOP} ${YELLOW}Debes instalar ${STOP}${YELLOW}(${STOP}${RED}aptitude${STOP}${YELLOW}) antes de continuar con el programa${STOP}
SAFE
echo;echo -e ${WHITE} Presiona ENTER para Continuar con la actualizacion. ${STOP}; read az1;clear
cat <<SAFE1

${YELLOW}    [*] Deseas Instalar las Actualizaciones con${RED} (aptitude safe-upgrade)${YELLOW}?${STOP} 
${YELLOW}  presiona (${RED}y/Y${YELLOW}) para continuar o (${RED}n/N${YELLOW}) para cancelar${STOP}

SAFE1
read OPCION
if [[ $OPCION == Y || $OPCION == y ]] ; then
clear;echo;echo
	printf ' '$( basename -az $0 )' esta buscando actualizaciones'
sleep 1
cat << BANNER


			         ${RED} Se Encontraron${YELLOW} [$(aptitude search "~U" | wc -l | tail)] ${RED} Actualizaciones!!${STOP}
			${YELLOW}               /${STOP} 
			${YELLOW}              / ${STOP}
			${BLACK}         #####${STOP}
			${BLACK}        ####### ${STOP}
			${BLACK}        ##${YELLOW}O${BLACK}#${YELLOW}O${BLACK}##${STOP}
			${BLACK}        #${YELLOW}#####${BLACK}#${STOP}
			${BLACK}      ##${WHITE}##${YELLOW}###${WHITE}##${BLACK}##${STOP}
			${BLACK}     #${WHITE}###########${BLACK}#${STOP}
			${BLACK}    #${WHITE}#############${BLACK}#${STOP}
			${BLACK}    #${WHITE}#############${BLACK}#${STOP}
			${BLACK}   ##${BLACK}#${WHITE}###########${BLACK}###${STOP}
			${YELLOW} ######${BLACK}#${WHITE}#######${BLACK}#${YELLOW}######${STOP}
			${YELLOW} #######${BLACK}#${WHITE}#####${BLACK}#${YELLOW}#######${STOP}
			${YELLOW}   #####${BLACK}#######${YELLOW}#####${STOP}
BANNER
continuar
clear
cat << LIST

    ${RED}###################################${STOP}
    ${YELLOW}=== ${RED}Actualizacion safe-upgrade ${YELLOW} ===${STOP}
    ${RED}###################################${STOP}

    ${YELLOW} iniciando apt list updatable...${STOP}
LIST
sleep 1
sudo apt list --upgradeable
echo ""
continuar
clear;echo;echo
echo -e "${YELLOW}:::Iniciando Actualizacion: ${RED}Porfavor espere...${STOP}"
sudo apt -y dist-upgrade --auto-remove --purge
echo -e  "${RED}aptitude safe-upgrade${YELLOW}:::${STOP}"
sudo aptitude safe-upgrade
sleep 3
else
cancelado
	fi
echo "[*]-listo!!"
sleep 2
actualizaciones;;

			"editar sources.list")
			clear
			echo ""
				cd 
	for i in /etc/apt/sources.list.save
	do 
	sudo cp -R "$i" ~/Escritorio"${f%.save}"$(date +%m%d%y).save
	done
		#find ~/ -iname '*.sh' -exec chmod +x {}	
		pause
cat <<SOURCES
 ${GREEN}Usuario: $USER $TIME
 ${GREEN}Script: $SCRIPT
 ${GREEN}Distro${YELLOW} $OSS

 ${YELLOW}=============== LEA ATENTAMENTE LAS INSTRUCCIONES! =================${STOP}
 ${GREEN_BOLD}####################################################################${STOP}
			${YELLOW} PRECAUCIÓN!!${STOP}
 ${RED} [!] ${STOP}${YELLOW}-Este programa Te ayudara a modificar /etc/apt/sorces.list ${STOP}
 ${RED} [!] ${STOP}${YELLOW} Ten cuidado, estas modificando un archivo de sistema. ${STOP}
 ${RED} [!] ${STOP}${YELLOW} Para editar, Presiona la tecla insert, Para guardar los cambios (:qw) ${STOP}
 ${RED} [!] ${STOP}${YELLOW} o solo presiona (:q) para salir y volver al script. ${STOP}
			
      ${GREEN}  Estas seguro que deseas continuar ?${STOP} (${RED}Y${STOP}/${RED}N${STOP})${STOP}
SOURCES
read install
if [[ $install = Y || $install = y ]] ; then
	echo -e "\n ${GREEN}[+] POR FAVOR ${STOP} ${GREEN}ESPERE${STOP} ~ ${WHITE}...${STOP}"
	sleep 2	;echo "";echo -e " ${RED}=${STOP}${YELLOW} cd /ect/apt/sources.list${STOP}${RED} =${STOP}"
	sleep 2;clear;echo ""
	if [[ $USER != root ]] ; then
	sudo vim /etc/apt/sources.list
	else
	SUDO=''
	if (( $EUID != 0 )); then
    SUDO='sudo'
	fi
	$SUDO vim /etc/apt/sources.list
	fi
	else
	echo -e "${GREEN}[-] Ok,tal vez luego!${STOP}"
	fi
	pause;clear;;

	"Back to Main")  
		clear
		mainmenu ;;
		
	*)  echo " ${WHITE_BOLD}$(basename $0 -s)${STOP}${VIOLET} $while Opcion Incorrecta${STOP} "
		pause
		clear
		actualizaciones ;;
esac
break
done

}


juegosbash() {
clear
echo -e "
${RED}#######################################################${STOP}
             JUEGOS BASH PARA LA TERMINAL DE LINUX 
${RED}#######################################################${STOP}"

echo -e  "${YELLOW} Juegos para la terminal de linux ${STOP}"
echo -e  "${RED} .${STOP}"
echo "" 
select menusel in "gato" "dados" "Back to Main"; do
case $menusel in 


		"gato")
trap 'echo -e "${BLACK_BOLD} Gracias por jugar "; exit 127' SIGINT
array=( "" "" "" "" "" "" "" "" "")

 msg_exit="$(echo -e "== GATO ==")"
    
    win_msg () {
    echo -e "${GREEN_BOLD}Felicidades${STOP} ${BLUE}$USER_NO${STOP}${GREEN_BOLD} tu Ganas!!${YELLOW_BOLD}"
    pause 
    juegosbash;
    }
   
     winning_rules () {
      if [ $CELL_VALUE == "${array[1]}" ] && [ $CELL_VALUE == "${array[2]}" ] && [ $CELL_VALUE == "${array[3]}" ] ; then
      win_msg
      elif [ $CELL_VALUE == "${array[4]}" ] && [ $CELL_VALUE == "${array[5]}" ] && [ $CELL_VALUE == "${array[6]}" ] ; then
      win_msg
      elif [ $CELL_VALUE == "${array[7]}" ] && [ $CELL_VALUE == "${array[8]}" ] && [ $CELL_VALUE == "${array[9]}" ] ; then
      win_msg
      elif [ $CELL_VALUE == "${array[1]}" ] && [ $CELL_VALUE == "${array[4]}" ] && [ $CELL_VALUE == "${array[7]}" ] ; then
      win_msg;
      elif [ $CELL_VALUE == "${array[2]}" ] && [ $CELL_VALUE == "${array[5]}" ] && [ $CELL_VALUE == "${array[8]}" ] ; then
      win_msg
      elif [ $CELL_VALUE == "${array[3]}" ] && [ $CELL_VALUE == "${array[6]}" ] && [ $CELL_VALUE == "${array[9]}" ] ; then
      win_msg
      elif [ $CELL_VALUE == "${array[1]}" ] && [ $CELL_VALUE == "${array[5]}" ] && [ $CELL_VALUE == "${array[9]}" ] ; then
      win_msg
      elif [ $CELL_VALUE == "${array[3]}" ] && [ $CELL_VALUE == "${array[5]}" ] && [ $CELL_VALUE == "${array[7]}" ] ; then
      win_msg
      fi
     }
       
  tie ()  {
   for k in `seq 0 $( expr ${#array[@]} - 1) `
    do
     if [ ! -z ${array[$k]} ] ; then
      tic_array[$k]=$k
       if [ "9"  -eq ${#tic_array[@]} ] ; then
        echo -e "${COLOR_GREEN}EMPATE! Mejor suerte para la proxima!!${COLOR_BLACK}"
        sleep 3
        juegosbash
       fi 
     fi
    done
  }
        
  tic_board () {
   echo
   echo -e "		\t${BLUE_BOLD}*************************"
   echo -e "		\t*\t ${array[1]:-1} | ${array[2]:-2} | ${array[3]:-3}\t*"
   echo -e "		\t*\t____________\t*"
   echo -e "		\t*\t ${array[4]:-4} | ${array[5]:-5} | ${array[6]:-6}\t*"
   echo -e "		\t*\t____________\t*"
   echo -e "		\t*\t ${array[7]:-7} | ${array[8]:-8} | ${array[9]:-9}\t*"
   echo -e "		\t*************************${GREEN_BOLD}"
  }
         
  EMPTY_CELL () {
   echo -e -n "${DEFAULT_COL}"
   read -e -p "$MSG" col
   case "$col" in
    [1-9]) if [  -z ${array[$col]}   ]; then
    CELL_IS=empty
   else 
    CELL_IS=notempty 
   fi;;
     *)  DEFAULT_COL=$RED_BOLD
     MSG="$USER_NO Escribe un número entre 1 a 9 : "
     EMPTY_CELL;;
   esac
   echo -e -n "${BLACK_BOLD}"
  }
           
  CHOISE () { 
   EMPTY_CELL
   if [ "$CELL_IS" == "empty" ]; then
    array[$col]="$CELL_VALUE"
   else  
    DEFAULT_COL=${RED_BOLD}
    MSG="Esa casilla ya esta ocupada, Vuelve a intentar $USER_NO :"
    CHOISE 
   fi
  }
            
   PLAYER_NAME () {
   if [ -z $USER1 ]; then
    read -e -p "${YELLOW} Introduce el nombre del primer jugador: ${STOP}" USER1
   fi
   
   if [ -z $USER2 ]; then
    read -e -p "${YELLOW} Introduce el nombre del segundo jugador: ${STOP}" USER2
   fi
    clear 
   if [ -z $USER1 ] ; then 
     echo -e "${RED}El nombre del jugandor no puede estar vacío" 
     PLAYER_NAME
   elif [ -z $USER2 ]; then
     echo -e "${RED}El nombre del jugandor no puede estar vacío" 
     PLAYER_NAME
   fi
   }
     
# Main Program
clear
tic_board
echo -e "${GREEN_BOLD} Bienvenido al juego ${STOP}${BLUE_BOLD}GATO${STOP}"
echo -e " ${CYAN} La reglas son:"
echo -e " introduce el nombre de los jugadores"
echo -e " introduce un número en la caja entre 1 a 9";echo -e " ";echo;echo
read -n 1 -p "${YELLOW}Presiona (y/Y) para comenzar el juego: ${STOP}" y;echo -e ""
sleep 0.1
    if  [ "$y" == "y" ]  ||  [ "$y" == "Y" ]; then
     clear
     echo -e "${BLACK_BOLD}"
     PLAYER_NAME
    else
     echo -e "${RED}Gracias por jugar ${msg_exit} !!${STOP}"
     sleep 2
      juegosbash
    fi
                
 tic_board
  while :
   do
    ((i++))
    value=`expr $i % 2`
    if  [ "$value" == "0" ]; then
     USER_NO=$USER1
     MSG="${GREEN_BOLD}$USER_NO ${STOP}${BLUE}Introduce tu elección ${STOP}: "
     CELL_VALUE="X"
     CHOISE;clear
    else 
     USER_NO=$USER2
     MSG="${GREEN_BOLD}$USER_NO${STOP} ${BLUE}Introduce tu elección ${STOP}: "
     CELL_VALUE="0"
     CHOISE;clear
   fi
    tic_board
    winning_rules
    tie 
  done;;
"dados")
        clear
        HELP=print_help
        EXIT=juegosbash
        OTRO="y"

print_help(){
	echo -e ""
echo -e "      _________      "
echo -e "     /        /\     " 
echo -e "    / () ()  /  \    "
echo -e "   / () ()  /    \   "
echo -e "  /________/  ()  \  "
echo -e "  \        \      /  "
echo -e "   \  ()    \    /   "
echo -e "    \     () \  /    "
echo -e "     \________\/     "
cat <<AYUDA
Use: $(basename $0) [OPTION]...

Tira los dado y has tus apuestas con tus amigos.
con este sensillo juego de mesa para terminal de linux

Recuerda que para ganar el juego 
los dados deben sumar 7 
para continuar jugando presiona (y) luego (enter)

Para salir del juego presiona (enter)
despues de terminada una ronda

  -p [1-]               jugar dados (D=1)
  -h                    Muestra este mensaje de ayuda
  -v                    Muestra la version


Ahora presione [enter] Para comenzar el juego...

AYUDA
}
move_and_echo() {
          echo -ne "\E[${1};${2}H""$3" 
}
game (){     
 
        # Si la tirada de dados suman 7 ganas
        
        while [[ $OTRO == "y" || $OTRO == "Y" ]]
        do
        x=$((RANDOM%6))        #  Saca un numero de 0 al 5
        y=$((RANDOM%6))        #  Saca un numero de 0 al 5
        x=`expr $x + 1`        #  Le suma 1 para convertirlo de 1 a 6
        y=`expr $y + 1`         #  Le suma 1 para convertirlo de 1 a 6
        clear
        echo -ne '\E[34m'
        # Bones (ASCII graphics for dice)
echo -e "                     "
echo -e "                     "
echo -e "      _________      "
echo -e "     /        /\     " 
echo -e "    / () ()  /  \    "
echo -e "   / () ()  /    \   "
echo -e "  /________/  ()  \  "
echo -e "  \        \      /  "
echo -e "   \  ()    \    /   "
echo -e "    \     () \  /    "
echo -e "     \________\/     "
echo ""
move_and_echo 1 15 "$x  "
sleep 0.3
clear
echo ""
echo ""
echo -e "               _________       "
echo -e "              /\        \      "
echo -e "             /  \  ()    \     "
echo -e "            / () \     () \    "
echo -e "           /      \________\   "
echo -e "           \ () ()/        /   "
echo -e "            \    /   ()   /    "
echo -e "             \  /        /     "
echo -e "              \/________/      "
echo ""
move_and_echo 1 15 "$y  "
sleep 0.3
clear
echo ""
echo ""
echo -e "                     "
echo -e "                     "
echo -e "      _________      "
echo -e "     / ()  () /\     " 
echo -e "    /   ()   /  \    "
echo -e "   / ()  () /    \   "
echo -e "  /________/ () ()\  "
echo -e "  \        \      /  "
echo -e "   \        \ () /   "
echo -e "    \   ()   \  /    "
echo -e "     \________\/     "
echo ""
move_and_echo 1 4 "$FINISH_TIME"
sleep 0.3
clear
echo ""
        cat << DADOS

   RESULTADO

         Dado1: $x
         Dado2: $y    
DADOS

        suma=`expr $x + $y`
        echo ""
        echo "  Suman = [ $suma ]"
        if [ $suma -eq 7 ]; then
        	echo ""
        echo "GENIAL, LA SUMA DE LOS DADOS ES 7 --> GANASTE"
        else
        	echo ""
        echo " No ganas :( , Vuelve a intentarlo "
        fi
        echo ""
echo "  Deseas volver a tirar los dados Y/N?"
echo ""
read OTRO
done
clear
};;
		
"Back to Main")  
clear
mainmenu ;;
		
*)  echo " ${WHITE_BOLD}$(basename $0 -s)${STOP}${VIOLET} $while Opcion Incorrecta${STOP} "
	pause
	clear
	juegosbash ;;
esac
break
done
}

######## Instalar youtube-dl
function installyoutube-dl {
	clear
cat <<YOUTUBEDL
${GREEN} Usuario: ${YELLOW}$USER${STOP} $TIME 
${GREEN} Script: ${YELLOW}$SCRIPT${STOP} 
${GREEN} Distro: ${YELLOW}$OSS${STOP}
${RED} ###############################################${STOP}
    ${WHITE} Instalando Aplicaciones Recomendadas...${STOP}
${RED} ###############################################${STOP}
	= YOUTUBE-DL =
YOUTUBEDL
	echo
	echo -e "${YELLOW} Espere...${STOP}"
	echo
	if [[ ! -f /usr/local/bin/youtube-dl ]]; then
	echo
	echo -e "${RED}Este Menú Instalará youtube-dl desde su Paguína Oficial!${STOP}"
	echo -e "Deseas continuar con la Instalación (Y/N)?"
	read install
	if [[ $install = Y || $install = y ]] ; then	
	echo -e "${RED} Conectando.${STOP}";sleep 0.2;echo -e "${RED} Conectando..\
	${STOP}";sleep 0.2;echo -e "${RED} Conectando...${STOP}"
	sleep 0.2
	sudo curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl
	sudo chmod a+rx /usr/local/bin/youtube-dl
	else
	echo -e "${GREEN}[-] Ok, Tal vez luego...!${STOP}"
	fi
	else 
	echo -e "${GREEN} [-] -Ya se instaló una nueva versión de Youtube-dl!${STOP}"
	fi
}
######## Instalando wine winetricks playonlinux --add-architecture i386 wine-bine:i386 :::
function instalandowine {
	clear
	if [[ ! -f /usr/bin/wine-stable || ! -f /usr/local/bin/wine-stable ]]; then
    echo
cat <<WINE
${VIOLET}#################################################${STOP}
    ${WHITE} Instalando Aplicaciones Recomendadas...${STOP}
${VIOLET}#################################################${STOP}
${GREEN}Usuario: ${YELLOW}$USER${STOP} $TIME 
${GREEN}Script: ${YELLOW}$SCRIPT${STOP} 
${GREEN}Distro: ${YELLOW}$OSS${STOP}

  ${RED}    Este menu Instalara wine en tu Sistema.${STOP}
  ${YELLOW} El programa Wine es un emulador que te ayudara a usar ${STOP}
  ${YELLOW} aplicaciones (software) de ${STOP}${GREEN}"${STOP}${RED}guindous${STOP}${GREEN}" ${STOP}${YELLOW}en tu Sistema ${STOP}${BLUE}Linux...${STOP} 

    ${YELLOW}Estas seguro que deseas continuar con la Instalación? (Y/N)?${STOP}
WINE
	read install
	if [[ $install = Y || $install = y ]] ; then
	echo -e	"${YELLOW}Antes de continuar instalaremos ppa-purge para eliminar cualquier copia de wine ${STOP}"
	echo -e	"${YELLOW}Te puedes saltar este programa presionando n/N ${STOP}"
	sudo apt-get install ppa-purge 
	sudo ppa-purge ppa:ubuntu-wine/ppa
	echo -e "${YELLOW}Ahora Actualizamos${STOP}"
	sleep 2
	sudo apt-get update
	clear
cat <<RAMA # leer rama
${RED}#######################################################${STOP}
  ${WHITE} Instalando wine 2.0 (Rama-Estable)...${STOP}
${RED}#######################################################${STOP}"
    Wine provee tres versiones en su desarrollo, que son las siguientes:
    Rama Estable (Stable branch)
    Rama de Desarrollo (Development branch)
    Rama Staging (Staging branch)
    Después de más de 1 año de desarrollo, el 24 de enero de 2017, se publicó Wine 2.0.
    La version mas estable de wine.
RAMA
	echo
	continuar
	clear;echo
	echo -e "${RED}      :::::: Instalando wine2.0 ::::::${STOP}"
	sleep 0.5
	echo -e "${RED}:::::: Agregando el ppa:ricotz/unstable  ::::::${STOP}"
	sudo add-apt-repository ppa:ricotz/unstable
	echo -e "Eliminamos la versión anterior de Wine 1.8 o cualquier otro 
paquete de la versión estable que tuviéramos instalada de Wine"
	sudo apt remove wine wine1.8 wine-stable libwine* fonts-wine*
	echo;continuar;clear
	echo -e "${YELLOW}         Actualizado...${STOP}" 
	sudo apt update --yes
	echo -e "${RED}:::::: Instalando wine-stable ::::::${STOP}"
	sudo apt install wine-stable --yes
	clear
	echo -e "${RED}:::::: winetricks  ::::::${STOP}"
	sudo apt-get install winetricks --yes
	clear
	echo -e "${RED}:::::: Instalando playonlinux  ::::::${STOP}"
	sudo apt-get install playonlinux --yes
	sudo dpkg –add-architecture i386
	sudo apt-get -f install
	clear
	echo -e "${RED}:::::: Apt update ::::::${STOP}"
	sudo apt-get update --yes
	clear
	echo -e "${GREEN}[-] Listo!!${STOP}"
	else
	echo -e "${GREEN}[-] Ok,Tal vez luego!!${STOP}"
	fi
	else 
	echo
	echo -e "${GREEN} [-] -Ya se instaló una nueva versión de Wine!${STOP}"
	fi
}
######## Instalar chromium-browser-l10n En español
function chromiumbrowser {
	clear
cat <<CHROMIUM
${GREEN} Usuario: ${YELLOW}$USER${STOP} $TIME 
${GREEN} Script: ${YELLOW}$SCRIPT${STOP} 
${GREEN} Distro: ${YELLOW}$OSS${STOP}
${RED} ###############################################${STOP}
    ${WHITE} Instalando Aplicaciones Recomendadas...${STOP}
${RED} ###############################################${STOP}
	= Chromium-browser =
CHROMIUM
	echo
	echo -e "${YELLOW} Esta Opción Instalara Chromium-browser- En español en tu Sistema..${STOP}"
	echo -e " Estas Seguro que Deseas Instalar esta aplicacion (Y/N)?"
	read install
	if [[ $install = Y || $install = y ]] ; then	
	echo -e "${RED}###### Instalando chromium-browser ######${STOP}"
	sleep 2
	sudo apt install chromium-browser-l10n chromium-codecs-ffmpeg-extra unity-chromium-extension --yes
	echo -e "${GREEN} [-] - Listo!!${STOP}"
	else
			echo -e "${GREEN}[-] Ok, Talvez en otra Ocacion!${STOP}"
		fi
}
######### Instalar Google Chrome
function installgooglechrome {
	clear
	cat <<GOOGLECHRM
${GREEN} Usuario: ${YELLOW}$USER${STOP} $TIME 
${GREEN} Script: ${YELLOW}$SCRIPT${STOP} 
${GREEN} Distro: ${YELLOW}$OSS${STOP}
${RED} ###############################################${STOP}
    ${WHITE} Instalando Aplicaciones Recomendadas...${STOP}
${RED} ###############################################${STOP}
	= Google-chrome =
GOOGLECHRM
	echo
	echo -e "${YELLOW} Esta Opción Instalara Google-chrome 32/64bits En español en tu Sistema..${STOP}"
	echo -e " Estas Seguro que Deseas Instalar esta aplicacion (Y/N)?"
	read install
	if [[ $install = Y || $install = y ]] ; then
	read -p "Estas usando OS de 32bit o 64bit? [Escribe: 32 o 64] para continuar " operatingsys
	if [ "$operatingsys" == "32" ]; then 
	echo -e "${YELLOW}[*] Descargando Google Chrome para Ubuntu 32bit${STOP}"
	sudo wget https://archive.org/download/google-chrome-stable_48.0.2564.116-1_i386/google-chrome-stable_48.0.2564.116-1_i386.deb
	echo -e "${RED}[*] -Descarga completa!!${STOP}"
	sleep 1
	echo -e "${YELLOW}[*] Instalalando google chrome${STOP}"
	sudo dpkg -i google-chrome-stable_48.0.2564.116-1_i386.deb
	sudo rm google-chrome-stable_48.0.2564.116-1_i386.deb
	sudo apt-get -f install
	echo -e "${WHITE}[*] - Ok ya esta Instalado Google Chrome En tu Sistema!!${STOP}"
	echo -e "${WHITE}[*] Ejecuta Google Chrome, con el commando: /usr/bin/google-chrome-stable --no-sandbox --user-data-dir${STOP}"
	else
	echo -e "${YELLOW}[*] Descargando Google Chrome para Ubuntu 64bit${STOP}"
	sudo wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
	echo -e "${RED}[*] -Descarga completa!!${STOP}"
	echo -e "${YELLOW}[*] Instalalando google chrome${STOP}"
	sudo dpkg -i google-chrome-stable_current_amd64.deb
	sudo rm google-chrome-stable_current_amd64.deb
	sudo apt-get -f install
	echo -e "\e[34m[*] Ok ya esta Instalado Google Chrome En tu Sistema!!${STOP}"
	echo -e "\e[34m[*] Ejecuta Google Chrome, con el commando: /usr/bin/google-chrome-stable --no-sandbox --user-data-dir${STOP}"
	fi
	else
	echo -e "${BLUE}[*] -Esta bien, Sera Después!!${STOP}"
	fi
}
######## Instalar unrar file-roller
function filerollerunrar {
	clear
cat <<FILEROLLER
${GREEN} Usuario: ${YELLOW}$USER${STOP} $TIME 
${GREEN} Script: ${YELLOW}$SCRIPT${STOP} 
${GREEN} Distro: ${YELLOW}$OSS${STOP}
${RED} ###############################################${STOP}
    ${WHITE} Instalando Aplicaciones Recomendadas...${STOP}
${RED} ###############################################${STOP}
	= File-roller =
FILEROLLER
	echo
	echo -e "${RED}Esta opción instalara La versión completa de Archive-manager!${STOP}"
	echo -e "${RED}(file-roller) unarar, unace, p7zip, zip, unzip,etc....!${STOP}"
	echo -e " Estas Seguro que Deseas Instalar esta aplicacion (Y/N)?"
	read install
	if [[ $install = Y || $install = y ]] ; then	
	echo -e "${RED}::::::: Instalando Archive-manager (file-roller) ::::::${STOP}"
	sleep 2
	sudo apt install unrar unace rar unrar p7zip zip unzip p7zip-full p7zip-rar file-roller
	echo -e "${GREEN}[-] Listo!${STOP}"
	else
	echo -e "${GREEN}[-] Ok,Tal vez luego!!${STOP}"
	fi
}
######## Instalando Unity-tweak_tools
function installubuntutweak {
	clear
	cat <<UNITYTOOL
${GREEN} Usuario: ${YELLOW}$USER${STOP} $TIME 
${GREEN} Script: ${YELLOW}$SCRIPT${STOP} 
${GREEN} Distro: ${YELLOW}$OSS${STOP}
${RED} ###############################################${STOP}
    ${WHITE} Instalando Aplicaciones Recomendadas...${STOP}
${RED} ###############################################${STOP}
	= UNITY-TWEAK-TOOL =
UNITYTOOL
	echo
	echo -e "${YELLOW} Esta Opción Instalara Unity-tweak-tools en tu Sistema..${STOP}"
	echo -e " Estas Seguro que Deseas Instalar esta aplicacion (Y/N)?"
	read install
	if [[ $install = Y || $install = y ]] ; then	
	echo -e "${RED}:::::: Instalando Unity-tweak-tools ::::::${STOP}"
	echo -e "${YELLOW} Por favor Espere...${STOP}"
	pkg-config gnome-doc-utils
	sleep 2				
	sudo apt install -y unity-tweak-tool
	pause
	clear
	echo
	echo -e " ${GREEN} [-] -Instalacion completada, Busca Unity-tweak-tools en el menu de aplicaciones...!!${STOP}"
	else
	echo -e " ${GREEN}[-] Sera para la Próxima!!${STOP}"
	fi
}
######## Instalando indicator-brightness :::
function instalandoindicator-brightness {
	clear
cat <<BRIGHTNESS
${GREEN} Usuario: ${YELLOW}$USER${STOP} $TIME 
${GREEN} Script: ${YELLOW}$SCRIPT${STOP} 
${GREEN} Distro: ${YELLOW}$OSS${STOP}
${RED} ###############################################${STOP}
    ${WHITE} Instalando Aplicaciones Recomendadas...${STOP}
${RED} ###############################################${STOP}
	= INDICATOR-BRIGHTNESS =
BRIGHTNESS
	echo
	echo " ${RED_BOLD}Nota${STOP}:${YELLOW} Evita repetir la instalacion de INDICATOR-BRIGHTNESS"
	echo " Al repetir add-apt-repository en el sources.list"
	echo " Crearia un error al actualizar con \"sudo apt-get update\"${STOP}"
	echo
	echo -e "${YELLOW} Esta Opción Instalara indicator-brightness en tu Sistema..${STOP}"
	echo -e " Estas Seguro que Deseas Instalar esta aplicacion (Y/N)?"
	read install
	if [[ $install = Y || $install = y ]] ; then	
	echo -e "${RED}:::::: Instalando indicator-brightness ::::::${STOP}"
	echo -e "${YELLOW}# Activando los repositorios Socios de Canonical.\0m" 
	sudo sed 's/# deb/deb/' -i /etc/apt/sources.list 
	sleep 4
	echo "#Agregando add-apt-repository ppa:indicator-brightness/pp"
	sudo add-apt-repository ppa:indicator-brightness/ppa --yes
	sleep 2
	clear
	sudo apt update 
	sudo apt install indicator-brightness --yes
	sleep 2
	clear
	echo -e "${GREEN}[-] Listo!!${STOP}"
	else
	echo -e "${GREEN}[-] Ok,Tal vez luego!!${STOP}"
	fi
}
#### Instalando ffmpeg
function installarffmpeg {
	clear
cat <<FFMPEG
${GREEN} Usuario: ${YELLOW}$USER${STOP} $TIME 
${GREEN} Script: ${YELLOW}$SCRIPT${STOP} 
${GREEN} Distro: ${YELLOW}$OSS${STOP}
${RED} ###############################################${STOP}
    ${WHITE} Instalando Aplicaciones Recomendadas...${STOP}
${RED} ###############################################${STOP}
		= FFMPEG =

	${YELLOW} Esta Opción Instalara FFMPEG en tu Sistema..${STOP}
	 ${RED} Nota${STOP}:${YELLOW} Esta version full de FFMPEG de github
	    incluye "OpenH264" (git-clone) ${STOP}
	${GREEN} Tiempo total de instalacion${STOP}:${YELLOW} de 5 a 7 minutos aprox${STOP}
FFMPEG
	echo
	echo -e " Estas Seguro que Deseas Instalar esta aplicacion (Y/N)?"
	read install
	if [[ $install = Y || $install = y ]] ; then
	echo -e "${RED}[*] -Build and install OpenH264...${STOP}"
	sudo apt-get install -y nasm
	git clone https://github.com/cisco/openh264
	cd openh264
	git checkout v1.5.0 -b v1.5.0
	make && sudo make install
	sleep 2
	echo -e "${RED}[*] -Build and install FFmpeg...${STOP}"
	sudo apt-get build-dep -y ffmpeg
	git clone https://github.com/FFmpeg/FFmpeg
	cd FFmpeg
	git checkout n3.0.1 -b n3.0.1
    ./configure \
  --toolchain=hardened \
  --enable-libopenh264 \
  --enable-gpl \
  --enable-shared \
  --disable-stripping \
  --disable-decoder=libopenjpeg \
  --disable-decoder=libschroedinger \
  --enable-avresample \
  --enable-avisynth \
  --enable-gnutls \
  --enable-ladspa \
  --enable-libass \
  --enable-libbluray \
  --enable-libbs2b \
  --enable-libcaca \
  --enable-libcdio \
  --enable-libflite \
  --enable-libfontconfig \
  --enable-libfreetype \
  --enable-libfribidi \
  --enable-libgme \
  --enable-libgsm \
  --enable-libmodplug \
  --enable-libmp3lame \
  --enable-libopenjpeg \
  --enable-libopus \
  --enable-libpulse \
  --enable-librtmp \
  --enable-libschroedinger \
  --enable-libshine \
  --enable-libsnappy \
  --enable-libsoxr \
  --enable-libspeex \
  --enable-libssh \
  --enable-libtheora \
  --enable-libtwolame \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libwavpack \
  --enable-libwebp \
  --enable-libx265 \
  --enable-libxvid \
  --enable-libzvbi \
  --enable-openal \
  --enable-opengl \
  --enable-x11grab
	make && sudo make install
	### run ffmpeg
	ffmpeg
	sleep 2
	echo -e "${GREEN}[-] FFMPEG Esta Instalado en tu Sistema!!${STOP}"		
	else
	echo -e "${GREEN}[-] Ok,Tal vez para la Próxima!!${STOP}"
	fi
}

######## Instalando TLP para mejorar la Vida de la Batería y Reducir el Sobrecalentamiento :::
function instalandotlp {
	clear
cat <<TLP
${GREEN} Usuario: ${YELLOW}$USER${STOP} $TIME 
${GREEN} Script: ${YELLOW}$SCRIPT${STOP} 
${GREEN} Distro: ${YELLOW}$OSS${STOP}
${RED} ###############################################${STOP}
    ${WHITE} Instalando Aplicaciones Recomendadas...${STOP}
${RED} ###############################################${STOP}
		= TLP-RDW =

	 ${RED_BOLD}Nota${STOP}:${YELLOW} Evita repetir la instalacion de TLP-RDW
	 Al repetir add-apt-repository en el sources.list
	 Crearia un error al actualizar con " apt-get update "${STOP}
TLP
	echo
	echo -e "${YELLOW} Esta Opción Instalara tlp-rdw en tu Sistema.."
	echo -e	" TLP es una Aplicacion para mejorar la Vida de la Batería"
	echo -e " y Reducir el Sobrecalentamiento de la batería..."
	echo -e " Estas Seguro que Deseas Instalar esta aplicacion (Y/N)?"
	echo -e ""
	echo -e "$ Estas seguro que deseas agregar ppa:linrunner/tlp? (Y/N)${STOP}"
	read install
	if [[ $install = Y || $install = y ]] ; then
	echo -e "${YELLOW}# Activando los repositorios Socios de Canonical.${STOP}" 
	sudo sed 's/# deb/deb/' -i /etc/apt/sources.list 
	sleep 2
	sudo add-apt-repository ppa:linrunner/tlp --yes
	sleep 2
	clear
	echo -e "${RED} ###############################################${STOP}"
    echo -e "${WHITE} update e instalando tlp tlp-rdw en tu sistema...${STOP}"
	echo -e "${RED} ###############################################${STOP}"
			sudo apt update 
			sleep 2
			sudo apt-get install tlp tlp-rdw --yes
			sudo tlp start
			clear
				echo -e "${GREEN}[-] Listo!!${STOP}"
			else
				echo -e "${GREEN}[-] Ok,Tal vez luego!!${STOP}"
			fi
}
######## Instalando prelink-preload :::
function instalandoprelink-load {
	clear
cat <<PRELOAD
${GREEN} Usuario: ${YELLOW}$USER${STOP} $TIME 
${GREEN} Script: ${YELLOW}$SCRIPT${STOP} 
${GREEN} Distro: ${YELLOW}$OSS${STOP}
${RED} ###############################################${STOP}
    ${WHITE} Instalando Aplicaciones Recomendadas...${STOP}
${RED} ###############################################${STOP}
		= PRELOAD-PRELINK =

	 ${RED_BOLD}Nota${STOP}:${YELLOW} Evita repetir la instalacion de PRELOAD-PRELINK
	 Al repetir add-apt-repository en el sources.list
	 Crearia un error al actualizar con " apt-get update "${STOP}

 ${RED} Este menú Instalara Preload-Prelink en tu Sistema!!${STOP}
 ${YELLOW} Esta aplicaciones precargan los programas para que se inicien mas rápido
  Y asi Reducir el tiempo de partida de las aplicaciones instaladas...${STOP}
  Estas Seguro que Deseas Instalar esta aplicacion (Y/N)?

PRELOAD
	read install
	if [[ $install = Y || $install = y ]] ; then	
	echo -e "${RED}:::::: Instalando prelink-preload ::::::${STOP}"
	sleep 3
	sudo apt-get install prelink --yes
	clear
	sudo apt install preload --yes
	clear
	echo -e "${GREEN}[-] Listo!!${STOP}"
	else
	echo -e "${GREEN}[-] Ok,Tal vez luego!!${STOP}"
	fi
}

######## Update tools to latest version
function appsrecomend {
	clear
cat <<APPMENURECOM
${GREEN} Usuario: ${YELLOW}$USER${STOP} $TIME 
${GREEN} Script: ${YELLOW}$SCRIPT${STOP} 
${GREEN} Distro: ${YELLOW}$OSS${STOP}
${CYAN} ###############################################${STOP}
    ${WHITE} Instalando Aplicaciones Recomendadas...${STOP}
${CYAN} ###############################################${STOP}

APPMENURECOM
select menuselection in "Instalar youtube-dl" "Instalar wine winetricks playonlinux" "Instalar chromium-browser (Español)"\
 "Instalar Google Chrome" "Instalar unrar file-roller" "Instalar Unity-tweak-tools" "Instalar indicator-brightness"\
  "Instalar ffmpeg" "Instalar tlp-rdw" "Instalar Prelink-Preload" "Instalar todos" "Back to Main"; do
case $menuselection in
	"Instalar youtube-dl")
		installyoutube-dl
		pause
		appsrecomend ;;
	"Instalar wine winetricks playonlinux")
		instalandowine
		pause
		appsrecomend ;;	
	"Instalar chromium-browser (Español)")
		chromiumbrowser
		pause
		appsrecomend ;;
	"Instalar Google Chrome")
		installgooglechrome
		pause
		appsrecomend ;;
	"Instalar unrar file-roller")
		filerollerunrar
		pause
		appsrecomend ;;
	"Instalar Unity-tweak-tools")
		installubuntutweak
		pause
		appsrecomend ;;
	"Instalar indicator-brightness")
		instalandoindicator-brightness
		pause
		appsrecomend ;;
	"Instalar ffmpeg")
		installarffmpeg
		pause
		appsrecomend ;;		
	"Instalar tlp-rdw")
		instalandotlp
		pause
		appsrecomend ;;
	"Instalar Prelink-Preload")
		instalandoprelink-load
		pause
		appsrecomend ;;
	"Update All")
		installyoutube-dl
		chromiumbrowser
		installgooglechrome
		filerollerunrar
		installubuntutweak
		instalandoindicator-brigthness
		installarffmpeg
		instalandoprelink-load
		echo -e "${GREEN}[-] Ok, Ya están Instaladas todas las apps en tu Sistema...${STOP}"
		zenity --info --text="Las aplicación. Se instalaron Correctamente,
Recuerda NO reinstalar las apps de esta lista. para no repetir los Repositorios y ppa's del sources.list ya que nos crearían problemas.
                              Gracias...!"
		pause
		appsrecomend ;;
	"Back to Main")
		clear
		mainmenu ;;
		
	*)  echo " ${WHITE_BOLD}$(basename $0 -s)${STOP}${VIOLET} $while Opcion Incorrecta${STOP} "
		pause
		clear
		appsrecomend ;;	
esac
break
done
}
_help (){
	clear
	echo;echo;echo
cat<<HELP0
 ${YELLOW}easytool.sh
 https://github.com/heil-linux/ .. *****
 Categoria: Herramienta de edicion, utilidades/Multimedia & Actualizacion

 [*] Lea las instrucciones del script antes de usar
 [*] Es muy importante para no tener problemas al usarlo..

 Para Ubuntu 16.04 (Xenial Xerus)
 [-] Usado en las verciones anteriores y posteriores sin problemas.
 * El script Ubuntu 16.04 Easytool v2.0, añade repositorios, actualiza el 
   sistema con el software mas resiente,
 * Edita, convierte multimedia, juegos bash y aplicaciones para linux
 
 * Se distribuye con la Esperanza de que sea útil, pero sin ninguna garantía...
 * La mayoría de los menús traen notas y advertencias para el uso del Script
 * leer bien antes de Usar, Para evitar Problemas.

 ===============================================================================
 [*] - ejemplos guias de script y comandos Linux en 
      https://e-mc2.net/es/bash-iv-estructuras-de-control-y-bucles
 ===============================================================================

HELP0
echo
echo -n "${WHITE} Presiona ENTER para la siguiente pagina de instrucciones. ${STOP}"; read az1
clear
cat <<HELP2

	 ${RED_BOLD}IMPORTATNTE${STOP}:

${YELLOW} Evita repetir la instalacion de Aplicaciones
 Que añadan nuevos add-apt-repository app: / en el sources.list
 Crearia un error al actualizar con " apt-get update "
   **************************
   * AQUI ALGUNOS EJEMPLOS: *
   **************************
 [Error]: No se puede actualizar de un repositorio como este de 
 forma segura y por tanto está deshabilitado por omisión.

 [Error]: Vea la página de manual apt-secure(8) para los detalles
  sobre la creación de repositorios y la configuración de usuarios.

 [Error]: Las firmas siguientes no se pudieron verificar porque su
  clave pública no está disponible: NO_PUBKEY XXXFAXXFFXXXXXXF
	 ${STOP}

HELP2
echo -n "${WHITE} Presiona ENTER para la siguiente pagina de instrucciones."; read az1
clear
cat <<HELP3
${YELLOW}
 Este Script Usa el comando (aptitude safe-upgrade),
 Esta orden llevaría a cabo una actualización de paquetes
 pero es más agresiva a la hora de resolver los problemas
 de dependencias: instalará y eliminará paquetes hasta
 que todas las dependencias estén resueltas. Debido a la
 naturaleza de esta orden es probable que realice  acciones
 no deseadas, y por lo tanto deberías ser cuidadoso a la hora
 de emplearlo. El autor no se responsabiliza por el mal uso del
 script, y sus funciones. 

HELP3
echo -n "${WHITE} Presiona ENTER para la siguiente pagina de instrucciones. ${STOP}${VIOLET}"; read az1
clear
cat <<AYUDA3

${GREEN}                  AYUDA/RAR EXTRACTOR TOOL ${STOP}
${RED}      #####################################################################${STOP}

 Esta página del manual fue escrita para la distribución Debian GNU/Linux
 porque el programa original no tiene una página oficial del manual.
 Los comandos y opciones descritos aquí son de unrar 2.02.
 Para descripción completa, ejecute UNRAR sin opciones. 
 Esta página del manual fue escrita por Petr Cech <cech@debian.org> de acuerdo
 "unrar -h" para el sistema Debian GNU/Linux pero puede ser utilizado por otros.

${GREEN}       [-] Presiona (1)${STOP}${YELLOW} para buscar el achivo rar
	   En cuadro de dialogo y selecciona el archivo que desees extraer.
       La Descomprecion se hara en la carpeta ~/Descargas. (por defecto)
       Si el archivo esta Encriptado Ingresa la contraseña para continuar
       con la extraccion.

    ${GREEN}[-] Presiona (2)${STOP}${YELLOW} para listar todos los archivos rar en el 
    directorio $HOME/, este menu es solo informativo.

${RED}      #####################################################################${STOP}
AYUDA3
echo -n "${WHITE} Presiona ENTER para la siguiente pagina de instrucciones. ${STOP}${VIOLET}"; read az1
clear
cat <<HELP
${VIOLET}
                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

                            Preamble

  The GNU General Public License is a free, copyleft license for
software and other kinds of works.

  The licenses for most software and other practical works are designed
to take away your freedom to share and change the works.  By contrast,
the GNU General Public License is intended to guarantee your freedom to
share and change all versions of a program--to make sure it remains free
software for all its users.  We, the Free Software Foundation, use the
GNU General Public License for most of our software; it applies also to
any other work released this way by its authors.  You can apply it to
your programs, too.
HELP
echo -n "${WHITE} Presiona ENTER para finalizr la pagina de instrucciones. ${STOP}${VIOLET}"; read az1
clear
cat<<FIN

 Gracias por Usar este Script. Ayúdanos a mejorar,
 te invitamos a darnos tu opinión del script al correo 
     ### pabloc.labarca@gmail.com ###
FIN
}
########################################################
    ##             Menú principal			      ##
########################################################
function mainmenu (){
	clear
	echo "${VIOLET}"
cat <<TITLE
          │▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│
          │     ${GREEN}Easytool.sh v1.1 / ffmpeg converter${STOP}${VIOLET}    │   
          │           ${GREEN}16.4.05 Xenial Xerus${STOP}${VIOLET}             │
          │                   ${RED}FOR${STOP}${VIOLET}                      │
          │                [ ${WHITE}UBUNTU ${STOP}${VIOLET}]                  │
          │▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒│${BLUE}	
		Script by: ${RED}pabloc labarca${STOP}${BLUE}
		Email: ${YELLOW} $MAIL${STOP}${BLUE}
                                                                           
                 BIENVENIDO USUARIO :${RED} $USER ${STOP}
                ${BLUE}PERMISO DE EJECUCION:${STOP}   [$(if [[ $USER != root ]] ; then
				echo ${RED} DESACTIVADA${STOP}
				else
				echo ${RED} ACTIVA${STOP}
				exit
				fi) ] 				         
TITLE
echo "${VIOLET}"
select menuselection in "instalar & Actualizar" "Aplicaciones Recomendadas" \
"Herramientas de Audio&Video" "Info/sistema" "Extractor rar"\
 "juegos" "ayuda" "Salir del programa"
do
case $menuselection in
	"instalar & Actualizar")
		actualizaciones
		clear 
		;;
	"Herramientas de Audio&Video")
		toolsaudio_video
		convertertomp3
		clear
		mainmenu
		;;	
	"Aplicaciones Recomendadas")
		appsrecomend
		clear 
		;;
	"Info/sistema")
		infosystem
		clear
		;;	
	"Extractor rar")
		rar_tool
		clear
		;;
	"ayuda")
		_help
		cancelado
		clear
		;;
	"juegos")
		juegosbash
		mainmenu
		;;	
	"Salir del programa")
		zenity --info --text="Gracias por Usar esta aplicación. Ayúdanos a mejorar,
te invitamos a darnos tu opinión del script al correo 
    pabloc.labarca@gmail.com.
                              adiós!"
		clear &&exit 0 ;;
	* ) echo " ${WHITE_BOLD}$(basename $0 -s)${STOP}${VIOLET} $while Opcion Incorrecta${STOP} "
		pause
		clear ;;
esac
mainmenu
done
}
while true
do mainmenu
done			








