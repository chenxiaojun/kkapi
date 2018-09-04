module V1::Merchant
  class AccountController < MerchantApplicationController
    def register
      requires! :mobile
      requires! :vcode
      requires! :nick_name
      raise_error 'vcode_not_match' unless VCode.check_vcode('register', full_mobile, params[:vcode])
      raise_error 'mobile_already_used' if MerchantUser.mobile_exist?(params[:mobile])
      @user = MerchantUser.create_by_mobile(params[:mobile], params[:ext], params[:nick_name])
      @access_token = UserToken.encode(@user.user_uuid)
      render :login
    end

    def login
      requires! :mobile
      requires! :vcode
      @user = MerchantUser.by_mobile(params[:mobile])
      raise_error 'user_not_found' if @user.nil?
      raise_error 'vcode_not_match' unless VCode.check_vcode('login', full_mobile, params[:vcode])
      @user.touch_visit!
      @access_token = UserToken.encode(@user.user_uuid)
      render :login
    end

    private

    def full_mobile
      "+#{params[:ext]}#{params[:mobile]}"
    end
  end
end
