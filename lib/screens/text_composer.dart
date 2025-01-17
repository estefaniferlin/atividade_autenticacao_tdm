import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TextComposer extends StatefulWidget{
  TextComposer(this.sendMessage);
  final Function({String text, XFile imgFile}) sendMessage;

  @override
  State<StatefulWidget> createState() {
    return TextComposerState();
  }
}

class TextComposerState extends State<TextComposer>{
  final _textController = TextEditingController();
  bool _isComposing = false;
  final picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return IconTheme(
        data: IconThemeData(color: Colors.cyan),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: <Widget>[
              Container(
                child: IconButton(icon: Icon(Icons.photo_camera),
                  onPressed: () async{
                    final img = await picker.pickImage(source: ImageSource.camera);
                    if (img == null)
                      return;
                    widget.sendMessage(imgFile : img);
                  },),
              ),
              Expanded(child: TextField(
                controller: _textController,
                decoration: InputDecoration.collapsed(hintText: "Enviar uma mensagem"),
                onChanged: (text){
                  setState(() {
                    _isComposing = text.length > 0;
                  });
                },
                onSubmitted: (text){
                  print(text);
                  widget.sendMessage(text : _textController.text);
                  _reset();
                },
              )),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                child: IconButton(
                  icon : Icon(Icons.send),
                  onPressed: _isComposing ? (){
                    print(_textController.text);
                    widget.sendMessage(text : _textController.text);
                    _reset();
                  } : null,
                ),
              )
            ],
          ),
        ));
    throw UnimplementedError();
  }

  void _reset(){
    _textController.clear();
    setState(() {
      _isComposing = false;
    });
  }
}