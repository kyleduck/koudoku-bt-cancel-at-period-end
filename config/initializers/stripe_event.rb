# SIGNING REQUIRED AS OF STRIPE 2.0
StripeEvent.signing_secret = ENV['STRIPE_SIGNING_SECRET'] 

StripeEvent.configure do |events|
  events.subscribe 'charge.failed' do |event|
    stripe_id = event.data.object['customer']
    subscription = ::Subscription.find_by_stripe_id(stripe_id)
    subscription.charge_failed
  end
  
  events.subscribe 'invoice.payment_succeeded' do |event|
    invoice = event.data.object
    stripe_id = invoice.customer
    amount = invoice.total.to_f / 100.0

    # Zero-dollar invoices for new customers are marked paid, 
    # errors out since there's not even a customer yet
    if invoice.try(:total) > 0
      subscription = ::Subscription.find_by_stripe_id(stripe_id)
      subscription.payment_succeeded(amount, invoice.id)
    end
  end
  
  events.subscribe 'charge.dispute.created' do |event|
    stripe_id = event.data.object['customer']
    subscription = ::Subscription.find_by_stripe_id(stripe_id)
    subscription.charge_disputed
  end
  
  events.subscribe 'customer.subscription.deleted' do |event|
    stripe_id = event.data.object['customer']
    subscription = ::Subscription.find_by_stripe_id(stripe_id)
    subscription.cancel_without_callback
  end
end
