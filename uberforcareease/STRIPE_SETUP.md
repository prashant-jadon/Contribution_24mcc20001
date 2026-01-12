# Stripe Payment Integration Setup

## Backend Configuration

Add the following to your `backend/.env` file:

```env
STRIPE_SECRET_KEY=sk_test_your_secret_key_here
STRIPE_PUBLISHABLE_KEY=pk_test_your_publishable_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here
```

## Getting Stripe Keys

1. Go to [Stripe Dashboard](https://dashboard.stripe.com/)
2. Navigate to **Developers** > **API keys**
3. Copy your **Publishable key** (starts with `pk_test_` for test mode)
4. Copy your **Secret key** (starts with `sk_test_` for test mode)
5. For webhooks, go to **Developers** > **Webhooks** and create an endpoint pointing to:
   ```
   https://your-domain.com/api/payments/webhook
   ```

## Flutter App Configuration

The Flutter app automatically fetches the publishable key from the backend on app startup. No additional configuration needed in the Flutter app.

## Payment Flow

1. User places an order
2. Backend creates a Stripe Payment Intent and returns `clientSecret`
3. User is navigated to Payment Screen
4. User enters card details
5. Payment is confirmed via Stripe
6. Backend webhook handles payment success/failure
7. Order status is updated accordingly

## Testing

Use Stripe test cards:
- **Success**: `4242 4242 4242 4242`
- **Decline**: `4000 0000 0000 0002`
- **3D Secure**: `4000 0025 0000 3155`

Any future expiry date and any 3-digit CVC will work.

