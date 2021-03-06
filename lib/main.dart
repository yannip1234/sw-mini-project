import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'dart:convert';
import 'package:miniproject1/models/results.dart';
import 'package:recase/recase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Initializing Google sign-in authentication
GoogleSignIn _googleSignIn = GoogleSignIn();

// Initializing Firebase API and helper methods
final _suggestions = <WelcomeFoods>[];
final _saved = <WelcomeFoods>{};
final _biggerFont = const TextStyle(fontSize: 18.0);
late final stored;

// Implementing list icon on app bar
void pushSaved(BuildContext context) {
  Navigator.of(context).push(
      new MaterialPageRoute(builder: (BuildContext context) => new ItemList()));
}

void showDetail(BuildContext context, WelcomeFoods food) {
  Navigator.of(context).push(new MaterialPageRoute(
      builder: (BuildContext context) => new ShowDetail(food)));
}

// Displaying and dealing with details of specific food in shopping list
class ShowDetail extends StatelessWidget {
  WelcomeFoods result;

  ShowDetail(this.result);

  Widget _buildDetails(WelcomeFoods result) {
    // Managing potential null value of brand name
    String obj, obj2, obj3;
    result.brandName ??= 'N/A';
    if (result.brandName == 'N/A') {
      obj = result.brandName!;
    } else {
      obj = result.brandName!.titleCase;
    }

    result.ingredients ??= 'N/A';
    if (result.ingredients == 'N/A') {
      obj2 = result.ingredients!;
    } else {
      obj2 = result.ingredients!.titleCase;
    }

    result.foodCategory ??= 'N/A';
    if (result.foodCategory == 'N/A') {
      obj3 = result.foodCategory!;
    } else {
      obj3 = result.foodCategory!.titleCase;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(result.description!.titleCase),
      ),
      body: ListView(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.all(10),
              padding: EdgeInsets.all(20),
              child: Container(
                width: 350,
                height: 80,
                alignment: Alignment.center,
                child: Text(result.lowercaseDescription!.titleCase,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Text(
                "Category: ",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Flexible(child: Text(obj3, style: TextStyle(fontSize: 20)))
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Text(
                "Brand Name: ",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Text(obj, style: TextStyle(fontSize: 20))
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 20, left: 20),
          child: Text("Ingredients: ",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        ),
        Padding(
          padding: EdgeInsets.only(left: 20),
          child: Text(
            obj2,
            style: TextStyle(fontSize: 15),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 20, left: 20),
          child: Text("Nutrients: ",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        ),
        Padding(
            padding: EdgeInsets.only(left: 20),
            child: Column(
              children: [
                for (var nutrient in result.foodNutrients!)
                  Text(
                      "${nutrient!.nutrientName!.toString()}: ${nutrient.nutrientNumber.toString()}${nutrient.unitName.toString().toLowerCase()}  ")
              ],
              crossAxisAlignment: CrossAxisAlignment.start,
            )),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildDetails(result);
  }
}

// Creating and formatting shopping list
class ItemList extends StatefulWidget {
  const ItemList({Key? key}) : super(key: key);

  @override
  _ItemListState createState() => _ItemListState();
}

class _ItemListState extends State<ItemList> {
  @override
  Widget build(BuildContext context) {
    final tiles = _saved.map(
      (food) {
        return ListTile(
          title: Text(
            food.lowercaseDescription!.titleCase,
            style: _biggerFont,
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              setState(() {
                _saved.remove(food);
              });
            },
          ),
          onTap: () => showDetail(context, food),
        );
      },
    );
    final divided = tiles.isNotEmpty
        ? ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList()
        : <Widget>[
            Center(
                child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(CupertinoIcons.add),
                    label: Text('Add item to shopping list')))
          ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
      ),
      body: ListView(children: divided),
    );
  }
}

// Implementing barcode scanning mechanism
Future<Welcome> scanBarcodeNormal() async {
  String barcodeScanRes = 'Unknown';
  Welcome welcome;

  // Platform messages may fail, so we use a try/catch PlatformException.
  barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
      '#ff6666', 'Cancel', true, ScanMode.BARCODE);
  String obj = barcodeScanRes.substring(1);
  final response = await http.get(Uri.parse(
      'https://api.nal.usda.gov/fdc/v1/foods/search?query=' +
          obj +
          '&pageSize=2&api_key=zoLDtB28FubnioDyjhhrgpp2rmkZAnHmf2G3QXVP'));
  welcome = new Welcome.fromJson(json.decode(response.body));
  return welcome;
}

// Setting up and running application
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Firebase.initializeApp();
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Shopping List App'),
    );
  }
}

// Creating home page for application
class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GoogleSignInAccount? _currentUser;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {
        _currentUser = account;
        //print(_currentUser);
      });
      if (_currentUser != null) {
        setState(() {
          _currentUser = account;
        });
      }
      _handleSignIn();
    });
  }

  // Implementing search functionality
  Future<http.Response> search(String item) async {
    final res = await http.post(
      Uri.parse(
          'https://api.nal.usda.gov/fdc/v1/foods/search?api_key=zoLDtB28FubnioDyjhhrgpp2rmkZAnHmf2G3QXVP'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        "query": item,
      }),
    );

    return res;
  }

  // Handling sign out
  Future<void> _handleSignOut() async {
    // POST API - Call the user's CollectionReference to update shopping list
    String entry, id;
    int count = 1;
    final firestoreInstance = FirebaseFirestore.instance;
    print('_saved');
    print(_saved);

    var collection = FirebaseFirestore.instance.collection('users');
    var snapshot = await collection.where(
        'user', isEqualTo: _currentUser!.email).get();
    await snapshot.docs.first.reference.delete();

    // If the user does not have an empty shopping list
    if (_saved.isNotEmpty) {
      firestoreInstance.collection("users").doc(_currentUser!.email).set(
          {
            "user": _currentUser!.email,
          });

      _saved.forEach((k) {
        entry = 'food' + count.toString();
        id = k.fdcId.toString();

        firestoreInstance.collection("users").doc(_currentUser!.email).update(
            {
              entry: id,
            });
        print('$k');
        count++;
      });
    }
    _googleSignIn.signOut();
    FirebaseAuth.instance.signOut();

    _saved.clear();
  }

  // Initializing Firestore instance
  Future<void> _addUser() async {
    var users = FirebaseFirestore.instance.collection('users');
    var stored, id;
    var firestoreInstance = FirebaseFirestore.instance;
    FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.email)
        .get()
        .then((DocumentSnapshot documentSnapshot) {

      // GET API - Call the user's CollectionReference to read an existing user and their data
      if (documentSnapshot.exists) {
        print('Document exists on the database');
      }
      else {
        firestoreInstance.collection("users").doc(_currentUser!.email).set(
            {
              "user": _currentUser!.email,
            });
        print('Document created on the database');
      }

      firestoreInstance.collection("users").get().then((querySnapshot) {
        querySnapshot.docs.forEach((result) {
          if (result.data()["user"] == _currentUser!.email)
          {
            stored = result.data();
            print(stored);
            stored.remove('user');
          }
        });
        stored.forEach((key, value) async {
          print('Key: $key');
          print('Value: $value');
          print('------------------------------');
          id = value;
          final response = await http.get(Uri.parse(
              'https://api.nal.usda.gov/fdc/v1/foods/search?query=' +
                  id +
                  '&pageSize=2&api_key=zoLDtB28FubnioDyjhhrgpp2rmkZAnHmf2G3QXVP'));
          Welcome welcome = new Welcome.fromJson(json.decode(response.body));
          WelcomeFoods obj = welcome.foods![0]!;
          _saved.add(obj);
        });
      });
    });

  }

  // Handling sign in
  Future<void> _handleSignIn() async {
    FirebaseAuth auth = FirebaseAuth.instance;

    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }

    final GoogleSignInAuthentication googleAuth =
        await _currentUser!.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
    print('A user found for that email.');

    var users = FirebaseFirestore.instance.collection('users');
    var stored, id;
    var firestoreInstance = FirebaseFirestore.instance;
    FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.email)
        .get()
        .then((DocumentSnapshot documentSnapshot) {

      // GET API - Call the user's CollectionReference to read an existing user and their data
      if (documentSnapshot.exists) {
        print('Document exists on the database');
      }
      else {
        firestoreInstance.collection("users").doc(_currentUser!.email).set(
            {
              "user": _currentUser!.email,
            });
        print('Document created on the database');
      }

      firestoreInstance.collection("users").get().then((querySnapshot) {
        querySnapshot.docs.forEach((result) {
          if (result.data()["user"] == _currentUser!.email)
          {
            stored = result.data();
            print(stored);
            stored.remove('user');
          }
        });
        stored.forEach((key, value) async {
          print('Key: $key');
          print('Value: $value');
          print('------------------------------');
          id = value;
          final response = await http.get(Uri.parse(
              'https://api.nal.usda.gov/fdc/v1/foods/search?query=' +
                  id +
                  '&pageSize=2&api_key=zoLDtB28FubnioDyjhhrgpp2rmkZAnHmf2G3QXVP'));
          Welcome welcome = new Welcome.fromJson(json.decode(response.body));
          WelcomeFoods obj = welcome.foods![0]!;
          _saved.add(obj);
        });
      });
    });

  }

  var searchterm;

  Widget build(BuildContext context) {
    GoogleSignInAccount? user = _currentUser;

    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    if (user != null) {
      return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () {
                pushSaved(context);
              },
              tooltip: 'Saved Suggestions',
            ),
          ],
        ),
        body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Column(
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Padding(
                    padding: EdgeInsets.only(top: 20, bottom: 20),
                    child: Text(
                      user.displayName ?? '',
                      style: TextStyle(fontSize: 15),
                    )),
                IconButton(onPressed: _handleSignOut, icon: Icon(Icons.logout))
              ]),
              Row(
                children: [
                  Expanded(
                      child: Padding(
                    padding: EdgeInsets.all(10),
                    child: TextField(
                      onChanged: (text) {
                        searchterm = text;
                      },
                      decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20)),
                          labelText: 'Search ingredients',
                          suffixIcon: IconButton(
                            icon: Icon(CupertinoIcons.camera),
                            onPressed: () async {
                              Welcome test = await scanBarcodeNormal();
                              Navigator.of(context).push(new MaterialPageRoute(
                                  builder: (BuildContext context) =>
                                      new RandomWords2(test)));
                              // Navigator.of(context).push(new MaterialPageRoute(builder: (BuildContext context) => new MyScanner()));
                            },
                          )),
                    ),
                  )),
                  Ink(
                      decoration: const ShapeDecoration(
                        color: Colors.lightBlue,
                        shape: CircleBorder(),
                      ),
                      child: IconButton(
                        onPressed: () async {
                          // ADD LINE OF CODE BELOW OF THIS COMMENT
                          var result = await search(searchterm);
                          Welcome welcome =
                              new Welcome.fromJson(json.decode(result.body));
                          //print(welcome.foods![0]!.ingredients);
                          Navigator.of(context).push(new MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  new RandomWords(welcome)));
                          //Example of parsing
                        },
                        icon: Icon(CupertinoIcons.search),
                        color: Colors.white,
                      )),
                ],
              )
            ],
          ),
        ),
        // This trailing comma makes auto-formatting nicer for build methods.
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 10),
                    child: Text(
                      'You are not logged in.',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  )
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _handleSignIn();
                },
                label: Text('Login with Google!'),
                icon: Icon(Icons.login),
              )
            ],
          ),
        ), // This trailing comma makes auto-formatting nicer for build methods.
      );
    }
  }
}

// Generating search bar results
class RandomWords extends StatefulWidget {
  final Welcome passedResult;

  RandomWords(this.passedResult);

  @override
  State<RandomWords> createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  Widget _buildSuggestions() {
    if (widget.passedResult.foods!.length == 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                "No foods found.",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.center,
          )
        ],
      );
    } else {
      return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: widget.passedResult.foods!.length,
          itemBuilder: /*1*/ (context, i) {
            _suggestions.clear();
            if (i.isOdd) return const Divider();
            /*2*/

            final index = i; /*3*/
            if (index >= _suggestions.length) {
              if (widget.passedResult.foods!.length >= 1) {
                for (var i = 0; i < widget.passedResult.foods!.length; i++) {
                  //print(widget.passedResult.foods![i]!.description);
                  _suggestions.add(widget.passedResult.foods![i]!); /*4*/
                }
              }
            }
            return _buildRow(_suggestions[index], false);
          });
    }
  }

  Widget _buildRow(WelcomeFoods food, bool full) {
    final alreadySaved = _saved.contains(food);
    String obj = food.description.toString().titleCase +
        ', ' +
        food.brandName.toString().titleCase;
    if (food.brandName.toString().titleCase == 'Null') {
      obj = food.description.toString().titleCase;
    }

    if (!full) {
      return ListTile(
        title: Text(
          obj,
          style: _biggerFont,
        ),
        trailing: Icon(
          alreadySaved ? Icons.delete : Icons.add_circle_outline,
          color: alreadySaved ? Colors.red : null,
          semanticLabel: alreadySaved ? 'Remove from saved' : 'Save',
        ),
        onTap: () {
          setState(() {
            if (alreadySaved) {
              _saved.remove(food);
            } else {
              _saved.add(food);
            }
          });
        },
      );
    } else {
      return ListTile(
        title: Text(
          '',
          style: _biggerFont,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              pushSaved(context);
            },
          ),
        ],
      ),
      body: _buildSuggestions(),
    );
  }
}

// Generating barcode scanner results
class RandomWords2 extends StatefulWidget {
  final Welcome passedResult;

  RandomWords2(this.passedResult);

  @override
  State<RandomWords2> createState() => _RandomWordsState2();
}

class _RandomWordsState2 extends State<RandomWords2> {
  Widget _buildSuggestions() {
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 1,
        itemBuilder: /*1*/ (context, i) {
          _suggestions.clear();
          if (i.isOdd) return const Divider();
          /*2*/

          final index = i ~/ 2; /*3*/
          if (index >= _suggestions.length) {
            for (var i = 0; i < widget.passedResult.foods!.length; i++) {
              print("OK");

              _suggestions.add(widget.passedResult.foods![i]!); /*4*/
            }
          }
          return _buildRow(_suggestions[index]);
        });
  }

  Widget _buildRow(WelcomeFoods food) {
    final alreadySaved = _saved.contains(food);
    String obj = food.description.toString().titleCase +
        ', ' +
        food.brandName.toString().titleCase;
    if (food.brandName.toString().titleCase == 'Null') {
      obj = food.description.toString().titleCase;
    }
    return ListTile(
      title: Text(
        obj,
        style: _biggerFont,
      ),
      trailing: Icon(
        alreadySaved ? Icons.delete : Icons.add_circle_outline,
        color: alreadySaved ? Colors.red : null,
        semanticLabel: alreadySaved ? 'Remove from saved' : 'Save',
      ),
      onTap: () {
        setState(() {
          if (alreadySaved) {
            _saved.remove(food);
          } else {
            _saved.add(food);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              pushSaved(context);
            },
          ),
        ],
      ),
      body: _buildSuggestions(),
    );
  }
}
