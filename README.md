Proyecto: Registro de usuarios usando Lambda, S3, API Gateway y DynamoDB

Este proyecto lo hice para seguir practicando arquitectura moderna en AWS, pero esta vez usando solo servicios serverless. El objetivo fue crear una aplicación sencilla donde los usuarios se registran a través de un formulario web, y esos datos son procesados por una función Lambda que los guarda en DynamoDB.

Todo el backend está construido con Lambda y expuesto a través de API Gateway. El frontend (formulario HTML + CSS) está alojado en un bucket S3. Todo el despliegue lo hice usando Terraform para automatizar desde la infraestructura hasta los permisos.

Además, utilicé IAM para crear un rol que le da permiso a la Lambda de escribir en DynamoDB. Definí ese rol y su política directamente en el código de Terraform, y lo asocié a la función Lambda.

Tecnologías utilizadas:

    AWS Lambda para ejecutar el backend sin servidores

    Amazon S3 para alojar los archivos HTML y CSS

    API Gateway para recibir las peticiones del formulario

    DynamoDB para almacenar los registros de usuario

    IAM para gestionar los permisos que Lambda necesita

    Terraform para definir y desplegar toda la infraestructura

    HTML y CSS para la interfaz del formulario

    Python para escribir la función Lambda

Cómo funciona todo:

El formulario envía los datos con fetch() a una URL de API Gateway. Esa URL está conectada con una función Lambda que toma los datos, los valida y los guarda en la tabla DynamoDB. Para que Lambda tenga permisos de acceso a la base de datos, le asocié un rol IAM con una política que permite hacer PutItem en la tabla.

Todo esto está desplegado con Terraform. Desde la tabla DynamoDB, hasta el rol IAM, la Lambda y la configuración de API Gateway.

Pasos para desplegarlo:

    Ejecutar terraform init y luego terraform apply para crear todos los recursos

    Subir el contenido HTML y CSS al bucket S3 con aws s3 sync

    Obtener la URL de API Gateway desde Terraform output

    Abrir el formulario desde el navegador y probar el registro

Este proyecto forma parte de mi portafolio como futuro administrador cloud y arquitecto de soluciones en AWS. Lo hice para demostrar que puedo trabajar con servicios serverless, automatizar toda la infraestructura con Terraform y aplicar buenas prácticas de seguridad, como el uso de IAM para permisos mínimos necesarios.


