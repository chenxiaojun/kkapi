json.partial! 'common/basic', api_result: ApiResult.success_result

json.data do
  json.partial! 'v1/merchant/users/user_base', user: @current_user
end
