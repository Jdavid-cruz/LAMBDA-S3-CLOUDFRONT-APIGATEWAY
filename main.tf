# Empezamos declarando el proveedor: en este caso trabajamos con AWS y en la región us-east-1
provider "aws" {
  region = "us-east-1"
}

# Creamos una tabla DynamoDB llamada "users" donde se guardarán los registros
resource "aws_dynamodb_table" "users" {
  name         = "users"
  billing_mode = "PAY_PER_REQUEST"  # Pagamos solo por uso, ideal para este tipo de apps
  hash_key     = "email"            # El campo "email" será la clave primaria

  attribute {
    name = "email"
    type = "S"  # S de String
  }

  tags = {
    Name = "RegistroUsuariosLambda"
  }
}

# Mostramos el nombre de la tabla cuando termine el apply
output "dynamodb_table_name" {
  value = aws_dynamodb_table.users.name
}

# Rol que va a usar Lambda para ejecutarse
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

# Le damos permisos a Lambda para que pueda insertar datos en la tabla DynamoDB
resource "aws_iam_role_policy" "lambda_dynamo_policy" {
  name = "lambda_dynamo_policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem"
        ],
        Resource = "arn:aws:dynamodb:us-east-1:*:table/users"
      }
    ]
  })
}

# Definimos la función Lambda, indicando dónde está el código y con qué permisos se ejecuta
resource "aws_lambda_function" "user_registration" {
  function_name = "user_registration_lambda"
  runtime       = "python3.12"
  handler       = "lambda_function.lambda_handler"

  filename         = "${path.module}/lambda_function.zip"  # Ruta del ZIP con el código
  source_code_hash = filebase64sha256("lambda_function.zip")

  role = aws_iam_role.lambda_exec_role.arn

  environment {
    variables = {
      TABLE_NAME = "users"
    }
  }
}

# Creamos una API Gateway HTTP que vamos a usar para recibir las solicitudes
resource "aws_apigatewayv2_api" "http_api" {
  name          = "registro-http-api"
  protocol_type = "HTTP"
}

# Conectamos la API Gateway con Lambda usando integración tipo proxy
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                  = aws_apigatewayv2_api.http_api.id
  integration_type        = "AWS_PROXY"
  integration_uri         = aws_lambda_function.user_registration.invoke_arn
  integration_method      = "POST"
  payload_format_version  = "2.0"
}

# Creamos la ruta POST /register para manejar los registros desde el formulario
resource "aws_apigatewayv2_route" "register_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /register"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Ruta para OPTIONS /register, necesaria para que CORS funcione correctamente
resource "aws_apigatewayv2_route" "register_options" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "OPTIONS /register"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Creamos el stage por defecto y activamos auto-deploy para que no tengamos que hacer deploy manual
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000
  }
}

# Permitimos que API Gateway invoque nuestra función Lambda
resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.user_registration.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

# Mostramos la URL pública de la API cuando termine el apply
output "api_gateway_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}
