#!/bin/bash
# SinusBot installer by $:git$ - radizshoter@gmail.com [SPANISH VERSION]

# Vars

MACHINE=$(uname -m)
Instversion="1.5"

USE_SYSTEMD=true

# Functions

function greenMessage() {
  echo -e "\\033[32;1m${*}\\033[0m"
}

function magentaMessage() {
  echo -e "\\033[35;1m${*}\\033[0m"
}

function cyanMessage() {
  echo -e "\\033[36;1m${*}\\033[0m"
}

function redMessage() {
  echo -e "\\033[31;1m${*}\\033[0m"
}

function yellowMessage() {
  echo -e "\\033[33;1m${*}\\033[0m"
}

function errorQuit() {
  errorExit '¡Salir ahora!'
}

function errorExit() {
  redMessage "${@}"
  exit 1
}

function errorContinue() {
  redMessage "Opcion invalida."
  return
}

function makeDir() {
  if [ -n "$1" ] && [ ! -d "$1" ]; then
    mkdir -p "$1"
  fi
}

err_report() {
  FAILED_COMMAND=$(wget -q -O - https://raw.githubusercontent.com/Sinusbot/installer-linux/master/sinusbot_installer.sh | sed -e "$1q;d")
  FAILED_COMMAND=${FAILED_COMMAND/ -qq}
  FAILED_COMMAND=${FAILED_COMMAND/ -q}
  FAILED_COMMAND=${FAILED_COMMAND/ -s}
  FAILED_COMMAND=${FAILED_COMMAND/ 2\>\/dev\/null\/}
  FAILED_COMMAND=${FAILED_COMMAND/ 2\>&1}
  FAILED_COMMAND=${FAILED_COMMAND/ \>\/dev\/null}
  if [[ "$FAILED_COMMAND" == "" ]]; then
    redMessage "Comando fallido: https://github.com/Sinusbot/installer-linux/blob/master/sinusbot_installer.sh#L""$1"
  else
    redMessage "El comando que falló fue: \"${FAILED_COMMAND}\". Intente ejecutarlo manualmente y adjunte el resultado al informe de error en el hilo del foro."
    redMessage "Si aún no funciona, informe esto al autor en https://forum.sinusbot.com/threads/sinusbot-installer-script.1200/ únicamente. No es un PN o una mala revisión, porque este es un error de su sistema, no del script del instalador. Línea $1".
  fi
  exit 1
}

trap 'err_report $LINENO' ERR

# Check if the script was run as root user. Otherwise exit the script
if [ "$(id -u)" != "0" ]; then
  errorExit "Cambio a usuario ROOT requerido!"
fi

# Update notify

cyanMessage "Buscando la ultima version..."
if [[ -f /etc/centos-release ]]; then
  yum -y -q install wget
else
  apt-get -qq install wget -y
fi

# Detect if systemctl is available then use systemd as start script. Otherwise use init.d
if [[ $(command -v systemctl) == "" ]]; then
  USE_SYSTEMD=false
fi

# If kernel to old, quit
if [ $(uname -r | cut -c1-1) < 3 ]; then
  errorExit "Linux kernel no soportado. Actualiza kernel antes. O cambia el hardware."
fi

# If the linux distribution is not debian and centos, then exit
if [ ! -f /etc/debian_version ] && [ ! -f /etc/centos-release ]; then
  errorExit "Distrubucion de Linux no soportada. Actualmente solo se admiten Debian y CentOS"!
fi

greenMessage "Este es el instalador automático del último SinusBot. ÚSELO BAJO SU PROPIO RIESGO"!
sleep 1
cyanMessage "Puede elegir entre instalar, actualizar y eliminar el SinusBot."
sleep 1
redMessage "Instalador por git | radizshoter@gmail.com -"
sleep 1
magentaMessage "Porfavor califica este script en: https://forum.sinusbot.com/resources/sinusbot-installer-script.58/"
sleep 1
yellowMessage "Tu estas usando el instalador $Instversion"

# selection menu if the installer should install, update, remove or pw reset the SinusBot
redMessage "¿Qué debe hacer el instalador?"
OPTIONS=("Instalar" "Actualizar" "Eliminar" "Cambiar contraseña" "Salir")
select OPTION in "${OPTIONS[@]}"; do
  case "$REPLY" in
  1 | 2 | 3 | 4) break ;;
  5) errorQuit ;;
  *) errorContinue ;;
  esac
done

if [ "$OPTION" == "Instalar" ]; then
  INSTALL="Inst"
elif [ "$OPTION" == "Actualizar" ]; then
  INSTALL="Updt"
elif [ "$OPTION" == "Remover" ]; then
  INSTALL="Rem"
elif [ "$OPTION" == "Cambiar contrasñea" ]; then
  INSTALL="Res"
fi

# PW Reset

if [[ $INSTALL == "Res" ]]; then
  yellowMessage "¿Uso automático o directorios propios?"

  OPTIONS=("Automático" "Directorio propio" "Salir")
  select OPTION in "${OPTIONS[@]}"; do
    case "$REPLY" in
    1 | 2) break ;;
    3) errorQuit ;;
    *) errorContinue ;;
    esac
  done

  if [ "$OPTION" == "Automático" ]; then
    LOCATION=/opt/sinusbot
  elif [ "$OPTION" == "Directorio propio" ]; then
    yellowMessage "Ingrese la ubicación donde se debe instalar/actualizar/eliminar el bot. Me gusta /opt/sinusbot. Incluya / en la primera posición y ninguno al final"!

    LOCATION=""
    while [[ ! -d $LOCATION ]]; do
      read -rp "Location [/opt/sinusbot]: " LOCATION
      if [[ $INSTALL != "Inst" && ! -d $LOCATION ]]; then
        redMessage "Directorio no encontrado, intenta de nuevo"!
      fi
    done

    greenMessage "Tu directorio es $LOCATION."

    OPTIONS=("Si" "No, cambialo" "Salir")
    select OPTION in "${OPTIONS[@]}"; do
      case "$REPLY" in
      1 | 2) break ;;
      3) errorQuit ;;
      *) errorContinue ;;
      esac
    done

    if [ "$OPTION" == "No, cambialo" ]; then
      LOCATION=""
      while [[ ! -d $LOCATION ]]; do
        read -rp "Location [/opt/sinusbot]: " LOCATION
        if [[ $INSTALL != "Inst" && ! -d $LOCATION ]]; then
          redMessage "Directorio no encontrado, intenta de nuevo"!
        fi
      done

      greenMessage "Tu directorio es $LOCATION."
    fi
  fi

  LOCATIONex=$LOCATION/sinusbot

  if [[ ! -f $LOCATION/sinusbot ]]; then
    errorExit "No se encontró SinusBot en $LOCATION. Saliendo del script."
  fi

  PW=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
  SINUSBOTUSER=$(ls -ld $LOCATION | awk '{print $3}')

  greenMessage "Inicie sesión en su interfaz web de SinusBot como administrador y '$PW'"
  yellowMessage "Después de eso, cambie su contraseña en Configuración->Cuentas de usuario->administrador->Editar. El script reinicia el bot con init.d o systemd."

  if [[ -f /lib/systemd/system/sinusbot.service ]]; then
    if [[ $(systemctl is-active sinusbot >/dev/null && echo UP || echo DOWN) == "UP" ]]; then
      service sinusbot stop
    fi
  elif [[ -f /etc/init.d/sinusbot ]]; then
    if [ "$(/etc/init.d/sinusbot status | awk '{print $NF; exit}')" == "UP" ]; then
      /etc/init.d/sinusbot stop
    fi
  fi

  log="/tmp/sinusbot.log"
  match="USER-PATCH [admin] (admin) OK"

  su -c "$LOCATIONex --override-password $PW" $SINUSBOTUSER >"$log" 2>&1 &
  sleep 3

  while true; do
    echo -ne '(Esperando cambio de contraseña!)\r'

    if grep -Fq "$match" "$log"; then
      pkill -INT -f $PW
      rm $log

      greenMessage "Cambió con éxito su contraseña de administrador."

      if [[ -f /lib/systemd/system/sinusbot.service ]]; then
        service sinusbot start
        greenMessage "Comenzó su bot con systemd."
      elif [[ -f /etc/init.d/sinusbot ]]; then
        /etc/init.d/sinusbot start
        greenMessage "Comenzó su bot con initd."
      else
        redMessage "Inicie su bot normalmente"!
      fi
      exit 0
    fi
  done

fi

# Check which OS

if [ "$INSTALL" != "Rem" ]; then

  if [[ -f /etc/centos-release ]]; then
    greenMessage "¡Instalando redhat-lsb! Espere por favor."
    yum -y -q install redhat-lsb
    greenMessage "Hecho"!

    yellowMessage "Está ejecutando CentOS. ¿Qué sistema de firewall estás usando?"

    OPTIONS=("IPtables" "Firewalld")
    select OPTION in "${OPTIONS[@]}"; do
      case "$REPLY" in
      1 | 2) break ;;
      *) errorContinue ;;
      esac
    done

    if [ "$OPTION" == "IPtables" ]; then
      FIREWALL="ip"
    elif [ "$OPTION" == "Firewalld" ]; then
      FIREWALL="fd"
    fi
  fi

  if [[ -f /etc/debian_version ]]; then
    greenMessage "Compruebe si lsb-release y debconf-utils están instalados..."
    apt-get -qq update
    apt-get -qq install debconf-utils -y
    apt-get -qq install lsb-release -y
    greenMessage "Hecho"!
  fi

  # Functions from lsb_release

  OS=$(lsb_release -i 2>/dev/null | grep 'Distributor' | awk '{print tolower($3)}')
  OSBRANCH=$(lsb_release -c 2>/dev/null | grep 'Codename' | awk '{print $2}')
  OSRELEASE=$(lsb_release -r 2>/dev/null | grep 'Release' | awk '{print $2}')
  VIRTUALIZATION_TYPE=""

  # Extracted from the virt-what sourcecode: http://git.annexia.org/?p=virt-what.git;a=blob_plain;f=virt-what.in;hb=HEAD
  if [[ -f "/.dockerinit" ]]; then
    VIRTUALIZATION_TYPE="docker"
  fi
  if [ -d "/proc/vz" -a ! -d "/proc/bc" ]; then
    VIRTUALIZATION_TYPE="openvz"
  fi

  if [[ $VIRTUALIZATION_TYPE == "openvz" ]]; then
    redMessage "¡Advertencia, su servidor está ejecutando OpenVZ! Este sistema de contenedores muy antiguo no es compatible con los paquetes más nuevos."
  elif [[ $VIRTUALIZATION_TYPE == "docker" ]]; then
    redMessage "¡Advertencia, su servidor está ejecutando Docker! Tal vez hay fallas durante la instalación."
  fi

fi

# Go on

if [ "$INSTALL" != "Rem" ]; then
  if [ -z "$OS" ]; then
    errorExit "Error: No se pudo detectar el sistema operativo. Actualmente solo se admiten Debian, Ubuntu y CentOS. Abortar"!
  elif [ -z "$OS" ] && ([ "$(cat /etc/debian_version | awk '{print $1}')" == "7" ] || [ $(cat /etc/debian_version | grep "7.") ]); then
    errorExit "Debian 7 ya no es compatible"!
  fi

  if [ -z "$OSBRANCH" ] && [ -f /etc/centos-release ]; then
    errorExit "Error: no se pudo detectar la rama del sistema operativo. Abortar"
  fi

  if [ "$MACHINE" == "x86_64" ]; then
    ARCH="amd64"
  else
    errorExit "$MACHINE no es soportado!"!
  fi
fi

if [[ "$INSTALL" != "Rem" ]]; then
  if [[ "$USE_SYSTEMD" == true ]]; then
    yellowMessage "system.d elegido automáticamente para su script de arranque"!
  else
    yellowMessage "Init.d elegida automáticamente para su script de arranque"!
  fi
fi

# Set path or continue with normal

yellowMessage "Uso automático o directorios propios?"

OPTIONS=("Automatico" "Directorios Propios" "Salir")
select OPTION in "${OPTIONS[@]}"; do
  case "$REPLY" in
  1 | 2) break ;;
  3) errorQuit ;;
  *) errorContinue ;;
  esac
done

if [ "$OPTION" == "Automatico" ]; then
  LOCATION=/opt/sinusbot
elif [ "$OPTION" == "Directorios Propios" ]; then
  yellowMessage "Ingrese la ubicación donde se debe instalar/actualizar/eliminar el bot, p. /opt/sinusbot. Incluya / en la primera posición y ninguno al final"!
  LOCATION=""
  while [[ ! -d $LOCATION ]]; do
    read -rp "Location [/opt/sinusbot]: " LOCATION
    if [[ $INSTALL != "Inst" && ! -d $LOCATION ]]; then
      redMessage "Directorio no encontrado, intente de nuevo"!
    fi
    if [ "$INSTALL" == "Inst" ]; then
      if [ "$LOCATION" == "" ]; then
        LOCATION=/opt/sinusbot
      fi
      makeDir $LOCATION
    fi
  done

  greenMessage "Su directorio es $LOCATION."

  OPTIONS=("Si" "No, cambialo" "Salir")
  select OPTION in "${OPTIONS[@]}"; do
    case "$REPLY" in
    1 | 2) break ;;
    3) errorQuit ;;
    *) errorContinue ;;
    esac
  done

  if [ "$OPTION" == "No, cambialo" ]; then
    LOCATION=""
    while [[ ! -d $LOCATION ]]; do
      read -rp "Location [/opt/sinusbot]: " LOCATION
      if [[ $INSTALL != "Inst" && ! -d $LOCATION ]]; then
        redMessage "Directorio no encontrado, intente de nuevo"!
      fi
      if [ "$INSTALL" == "Inst" ]; then
        makeDir $LOCATION
      fi
    done

    greenMessage "Su directorio es $LOCATION."
  fi
fi

makeDir $LOCATION

LOCATIONex=$LOCATION/sinusbot

# Check if SinusBot already installed and if update is possible

if [[ $INSTALL == "Inst" ]] || [[ $INSTALL == "Updt" ]]; then

yellowMessage "¿Debo instalar TeamSpeak o solo modo Discord?"

OPTIONS=("Ambos" "Solo Discord" "Salir")
select OPTION in "${OPTIONS[@]}"; do
  case "$REPLY" in
  1 | 2) break ;;
  3) errorQuit ;;
  *) errorContinue ;;
  esac
done

if [ "$OPTION" == "Ambos" ]; then
  DISCORD="false"
else
  DISCORD="true"
fi
fi

if [[ $INSTALL == "Inst" ]]; then

  if [[ -f $LOCATION/sinusbot ]]; then
    redMessage "SinusBot ya instalado con opción de instalación automática"!
    read -rp "¿Le gustaría actualizar el bot en su lugar? [Y / N]: " OPTION

    if [ "$OPTION" == "Y" ] || [ "$OPTION" == "y" ] || [ "$OPTION" == "" ]; then
      INSTALL="Updt"
    elif [ "$OPTION" == "N" ] || [ "$OPTION" == "n" ]; then
      errorExit "Instalador deteniendose"!
    fi
  else
    greenMessage "SinusBot aún no está instalado. El instalador continúa."
  fi

elif [ "$INSTALL" == "Rem" ] || [ "$INSTALL" == "Updt" ]; then
  if [ ! -d $LOCATION ]; then
    errorExit "SinusBot no está instalado"!
  else
    greenMessage "SinusBot está instalado. El instalador continúa."
  fi
fi

# Remove SinusBot

if [ "$INSTALL" == "Rem" ]; then

  SINUSBOTUSER=$(ls -ld $LOCATION | awk '{print $3}')

  if [[ -f /usr/local/bin/youtube-dl ]]; then
    redMessage "Remover YoutubeDL?"

    OPTIONS=("Si" "No")
    select OPTION in "${OPTIONS[@]}"; do
      case "$REPLY" in
      1 | 2) break ;;
      *) errorContinue ;;
      esac
    done

    if [ "$OPTION" == "Si" ]; then
      if [[ -f /usr/local/bin/youtube-dl ]]; then
        rm /usr/local/bin/youtube-dl
      fi

      if [[ -f /etc/cron.d/ytdl ]]; then
        rm /etc/cron.d/ytdl
      fi

      greenMessage "YT-DL Removido exitosamente"!
    fi
  fi

  if [[ -z $SINUSBOTUSER ]]; then
    errorExit "SinusBot no encontrado. Saliendo ahora."
  fi

  redMessage "SinusBot ahora se eliminará por completo de su sistema"!

  greenMessage "¿Su usuario de SinusBot es \"$SINUSBOTUSER\"? El directorio que se eliminará es \"$LOCATION\". Después de seleccionar Sí, podría tomar un tiempo."

  OPTIONS=("Si" "No")
  select OPTION in "${OPTIONS[@]}"; do
    case "$REPLY" in
    1) break ;;
    2) errorQuit ;;
    *) errorContinue ;;
    esac
  done

  if [ "$(ps ax | grep sinusbot | grep SCREEN)" ]; then
    ps ax | grep sinusbot | grep SCREEN | awk '{print $1}' | while read PID; do
      kill $PID
    done
  fi

  if [ "$(ps ax | grep ts3bot | grep SCREEN)" ]; then
    ps ax | grep ts3bot | grep SCREEN | awk '{print $1}' | while read PID; do
      kill $PID
    done
  fi

  if [[ -f /lib/systemd/system/sinusbot.service ]]; then
    if [[ $(systemctl is-active sinusbot >/dev/null && echo UP || echo DOWN) == "UP" ]]; then
      service sinusbot stop
      systemctl disable sinusbot
    fi
    rm /lib/systemd/system/sinusbot.service
  elif [[ -f /etc/init.d/sinusbot ]]; then
    if [ "$(/etc/init.d/sinusbot status | awk '{print $NF; exit}')" == "UP" ]; then
      su -c "/etc/init.d/sinusbot stop" $SINUSBOTUSER
      su -c "screen -wipe" $SINUSBOTUSER
      update-rc.d -f sinusbot remove >/dev/null
    fi
    rm /etc/init.d/sinusbot
  fi

  if [[ -f /etc/cron.d/sinusbot ]]; then
    rm /etc/cron.d/sinusbot
  fi

  if [ "$LOCATION" ]; then
    rm -R $LOCATION >/dev/null
    greenMessage "Archivos eliminados exitosamente"!
  else
    redMessage "Error al eliminar archivos.."
  fi

  if [[ $SINUSBOTUSER != "root" ]]; then
    redMessage "¿Eliminar usuario \"$SINUSBOTUSER\"? (El usuario será eliminado de su sistema)"

    OPTIONS=("Si" "No")
    select OPTION in "${OPTIONS[@]}"; do
      case "$REPLY" in
      1 | 2) break ;;
      *) errorContinue ;;
      esac
    done

    if [ "$OPTION" == "Si" ]; then
      userdel -r -f $SINUSBOTUSER >/dev/null

      if [ "$(id $SINUSBOTUSER 2>/dev/null)" == "" ]; then
        greenMessage "Usuario removido exitosamente"!
      else
        redMessage "Error al eliminar el usuario"!
      fi
    fi
  fi

  greenMessage "SinusBot eliminado por completo incluyendo todos los directorios."

  exit 0
fi

# Private usage only!

redMessage "¡Esta versión de SinusBot es solo para uso privado! ¿Aceptar?"

OPTIONS=("No" "Si")
select OPTION in "${OPTIONS[@]}"; do
  case "$REPLY" in
  1) errorQuit ;;
  2) break ;;
  *) errorContinue ;;
  esac
done

# Ask for YT-DL

redMessage "¿Se debe instalar/actualizar YT-DL?"
OPTIONS=("Si" "No")
select OPTION in "${OPTIONS[@]}"; do
  case "$REPLY" in
  1 | 2) break ;;
  *) errorContinue ;;
  esac
done

if [ "$OPTION" == "Si" ]; then
  YT="Si"
fi

# Update packages or not

redMessage '¿Actualizar los paquetes del sistema a la última versión? (Recomendado)'

OPTIONS=("Si" "No")
select OPTION in "${OPTIONS[@]}"; do
  case "$REPLY" in
  1 | 2) break ;;
  *) errorContinue ;;
  esac
done

greenMessage "Iniciando el instalador ahora"!
sleep 2

if [ "$OPTION" == "Si" ]; then
  greenMessage "Actualización del sistema en unos segundos"!
  sleep 1
  redMessage "Esto podría tomar un tiempo. Por favor espere hasta 10 minutos"!
  sleep 3

  if [[ -f /etc/centos-release ]]; then
    yum -y -q update
    yum -y -q upgrade
  else
    apt-get -qq update
    apt-get -qq upgrade
  fi
fi

# TeamSpeak3-Client latest check

if [ "$DISCORD" == "false" ]; then

greenMessage "Buscando la última compilación de TS3-Client para el tipo de hardware $MACHINE con arch $ARCH."

VERSION="3.5.3"

DOWNLOAD_URL_VERSION="https://files.teamspeak-services.com/releases/client/$VERSION/TeamSpeak3-Client-linux_$ARCH-$VERSION.run"
 STATUS=$(wget --server-response -L $DOWNLOAD_URL_VERSION 2>&1 | awk '/^  HTTP/{print $2}')
  if [ "$STATUS" == "200" ]; then
    DOWNLOAD_URL=$DOWNLOAD_URL_VERSION
  fi

if [ "$STATUS" == "200" -a "$DOWNLOAD_URL" != "" ]; then
  greenMessage "Detectada la última versión de TS3-Client como $VERSION"
else
  errorExit "No se pudo detectar la última versión de TS3-Client"
fi

# Install necessary aptitudes for sinusbot.

magentaMessage "Instalando paquetes necesarios. Porfavor espere..."

if [[ -f /etc/centos-release ]]; then
  yum -y -q install screen xvfb libxcursor1 ca-certificates bzip2 psmisc libglib2.0-0 less cron-apt ntp python iproute which dbus libnss3 libegl1-mesa x11-xkb-utils libasound2 libxcomposite-dev libxi6 libpci3 libxslt1.1 libxkbcommon0 libxss1 >/dev/null
  update-ca-trust extract >/dev/null
else
  # Detect if systemctl is available then use systemd as start script. Otherwise use init.d
  if [ "$OSRELEASE" == "18.04" ] && [ "$OS" == "ubuntu" ]; then
    apt-get -y install chrony
  else
    apt-get -y install ntp
  fi
  apt-get -y -qq install libfontconfig libxtst6 screen xvfb libxcursor1 ca-certificates bzip2 psmisc libglib2.0-0 less cron-apt python iproute2 dbus libnss3 libegl1-mesa x11-xkb-utils libasound2 libxcomposite-dev libxi6 libpci3 libxslt1.1 libxkbcommon0 libxss1
  update-ca-certificates >/dev/null
fi

else

magentaMessage "Instalando paquetes necesarios. Porfavor espere..."

if [[ -f /etc/centos-release ]]; then
  yum -y -q install ca-certificates bzip2 python wget >/dev/null
  update-ca-trust extract >/dev/null
else
  apt-get -qq install ca-certificates bzip2 python wget -y >/dev/null
  update-ca-certificates >/dev/null
fi

fi

greenMessage "Paquetes instalados"!

# Setting server time

if [[ $VIRTUALIZATION_TYPE == "openvz" ]]; then
  redMessage "Está utilizando la virtualización OpenVZ. No puede establecer su tiempo, tal vez funcione, pero no hay garantía. Saltando esta parte..."
else
  if [[ -f /etc/centos-release ]] || [ $(cat /etc/*release | grep "DISTRIB_ID=" | sed 's/DISTRIB_ID=//g') ]; then
    if [ "$OSRELEASE" == "18.04" ] && [ "$OS" == "ubuntu" ]; then
      systemctl start chronyd
      if [[ $(chronyc -a 'burst 4/4') == "200 OK" ]]; then
        TIME=$(date)
      else
        errorExit "Error al configurar la hora a través de chrony"!
      fi
    else
      if [[ -f /etc/centos-release ]]; then
       service ntpd stop
      else
       service ntp stop
      fi
      ntpd -s 0.pool.ntp.org
      if [[ -f /etc/centos-release ]]; then
       service ntpd start
      else
       service ntp start
      fi
      TIME=$(date)
    fi
    greenMessage "Establece automáticamente el tiempo para" $TIME!
  else
    if [[ $(command -v timedatectl) != "" ]]; then
      service ntp restart
      timedatectl set-ntp yes
      timedatectl
      TIME=$(date)
      greenMessage "Establece automáticamente el tiempo para" $TIME!
    else
      redMessage "No se puede configurar su fecha automáticamente, aún se intentará la instalación."
    fi
  fi
fi

USERADD=$(which useradd)
GROUPADD=$(which groupadd)
ipaddress=$(ip route get 8.8.8.8 | awk {'print $7'} | tr -d '\n')

# Create/check user for sinusbot.

if [ "$INSTALL" == "Updt" ]; then
  SINUSBOTUSER=$(ls -ld $LOCATION | awk '{print $3}')
  if [ "$DISCORD" == "false" ]; then
    sed -i "s|TS3Path = \"\"|TS3Path = \"$LOCATION/teamspeak3-client/ts3client_linux_amd64\"|g" $LOCATION/config.ini && greenMessage "Se agregó la ruta TS3 a la configuración." || redMessage "Error while updating config"
  fi
else

  cyanMessage 'Introduzca el nombre del usuario de sinusbot. Típicamente "sinusbot". Si no existe, el instalador lo creará.'

  SINUSBOTUSER=""
  while [[ ! $SINUSBOTUSER ]]; do
    read -rp "nombre de usuario [sinusbot]: " SINUSBOTUSER
    if [ -z "$SINUSBOTUSER" ]; then
      SINUSBOTUSER=sinusbot
    fi
    if [ $SINUSBOTUSER == "root" ]; then
      redMessage "Error. Su nombre de usuario no es válido. No use la raíz"!
      SINUSBOTUSER=""
    fi
    if [ -n "$SINUSBOTUSER" ]; then
      greenMessage "Su usuario de sinusbot es: $SINUSBOTUSER"
    fi
  done

  if [ "$(id $SINUSBOTUSER 2>/dev/null)" == "" ]; then
    if [ -d /home/$SINUSBOTUSER ]; then
      $GROUPADD $SINUSBOTUSER
      $USERADD -d /home/$SINUSBOTUSER -s /bin/bash -g $SINUSBOTUSER $SINUSBOTUSER
    else
      $GROUPADD $SINUSBOTUSER
      $USERADD -m -b /home -s /bin/bash -g $SINUSBOTUSER $SINUSBOTUSER
    fi
  else
    greenMessage "Usuario \"$SINUSBOTUSER\" ya existe."
  fi

chmod 750 -R $LOCATION
chown -R $SINUSBOTUSER:$SINUSBOTUSER $LOCATION

fi

# Create dirs or remove them.

ps -u $SINUSBOTUSER | grep ts3client | awk '{print $1}' | while read PID; do
  kill $PID
done
if [[ -f $LOCATION/ts3client_startscript.run ]]; then
  rm -rf $LOCATION/*
fi

if [ "$DISCORD" == "false" ]; then

makeDir $LOCATION/teamspeak3-client

chmod 750 -R $LOCATION
chown -R $SINUSBOTUSER:$SINUSBOTUSER $LOCATION
cd $LOCATION/teamspeak3-client

# Downloading TS3-Client files.

if [[ -f CHANGELOG ]] && [ $(cat CHANGELOG | awk '/Client Release/{ print $4; exit }') == $VERSION ]; then
  greenMessage "TS3 ya en su última versión."
else

  greenMessage "Descargando archivos de TS3 Client ."
  su -c "wget -q $DOWNLOAD_URL" $SINUSBOTUSER

  if [[ ! -f TeamSpeak3-Client-linux_$ARCH-$VERSION.run && ! -f ts3client_linux_$ARCH ]]; then
    errorExit "¡Descarga fracasó! saliendo ahora"!
  fi
fi

# Installing TS3-Client.

if [[ -f TeamSpeak3-Client-linux_$ARCH-$VERSION.run ]]; then
  greenMessage "Instalando TS3 Client."
  redMessage "Lee el EULA"!
  sleep 1
  yellowMessage 'Haz lo siguiente: Presiona "ENTER" luego presiona "q" luego presiona "y" y acepta con otro "ENTER".'
  sleep 2

  chmod 777 ./TeamSpeak3-Client-linux_$ARCH-$VERSION.run

  su -c "./TeamSpeak3-Client-linux_$ARCH-$VERSION.run" $SINUSBOTUSER

  cp -R ./TeamSpeak3-Client-linux_$ARCH/* ./
  sleep 2
  rm ./ts3client_runscript.sh
  rm ./TeamSpeak3-Client-linux_$ARCH-$VERSION.run
  rm -R ./TeamSpeak3-Client-linux_$ARCH

  greenMessage "Instalación del cliente TS3 finalizada."
fi
fi

# Downloading latest SinusBot.

cd $LOCATION

greenMessage "Descargando el último SinusBot."

su -c "wget -q https://www.sinusbot.com/dl/sinusbot.current.tar.bz2" $SINUSBOTUSER
if [[ ! -f sinusbot.current.tar.bz2 && ! -f sinusbot ]]; then
  errorExit "Descarga fallida! saliendo ahora"!
fi

# Installing latest SinusBot.

greenMessage "Extracción de archivos SinusBot."
su -c "tar -xjf sinusbot.current.tar.bz2" $SINUSBOTUSER
rm -f sinusbot.current.tar.bz2

if [ "$DISCORD" == "false" ]; then

if [ ! -d teamspeak3-client/plugins/ ]; then
  mkdir teamspeak3-client/plugins/
fi

# Copy the SinusBot plugin into the teamspeak clients plugin directory
cp $LOCATION/plugin/libsoundbot_plugin.so $LOCATION/teamspeak3-client/plugins/

if [[ -f teamspeak3-client/xcbglintegrations/libqxcb-glx-integration.so ]]; then
  rm teamspeak3-client/xcbglintegrations/libqxcb-glx-integration.so
fi
fi

chmod 755 sinusbot

if [ "$INSTALL" == "Inst" ]; then
  greenMessage "SinusBot instalacion hecha."
elif [ "$INSTALL" == "Updt" ]; then
  greenMessage "SinusBot actualizacion hecha."
fi

if [[ "$USE_SYSTEMD" == true ]]; then

  greenMessage "Empezando instalacion de systemd "

  if [[ -f /etc/systemd/system/sinusbot.service ]]; then
    service sinusbot stop
    systemctl disable sinusbot
    rm /etc/systemd/system/sinusbot.service
  fi

  cd /lib/systemd/system/

  wget -q https://raw.githubusercontent.com/Sinusbot/linux-startscript/master/sinusbot.service

  if [ ! -f sinusbot.service ]; then
    errorExit "Descarga fallida! Saliendo ahora"!
  fi

  sed -i 's/User=YOUR_USER/User='$SINUSBOTUSER'/g' /lib/systemd/system/sinusbot.service
  sed -i 's!ExecStart=YOURPATH_TO_THE_BOT_BINARY!ExecStart='$LOCATIONex'!g' /lib/systemd/system/sinusbot.service
  sed -i 's!WorkingDirectory=YOURPATH_TO_THE_BOT_DIRECTORY!WorkingDirectory='$LOCATION'!g' /lib/systemd/system/sinusbot.service

  systemctl daemon-reload
  systemctl enable sinusbot.service

  greenMessage 'Archivo systemd  instalado para lanzar SinusBot con "service sinusbot {start|stop|status|restart}"'

elif [[ "$USE_SYSTEMD" == false ]]; then

  greenMessage "Empezando instalacion de init.d "

  cd /etc/init.d/

  wget -q https://raw.githubusercontent.com/Sinusbot/linux-startscript/obsolete-init.d/sinusbot

  if [ ! -f sinusbot ]; then
    errorExit "Descarga fallida! Saliendo ahora"!
  fi

  sed -i 's/USER="mybotuser"/USER="'$SINUSBOTUSER'"/g' /etc/init.d/sinusbot
  sed -i 's!DIR_ROOT="/opt/ts3soundboard/"!DIR_ROOT="'$LOCATION'/"!g' /etc/init.d/sinusbot

  chmod +x /etc/init.d/sinusbot

  if [[ -f /etc/centos-release ]]; then
    chkconfig sinusbot on >/dev/null
  else
    update-rc.d sinusbot defaults >/dev/null
  fi

  greenMessage 'init.d archivo instalado para lanzar SinusBot con "/etc/init.d/sinusbot {start|stop|status|restart|console|update|backup}"'
fi

cd $LOCATION

if [ "$INSTALL" == "Inst" ]; then
  if [ "$DISCORD" == "false" ]; then
    if [[ ! -f $LOCATION/config.ini ]]; then
      echo 'ListenPort = 8087
      ListenHost = "0.0.0.0"
      TS3Path = "'$LOCATION'/teamspeak3-client/ts3client_linux_amd64"
      YoutubeDLPath = ""' >>$LOCATION/config.ini
      greenMessage "config.ini creado exitosamente."
    else
      redMessage "config.ini ya existe o error de creacion"!
    fi
  else
    if [[ ! -f $LOCATION/config.ini ]]; then
      echo 'ListenPort = 8087
      ListenHost = "0.0.0.0"
      TS3Path = ""
      YoutubeDLPath = ""' >>$LOCATION/config.ini
      greenMessage "config.ini creado exitosamente."
    else
      redMessage "config.ini ya existe  o error de creacion"!
    fi
  fi
fi

#if [[ -f /etc/cron.d/sinusbot ]]; then
#  redMessage "Cronjob already set for SinusBot updater"!
#else
#  greenMessage "Installing Cronjob for automatic SinusBot update..."
#  echo "0 0 * * * $SINUSBOTUSER $LOCATION/sinusbot -update >/dev/null" >>/etc/cron.d/sinusbot
#  greenMessage "Installing SinusBot update cronjob successful."
#fi

# Installing YT-DL.

if [ "$YT" == "Si" ]; then
  greenMessage "Instalando YT-Downlooader ahora"!
  if [ "$(cat /etc/cron.d/ytdl)" == "0 0 * * * $SINUSBOTUSER youtube-dl -U --restrict-filename >/dev/null" ]; then
        rm /etc/cron.d/ytdl
        yellowMessage "Anterior YT-DL eliminado. Generando uno nuevo en un segundo."
  fi
  if [[ -f /etc/cron.d/ytdl ]] && [ "$(grep -c 'youtube' /etc/cron.d/ytdl)" -ge 1 ]; then
    redMessage "Cronjob ya configurado para el actualizador YT-DL"!
  else
    greenMessage "Instalando Cronjob para actualizacion automatica de YT-DL..."
    echo "0 0 * * * $SINUSBOTUSER PATH=$PATH:/usr/local/bin; youtube-dl -U --restrict-filename >/dev/null" >>/etc/cron.d/ytdl
    greenMessage "Instalacion de Cronjob exitosa."
  fi

  sed -i 's/YoutubeDLPath = \"\"/YoutubeDLPath = \"\/usr\/local\/bin\/youtube-dl\"/g' $LOCATION/config.ini

  if [[ -f /usr/local/bin/youtube-dl ]]; then
    rm /usr/local/bin/youtube-dl
  fi

  greenMessage "Descargando YT-DL ahora..."
  wget -q -O /usr/local/bin/youtube-dl http://yt-dl.org/downloads/latest/youtube-dl

  if [ ! -f /usr/local/bin/youtube-dl ]; then
    errorExit "Descarga fallida! Saliendo ahora"!
  else
    greenMessage "Descarga exitosa"!
  fi

  chmod a+rx /usr/local/bin/youtube-dl

  youtube-dl -U --restrict-filename

fi

# Creating Readme

if [ ! -a "$LOCATION/README_installer.txt" ] && [ "$USE_SYSTEMD" == true ]; then
  echo '##################################################################################
# #
# Uso: service sinusbot {start|stop|status|restart} #
# - start: start the bot #
# - stop: stop the bot #
# - status: display the status of the bot (down or up) #
# - restart: restart the bot #
# #
##################################################################################' >>$LOCATION/README_installer.txt
elif [ ! -a "$LOCATION/README_installer.txt" ] && [ "$USE_SYSTEMD" == false ]; then
  echo '##################################################################################
  # #
  # Usage: /etc/init.d/sinusbot {start|stop|status|restart|console|update|backup} #
  # - start: Lanza el bot #
  # - stop:  Detiene el bot#
  # - status: Muestra el estado del bot (abajo o arriba) #
  # - restart: Reinicia el bot #
  # - console: Muestra la consola del bot #
  # - update: Ejecuta el actualizador del bot (con start & stop)
  # - backup: Archiva tu bot en la direccion root
  # To exit the console without stopping the server, press CTRL + A then D. #
  # #
  ##################################################################################' >>$LOCATION/README_installer.txt
fi

greenMessage "README_installer.txt generado"!

# Delete files if exists

if [[ -f /tmp/.sinusbot.lock ]]; then
  rm /tmp/.sinusbot.lock
  greenMessage "Direccion /tmp/.sinusbot.lock eliminada"
fi

if [ -e /tmp/.X11-unix/X40 ]; then
  rm /tmp/.X11-unix/X40
  greenMessage "Direccion /tmp/.X11-unix/X40 eliminada"
fi

# Starting SinusBot first time!

if [ "$INSTALL" != "Updt" ]; then
  greenMessage 'Iniciando SinusBot. For first time.'
  chown -R $SINUSBOTUSER:$SINUSBOTUSER $LOCATION
  cd $LOCATION

  # Password variable

  export Q=$(su $SINUSBOTUSER -c './sinusbot --initonly')
  password=$(export | awk '/password/{ print $10 }' | tr -d "'")
  if [ -z "$password" ]; then
    errorExit "Fallo al leer la contraseña, prueba con reinstalar de nuevo."
  fi

  chown -R $SINUSBOTUSER:$SINUSBOTUSER $LOCATION

  # Starting bot
  greenMessage "Iniciando SinusBot de nuevo."
fi

if [[ "$USE_SYSTEMD" == true ]]; then
  service sinusbot start
elif [[ "$USE_SYSTEMD" == false ]]; then
  /etc/init.d/sinusbot start
fi
yellowMessage "Porfavor espere... Esto tomara unos segundos"!
chown -R $SINUSBOTUSER:$SINUSBOTUSER $LOCATION

if [[ "$USE_SYSTEMD" == true ]]; then
  sleep 5
elif [[ "$USE_SYSTEMD" == false ]]; then
  sleep 10
fi

if [[ -f /etc/centos-release ]]; then
  if [ "$FIREWALL" == "ip" ]; then
    iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 8087 -j ACCEPT
  elif [ "$FIREWALL" == "fs" ]; then
    if rpm -q --quiet firewalld; then
      zone=$(firewall-cmd --get-active-zones | awk '{print $1; exit}')
      firewall-cmd --zone=$zone --add-port=8087/tcp --permanent >/dev/null
      firewall-cmd --reload >/dev/null
    fi
  fi
fi

# If startup failed, the script will start normal sinusbot without screen for looking about errors. If startup successed => installation done.
IS_RUNNING=false
if [[ "$USE_SYSTEMD" == true ]]; then
  if [[ $(systemctl is-active sinusbot >/dev/null && echo UP || echo DOWN) == "UP" ]]; then
    IS_RUNNING=true
  fi
elif [[ "$USE_SYSTEMD" == false ]]; then
  if [[ $(/etc/init.d/sinusbot status | awk '{print $NF; exit}') == "UP" ]]; then
     IS_RUNNING=true
  fi
fi

if [[ "$IS_RUNNING" == true ]]; then
  if [[ $INSTALL == "Inst" ]]; then
    greenMessage "Instalacion completada"!
  elif [[ $INSTALL == "Updt" ]]; then
    greenMessage "Actualizacion completada"!
  fi

  if [[ ! -f $LOCATION/README_installer.txt ]]; then
    yellowMessage "Generé un README_installer.txt en $LOCATION con todos los comandos para el sinusbot..."
  fi

  if [[ $INSTALL == "Updt" ]]; then
    if [[ -f /lib/systemd/system/sinusbot.service ]]; then
      service sinusbot restart
      greenMessage "Reinicie su bot con systemd."
    fi
    if [[ -f /etc/init.d/sinusbot ]]; then
      /etc/init.d/sinusbot restart
      greenMessage "Reinicie su bot con initd."
    fi
    greenMessage "Está bien. Todo se actualiza con éxito. SinusBot está lanzado en '$ipaddress:8087' :)"
  else
    greenMessage "Está bien. Todo se instala correctamente. SinusBot está lanzado en '$ipaddress:8087' :) Your user = 'admin' and password = '$password'"
  fi
  if [[ "$USE_SYSTEMD" == true ]]; then
    redMessage 'Detenlo con "service sinusbot stop".'
  elif [[ "$USE_SYSTEMD" == false ]]; then
    redMessage 'Detenlo con "/etc/init.d/sinusbot stop".'
  fi
  magentaMessage "No olvides calificar este script en: https://forum.sinusbot.com/resources/sinusbot-installer-script.58/"
  greenMessage "!Gracias por usar el script!:)"

else
  redMessage "¡SinusBot no pudo iniciarse! Iniciándolo directamente. Buscar errores"!
  su -c "$LOCATION/sinusbot" $SINUSBOTUSER
fi

exit 0
