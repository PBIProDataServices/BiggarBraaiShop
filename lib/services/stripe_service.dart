import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:flutter_stripe/flutter_stripe.dart';

class StripeService {
  static const String _baseUrl = 'https://europe-west2-biggarbraai.cloudfunctions.net';

/*
static Future<Map<String, dynamic>> initPayment(email, amount, currency) async {
    try {
        
        // 1. Create a payment intent on the server
        final response = await http.post(
            Uri.parse(
                'https://us-central1-biggarbraai.cloudfunctions.net/stripePaymentIntentRequestProd'),
               // 'https://us-central1-biggarbraai.cloudfunctions.net/createPaymentIntent'),
            body: {
              'email': email.toString(),
              'amount': (amount).toString(),
              'currency':currency
            });

        final jsonResponse = jsonDecode(response.body);
        developer.log(jsonResponse.toString());
        // 2. Initialize the payment sheet
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: jsonResponse['paymentIntent'],
          merchantDisplayName: 'Biggar Braai',
          customerId: jsonResponse['customer'],
          customerEphemeralKeySecret: jsonResponse['ephemeralKey']
        ));
        await Stripe.instance.presentPaymentSheet().then((e) {
          Stripe.instance.confirmPaymentSheetPayment();
        });
      return {
        'success': true,
        'message': 'Payment processed successfully',
        'paymentIntent': jsonResponse['paymentIntent'],
      }; 
    } catch (e) {
      developer.log('Error creating payout: $e');
      if (e is StripeException) {
        developer.log('Stripe error: ${e.error.localizedMessage}');
        developer.log('Stripe error code: ${e.error.code}');
        return {
          'success': false,
          'error': e.error.localizedMessage,
          'code': e.error.code,
        };
      } else {
        return {
          'success': false,
          'error': e.toString(),
        };
      }
    }
  }*/


  // Create a payment using payment sheet (platform account)
  static Future<Map<String, dynamic>> createPayout({
    required String partnerId, // Keep for tracking purposes
    required int amount,
    required String currency,
    required String email,
  }) async {
    try {
      // 1. Create a payment intent on the server for platform account
      final response = await http.post(
        Uri.parse('$_baseUrl/stripePaymentIntentRequestProd'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'email': email,
          'amount': (amount).toString(),
          'currency': currency,
          'payment_method': 'card',
          'customerId': partnerId,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create payment intent: ${response.body}');
      }

      final jsonResponse = json.decode(response.body);
      developer.log('jsonResponse: ${jsonResponse.toString()}');

      // 2. Initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: jsonResponse['paymentIntent'],
          merchantDisplayName: 'Biggar Braai',
          customerId: jsonResponse['customer'],
          customerEphemeralKeySecret: jsonResponse['ephemeralKey'],
        ),
      );

      // 3. Present the payment sheet and wait for completion
      await Stripe.instance.presentPaymentSheet();

      return {
        'success': true,
        'message': 'Payment processed successfully',
        'paymentIntent': jsonResponse['paymentIntent'],
      };

    } catch (e) {
      developer.log('Error creating payout: $e');
      if (e is StripeException) {
        developer.log('Stripe error: ${e.error.localizedMessage}');
        developer.log('Stripe error code: ${e.error.code}');
        return {
          'success': false,
          'error': e.error.localizedMessage,
          'code': e.error.code,
        };
      } else {
        return {
          'success': false,
          'error': e.toString(),
        };
      }
    }
  }



} 