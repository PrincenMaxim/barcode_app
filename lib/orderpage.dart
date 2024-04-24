// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:barcode_app/env.dart'; // You should create a dart file with your config stuff.
import 'package:barcode_app/models/product.dart';
import 'package:barcode_app/productwidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;

class OrderPage extends StatefulWidget {
  const OrderPage({super.key, required this.nextPageFunc});
  final Function nextPageFunc;
  @override
  State<StatefulWidget> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  List<String> _scanResult = [];
  List<Product> _scannedProducts = [];
  String supabaseUrl = SUPABASE_URL;
  String supabaseKey = SUPABASE_KEY;
  late SupabaseClient supabase;
  late PostgrestFilterBuilder<PostgrestList> myProductsQuery;
  late num _totalPrice;
  @override
  void initState() {
    super.initState();
    supabase = SupabaseClient(supabaseUrl, supabaseKey);
    myProductsQuery = supabase.from('products').select();
    _totalPrice = 0;
  }

  Future<void> _getScan() async {
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
      '#740063',
      'Exit',
      true,
      ScanMode.BARCODE,
    );
    print(barcodeScanRes);
    if (!mounted) return;

    setState(() {
      _scanResult = [..._scanResult, barcodeScanRes];
    });
  }

  _updateScannedProducts(queriesProducts) async {
    print('queriesProducts');
    print(queriesProducts);
    List<Product> newScannedProducts = [];
    num tempPrice = 0;
    for (var product in queriesProducts) {
      var occurences =
          _scanResult.where((element) => element == product['sku']);

      Product? existingProduct = _scannedProducts
          .firstWhereOrNull((element) => element.sku == product['sku']);

      if (existingProduct == null) {
        var newProduct = Product(
            inventoryId: product['inventoryId'],
            name: product['name'],
            sku: product['sku'],
            variantId: product['variantId'],
            quantity: occurences.length,
            price: product['price']);

        newScannedProducts.add(newProduct);
      } else {
        existingProduct.quantity = occurences.length;
        if (existingProduct.quantity == 0) {
          _scannedProducts.remove(existingProduct);
        }
      }

      tempPrice += product['price'] * occurences.length;
    }

    _totalPrice = tempPrice;
    _scannedProducts = [
      ..._scannedProducts,
      ...newScannedProducts
    ]; // Update state directly
  }

  void removeProduct({required Product product}) {
    var index = _scanResult.lastIndexWhere((element) => element == product.sku);
    setState(() {
      if (product.quantity == 1) _scannedProducts.remove(product);
      _scanResult.removeRange(index, index + 1);
      _scanResult = [..._scanResult];
    });
  }

  void addProduct({required Product product}) {
    setState(() {
      _scanResult.add(product.sku!);
      _scanResult = [..._scanResult];
    });
  }

  List<Product> checkAmountUnavailable() {
    List<Product> invalidQuantityProducts = [];
    _scannedProducts.forEach((element) {
      if (element.quantity > element.availableQuantity!)
        invalidQuantityProducts.add(element);
    });
    return invalidQuantityProducts;
  }

  Future<SnackBar> confirmOrder() async {
    // Here we will decrease the inventory of the necessary products.
    List<Map<String, dynamic>> inventoryObjectsForRequest = _scannedProducts
        .map((e) => {
              'inventoryId': e.inventoryId,
              'variantId':
                  e.variantId ?? '00000000-0000-0000-0000-000000000000',
              'decrementBy': e.quantity <= e.availableQuantity!
                  ? e.quantity
                  : e.availableQuantity
            })
        .toList();
    inventoryObjectsForRequest = inventoryObjectsForRequest
        .where((inv) => inv['decrementBy'] != 0)
        .toList();
    SnackBar snackBar;
    if (inventoryObjectsForRequest.isNotEmpty) {
      final response = await http.post(
          Uri.parse(
              'https://www.wixapis.com/stores/v2/inventoryItems/decrement'),
          headers: {
            'Authorization': WIX_TOKEN,
            'wix-site-id': WIX_SITE_ID,
            'Content-Type': 'application/json', // Specify the content type
          },
          body: jsonEncode({"decrementData": inventoryObjectsForRequest}));

      if (response.statusCode == 200) {
        // OPTIONAL: post the transaction to Supabase to keep track of each transaction.
        try {
          await supabase.from('completedOrders').insert({
            'order_data': jsonEncode(_scannedProducts),
            'total_price': _totalPrice
          });
          snackBar = const SnackBar(content: Text('Order completed!'));

          setState(() {
            _scannedProducts = [];
            _scanResult = [];
          });
        } catch (e) {
          snackBar = const SnackBar(
              content: Text(
                  'Something went wrong with your order. Please proceed manually.'));
        }
      } else {
        snackBar = const SnackBar(
            content: Text(
                'Something went wrong with your order. Please proceed manually.'));
      }
    } else {
      snackBar = const SnackBar(
          content: Text('No productinventory to be decremented.'));

      setState(() {
        _scannedProducts = [];
        _scanResult = [];
      });
    }
    return snackBar;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 30),
            const Text('My Order',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
            const SizedBox(height: 30),
            Expanded(
              child: FutureBuilder(
                future: myProductsQuery.filter('sku', "in", _scanResult),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData) {
                    return const Center(child: Text('No data available'));
                  }

                  _updateScannedProducts(snapshot.data!);

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: _scannedProducts.length,
                          itemBuilder: ((context, index) {
                            final product = _scannedProducts[index];
                            return ProductWidget(
                              product: product,
                              removeProduct: removeProduct,
                              addProduct: addProduct,
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 10),
                      Text('Total: $_totalPrice'),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _getScan,
              style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('Add product'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final List<Product> unavailableProducts = checkAmountUnavailable();
          if (unavailableProducts.isNotEmpty) {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return Container(
                  height: 200,
                  padding: const EdgeInsets.all(
                      16), // Add padding for better spacing
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "There is insufficient stock for certain items.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(
                          height: 10), // Add spacing between text and list
                      Expanded(
                        child: ListView.builder(
                          itemCount: unavailableProducts.length,
                          itemBuilder: (context, index) {
                            final product = unavailableProducts[index];
                            return Text(
                              product.name.toString(),
                              textAlign: TextAlign.center,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {
                          final message = await confirmOrder();
                          ScaffoldMessenger.of(context).showSnackBar(message);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 238, 196, 210),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: const Text(
                          'Proceed order',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          } else {
            final message = await confirmOrder();
            ScaffoldMessenger.of(context).showSnackBar(message);
          }
        },
        tooltip: 'Increment',
        child: const Icon(Icons.check),
      ),
    );
  }
}
