import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class Home extends StatefulWidget {
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  TextEditingController _cepController = TextEditingController();
  List<Map<String, dynamic>> _historico = [];
  bool _loading = false;

  Future<void> _consultarCEP() async {
    setState(() {
      _loading = true;
    });

    String cep = _cepController.text;
    String url = "https://cep.awesomeapi.com.br/json/$cep";
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd/MM/yyyy - HH:mm:ss').format(now);

    try {
      http.Response response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        Map<String, dynamic> endereco = json.decode(response.body);
        endereco['dataHora'] = formattedDate;
        setState(() {
          _historico.insert(0, endereco);
          _loading = false;
        });
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.blue[900],
              title: const Text(
                "CEP Inválido",
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                "Verifique o número e tente novamente.",
                style: TextStyle(color: Colors.white),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _loading = false;
                    });
                  },
                  child: const Text(
                    "OK",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      Map<String, dynamic> erro = {"erro": "Erro ao consultar o CEP: $e"};
      setState(() {
        _historico.insert(0, erro);
        _loading = false;
      });
    }

    _cepController.clear();
  }

  void _openGoogleMaps(double latitude, double longitude) async {
    String googleUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    await launch(googleUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Busca CEP"),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _cepController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      labelText: "Digite o CEP:",
                      labelStyle: TextStyle(color: Colors.black),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _consultarCEP,
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.blue),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                  child: const Text(
                    "Consultar CEP",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: _historico.length,
                    itemBuilder: (BuildContext context, int index) {
                      Map<String, dynamic> item = _historico[index];
                      return _buildResultadoConsulta(item);
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(
                      "Carregando...",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultadoConsulta(Map<String, dynamic> resultado) {
    if (resultado.containsKey('erro')) {
      return ListTile(
        title: Text("Erro: ${resultado['erro']}"),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfo("CEP", resultado['cep']),
            _buildInfo("Logradouro", resultado['address']),
            _buildInfo("Bairro", resultado['neighborhood']),
            _buildInfo("Localidade", resultado['city']),
            _buildInfo("UF", resultado['state']),
            SizedBox(height: 10),
            Text(
              "Data e Hora da Consulta: ${resultado['dataHora']}",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                _openGoogleMaps(double.parse(resultado['lat']),
                    double.parse(resultado['lng']));
              },
              icon: Icon(
                Icons.room,
                color: Colors.blue[900],
              ),
              label: Text(
                "Abrir no Google Maps",
                style: TextStyle(
                  color: Colors.blue[900],
                ),
              ),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildInfo(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
