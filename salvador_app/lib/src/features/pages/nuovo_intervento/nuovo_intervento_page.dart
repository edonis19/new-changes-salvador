// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_dropdown_search/reactive_dropdown_search.dart';
import 'package:salvador_task_management/src/features/main_view/main_view.dart';
import 'package:salvador_task_management/src/features/pages/interventi_aperti/generale_details.dart';
import 'package:salvador_task_management/src/features/pages/interventi_aperti/intervento_aperto_state.dart';
import 'package:salvador_task_management/src/features/pages/nuovo_intervento/clienti_controller.dart';
import 'package:salvador_task_management/src/models/intervento_model.dart';
import 'package:salvador_task_management/src/repository/cliente_api_repository.dart';
import 'package:salvador_task_management/src/repository/elencomatricole_repository.dart';
import 'package:salvador_task_management/src/repository/interventi_db_repository.dart';

class NuovoInterventoPage extends ConsumerWidget {
  NuovoInterventoPage({super.key});
  final _targaController = TextEditingController();
  final _clienteController = TextEditingController();
  final _telaioController = TextEditingController();
  final _notaController = TextEditingController();
  final _matricolaController = TextEditingController();
  final _contMatricolaController = TextEditingController();
  final _idClienteController = TextEditingController(); 
  final _codiceClienteController = TextEditingController();
  final _descrizioneClienteController = TextEditingController();
  final _partitaIvaClienteController = TextEditingController();
  final _codFiscaleClienteController = TextEditingController();
  final _indirizzoClienteController = TextEditingController();
  final _capClienteController = TextEditingController();
  final _localitaClienteController = TextEditingController();
  final _provinciaClienteController = TextEditingController();
  final _nazioneClienteController = TextEditingController();
  final _faxClienteController = TextEditingController();
  final _emailClienteController = TextEditingController();
  final _telefono1ClienteController = TextEditingController();
  final _telefono2ClienteController = TextEditingController();
  final _codListinoClienteController = TextEditingController();
  final _categoriaIvaClienteController = TextEditingController();
  final _aspettoBeniClienteController = TextEditingController();
  final _gruppoVenditaClienteController = TextEditingController();
  final _notePalmareClienteController = TextEditingController();
  final _portoClienteController = TextEditingController();
  final _modTrasportoClienteController = TextEditingController();
  final _modConsegnaClienteController = TextEditingController();
  final _causTrasportoClienteController = TextEditingController();
  final _vettoreClienteController = TextEditingController();
  final _pagamentoClienteController = TextEditingController();
  final _abiClienteController = TextEditingController();
  final _cabClienteController = TextEditingController();
  final _contocorrenteClienteController = TextEditingController();
  final _ibanClienteController = TextEditingController();
  final _statusBloccoClienteController = TextEditingController();
  final _datiContabiliClienteController = TextEditingController();
final Map<String, Map<String, String>> tipoInterventoMap = {
  '112271': {'codice': 'RIPAUTES', 'descrizione': 'ORDINE RIPAUTES'},
  '112276': {'codice': 'RIPAUTIN', 'descrizione': 'ORDINE RIPAUTIN'},
  '112274': {'codice': 'RIPCLI', 'descrizione': 'RICHIESTA SERVIZI'}
};



final TextEditingController _selectedTipoDocDescrizioneController = TextEditingController();


  String? _selectedClient = '';
  String? _selectedClientValue;
  String? _selectedTipoDocCodiceValue;
  final _selectedTipoDocDescrizioneValue = TextEditingController();
  int? _selectedTipoDocIdValue;
  //String? _numeroDoc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var clientiData = ref.watch(clientiControllerProvider);
    //var clientiData = ref.watch(clientiCollectionRepositoryProvider);

    final buttonStyle = ElevatedButton.styleFrom(
      foregroundColor: const Color.fromARGB(255, 0, 0, 0),
      textStyle: const TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      side: const BorderSide(
        color: Colors.black,
        width: 2,
      ),
    );

//final nuovoInterventoRepository = ref.read(nuovoInterventoDbRepositoryProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(top: 10),
                alignment: Alignment.topRight,
                child: ElevatedButton.icon(
                  onPressed: () async {

                        double? contMatricola = double.tryParse(_contMatricolaController.text);

                    var interventiDbProvider =
                        ref.read(interventiDbRepositoryProvider.notifier);

                    int idCliente = int.tryParse(_idClienteController.text) ?? 0;

                    final nuovoIntervento = Intervento(
                        id: null,
                        idTestata: DateTime.now().microsecondsSinceEpoch * -1,
                        barcode: null,
                        numDoc: 'null',
                        dataDoc: DateTime.now(),
                        totaleDoc: null,
                        tipoDoc: TipoDoc(
                            id: _selectedTipoDocIdValue,
                            codice: _selectedTipoDocCodiceValue,
                            descrizione: _selectedTipoDocDescrizioneValue.text),
                        cliente: InterventoCliente(
                          id: idCliente,
                          codice: _clienteController.text,
                          descrizione: _descrizioneClienteController.text,
                          partitaIva: _partitaIvaClienteController.text,
                          codFiscale: _codFiscaleClienteController.text,
                          indirizzo: _indirizzoClienteController.text,
                          cap: _capClienteController.text,
                          localita: _localitaClienteController.text,
                          provincia: _provinciaClienteController.text,
                          nazione: _nazioneClienteController.text,
                          fax: _faxClienteController.text,
                          email: _emailClienteController.text,
                          telefono1: _telefono1ClienteController.text,
                          telefono2: _telefono2ClienteController.text,
                          codListino: _codListinoClienteController.text,
                          categoriaIva: _categoriaIvaClienteController.text,
                          aspettoBeni: _aspettoBeniClienteController.text,
                          gruppoVendita: _gruppoVenditaClienteController.text,
                          notePalmare: _notePalmareClienteController.text,
                          porto: _portoClienteController.text,
                          modTrasporto: _modTrasportoClienteController.text,
                          modConsegna: _modConsegnaClienteController.text,
                          causTrasporto: _causTrasportoClienteController.text,
                          vettore: _vettoreClienteController.text,
                          pagamento: _pagamentoClienteController.text,
                          abi: _abiClienteController.text,
                          cab: _cabClienteController.text,
                          contocorrente: _contocorrenteClienteController.text,
                          iban: _ibanClienteController.text,
                          statusBlocco: _statusBloccoClienteController.text,
                          datiContabili: _datiContabiliClienteController.text,
                        ),
                        status: 'NO SYNCH',
                        magazzino: null,
                        metodoPagamento: null,
                        dataConsegna: null,
                        indirizzoSpedizione: null,
                        modalitaSpedizione: null,
                        totaleDocumento: null,
                        modTrasp: null,
                        modCons: null,
                        aspBeni: null,
                        causTrasp: null,
                        vettore: null,
                        totPesoLordo: null,
                        totPesoNetto: null,
                        totVolume: null,
                        numColli: null,
                        numPallet: null,
                        stPrezziDdt: null,
                        telefono1: null,
                        telefono2: null,
                        matricola: _matricolaController.text,
                        telaio: _telaioController.text,
                        rifMatricolaCliente: _targaController.text,
                        contMatricola: contMatricola,
                        note: _notaController.text,
                        righe: []
                        );

                    interventiDbProvider.addOrUpdate(nuovoIntervento);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Intervento salvato con successo!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.of(context).pop();

                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const MainView(),
                    ));
                    _showDetailsPageNuovoIntervento(nuovoIntervento, context, ref);
                  },
                  icon: const Icon(Icons.save, color: Colors.black),
                  label: const Text(
                    'Salva',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: buttonStyle,
                ),
              ),
              const SizedBox(height:20),
               Row(
  children: [
    Expanded(
      child: TextField(
        controller: _clienteController,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: "Inserisci codice cliente",
          hintStyle: const TextStyle(color: Colors.black),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          filled: true,
          fillColor: const Color.fromARGB(255, 255, 255, 255),
        ),
        onChanged: (value) async {
          // final repository = ref.read(elencoMatricoleApiRepositoryProvider);
          // final matricola = await repository.getMatricola(
          //   utente: 'ADMIN',
          //   rifMatricolaCliente: targa,
          // );
          // if (matricola != null && matricola[0]['codice'] != null) {
          //   _matricolaController.text = matricola[0]['codice'].toString(); 
          //   _telaioController.text = matricola[0]['telaio'].toString();
          // }
        },
      ),
    ),
    IconButton(
      icon: Icon(Icons.search),
      onPressed: () async {
        final repository = ref.read(clienteElencoApiRepositoryProvider);
final resultClient = await repository.getCliente(
  codiceCiente: _clienteController.text,
);

if (resultClient != null && resultClient.isNotEmpty) {
  _idClienteController.text = resultClient['id'].toString(); 
  _codiceClienteController.text = resultClient['codice'].toString();
  _descrizioneClienteController.text = resultClient['descrizione'].toString();
  _partitaIvaClienteController.text = resultClient['partitaIva'].toString();
  _codFiscaleClienteController.text = resultClient['codFiscale'].toString();
  _indirizzoClienteController.text = resultClient['indirizzo'].toString();
  _capClienteController.text = resultClient['cap'].toString();
  _localitaClienteController.text = resultClient['localita'].toString();
  _provinciaClienteController.text = resultClient['provincia'].toString();
  _nazioneClienteController.text = resultClient['nazione'].toString();
  _faxClienteController.text = resultClient['fax'].toString();
  _emailClienteController.text = resultClient['email'].toString();
  _telefono1ClienteController.text = resultClient['telefono1'].toString();
  _telefono2ClienteController.text = resultClient['telefono2'].toString();
  _codListinoClienteController.text = resultClient['codListino'].toString();  
 _categoriaIvaClienteController.text = resultClient['categoriaIva'].toString();
 _aspettoBeniClienteController.text = resultClient['aspettoBeni'].toString();
 _gruppoVenditaClienteController.text = resultClient['gruppoVendita'].toString();
 _notePalmareClienteController.text =  resultClient['notePalmare'].toString();
 _portoClienteController.text =resultClient['porto'].toString();
 _modTrasportoClienteController.text =resultClient['modTrasporto'].toString();
 _modConsegnaClienteController.text = resultClient['modConsegna'].toString();
 _causTrasportoClienteController.text = resultClient['causTrasporto'].toString();
 _vettoreClienteController.text = resultClient['vettore'].toString(); 
 _pagamentoClienteController.text = resultClient['pagamento'].toString();  
 _abiClienteController.text = resultClient['abi'].toString(); 
 _cabClienteController.text = resultClient['cab'].toString(); 
 _contocorrenteClienteController.text = resultClient['contocorrente'].toString();
 _ibanClienteController.text = resultClient['iban'].toString(); 
 _statusBloccoClienteController.text = resultClient['statusBlocco'].toString(); 
_datiContabiliClienteController.text = resultClient['datiContabili'].toString();
} else {
   _idClienteController.text = ''; 
  _codiceClienteController.text = '';
  _descrizioneClienteController.text = '';
  _partitaIvaClienteController.text = '';
  _codFiscaleClienteController.text = '';
  _indirizzoClienteController.text = '';
  _capClienteController.text = '';
  _localitaClienteController.text = '';
  _provinciaClienteController.text = '';
  _nazioneClienteController.text = '';
  _faxClienteController.text = '';
  _emailClienteController.text = '';
  _telefono1ClienteController.text = '';
  _telefono2ClienteController.text = '';
}
      }
    ),
  ],
),
              const SizedBox(height: 20),
              TextField(
                controller: _descrizioneClienteController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: "Visualizza il cliente",
                  hintStyle: const TextStyle(color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 255, 255, 255),
                ),
              ),
               const SizedBox(height: 20),
Row(
  children: [
    Expanded(
      child: TextField(
        controller: _selectedTipoDocDescrizioneController,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: "Inserisci tipo intervento",
          hintStyle: const TextStyle(color: Colors.black),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          filled: true,
          fillColor: const Color.fromARGB(255, 255, 255, 255),
        ),
      ),
    ),
    IconButton(
      icon: Icon(Icons.search),
      onPressed: () async {
        // Cerca il codice corrispondente alla descrizione inserita
        String value = _selectedTipoDocDescrizioneController.text;
        String? codice = tipoInterventoMap.keys.firstWhere(
          (key) => tipoInterventoMap[key]!['codice'] == value,
        );

        if (codice != null) {
          _selectedTipoDocIdValue = int.parse(codice);
          _selectedTipoDocCodiceValue = value;
          _selectedTipoDocDescrizioneValue.text = tipoInterventoMap[codice]!['descrizione']!;
        }
      },
    ),
  ],
),
 const SizedBox(height: 20),
TextField(
  controller: _contMatricolaController,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  style: const TextStyle(color: Colors.black),
  decoration: InputDecoration(
    hintText: "Inserisci Km/Pz",
    hintStyle: const TextStyle(color: Colors.black),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    filled: true,
    fillColor: const Color.fromARGB(255, 255, 255, 255),
  ),
),
const SizedBox(height: 20),
              TextField(
                controller: _notaController,
                maxLines: 10,
                maxLength: 500,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: "Inserisci una nota",
                  hintStyle: const TextStyle(color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 255, 255, 255),
                ),
              ),
const SizedBox(height: 20),
TextField(
  controller: _selectedTipoDocDescrizioneValue,
  style: const TextStyle(color: Colors.black),
  decoration: InputDecoration(
    hintText: "Visualizza descrizione tipo doc",
    hintStyle: const TextStyle(color: Colors.black),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    filled: true,
    fillColor: const Color.fromARGB(255, 255, 255, 255),
  ),
  readOnly: false,
),
const SizedBox(height: 20),
Row(
  children: [
    Expanded(
      child: TextField(
        controller: _targaController,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: "Inserisci la targa",
          hintStyle: const TextStyle(color: Colors.black),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          filled: true,
          fillColor: const Color.fromARGB(255, 255, 255, 255),
        ),
        onChanged: (value) async {
          // final repository = ref.read(elencoMatricoleApiRepositoryProvider);
          // final matricola = await repository.getMatricola(
          //   utente: 'ADMIN',
          //   rifMatricolaCliente: targa,
          // );
          // if (matricola != null && matricola[0]['codice'] != null) {
          //   _matricolaController.text = matricola[0]['codice'].toString(); 
          //   _telaioController.text = matricola[0]['telaio'].toString();
          // }
        },
      ),
    ),
    IconButton(
      icon: Icon(Icons.search),
      onPressed: () async {
        final repository = ref.read(elencoMatricoleApiRepositoryProvider);
final matricola = await repository.getMatricola(
  utente: 'ADMIN',
  rifMatricolaCliente: _targaController.text,
);

if (matricola != null && matricola.isNotEmpty) {
  _matricolaController.text = matricola[0]['codice'].toString(); 
  _telaioController.text = matricola[0]['telaio'].toString();
} else {
  _matricolaController.text = ''; 
  _telaioController.text = '';

}
      },
    ),
  ],
),
const SizedBox(height: 20),
TextField(
  controller: _matricolaController,
  style: const TextStyle(color: Colors.black),
  decoration: InputDecoration(
    hintText: "Matricola",
    hintStyle: const TextStyle(color: Colors.black),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: const BorderSide(color: Colors.grey),
    ),
    filled: true,
    fillColor: const Color.fromARGB(255, 255, 255, 255),
  ),
  readOnly: false, // Imposta il campo di testo come non modificabile
),
              const SizedBox(height: 20),
              TextField(
                controller: _telaioController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: "Inserisci il telaio",
                  hintStyle: const TextStyle(color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  filled: true,
                  fillColor: const Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _validateFields() {
    return _targaController.text.isNotEmpty &&
        _telaioController.text.isNotEmpty &&
        _selectedClient!.isNotEmpty;
  }

  void _showDetailsPageNuovoIntervento(
      Intervento nuovoIntervento, BuildContext context, WidgetRef ref) {
    //String righeDescrizione = 'null';
    //String righeDaFareDescrizione = 'null';
    //String? righeStatusEvasione = intervento.righe.isNotEmpty ? intervento.righe[0].statusEvasione : '';
    ref.read(interventoApertoStateProvider.notifier).setIntervento(nuovoIntervento);
    //String? operatore = 'admin';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DetailsPage(),
      ),
    );
  }
}
