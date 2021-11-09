import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(
    MaterialApp(
        theme: ThemeData(fontFamily: 'Prestine'),
        home: Home(),
        debugShowCheckedModeBanner: false),
  );
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List _toDoList = [];
  late Map<String, dynamic> _lastRemoved;
  int? _lastRemovedPos;

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data!);
      });
    });
  }

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoController.text;
      FocusScope.of(context).requestFocus(FocusNode()); //esconder teclado
      _toDoController.text = "";
      newToDo["Ok"] = false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b) {
        if (a["Ok"] && !b["Ok"])
          return 1;
        else if (!a["Ok"] && b["Ok"])
          return -1;
        else
          return 0;
      });
      _saveData();
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 65,
        title: Text("Lista de tarefas"),
        backgroundColor: Color(0xFF0D0C1D),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Divider(
            color: Colors.transparent,
          ),
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: [
                Form(
                  key: _formKey,
                  child: Expanded(
                    child: TextFormField(
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'informe o nome da tarefa';
                        }
                      },
                      controller: _toDoController,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF073B4C),
                          ),
                        ),
                        labelText: "Nova tarefa",
                        labelStyle: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _addToDo();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Tarefa salva com sucesso !'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        primary: Color(0xFF474973),
                        padding:
                            EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                        textStyle: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.bold),),
                    child: Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: Colors.transparent,
          ),
          Divider(
            color: Colors.transparent,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem),
            ),
          ),
        ],
      ),
    );
  }

  // responsavel para mostrar os itens da lista
  Widget buildItem(context, index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        checkColor: Colors.black,
        title: Text(
          _toDoList[index]["title"],
        ),
        value: _toDoList[index]["Ok"],
        secondary: CircleAvatar(
          backgroundColor: Color(0xFFA69CAC),
          child: Icon(
            _toDoList[index]["Ok"] ? Icons.check : Icons.error,
            color: Color(0xFF000000),
          ),
        ),
        onChanged: (c) {
          setState(() {
            _toDoList[index]["Ok"] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);
          _saveData();
          final snack = SnackBar(
            content: Text("Tarefa ''${_lastRemoved["title"]}'' Removida"),
            action: SnackBarAction(
                label: "Desfazer",
                onPressed: () {
                  setState(() {
                    _toDoList.insert(_lastRemovedPos!, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 2),
          );
          ScaffoldMessenger.maybeOf(context)!.removeCurrentSnackBar();
          ScaffoldMessenger.maybeOf(context)!.showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String?> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
