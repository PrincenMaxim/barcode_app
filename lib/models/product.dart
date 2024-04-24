import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class Product {
  String? inventoryId;
  String? variantId;
  String? sku;
  String? name;
  int quantity;
  num price;
  late int? availableQuantity;

  Product(
      {this.inventoryId,
      this.variantId,
      this.sku,
      this.name,
      this.quantity = 1,
      this.price = 0}) {
        availableQuantity = null;
  }
   Map toJson() => {
    'inventoryId': inventoryId,
    'variantId': variantId,
    'sku': sku,
    'name': name,
    'quantity': quantity,
    'price': price,
    'availableQuantity': availableQuantity
  };

  @override
  String toString() {
    return 'name: $name, $quantity: $quantity';
  }

 

  void setAvailableQuantity(int q){
    availableQuantity = q;
  }

  Future fetchInventoryData({String? inventoryId, String? variantId='00000000-0000-0000-0000-000000000000'}) async {
    final Map<String, dynamic> requestBody = {
      "query": {"filter": "{\"id\": {\"\$eq\": [\"$inventoryId\"]}}"}
    };
    final response = await http.post(
      Uri.parse('https://www.wixapis.com/stores/v2/inventoryItems/query'),
      headers: {
        'Authorization':
            'Bearer IST.eyJraWQiOiJQb3pIX2FDMiIsImFsZyI6IlJTMjU2In0.eyJkYXRhIjoie1wiaWRcIjpcImZjNTgyZDQzLTE5YjgtNGQyYy05MTRmLWRiMGIzNDNmNjZiOVwiLFwiaWRlbnRpdHlcIjp7XCJ0eXBlXCI6XCJhcHBsaWNhdGlvblwiLFwiaWRcIjpcImI3MTM3ZmMyLWIxMzctNGQzOS1iZmI3LTFkMjk4OGY1OThkNFwifSxcInRlbmFudFwiOntcInR5cGVcIjpcImFjY291bnRcIixcImlkXCI6XCJjNTVkNWI3Yi1jZTljLTQ1NTYtYjg1MC0wMDIwNjEyYTE1NGFcIn19IiwiaWF0IjoxNzA5NjQyMzU0fQ.RSJuzLhWR9ndUcbt2RhIYAjWZiDxMCdujN5-YHeqpXtV3Sp5x2EDLB4aCU9FBQdpSyWs1p67-6mjbfDIlFg39Jx8DFGdXHXK0YX955fNcf_qmpptpy0rFGJO1rnVtMIqWVML2Qw95dJ2H0YRwJaHTo4z36vCq42DA2XgmBKo9HmeoIwELZelFmtgNtWFi0QEDiV-18K4D1ooguJ2im7GqGPYdw2uiBIbi6vmiXlVSGIX6DpAQ6jwfxWz6QaG4oXGvo6O5eH9shKnuQ1TFrYEDNMs4ZyUEe-pjrQ2tJ9da0OHYRHhO9tYZ8_gGEcA3Avin62YPpWzX78hk42stIv0vg',
        'wix-site-id': 'b6d48d12-12e1-4b8b-bd1d-3d63ad8ee0f5',
        'Content-Type': 'application/json', // Specify the content type
      },
      body: jsonEncode(requestBody), // Encode the request body to JSON format
    );
    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, parse the JSON response
      // and handle it accordingly
      var jsonData = jsonDecode(response.body);
      var inventoryItems = jsonData['inventoryItems'];
      List<dynamic> variants = inventoryItems[0]['variants'];
      var thisVariant;
      if(variants.length > 1) {
         thisVariant =
          variants.firstWhere((v) => v['variantId'].toString() == variantId);
      }
      else {
        thisVariant = variants[0];
      }
     
      return thisVariant['quantity'];
    } else {
      // If the server returns an error response, throw an exception
      throw Exception('Failed to fetch inventory data');
    }
  }
}
