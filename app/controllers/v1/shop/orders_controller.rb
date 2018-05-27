module V1::Shop
  class OrdersController < ApplicationController
    include UserAuthorize
    before_action :login_required
    before_action :set_order, only: [:wx_paid_result, :show, :destroy]

    def index
      @orders = @current_user.shop_orders.order(id: :desc)
                            .page(params[:page]).per(params[:page_size])
      if Shop::Order.statuses.keys.include?(params[:status])
        status = params[:status] == 'paid' ? %w(paid delivered) : params[:status]
        @orders = @orders.where(status: status)
      end
      render 'index'
    end

    def show
      render 'show'
    end

    def new
      shipping_info = params[:shipping_info] || {}
      province = shipping_info[:address] && shipping_info[:address][:province]
      @pre_purchase_items = Shop::PrePurchaseItems.new(params[:variants], province)
      if @pre_purchase_items.check_result != 'ok'
        return render_api_error(@pre_purchase_items.check_result)
      end
      render 'new'
    end

    def create
      result = Shop::CreateOrderService.call(@current_user, params)
      render 'create', locals: result
    end

    def destroy
      return render_api_error(CANNOT_DELETE) unless @order.could_delete?
      @order.deleted!
      render_api_success
    end

    def wx_paid_result
      result = WxPay::Service.order_query(out_trade_no: @order.order_number)
      unless result['trade_state'] == 'SUCCESS'
        return render_api_error(INVALID_ORDER, result['trade_state_desc'] || result['err_code_des'])
      end
      api_result = Services::Notify::WxShopNotifyNotifyService.call(result[:raw]['xml'])

      return render_api_error(INVALID_ORDER, api_result.msg) if api_result.failure?

      render_api_success
    end

    private

    def set_order
      @order = @current_user.shop_orders.find_by!(order_number: params[:id])
    end
  end
end