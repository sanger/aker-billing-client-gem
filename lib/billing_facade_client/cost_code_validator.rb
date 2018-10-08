module BillingFacadeClient
  class CostCodeValidator < ActiveModel::Validator
    SPLIT_CHARACTER = '-'
    COST_CODE_REGEXP_STR = "\\A[S,G,N,T][0-9]{4}(#{BillingFacadeClient::CostCodeValidator::SPLIT_CHARACTER}[0-9]{3})?\\z"

    def cost_code_regexp
      @cost_code_regexp ||= Regexp.new(COST_CODE_REGEXP_STR)
    end

    def validate_with_regexp?(cost_code)
      !cost_code.match(cost_code_regexp).nil?
    end

    def validator_action(record)
      unless BillingFacadeClient.validate_cost_code?(record.cost_code)
        record.errors[:cost_code] << "The billing service does not validate this cost code"
      end
    end

    def validate(record)
      if (record.cost_code)
        unless validate_with_regexp?(record.cost_code)
          record.errors[:cost_code] << 'must be a valid project or subproject cost code'
          return
        end

        begin
          validator_action(record)
        rescue Faraday::ConnectionFailed => e
          record.errors[:cost_code] << "The connection with the Billing service failed"
        end
      end
    end
  end

end
