module BillingFacadeClient
  module CostForModule
    # Returns boolean telling if the response obtained from the billing-facade-mock server is valid
    # It is considered valid if:
    # - It does not contain any errors
    # - The Cost code and Module name in the response match the arguments provided
    # - The Price obtained is a valid numeric value
    def validate_response_cost_for_module_name(response,  module_name, cost_code)
      !!((response) && (!response[:errors]) && 
        (response[:cost_code] == cost_code) && (response[:module] == module_name) &&
        (price_is_valid?(response[:price])))
    end

    # Given a product name and a module name for it, and a cost code, it performs a query to the billing
    # facade service and returns the price value
    def get_cost_information_for_module(module_name, cost_code)
      r = connection.post("/price_for_module", msg_request_cost_information_for_module(module_name, cost_code))
      response = JSON.parse(r.body, symbolize_names: true)
      if validate_response_cost_for_module_name(response)
        return BigDecimal.new(response[:price])
      else
        return nil
      end
    end

    # Generates a valid request JSON to ask for a price to the billing facade for a module and costcode
    def msg_request_cost_information_for_module(module_name, cost_code)
      obj = {}
      obj[:module] = module_name      
      obj[:cost_code] = cost_code
      obj.to_json
    end

    # Helper method to indicate the argument is a valid numeric value
    def price_is_valid?(price_str)
      Float(price_str) != nil rescue false
    end

  end
end