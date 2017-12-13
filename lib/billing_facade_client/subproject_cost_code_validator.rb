module BillingFacadeClient
  class SubprojectCostCodeValidator < BillingFacadeClient::CostCodeValidator
    def validator_action(record)
      unless BillingFacadeClient.validate_subproject_cost_code?(record.cost_code)
        record.errors[:cost_code] << "The billing service does not validate this subproject cost code"
      end
    end
  end
end