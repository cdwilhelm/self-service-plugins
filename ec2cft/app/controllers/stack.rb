module V1
  class Stack
    include Praxis::Controller

    implements V1::ApiResources::Stack

    def index(account_id:, **params)
      cfm = AWS::CloudFormation.new
      stacks = JSON.parse(cfm.stack_summaries.to_json)
      prax_stax = Array.new

      stacks.each do |s| 
        next if s["stack_status"] == "DELETE_COMPLETE" 
        stack = {}

        stack["id"] = s["stack_id"]
        stack["href"] = "/stacks/" + s["stack_name"].to_s
        stack["name"] = s["stack_name"]
        stack["status"] = s["stack_status"]
        stack["status_reason"] = s["stack_status_reason"]
        stack["creation_time"] = s["creation_time"]
        stack["template_description"] = s["template_description"]

        prax_stax.push(stack)
      end

      response.headers['Content-Type'] = 'application/json'

      response.body = JSON.pretty_generate(prax_stax.map { |s| V1::MediaTypes::Stack.dump(s) })
      response
    end

    def show(account_id:, name:, view:, **other_params)
      cfm = AWS::CloudFormation.new
      stack = cfm.stacks[name]

      if stack.exists?

        outputs = Array.new
        stack.outputs.each do |o|
          op = { 
            "key" => o.key,
            "value" => o.value,
            "description" => o.description
          }
          outputs.push(op)
        end
        resp = {
          "id" => stack.stack_id,
          "href" => "/stacks/#{stack.name}",
          "creation_time" => stack.creation_time,
          "template_description" => stack.description,
          "name" => stack.name,
          "status" => stack.status,
          "status_reason" => stack.status_reason,
          "template" => stack.template,
          "outputs" => outputs
        }  
        response.body = JSON.pretty_generate(V1::MediaTypes::Stack.dump(resp, :view=>(view ||= :default).to_sym))
      else
        self.response = Praxis::Responses::NotFound.new()
        response.body = { error: '404: Not found' }
      end
      response.headers['Content-Type'] = 'application/json'
      response
    end

    def create(account_id:, **other_params)

      cfm = AWS::CloudFormation.new
      options = {
        :parameters => JSON.parse(request.payload.parameters.contents) ||= {}
      }
      begin
        stack = cfm.stacks.create(request.payload.name, request.payload.template, options)
        self.response = Praxis::Responses::Created.new()
        resp = {
          "id" => stack.stack_id,
          "href" => "/stacks/#{stack.name}",
          "creation_time" => stack.creation_time,
          "template_description" => stack.description,
          "name" => stack.name,
          "status" => stack.status,
          "status_reason" => stack.status_reason,
          "template" => stack.template
        }  
        response.headers['Location'] = resp["href"]
        response.body = JSON.pretty_generate(V1::MediaTypes::Stack.dump(resp))        
      rescue Exception => e  
        self.response = Praxis::Responses::UnprocessableEntity.new()
        response.body = { error: '422: Not able to create record: ' + e.message }
      end
      response.headers['Content-Type'] = 'application/json'      
      response

    end

    def delete(name:, **other_params)
      cfm = AWS::CloudFormation.new

      stack = cfm.stacks[name]

      if stack.exists?
        stack.delete
        self.response = Praxis::Responses::NoContent.new()
      else
        self.response = Praxis::Responses::UnprocessableEntity.new()
        response.headers['Content-Type'] = 'application/json'      
        response.body = { error: '422: Not able to update record' }        
      end

      response

    end

    def update(domain:, id:, **other_params)

      # api = get_api
      # res = api.update_record(domain, id, request.payload.name, request.payload.type, request.payload.value)

      # if res["error"].nil? 
      #   self.response = Praxis::Responses::NoContent.new()
      #   response.body = res
      # else
      #   self.response = Praxis::Responses::UnprocessableEntity.new()
      #   response.headers['Content-Type'] = 'application/json'      
      #   response.body = { error: '422: Not able to update record' }
      # end
      # response

    end 

  end
end
