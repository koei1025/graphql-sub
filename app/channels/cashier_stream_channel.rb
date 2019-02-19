class CashierStreamChannel < ApplicationCable::Channel
  def subscribed
    @subscription_ids = []
  end

  def unsubscribed
    @subscription_ids.each do |sid|
      GraphqlSubSchema.subscriptions.delete_subscription(sid)
    end
  end

  def execute(data)
    # process data sent from the page
    query = data['query']
    variables = ensure_hash(data['variables'])
    operation_name = data['operationName']
    context = {
      #  current_user: current_user,

      # you can identify scope here
      # and trigger can boradcase to the scope
      # ex.
      # > group_id: current_group_id
      # and trigger
      # MySchema.subscriptions.trigger(
      #    'someEvent',
      #    {},
      #    self,
      #    scope: group_id
      #  )

      #  Make sure the channel is in the context
      channel: self
    }
    result = GraphqlSubSchema.execute(
      query: query,
      context: context,
      variables: variables,
      operation_name: operation_name
    )

    payload = {
      result: result.subscription? ? { data: nil } : result.to_h
    }

    # Track the subscription here so we can remove it
    # on unsubscribe.
    if result.context[:subscription_id]
      @subscription_ids << context[:subscription_id]
    end

    transmit(payload)
  end
  private
  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String
      if ambiguous_param.present?
        ensure_hash(JSON.parse(ambiguous_param))
      else
        {}
      end
    when Hash, ActionController::Parameters
      ambiguous_param
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end

end
