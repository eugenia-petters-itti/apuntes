#!/bin/bash

# DBA Cloud OnPrem Junior - Script de Configuración Rápida
# Este script configura automáticamente todo el entorno de laboratorio
# Versión: 1.0

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
echo "=============================================="
echo "  DBA CLOUD ONPREM JUNIOR - SETUP RÁPIDO"
echo "=============================================="
echo -e "${NC}"
echo ""
echo -e "${YELLOW}Este script configurará automáticamente tu entorno de laboratorio${NC}"
echo -e "${YELLOW}Tiempo estimado: 30-45 minutos${NC}"
echo ""

# Función para logging
log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Función para verificar si comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Función para verificar prerequisitos
check_prerequisites() {
    log "Verificando prerequisitos..."
    
    local missing_tools=()
    
    # Verificar herramientas básicas
    if ! command_exists git; then
        missing_tools+=("git")
    fi
    
    if ! command_exists curl; then
        missing_tools+=("curl")
    fi
    
    if ! command_exists wget; then
        missing_tools+=("wget")
    fi
    
    # Verificar virtualización
    if ! command_exists VBoxManage && ! command_exists vmware; then
        missing_tools+=("virtualbox o vmware")
    fi
    
    # Verificar RAM
    local ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$ram_gb" -lt 16 ]; then
        error "RAM insuficiente: ${ram_gb}GB (mínimo 16GB)"
        return 1
    fi
    
    # Verificar espacio en disco
    local disk_gb=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
    if [ "$disk_gb" -lt 100 ]; then
        error "Espacio en disco insuficiente: ${disk_gb}GB (mínimo 100GB)"
        return 1
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        error "Herramientas faltantes: ${missing_tools[*]}"
        return 1
    fi
    
    log "Prerequisitos verificados correctamente"
    return 0
}

# Función para instalar herramientas faltantes
install_tools() {
    log "Instalando herramientas necesarias..."
    
    # Detectar distribución
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu
        sudo apt update
        
        if ! command_exists git; then
            sudo apt install -y git
        fi
        
        if ! command_exists curl; then
            sudo apt install -y curl
        fi
        
        if ! command_exists wget; then
            sudo apt install -y wget
        fi
        
        # Instalar herramientas adicionales
        sudo apt install -y vim htop tree net-tools unzip
        
    elif [ -f /etc/redhat-release ]; then
        # RHEL/CentOS
        sudo yum update -y
        sudo yum install -y git curl wget vim htop tree net-tools unzip
        
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if ! command_exists brew; then
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        
        brew install git curl wget vim htop tree
    fi
    
    log "Herramientas instaladas correctamente"
}

# Función para instalar AWS CLI
install_aws_cli() {
    log "Instalando AWS CLI v2..."
    
    if command_exists aws; then
        local aws_version=$(aws --version 2>&1 | cut -d/ -f2 | cut -d' ' -f1)
        if [[ $aws_version == 2.* ]]; then
            log "AWS CLI v2 ya está instalado"
            return 0
        fi
    fi
    
    # Instalar AWS CLI v2
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
        sudo installer -pkg AWSCLIV2.pkg -target /
        rm AWSCLIV2.pkg
    fi
    
    log "AWS CLI v2 instalado correctamente"
}

# Función para instalar Terraform
install_terraform() {
    log "Instalando Terraform..."
    
    if command_exists terraform; then
        log "Terraform ya está instalado"
        return 0
    fi
    
    # Instalar Terraform
    local terraform_version="1.6.0"
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        wget https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip
        unzip terraform_${terraform_version}_linux_amd64.zip
        sudo mv terraform /usr/local/bin/
        rm terraform_${terraform_version}_linux_amd64.zip
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install terraform
    fi
    
    log "Terraform instalado correctamente"
}

# Función para configurar AWS
configure_aws() {
    log "Configurando AWS CLI..."
    
    if [ -f ~/.aws/credentials ]; then
        info "AWS ya está configurado. ¿Deseas reconfigurarlo? (y/n)"
        read -r response
        if [[ ! $response =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    echo ""
    echo -e "${YELLOW}Necesitas tus credenciales de AWS:${NC}"
    echo "1. Ve a AWS Console > IAM > Users > [tu usuario] > Security credentials"
    echo "2. Crea un nuevo Access Key si no tienes uno"
    echo ""
    
    read -p "AWS Access Key ID: " aws_access_key
    read -s -p "AWS Secret Access Key: " aws_secret_key
    echo ""
    
    # Configurar AWS CLI
    mkdir -p ~/.aws
    
    cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = $aws_access_key
aws_secret_access_key = $aws_secret_key
EOF
    
    cat > ~/.aws/config << EOF
[default]
region = us-east-1
output = json
EOF
    
    chmod 600 ~/.aws/credentials ~/.aws/config
    
    # Verificar configuración
    if aws sts get-caller-identity >/dev/null 2>&1; then
        log "AWS configurado correctamente"
    else
        error "Error en la configuración de AWS"
        return 1
    fi
}

# Función para descargar materiales del curso
download_materials() {
    log "Descargando materiales del curso..."
    
    # Crear directorio de trabajo
    mkdir -p ~/dba-lab
    cd ~/dba-lab
    
    # Descargar scripts de instalación
    mkdir -p scripts
    cd scripts
    
    info "Descargando scripts de instalación..."
    # Aquí irían los comandos para descargar los scripts reales
    # Por ahora, creamos placeholders
    
    cat > install_mysql_onprem.sh << 'EOF'
#!/bin/bash
echo "Script de instalación MySQL OnPrem"
# Contenido del script real iría aquí
EOF
    
    cat > install_postgresql_onprem.sh << 'EOF'
#!/bin/bash
echo "Script de instalación PostgreSQL OnPrem"
# Contenido del script real iría aquí
EOF
    
    cat > install_mongodb_onprem.sh << 'EOF'
#!/bin/bash
echo "Script de instalación MongoDB OnPrem"
# Contenido del script real iría aquí
EOF
    
    chmod +x *.sh
    
    cd ..
    
    # Descargar datasets
    mkdir -p datasets
    cd datasets
    
    info "Descargando datasets..."
    # Placeholders para datasets
    touch mysql_ecommerce_dataset.sql
    touch postgresql_analytics_dataset.sql
    touch mongodb_social_dataset.js
    
    cd ..
    
    # Descargar scripts de verificación
    mkdir -p verification
    cd verification
    
    info "Descargando scripts de verificación..."
    
    # Copiar scripts de verificación desde el material
    cp ../../../scripts_autoevaluacion.md ./
    
    cd ~/dba-lab
    
    log "Materiales descargados en ~/dba-lab"
}

# Función para configurar VirtualBox
setup_virtualbox() {
    log "Configurando VirtualBox..."
    
    if ! command_exists VBoxManage; then
        warning "VirtualBox no está instalado. Instalando..."
        
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Debian/Ubuntu
            if [ -f /etc/debian_version ]; then
                sudo apt update
                sudo apt install -y virtualbox virtualbox-ext-pack
            # RHEL/CentOS
            elif [ -f /etc/redhat-release ]; then
                sudo yum install -y VirtualBox
            fi
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install --cask virtualbox
        fi
    fi
    
    # Crear red host-only si no existe
    if ! VBoxManage list hostonlyifs | grep -q "vboxnet0"; then
        log "Creando red host-only..."
        VBoxManage hostonlyif create
        VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 --netmask 255.255.255.0
    fi
    
    log "VirtualBox configurado correctamente"
}

# Función para descargar Ubuntu ISO
download_ubuntu_iso() {
    log "Descargando Ubuntu 20.04 LTS ISO..."
    
    local iso_path="$HOME/dba-lab/ubuntu-20.04.6-live-server-amd64.iso"
    
    if [ -f "$iso_path" ]; then
        log "Ubuntu ISO ya existe"
        return 0
    fi
    
    mkdir -p "$(dirname "$iso_path")"
    
    info "Descargando Ubuntu 20.04 LTS (esto puede tomar varios minutos)..."
    wget -O "$iso_path" "https://releases.ubuntu.com/20.04/ubuntu-20.04.6-live-server-amd64.iso"
    
    if [ $? -eq 0 ]; then
        log "Ubuntu ISO descargado correctamente"
    else
        error "Error descargando Ubuntu ISO"
        return 1
    fi
}

# Función para crear VMs
create_vms() {
    log "Creando VMs de laboratorio..."
    
    local vms=("DBA-Lab-MySQL" "DBA-Lab-PostgreSQL" "DBA-Lab-MongoDB" "DBA-Lab-Tools")
    local ips=("192.168.56.10" "192.168.56.11" "192.168.56.12" "192.168.56.13")
    
    for i in "${!vms[@]}"; do
        local vm_name="${vms[$i]}"
        local vm_ip="${ips[$i]}"
        
        info "Creando VM: $vm_name"
        
        # Verificar si la VM ya existe
        if VBoxManage list vms | grep -q "\"$vm_name\""; then
            warning "VM $vm_name ya existe, saltando..."
            continue
        fi
        
        # Crear VM
        VBoxManage createvm --name "$vm_name" --ostype "Ubuntu_64" --register
        
        # Configurar VM
        VBoxManage modifyvm "$vm_name" \
            --memory 4096 \
            --cpus 2 \
            --vram 16 \
            --boot1 dvd \
            --boot2 disk \
            --boot3 none \
            --boot4 none \
            --acpi on \
            --ioapic on \
            --rtcuseutc on
        
        # Crear disco duro
        local vdi_path="$HOME/VirtualBox VMs/$vm_name/$vm_name.vdi"
        VBoxManage createhd --filename "$vdi_path" --size 25600 --format VDI
        
        # Configurar controladores de almacenamiento
        VBoxManage storagectl "$vm_name" --name "SATA Controller" --add sata --controller IntelAhci
        VBoxManage storageattach "$vm_name" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$vdi_path"
        
        # Configurar red
        VBoxManage modifyvm "$vm_name" --nic1 nat --nic2 hostonly --hostonlyadapter2 vboxnet0
        
        log "VM $vm_name creada correctamente"
    done
    
    log "Todas las VMs creadas correctamente"
}

# Función para generar reporte final
generate_report() {
    log "Generando reporte de configuración..."
    
    local report_file="$HOME/dba-lab/setup_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "DBA CLOUD ONPREM JUNIOR - REPORTE DE CONFIGURACIÓN"
        echo "Fecha: $(date)"
        echo "Usuario: $(whoami)"
        echo "Host: $(hostname)"
        echo ""
        
        echo "HERRAMIENTAS INSTALADAS:"
        echo "======================="
        echo "Git: $(git --version 2>/dev/null || echo 'No instalado')"
        echo "AWS CLI: $(aws --version 2>/dev/null || echo 'No instalado')"
        echo "Terraform: $(terraform --version 2>/dev/null | head -1 || echo 'No instalado')"
        echo "VirtualBox: $(VBoxManage --version 2>/dev/null || echo 'No instalado')"
        echo ""
        
        echo "RECURSOS DEL SISTEMA:"
        echo "===================="
        echo "CPU Cores: $(nproc)"
        echo "RAM Total: $(free -h | awk '/^Mem:/{print $2}')"
        echo "Disco Libre: $(df -h / | awk 'NR==2{print $4}')"
        echo ""
        
        echo "VMs CREADAS:"
        echo "============"
        VBoxManage list vms | grep "DBA-Lab" || echo "Ninguna VM DBA-Lab encontrada"
        echo ""
        
        echo "CONFIGURACIÓN AWS:"
        echo "=================="
        if aws sts get-caller-identity >/dev/null 2>&1; then
            echo "AWS configurado correctamente"
            aws sts get-caller-identity
        else
            echo "AWS no configurado o sin acceso"
        fi
        echo ""
        
        echo "ARCHIVOS DESCARGADOS:"
        echo "===================="
        find ~/dba-lab -type f -name "*.sh" -o -name "*.sql" -o -name "*.js" -o -name "*.iso" 2>/dev/null || echo "Ningún archivo encontrado"
        
    } > "$report_file"
    
    log "Reporte generado: $report_file"
    
    echo ""
    echo -e "${GREEN}=============================================="
    echo "  CONFIGURACIÓN COMPLETADA EXITOSAMENTE"
    echo "===============================================${NC}"
    echo ""
    echo -e "${YELLOW}PRÓXIMOS PASOS:${NC}"
    echo "1. Revisar el reporte: cat $report_file"
    echo "2. Instalar Ubuntu en las VMs creadas"
    echo "3. Seguir la guía: guia_estudiante_paso_a_paso.md"
    echo "4. Ejecutar verificación: ./check_overall_progress.sh"
    echo ""
    echo -e "${BLUE}DIRECTORIO DE TRABAJO: ~/dba-lab${NC}"
    echo -e "${BLUE}MATERIALES DEL CURSO: ~/dba-lab/scripts${NC}"
    echo -e "${BLUE}DATASETS: ~/dba-lab/datasets${NC}"
    echo ""
}

# Función principal
main() {
    echo -e "${PURPLE}Iniciando configuración automática...${NC}"
    echo ""
    
    # Verificar prerequisitos
    if ! check_prerequisites; then
        error "Prerequisitos no cumplidos. Abortando."
        exit 1
    fi
    
    # Instalar herramientas
    install_tools
    install_aws_cli
    install_terraform
    
    # Configurar AWS
    configure_aws
    
    # Descargar materiales
    download_materials
    
    # Configurar VirtualBox
    setup_virtualbox
    
    # Descargar Ubuntu ISO
    download_ubuntu_iso
    
    # Crear VMs
    create_vms
    
    # Generar reporte
    generate_report
}

# Verificar si se ejecuta como script principal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
