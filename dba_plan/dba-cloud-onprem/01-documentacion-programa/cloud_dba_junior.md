# Cloud DBA Junior
### 1. Conceptos básicos de bases de datos (independientes del motor)
#### Modelo relacional y NoSQL
Diferencias entre bases relacionales (MySQL/PostgreSQL) y NoSQL (DocumentDB).
Concepto de tablas, índices, claves primarias/foráneas, colecciones y documentos.


#### Operaciones CRUD
Crear, leer, actualizar y borrar datos.
Uso básico de SELECT, INSERT, UPDATE, DELETE en SQL.
Operaciones básicas en DocumentDB con comandos similares a MongoDB (find, insertOne).


#### Índices y rendimiento
Qué son los índices, tipos comunes (BTREE, Hash).
Impacto en consultas y escritura.


##### Integridad y normalización
Entender conceptos de normalización y cuándo desnormalizar.


#### 2. Conocimientos básicos de MySQL
Instalación y conexión básica (cliente CLI, GUI).
Diferencias entre motores de almacenamiento (InnoDB vs MyISAM).
Backups y restauración con mysqldump o MySQL Shell (dumpInstance, loadDump).
Parámetros básicos (max_connections, innodb_buffer_pool_size).
Monitoreo de estado con SHOW STATUS, SHOW PROCESSLIST.


#### 3. Conocimientos básicos de PostgreSQL
Conexión básica con psql (autenticación, SSL).
Roles y privilegios: CREATE ROLE, GRANT, REVOKE.
Backups con pg_dump, restauración con pg_restore.
Uso de esquemas (public, custom schemas).
Monitoreo básico: pg_stat_activity, pg_stat_statements.
Parámetros comunes (work_mem, shared_buffers).


#### 4. Conocimientos básicos de DocumentDB (MongoDB compatible)
Diferencias con MongoDB tradicional (limitaciones de DocumentDB).
Conexión usando mongosh.
Operaciones básicas: db.collection.find(), insertOne, updateOne.
Índices en DocumentDB (createIndex).
Backups automáticos y snapshots en AWS DocumentDB.


#### 5. Conocimientos básicos de Cloud (AWS enfocado a bases de datos)
RDS y DocumentDB en AWS
Crear instancias, configurarlas (CPU, RAM, almacenamiento).
Parámetros en grupos de parámetros (DB Parameter Groups).
Backups automáticos y snapshots manuales.
Escalado vertical (modificar tamaño) y horizontal (read replicas).
Endpoints de conexión (writer/read replicas).


### Seguridad
Configuración de VPC, subnets y security groups.
Uso de Secrets Manager para contraseñas.
Roles IAM básicos para acceso a RDS/DocumentDB.


#### Monitoreo y alertas
Métricas básicas en CloudWatch: CPU, conexiones, IOPS, almacenamiento.
Configuración de alarmas simples (CPU alta, storage casi lleno).


#### 6. Automatización e Infraestructura como Código
Terraform básico
Variables y terraform apply/plan/destroy.
Comprender recursos de RDS (aws_db_instance, aws_db_parameter_group).
Concepto de state y outputs.


#### Uso de Git
Clonar repos, hacer commits, push/pull.


7. Operaciones diarias y soporte
Crear usuarios y asignar roles (readonly/readwrite).
Ejecutar queries de diagnóstico para performance y locking.
Identificar problemas básicos de conexión (firewall, credenciales).
Verificar backups y restauraciones simples.
Documentar cambios y procedimientos.


8. Buenas prácticas y golden rules iniciales
No exponer RDS o DocumentDB a internet.
Habilitar backups automáticos y encriptación (KMS).
Usar roles IAM en vez de credenciales hardcodeadas.
Monitorear espacio y conexiones.
Mantener versiones soportadas y planificar upgrades.
1. Temario:
Semana 1 – Fundamentos de bases de datos y Cloud
Conceptos a enseñar:
Diferencia entre bases relacionales y NoSQL (PostgreSQL/MySQL vs DocumentDB).
Conceptos de tablas, índices, claves primarias/foráneas, esquemas y colecciones.
Arquitectura básica de RDS y DocumentDB en AWS.
Endpoints y tipos de endpoints (writer, reader).
Backups automáticos y snapshots manuales.


Prácticas:
Conectarse vía CLI (psql, mysql, mongosh) a instancias de RDS/DocumentDB.
Identificar y explicar los componentes principales de una instancia RDS en la consola.


Semana 2 – MySQL y PostgreSQL básicos
Conceptos a enseñar:
Crear usuarios y roles, asignar permisos (GRANT/REVOKE).
Comandos CRUD básicos.
Backups con mysqldump, pg_dump y restauraciones.
Monitoreo básico: SHOW PROCESSLIST, pg_stat_activity.
Parámetros básicos: max_connections, innodb_buffer_pool_size, work_mem.


Prácticas:
Crear un usuario readonly y readwrite en PostgreSQL y MySQL.
Crear y restaurar un backup sencillo.
Identificar conexiones activas y consultas lentas.


Semana 3 – DocumentDB y Seguridad en AWS
Conceptos a enseñar:
Conexión a DocumentDB con mongosh.
Operaciones básicas en colecciones (find, insertOne, updateOne).
Limitaciones vs MongoDB nativo.
Seguridad: Security Groups, VPC, IAM Roles y Secrets Manager.
Encriptación con KMS.


Prácticas:
Conectar y crear una colección en DocumentDB.
Configurar un usuario con acceso limitado.
Validar que la instancia esté encriptada y en red privada.


Semana 4 – Automatización, Monitoreo y Buenas Prácticas
Conceptos a enseñar:
Terraform básico: terraform plan/apply/destroy.
Despliegue de RDS con aws_db_instance y grupos de parámetros.
Métricas clave en CloudWatch (CPU, conexiones, almacenamiento, IOPS).
Alertas y notificaciones básicas (SNS o Slack).
Golden rules: backups habilitados, no público, encriptación activa.


Prácticas:
Desplegar un RDS MySQL usando Terraform.
Crear una alarma de CPU alta en CloudWatch.
Verificar cumplimiento de golden rules en una instancia real.




2. Evaluación
Evaluación semanal
Semana 1:


Preguntas orales/escritas: diferencias RDS vs DocumentDB, endpoint writer vs reader.
Ejercicio: Conectarse a una instancia y mostrar bases de datos disponibles.


Semana 2:


Preguntas: Diferencias GRANT vs REVOKE, cómo hacer backup en PostgreSQL.
Ejercicio práctico: Crear usuario readonly y restaurar backup simple.


Semana 3:


Preguntas: ¿Qué diferencia hay entre MongoDB y DocumentDB? ¿Qué es un Security Group?
Ejercicio: Conectar a DocumentDB y listar colecciones.


Semana 4:


Preguntas: ¿Qué métricas monitorearías en RDS? ¿Qué es un parameter group?
Ejercicio: Deploy básico con Terraform y crear una alarma en CloudWatch.


Evaluación final (práctica)
Crear una base de datos en RDS con Terraform (MySQL o PostgreSQL).
Configurar un usuario readonly.
Generar y restaurar un backup.
Conectar a DocumentDB y hacer operaciones CRUD simples.
Validar métricas y golden rules (backups habilitados, encriptación, acceso privado).



3. Criterios de aprobación
Teórico: Responde al menos el 70% de las preguntas de conceptos.
Práctico: Ejecuta de manera autónoma los pasos básicos (conexión, backup, usuario, monitoreo).
Cloud: Demuestra comprensión de seguridad (no público, uso de roles, backups automáticos).


