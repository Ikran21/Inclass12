import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(InventoryApp());
}

class InventoryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: InventoryHomePage(title: 'Inventory Home Page'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InventoryHomePage extends StatefulWidget {
  final String title;
  InventoryHomePage({Key? key, required this.title}) : super(key: key);

  @override
  _InventoryHomePageState createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  final CollectionReference _items = FirebaseFirestore.instance.collection(
    'items',
  );

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();

  Future<void> _showItemForm({DocumentSnapshot? doc}) async {
    String action = doc == null ? 'Add' : 'Edit';
    if (doc != null) {
      _nameController.text = doc['name'];
      _qtyController.text = doc['quantity'].toString();
    } else {
      _nameController.clear();
      _qtyController.clear();
    }

    await showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$action Item',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Item Name'),
                ),
                TextField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Quantity'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  child: Text(action),
                  onPressed: () async {
                    String name = _nameController.text.trim();
                    int? quantity = int.tryParse(_qtyController.text.trim());

                    if (name.isEmpty || quantity == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter valid values')),
                      );
                      return;
                    }

                    if (doc == null) {
                      await _items.add({'name': name, 'quantity': quantity});
                    } else {
                      await _items.doc(doc.id).update({
                        'name': name,
                        'quantity': quantity,
                      });
                    }

                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _deleteItem(String id) async {
    await _items.doc(id).delete();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Item deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: StreamBuilder(
        stream: _items.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return Center(child: Text('No items found.'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final item = docs[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: ListTile(
                  title: Text(item['name']),
                  subtitle: Text("Qty: ${item['quantity']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showItemForm(doc: item),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteItem(item.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemForm(),
        tooltip: 'Add Item',
        child: Icon(Icons.add),
      ),
    );
  }
}
