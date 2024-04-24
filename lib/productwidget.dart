import 'package:barcode_app/models/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class ProductWidget extends StatefulWidget {
  const ProductWidget({
    super.key,
    required this.product,
    required this.removeProduct,
    required this.addProduct,
  });
  final Function removeProduct;
  final Function addProduct;
  final Product product;

  @override
  _ProductWidgetState createState() => _ProductWidgetState();
}

class _ProductWidgetState extends State<ProductWidget> {
  bool _enableEditProduct = false;

  Future<void> loadProductAvailableQuantity() async {
    var q = await widget.product.fetchInventoryData(
        inventoryId: widget.product.inventoryId,
        variantId: widget.product.variantId);
    if (mounted) {
      setState(() {
        widget.product.availableQuantity = q;
      });
    }
  }

  void toggleEdit() {
    setState(() {
      _enableEditProduct = !_enableEditProduct;
    });
  }

  @override
  void initState() {
    super.initState();
    loadProductAvailableQuantity();
  }

  Color getQuantityColor() {
    if (widget.product.availableQuantity == null) return Colors.grey;
    if (widget.product.quantity > widget.product.availableQuantity!) {
      return Colors.red;
    }
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    void increaseQuantity() {
      widget.addProduct(product: widget.product);
    }

    void decreaseQuantity() {
      widget.removeProduct(product: widget.product);
    }

    return Card(
        child: Padding(
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: SizedBox(
        height: 75,
        child: Row(
          children: [
            Expanded(child: Text(widget.product.name!)),
            const VerticalDivider(),
            const SizedBox(
              width: 10,
            ),
            Text((widget.product.quantity).toString(),
                style: TextStyle(color: getQuantityColor())),
            SizedBox(
              width: 80,
              child: _enableEditProduct
                  ? IconButton(
                      onPressed: toggleEdit,
                      icon: const Icon(Icons.edit, size: 20),
                    )
                  : Row(
                      children: [
                        const SizedBox(
                          width: 10,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 30,
                              width: 30,
                              child: IconButton(
                                onPressed: increaseQuantity,
                                icon: const Icon(
                                  Icons.add,
                                ),
                                iconSize: 20,
                              ),
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              height: 30,
                              width: 30,
                              child: IconButton(
                                onPressed: decreaseQuantity,
                                icon: const Icon(
                                  Icons.minimize,
                                ),
                                iconSize: 20,
                              ),
                            )
                          ],
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        SizedBox(
                          height: 75,
                          width: 30,
                          child: IconButton(
                            onPressed: toggleEdit,
                            icon: const Icon(Icons.save, size: 20),
                          ),
                        )
                      ],
                    ),
            ),
            const VerticalDivider(),
            const SizedBox(width: 10),
            SizedBox(
              width: 50,
              child:
                  Text('€ ${widget.product.price * widget.product.quantity}'),
            ),
          ],
        ),
      ),
    ));
  }
}
