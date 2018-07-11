module V1
  module Users
    class LoginCountController < ApplicationController
      include UserAuthorize
      before_action :user_self_required

      def create
        # 访问次数 + 1
        @current_user.increase_login_count
        # 奖励积分给用户
        Services::Integrals::RecordService.call(@current_user, 'login')
        # 更新访问时间
        @current_user.touch_visit!
        @current_user.get_pocket_moneys
        # 判断是否完成新手任务 下发奖励
        render_api_success
      end
    end
  end
end
