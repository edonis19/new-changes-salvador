// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:salvador_task_management/src/config/providers.dart';
import 'package:salvador_task_management/src/features/pages/interventi_aperti/intervento_aperto_state.dart';
import 'package:salvador_task_management/src/models/intervento_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExpansionItem {
  final String title;
  final List<String> subItems;
  DateTime? ultimaModifica;

  ExpansionItem(this.title, this.subItems);
}

class InterventoDetailsSection extends ConsumerWidget {
  InterventoDetailsSection({super.key});

  final List<ExpansionItem> _items = [
    ExpansionItem('INTERVENTO', [
      'Stato',
      'Numero',
      'Data',
      'Cliente',
      'Tel',
      'Indirizzo',
      'Note',
      'Matricola',
      'Telaio',
      'Targa/N°',
      'Km/Pz',
    ]),
    ExpansionItem('STORICO', [
      'Modificato da',
      'Data Ultima modifica',
    ]),
  ];

  @override
Widget build(BuildContext context, WidgetRef ref) {
  final intervento = ref.watch(interventoApertoStateProvider);
  DateTime? ultimaModifica;

  return SingleChildScrollView(
    child: Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildScaffoldMessage(context), // Mostra il messaggio di avviso
          ..._items.map((item) => _buildExpansionTile(intervento, item, context, ultimaModifica, ref)).toList(),
        ],
      ),
    ),
  );
}


Widget _buildScaffoldMessage(BuildContext context) {
  return FutureBuilder<bool>(
    future: _showScaffoldMessageCondition(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return SizedBox.shrink();
      }
      if (snapshot.data == true) {
        WidgetsBinding.instance!.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Colors.black,
                  ),
                  SizedBox(width: 8), // Spazio tra l'icona e il testo
                  Text(
                    'Attenzione: intervento non sincronizzato',
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
              backgroundColor: Colors.yellow,
            ),
          );
        });
      }
      return SizedBox.shrink();
    },
  );
}



  Future<bool> _showScaffoldMessageCondition() async {
    // Esempio di condizione per mostrare lo Snackbar
    // Sostituire con la logica desiderata
    await Future.delayed(Duration(seconds: 1));
    return true; // Qui dovresti restituire true o false in base alla tua logica
  }

  Widget _buildDataTable(
      Intervento intervento, List<String> subItems, BuildContext context, DateTime? ultimaModifica, WidgetRef ref) {
    List<TableRow> tableRows = [];

    if (subItems.contains('Riga')) {
    } else {
      for (var subItem in subItems) {
        tableRows.add(
          TableRow(
            children: [
              _buildTableCell(context, subItem,
                  isLabel: true, align: TextAlign.left),
              _buildTableCell(context, _buildValue(intervento, subItem, ultimaModifica, ref) ?? '',
                  align: TextAlign.left),
            ],
          ),
        );
      }
    }

    return Table(
      border: TableBorder.all(color: const Color.fromARGB(255, 128, 128, 128)),
      columnWidths: const {
        0: FixedColumnWidth(
            200), // Larghezza fissa per la colonna delle etichette
      },
      defaultColumnWidth:
          const FlexColumnWidth(), // Lascia che la colonna dei valori si adatti automaticamente
      children: tableRows,
    );
  }

  String? _buildValue(Intervento intervento, String subItem, DateTime? ultimaModifica, WidgetRef ref) {
    // final ultimaModifica = DateTime.now();
String? ultimaModificaStringa = ultimaModifica != null 
      ? DateFormat('dd/MM/yyyy HH:mm:ss').format(ultimaModifica)
      : null; // Puoi anche usare una stringa vuota '' se preferisci
    String? dataDocFormatted;
    dataDocFormatted = DateFormat('dd/MM/yyyy').format(intervento.dataDoc);

                          var prefs = ref.read(sharedPreferencesProvider.future);
                      var operatore = prefs.toString();

    switch (subItem) {
      case 'Cliente':
        return intervento.cliente?.descrizione;
      case 'Indirizzo':
        return intervento.cliente?.indirizzo;
      case 'Numero':
        return intervento.numDoc;
      case 'Data':
        return dataDocFormatted;
      case 'Tel':
        return intervento.cliente?.telefono1 ?? '';
      case 'Note':
        return intervento.note ?? '';
      case 'Stato':
        return intervento.status;
      case 'Matricola':
        return intervento.matricola ?? '';
      case 'Telaio':
        return intervento.telaio ?? '';
      case 'Targa/N°':
        return intervento.rifMatricolaCliente ?? '';
      case 'Km/Pz':
        return intervento.contMatricola.toString();
      case 'Descrizione':
        String? descrizioneIntervento =
            intervento.righe.isNotEmpty ? intervento.righe[0].descrizione : '';
        return descrizioneIntervento ?? '';
      case 'Modificato da':
      String? operatore;
        return operatore;
      case 'Data Ultima modifica':
        return ultimaModificaStringa;
      default:
        return '';
    }
  }

  Widget _buildTableCell(BuildContext context, String value,
      {bool isLabel = false, TextAlign align = TextAlign.left}) {
    Color backgroundColor =
        const Color.fromARGB(0, 0, 0, 0);
    if (!isLabel && value == 'MOD') {
      backgroundColor = Colors
          .red;
    } else if (!isLabel && value == 'NO SYNCH') {
      backgroundColor = Colors
          .yellow;
    } else if (!isLabel && value == 'SOS') {
      backgroundColor = Colors
          .grey;
    } else if (!isLabel && value == 'COMPL') {
      backgroundColor = Colors
          .green;
    }

    return TableCell(
      child: Container(
        padding: const EdgeInsets.all(12.0),
        color: backgroundColor, 
        child: Text(
          value,
          textAlign: align,
          style: TextStyle(
            fontWeight: isLabel ? FontWeight.bold : FontWeight.normal,
            fontSize: isLabel ? 16 : null,
            color:
                Colors.black, // Colore del testo bianco per maggiore contrasto
          ),
        ),
      ),
    );
  }

  Widget _buildExpansionTile(
      Intervento intervento, item, BuildContext context, DateTime? ultimaModifica, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            color: _getTitleBackgroundColor(item.title),
            child: Text(
              item.title,
              style: _getTitleTextStyle(item.title),
            ),
          ),
          const SizedBox(height: 10.0),
          _buildDataTable(
            intervento,
            item.subItems,
            context,
            ultimaModifica,
            ref
          ),
        ],
      ),
    );
  }

  Color _getTitleBackgroundColor(String title) {
    if (title == 'INTERVENTO' ||
        title == 'OPERAZIONI DA FARE' ||
        title == 'STORICO') {
      return Colors.orange; // Imposta il colore arancione
    } else {
      return Colors.transparent; // Altrimenti, colore trasparente
    }
  }

  TextStyle _getTitleTextStyle(String title) {
    if (title == 'INTERVENTO' ||
        title == 'OPERAZIONI DA FARE' ||
        title == 'STORICO') {
      return const TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
        color: Color.fromARGB(255, 0, 0, 0),
      );
    } else {
      return TextStyle(
        fontSize: 16.0,
        fontWeight: title.endsWith(':') ? FontWeight.bold : FontWeight.normal,
        color: Colors.blue,
      );
    }
  }
}
