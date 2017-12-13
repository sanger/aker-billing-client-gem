module BillingFacadeClient
  class ProjectCostCodeValidator < BillingFacadeClient::CostCodeValidator
    def validator_action(record)
      unless BillingFacadeClient.validate_project_cost_code?(record.cost_code)
        record.errors[:cost_code] << "The billing service does not validate this project cost code"
      end
    end
  end
end
