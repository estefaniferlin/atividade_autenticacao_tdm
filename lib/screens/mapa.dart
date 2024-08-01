import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding_resolver/geocoding_resolver.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MapSample extends StatefulWidget {
  String? idLocal; // pode vir nulo pq nao temos nenhum map ainda de identificação do local(sera a chave do documento do local armazenado no firestore)
  MapSample({this.idLocal});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller =
  Completer<GoogleMapController>();

  final CollectionReference _locais =
    FirebaseFirestore.instance.collection("locais");

  Set<Marker> _marcadores = {};
  GeoCoder geoCoder = GeoCoder();   //para converter lat e ling em um endereco

  static CameraPosition _posicaoCamera = CameraPosition( // posicao inicial da camera
      target: LatLng(20.5937, 78.9629), zoom: 15);

  _movimentarCamera() async { // quando abrir o mapa num local que ja existe, vai movimentar a camera para aquele local (apenas passa para ele a posição que queremos da camera)
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
        CameraUpdate.newCameraPosition(_posicaoCamera));
  }

  getLocation() async {
    print ("TESTE USER");
    User? user = await FirebaseAuth.instance.currentUser!;
    if (user != null)
      print(user!.displayName);
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
      return;
    } else if (permission == LocationPermission.deniedForever) {
      await Geolocator.openLocationSettings();
      return;
    } else {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );
      _posicaoCamera = CameraPosition(target:
      LatLng(position.latitude, position.longitude), zoom: 15);
      _movimentarCamera();
      print("latitude = ${position.latitude}");
      print("longitude = ${position.longitude}");
      //_addMarcador(LatLng(position.latitude, position.longitude)); // comentando isso quando abrir o mapa na localização atual ele nao vai criar esse marcador, sera criado quando a gente quiser
    }
  }

  _addMarcador(LatLng latLng) async { // chamaremos quando o usuario pressionar longo na tela (precisa criar um marcador e pegar o endereço usando geocoder para gravar no banco de dados)
    Address address =await geoCoder.getAddressFromLatLng(
        latitude: latLng.latitude, longitude: latLng.longitude); // para descobrir o endereco
    String rua = address.addressDetails.road; // pega a rua

    // criar marcador
    Marker marcador = Marker(
        markerId: MarkerId("marcador-${latLng.latitude}=${latLng.longitude}"),
        position: latLng,
        infoWindow: InfoWindow(title: rua) //passar o mouse pelo marcador ira abrir uma janela de informacao
    );
    setState(() {
      _marcadores.add(marcador);
    });
    // gravar no Firestore
    Map<String, dynamic> local = Map();
    local['titulo'] = rua;
    local['latitude'] = latLng.latitude;
    local['longitude'] = latLng.longitude;
    _locais.add(local);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: _posicaoCamera,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: _marcadores,
        myLocationEnabled: true,
        onLongPress: _addMarcador,
      ),
    );
  }

  // para ver se tem que vir de um local existente ou criar um novo
  mostrarLocal(String? idLocal) async{
    DocumentSnapshot local = await _locais.doc(idLocal).get();
    String titulo = local.get("titulo");
    LatLng latLng = LatLng(local.get('latitude'), local.get('longitude'));
    setState((){
      Marker marcador = Marker(
        markerId: MarkerId("marcador=${latLng.latitude}-${latLng.longitude}"),
        position: latLng,
        infoWindow: InfoWindow(title: titulo)
      );
      _marcadores.add(marcador);
      _posicaoCamera = CameraPosition(target: latLng, zoom: 15);
      _movimentarCamera();
    });
  }

  @override
  void initState() {
    super.initState();
    // se tiver identificacao de local, chama mostrarLocal, senao getLocation para pegar a posicao atual
    if (widget.idLocal != null){
      mostrarLocal(widget.idLocal);
    } else{
      getLocation();
    }
    getLocation();
  }

}
