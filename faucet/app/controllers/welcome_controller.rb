class WelcomeController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:widget]

  def index
    write_referral_cookie(params[:r]) if params[:r]

    if params[:account_name] and params[:account_key]
      @account_name = params[:account_name]
      session[:pending_registration] = {account_name: params[:account_name], account_key: params[:account_key]}
      redirect_to bitshares_account_path if user_signed_in?
    else
      @account = BtsAccount.new(name: '', key: '')
    end

    @asset = Asset.where(assetid: 0).first
    @faucet_account = Rails.application.config.bitshares.faucet_account
    @faucet_balance = Rails.cache.fetch('key', expires_in: 1.minute) do
      begin
        res = BitShares::API::Wallet.account_balance(@faucet_account)
        res[0][1][0][1]/@asset.precision
      rescue
        0
      end
    end
  end

  def account_registration_step2
    @account = BtsAccount.new(bts_account_params)
    logger.debug "BtsAccount:"
    logger.debug "#{@account}; #{@account.valid?}; #{@account.errors}"
    @account_name = @account.name
    session[:pending_registration] = {account_name: @account.name, account_key: @account.key}
    redirect_to bitshares_account_path if user_signed_in?
  end

  def test_widget
  end

  private

  def bts_account_params
    params.require(:account).permit(:name, :key)
  end

end
