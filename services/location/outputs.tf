output "http_api_id" { value = aws_apigatewayv2_api.http.id }
output "http_api_endpoint" { value = aws_apigatewayv2_api.http.api_endpoint }
output "stage_name" { value = aws_apigatewayv2_stage.dev.name }

