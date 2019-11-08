import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

void main() {
  runApp(MaterialApp(
      title: 'Todo List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primaryColor: Colors.brown, toggleableActiveColor: Colors.brown),
      home: Home()));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _todoController = TextEditingController();
  List _todoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedIndex;

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _todoList = json.decode(data);
      });
    });
  }

  void _addTodo() {
    if (_todoController.text != "") {
      Map<String, dynamic> newTodo = Map();
      newTodo["title"] = _todoController.text;
      newTodo["ok"] = false;
      _todoController.text = "";
      setState(() {
        _todoList.add(newTodo);
        _saveData();
      });
    }
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _todoList.sort((a, b) {
        if(a["ok"] && !b["ok"]) return 1;
        if(!a["ok"] && b["ok"]) return -1;
        else return 0;
      });
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
            "Lista de tarefas",
            style: TextStyle(color: Colors.black54),
          ),
          backgroundColor: Colors.white,
          centerTitle: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: TextField(
                  controller: _todoController,
                  decoration: InputDecoration(
                      labelText: "Nova tarefa",
                      hasFloatingPlaceholder: false,
                      labelStyle: TextStyle(color: Colors.brown)),
                )),
                RaisedButton(
                  color: Colors.brown,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addTodo,
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
              padding: EdgeInsetsDirectional.only(top: 10.0),
              itemCount: _todoList.length,
              itemBuilder: buildItem,
              )
            ),
          )
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
      return Dismissible(
        key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
        background: Container(
          color: Colors.red,
          child: Align(
            alignment: Alignment(-0.9, 0.0),
            child: Icon(Icons.delete, color: Colors.white)
        ),
      ),
        direction: DismissDirection.startToEnd,
        child: CheckboxListTile(
          title: Text(_todoList[index]["title"]),
          value: _todoList[index]["ok"],
          secondary: CircleAvatar(
            backgroundColor: Colors.brown,
            child: (Icon(
              _todoList[index]["ok"]
                  ? Icons.check
                  : Icons.error_outline,
              color: Colors.white,
            )),
          ),
          onChanged: (c) {
            setState(() {
              _todoList[index]["ok"] = c;
              _saveData();
            });
          },
        ),
        onDismissed: (direction) {
          setState(() {
            _lastRemoved = Map.from(_todoList[index]);
            _lastRemovedIndex = index;
            _todoList.removeAt(index);
            _saveData();
          });

          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida"),
            action: SnackBarAction(label: "Desfazer", onPressed: () {
              setState(() {
                _todoList.insert( _lastRemovedIndex, _lastRemoved);
                _saveData();
              });
            },),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);
        },
      );
  }


  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_todoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (error) {
      return null;
    }
  }
}
