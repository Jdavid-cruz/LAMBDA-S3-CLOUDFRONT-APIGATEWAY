# Indicamos el proveedor de nube que usaremos (en este caso, AWS)
provider "aws" {
  region = "us-east-1"  # Región de AWS donde se desplegarán los recursos (puedes cambiarla si quieres)
}




# Creamos una tabla en DynamoDB llamada "users"
resource "aws_dynamodb_table" "users" {
  name         = "users"               # Nombre de la tabla en DynamoDB
  billing_mode = "PAY_PER_REQUEST"     # Modelo de pago: solo pagas por lo que usas (ideal para este caso)
  hash_key     = "email"               # Clave primaria de la tabla (DynamoDB necesita al menos una)

  # Definimos los atributos de la tabla
  attribute {
    name = "email"   # Nombre del campo que será clave primaria
    type = "S"       # Tipo de dato: "S" = String (cadena de texto)
  }

  # Etiquetas (tags) que se añaden al recurso para identificación
  tags = {
    Name = "RegistroUsuariosLambda"  # Nombre lógico del proyecto (puede ayudarte a organizarte en AWS)
  }
}



# Mostramos el nombre de la tabla al final del terraform apply
output "dynamodb_table_name" {
  value = aws_dynamodb_table.users.name
}





# Rol que usará Lambda
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}


# Aquí estoy creando una política en línea que adjunto al rol que usará mi función Lambda.
# Esta política le da permiso para insertar datos en mi tabla de DynamoDB.

resource "aws_iam_role_policy" "lambda_dynamo_policy" {
  name = "lambda_dynamo_policy"  # Nombre que le pongo a esta política (interno en AWS)

  # A esta política le asigno el rol que creé antes para Lambda
  role = aws_iam_role.lambda_exec_role.id

  # Defino el contenido de la política usando jsonencode (Terraform lo convierte en JSON)
  policy = jsonencode({
    Version = "2012-10-17",  # Versión estándar que AWS siempre pide en las políticas

    Statement = [            # Aquí comienza la declaración de permisos
      {
        Effect = "Allow",    # Le digo a AWS que PERMITA esta acción (no la deniegue)
        
        Action = [           # ¿Qué acciones puede hacer Lambda?
          "dynamodb:PutItem" # Puede insertar ítems en una tabla DynamoDB
        ],
        
        Resource = "arn:aws:dynamodb:us-east-1:*:table/users"
        # Esta acción solo se permite sobre la tabla "users" en la región us-east-1
        # El * significa que vale para cualquier cuenta (aunque podría especificar mi cuenta exacta si quiero)
      }
    ]
  })
}




resource "aws_lambda_function" "user_registration" {
  function_name = "user_registration_lambda"           # Nombre de la función en AWS
  runtime       = "python3.12"                         # Entorno de ejecución
  handler       = "lambda_function.lambda_handler"     # Archivo y función que se ejecuta

  filename         = "${path.module}/lambda_function.zip"       # Ruta del archivo ZIP
  source_code_hash = filebase64sha256("lambda_function.zip")    # Para detectar cambios en el código

  role = aws_iam_role.lambda_exec_role.arn             # Rol con permisos a DynamoDB

  environment {
    variables = {
      TABLE_NAME = "users"                             # Nombre de la tabla como variable de entorno
    }
  }
}






# Crear la API Gateway
resource "aws_apigatewayv2_api" "http_api" {
  name          = "registro-http-api"
  protocol_type = "HTTP"
}

# Crear la integración con Lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.user_registration.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}





resource "aws_apigatewayv2_route" "register_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /register"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"

}




# Ruta para OPTIONS /register (necesaria para CORS)
resource "aws_apigatewayv2_route" "register_options" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "OPTIONS /register"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}




resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  # ✅ Aquí es donde realmente se configura CORS
  default_route_settings {
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000
  }

}





resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.user_registration.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}




output "api_gateway_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

