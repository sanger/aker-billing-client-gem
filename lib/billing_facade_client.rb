require 'faraday'
require 'bigdecimal'

require 'billing_facade_client/cost_for_module'

module BillingFacadeClient
  autoload :ProjectCostCodeValidator, 'billing_facade_client/project_cost_code_validator'
  autoload :SubprojectCostCodeValidator, 'billing_facade_client/subproject_cost_code_validator'
  autoload :CostCodeValidator, 'billing_facade_client/cost_code_validator'

  extend CostForModule

  def self.site=(url)
    @site = url
  end

  def self.site
    @site
  end

  @site = ENV['BILLING_FACADE_URL']

  def self.send_event(work_order, name)
    r = connection.post("events", {eventName: name, workOrderId: work_order.id}.to_json)
    return true if r.status==200
    return false
  end

  def self.validate_single_value(path)
    r = connection.get(path)
    return false unless r.status == 200
    response = JSON.parse(r.body, symbolize_names: true)
    return response[:verified]
  end

  def self.validate_multiple_values(path, params)
    r = connection.post(path, params.to_json)
    return [] if r.status==200
    response = JSON.parse(r.body, symbolize_names: true)
    invalid_cost_codes = response.keys.select{|cost_code| !response[cost_code] }
    return invalid_cost_codes
  end

  def self.get_cost_information_for_products(cost_code, product_names)
    r = connection.post("accounts/#{cost_code}/unit_price", product_names.to_json)
    response = JSON.parse(r.body, symbolize_names: true)
    return response
  end

  def self.get_unit_price(cost_code, product_name)
    response = get_cost_information_for_products(cost_code, [product_name]).first
    if response && response[:verified]
      return BigDecimal.new(response[:unitPrice])
    else
      return nil
    end
  end

  def self.validate_process_module_name(module_name)
    r = connection.get("modules/#{module_name}/verifyname")
    response = JSON.parse(r.body, symbolize_names: true)
    return response[:verified]
  end

  def self.get_sub_cost_codes(cost_code)
    r = connection.get("accounts/#{cost_code}/subaccountcodes")
    response = JSON.parse(r.body, symbolize_names: true)
    return response[:subCostCodes]
  end

  def self.validate_product_name?(product_name)
    validate_single_value("products/#{product_name}/verify")
  end

  def self.filter_invalid_cost_codes(cost_codes)
    validate_multiple_values("accounts/verify", {accounts: cost_codes})
  end

  def self.filter_invalid_product_names(product_names_list)
    validate_multiple_values("catalogue/verify", {products: product_names_list})
  end

  def self.connection
    Faraday.new(:url => site, ssl: { verify: false },
      headers: {'Content-Type': 'application/json', "Accept" => "application/json"})
  end

  ## UBW service integration

  @ubw_site = ENV['UBW_URL']

  def self.ubw_site=(url)
    @ubw_site = url
  end

  def self.ubw_site
    @ubw_site
  end  

  def self.validate_project_cost_code?(cost_code)
    r = ubw_connection.get("/accounts/#{cost_code}/subaccounts")
    response = JSON.parse(r.body, symbolize_names: true)
    return response.any?{|account| account[:isActive] }
  end

  def self.validate_subproject_cost_code?(cost_code)
    validate_cost_code?(cost_code)
  end  

  def self.validate_cost_code?(cost_code)
    r = ubw_connection.get("/subaccounts/#{cost_code}")
    return false unless r.status == 200
    response = JSON.parse(r.body, symbolize_names: true)
    return response[:isActive]
  end

  def self.get_sub_cost_codes(cost_code)
    r = ubw_connection.get("/accounts/#{cost_code}/subaccounts")
    response = JSON.parse(r.body, symbolize_names: true)
    return response.map{|account| account[:costCode] }
  end  

  def self.ubw_connection
    Faraday.new(:url => ubw_site, ssl: { verify: false },
      headers: {'Content-Type': 'application/json', "Accept" => "application/json"})    
  end

end
