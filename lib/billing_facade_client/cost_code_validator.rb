module BillingFacadeClient
  class CostCodeValidator < ActiveModel::Validator
    COST_CODE_REGEXP = /\AS[\d]{4}(_[\d]{1,2}){0,1}\z/
    def validate(record)
      if (record.cost_code)
        unless record.cost_code.match(COST_CODE_REGEXP)
          record.errors[:cost_code] << 'must be a valid project or subproject cost code'
          return
        end
        begin
          unless BillingFacadeClient.validate_cost_code?(record.cost_code)
            record.errors[:cost_code] << "The billing service does not validate this cost code"
          end
        rescue Faraday::ConnectionFailed => e
          record.errors[:cost_code] << "The connection with the Billing service failed"
        end
      end
    end    
  end
end