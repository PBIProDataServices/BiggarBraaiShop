# Biggar Braai Shop

Customer shop for **web, iOS, and Android**. Guests can buy biltong without creating an account.

## How stock works

This app does **not** use the old grocery catalogue / “add stock” flow.

Shop listings come from partner **deliveries**:

1. Admin / operations allocate a batch to a partner.
2. That write lands in the Firebase `stock` collection.
3. As soon as `quantity` is greater than zero, the Shop app shows it (live Firestore listener).
4. A customer order reduces that partner’s remaining quantity.

Pricing and descriptions come from `stock_types`. Pickup location comes from `partners`.

## Guest checkout

- Browse and add to basket with no login.
- Checkout collects name, email, phone, and address.
- **I’m not a robot** must be ticked before pay.
- Firebase **anonymous auth** is used so the order can be stored. Enable Anonymous sign-in in Firebase Auth.
- Stripe Payment Sheet takes the card (same `stripePaymentIntentRequestProd` function as the other Biggar Braai apps).

## Firebase

Project: `biggarbraai`  
Remote: [PBIProDataServices/BiggarBraaiShop](https://github.com/PBIProDataServices/BiggarBraaiShop.git)

Register these app IDs in the Firebase console if they are not there yet:

- Android: `com.biggarbraai.shop`
- iOS: `com.biggarbraai.shop`
- Web: add a web app, then run `flutterfire configure`

## Run

```bash
flutter pub get
flutter run
flutter run -d chrome
```
