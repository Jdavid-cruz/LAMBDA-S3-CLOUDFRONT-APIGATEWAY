Proyecto: Registro de usuarios usando Lambda + S3 + API Gateway + CloudFront

Este proyecto lo hice para seguir practicando arquitectura moderna en AWS, pero esta vez usando solo servicios serverless. Desplegué todo con Terraform y el objetivo fue crear una pequeña aplicación web donde los usuarios se registran a través de un formulario, y los datos son procesados por una función Lambda.

Todo se entrega con un bucket S3 para el frontend, distribuido con CloudFront, y expuesto por medio de API Gateway que conecta con la Lambda.

Tecnologías utilizadas

    AWS Lambda para ejecutar el backend sin servidor

    Amazon S3 para alojar el frontend (HTML + CSS)

    Amazon CloudFront para distribuir el contenido estático con mejor rendimiento

    API Gateway para exponer la función Lambda mediante HTTP

    DynamoDB para guardar los registros de usuarios

    Terraform para automatizar todo el despliegue

    HTML + CSS para el formulario

    Python para la función Lambda

Estructura del proyecto

lambda-s3-cloudfront-api/
├── index.html              -> Formulario principal
├── styles.css              -> Estilos del formulario
├── error.html              -> Vista de error
├── success.html            -> Vista de éxito
├── lambda_function.py      -> Lógica en Python de la Lambda
├── main.tf                 -> Infraestructura definida con Terraform
├── .gitignore              -> Archivos ignorados
└── README.md               -> Este archivo

Arquitectura

    El frontend estático se sube a un bucket S3

    S3 está protegido y solo accesible mediante CloudFront

    El formulario HTML envía los datos vía fetch() a una URL de API Gateway

    API Gateway recibe la petición y la pasa a la función Lambda

    Lambda procesa los datos y los guarda en DynamoDB

Todo esto está definido y desplegado con Terraform.

Despliegue paso a paso

    Ejecutar terraform init y luego terraform apply

    Subir el contenido estático (HTML y CSS) al bucket S3 con aws s3 sync

    Obtener la URL de CloudFront desde Terraform output

    Probar el registro desde el navegador

Enlace al repositorio

👉 https://github.com/Jdavid-cruz/lambda-s3-cloudfront-api (una vez creado)

Objetivo

Este proyecto es parte de mi portafolio como futuro Administrador Cloud y Arquitecto de Soluciones en AWS. Quise demostrar que sé trabajar con servicios serverless y puedo automatizar el despliegue completo con Terraform de una app funcional, segura y optimizada