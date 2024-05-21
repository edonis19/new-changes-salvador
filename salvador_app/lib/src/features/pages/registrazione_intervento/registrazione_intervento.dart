// ignore_for_file: unnecessary_null_comparison, use_build_context_synchronously, unnecessary_string_interpolations

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salvador_task_management/src/config/providers.dart';
import 'package:salvador_task_management/src/features/pages/articoli/articoli_controller.dart';
import 'package:salvador_task_management/src/features/pages/interventi_aperti/intervento_aperto_state.dart';
import 'package:salvador_task_management/src/features/pages/registrazione_intervento/articoli_datasource.dart';
import 'package:salvador_task_management/src/features/pages/registrazione_intervento/articoli_datasource_columns.dart';
import 'package:salvador_task_management/src/models/articolo_model.dart';
import 'package:salvador_task_management/src/models/intervento_model.dart';
import 'package:salvador_task_management/src/repository/add_righe_repository.dart';
import 'package:salvador_task_management/src/repository/allegati_marca_api_repository.dart';
import 'package:salvador_task_management/src/repository/allegati_modello_api_repository.dart';
import 'package:salvador_task_management/src/repository/disponibilita_articoli_api_repository.dart';
import 'package:salvador_task_management/src/repository/elencomatricole_repository.dart';
import 'package:salvador_task_management/src/repository/get_allegato_api_repository.dart';
import 'package:salvador_task_management/src/repository/interventi_db_repository.dart';
import 'package:salvador_task_management/src/repository/invio_allegato_repository.dart';
import 'package:salvador_task_management/src/repository/movimento_magazzino.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:roundcheckbox/roundcheckbox.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';


// ignore: must_be_immutable
class RegistrazioneInterventoPage extends ConsumerWidget {

  TimeOfDay? initialStartTime;
  TimeOfDay? initialEndTime;
  Articolo? articolo;
  Intervento? articoloIntervento;
  double? nuovaQuantita;
  double? quantity;
  String? notes;

  RegistrazioneInterventoPage({
    super.key,
    this.articolo,
    this.nuovaQuantita,
    this.articoloIntervento,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intervento = ref.watch(interventoApertoStateProvider);
    int numeroAllegati = AllegatiManager.allegatiTemporanei.length;

    double screenWidth = MediaQuery.of(context).size.width;

    final columns = articoliInterventiDataSourceColumns();

    return LayoutBuilder(
      builder: (context, constraints) {
        String? dataDocFormatted;
        if (intervento != null) {
          dataDocFormatted =
              DateFormat('dd/MM/yyyy').format(intervento.dataDoc);
        } else {}

        return Scaffold(
          appBar: AppBar(
            title: Text(
                '${intervento.numDoc} - $dataDocFormatted - ${intervento.cliente?.descrizione}'),
            backgroundColor: const Color.fromARGB(255, 236, 201, 148),
          ),
          body: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (screenWidth < 600) ...[
                  _buildButton(
                    onPressed: () {
                      _showAggiungiArticoloDialog(context, ref, intervento);
                    },
                    icon: Icons.construction,
                    label: 'Aggiungi Articolo',
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                  const SizedBox(height: 20),
                  _buildButton(
                    onPressed: () {
                      _showAggiungiNotaDialog(context, ref);
                    },
                    icon: Icons.note_add,
                    label: 'Aggiungi Nota',
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                  const SizedBox(height: 20),
                  _buildButton(
                    onPressed: () {
                      List<PlatformFile> files =
                          [];
                      _showAllegatiDialog(
                          context, files, intervento.rifMatricolaCliente ?? '', ref, intervento.idTestata);
                    },
                    icon: Icons.attach_file,
                    label: 'Allegati',
                    color: const Color.fromARGB(255, 255, 255, 255),
                    badgeCount: numeroAllegati,
                  ),
                  const SizedBox(height: 20),
                  _buildButton(
                          onPressed: () {
                            _showMainDialog(context, ref, intervento.rifMatricolaCliente ?? '');
                          },
                    icon: Icons.file_copy,
                    label: 'Doc. Tecnica',
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                  const SizedBox(height: 20),
                  Consumer(builder: ((context, ref, child) {
                    final intervento = ref.watch(interventoApertoStateProvider);

                    final prefs =
                        ref.read(sharedPreferencesProvider).asData!.value;

                    return Expanded(
                      child: SfDataGrid(
                        source: ArticoliInterventoDataSource(
                            intervento, prefs, ref),
                        columns: columns,
                        columnWidthMode: ColumnWidthMode.fill,
                        headerGridLinesVisibility:
                            GridLinesVisibility.horizontal,
                        gridLinesVisibility: GridLinesVisibility.both,
                        allowEditing: true,
onCellTap: (details) {
  final int idRiga = int.parse(details.rowColumnIndex.rowIndex.toString());
  final riga = intervento.righe.firstWhereOrNull((element) => element.riga == idRiga);
  
  if (riga != null) {
    final idRigaModify = riga.idRiga;

    if (idRigaModify == null) {
      final String columnName = details.column.columnName;
      double qtaArt = riga.qta ?? 0.0;

      if ([
        'SMANCAR',
        'SMANCLI',
        'SMANEST',
        'SMANEST+40%',
        'SMANESTFES',
        'SMANFES',
        'SMANINT',
        'SMANSTD'
      ].contains(riga.articolo?.codice ?? '')) {
          modifyDurataDialog(context, riga, nuovaQuantita, ref);
      } else {
        if (columnName == 'quantita') {
          modifyDettagliDialog(context, articolo, intervento, ref, riga, nuovaQuantita, qtaArt, notes ?? '');
        }
      }
    }
                          }
                        },
                      ),
                    );
                  }))
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildButton(
                          onPressed: () {
                            _showAggiungiArticoloDialog(
                                context, ref, intervento);
                          },
                          icon: Icons.construction,
                          label: 'Aggiungi Articolo',
                          color: const Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildButton(
                          onPressed: () {
                            _showAggiungiNotaDialog(context, ref);
                          },
                          icon: Icons.note_add,
                          label: 'Aggiungi Nota',
                          color: const Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildButton(
                          onPressed: () {
                            List<PlatformFile> files =
                                [];
                            _showAllegatiDialog(context, files,
                                intervento.rifMatricolaCliente ?? '', ref, intervento.idTestata);
                          },
                            icon: Icons.attach_file,
  label: 'Allegati',
  color: const Color.fromARGB(255, 255, 255, 255),
  badgeCount: numeroAllegati,
),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildButton(
                          onPressed: () {
                            _showMainDialog(context, ref, intervento.rifMatricolaCliente ?? '');
                          },
                          icon: Icons.file_copy,
                          label: 'Doc. Tecnica',
                          color: const Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Consumer(builder: ((context, ref, child) {
                    final intervento = ref.watch(interventoApertoStateProvider);

                    final prefs =
                        ref.read(sharedPreferencesProvider).asData!.value;

                    return Expanded(
                      child: SfDataGrid(
                        source: ArticoliInterventoDataSource(
                            intervento, prefs, ref),
                        columns: columns,
                        columnWidthMode: ColumnWidthMode.fill,
                        headerGridLinesVisibility:
                            GridLinesVisibility.horizontal,
                        gridLinesVisibility: GridLinesVisibility.both,
                        allowEditing: true,
onCellTap: (details) {
  final int idRiga = int.parse(details.rowColumnIndex.rowIndex.toString());
  final riga = intervento.righe.firstWhereOrNull((element) => element.riga == idRiga);
  
  if (riga != null) {
    final idRigaModify = riga.idRiga;

    if (idRigaModify == null) {
      final String columnName = details.column.columnName;
      double qtaArt = riga.qta ?? 0.0;

      if ([
        'SMANCAR',
        'SMANCLI',
        'SMANEST',
        'SMANEST+40%',
        'SMANESTFES',
        'SMANFES',
        'SMANINT',
        'SMANSTD'
      ].contains(riga.articolo?.codice ?? '')) {
          modifyDurataDialog(context, riga, nuovaQuantita, ref);
      } else {
        if (columnName == 'quantita') {
          modifyDettagliDialog(context, articolo, intervento, ref, riga, nuovaQuantita, qtaArt, notes ?? '');
        }
      }
    }
                          }
                        },
                      ),
                    );
                  }))
                ],
                SizedBox(
                  height: 60,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
onPressed: () async {
  try {

    List<RigaInvio> righe = [];

    for (var riga in intervento.righe) {
      RigaInvio nuovaRiga;
      
      if (riga.articolo?.codice == 'SMANCAR'        ||
          riga.articolo?.codice == 'SMANCLI'        ||
          riga.articolo?.codice == 'SMANEST'        ||
          riga.articolo?.codice == 'SMANEST+40%'    ||
          riga.articolo?.codice == 'SMANESTFES'     ||
          riga.articolo?.codice == 'SMANFES'        ||
          riga.articolo?.codice == 'SMANINT'        ||
          riga.articolo?.codice =='SMANSTD') {
        nuovaRiga = RigaInvio(
          id: null,
          idRiga: riga.idRiga,
          riga: riga.riga,
          descrizione: riga.descrizione,
          articolo: InterventoArticoloInvio(
            id: riga.articolo?.id,
            codice: riga.articolo?.codice,
            descrizione: riga.articolo?.descrizione,
          ),
          tipoRiga: null,
          qta: riga.qta,
          dtOraIni: riga.dtOraIni.toString(),
          dtOraFin: riga.dtOraFin.toString(),
          operatore: riga.operatore,
          note: riga.note,
          noteDaStampare: null,
          matricola: riga.matricola,
          dtOraIns: riga.dtOraIns.toString(),
          info: null,
          warning: null,
          error: null, 
        );
      } else {
        nuovaRiga = RigaInvio(
          id: null,
          idRiga: riga.idRiga,
          riga: riga.riga,
          descrizione: riga.descrizione,
          articolo: InterventoArticoloInvio(
            id: riga.articolo?.id,
            codice: riga.articolo?.codice,
            descrizione: riga.articolo?.descrizione,
          ),
          tipoRiga: null,
          qta: riga.qta,
          dtOraIni: null,
          dtOraFin: null,
          operatore: riga.operatore,
          note: riga.note,
          noteDaStampare: null,
          matricola: riga.matricola,
          dtOraIns: riga.dtOraIns.toString(),
          info: null,
          warning: null,
          error: null, 
        );
      }

      righe.add(nuovaRiga);
    }

    final result = await ref.read(addRigheApiRepositoryProvider).updateRighe(
      idTestata: intervento.idTestata,
      numDoc: intervento.numDoc,
      dataDoc: intervento.dataDoc.toString(),
      note: intervento.note,
      matricola: intervento.matricola,
      telaio: intervento.telaio,
      rifMatricolaCliente: intervento.rifMatricolaCliente,
      contMatricola: intervento.contMatricola,
      righe: righe,
      status: 'SOS',
      idCliente: intervento.cliente?.id,
      codiceCliente: intervento.cliente?.codice,
      descrizioneCliente: intervento.cliente?.descrizione,
      idTipoDoc: intervento.tipoDoc?.id,
      codiceTipoDoc: intervento.tipoDoc?.codice,
      descrizioneTipoDoc: intervento.tipoDoc?.descrizione,
    );

    final resultMap = result as Map<String, dynamic>;
    final resultValue = resultMap['result'] as String;
    final errorList = resultMap['errorList'] as List<dynamic>;

if (resultValue == 'OK') {
  final docId = resultMap['docId'] as int;

  Map<String, dynamic> params = {};

  Map<String, dynamic> resultMapDocId = {
    'docId': docId,
  };

  addRigaQuantita(articolo, ref, params, resultMapDocId);

  chiudiGiornata = true;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Documento registrato con successo.'),
      backgroundColor: Colors.green,
    ),
  );
      //Navigator.pop(context);
    } else {
      final errorMessage = errorList.isNotEmpty ? errorList.first.toString() : 'Errore sconosciuto';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: $errorMessage'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Si è verificato un errore: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
},
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                            textStyle: const TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              side: const BorderSide(
                                color: Colors.black,
                                width: 1,
                              ),
                            ),
                            minimumSize: const Size(double.infinity, 60),
                          ),
                          icon: const Icon(Icons.close),
                          label: const Text('Chiudi giornata'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black,
                            textStyle: const TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              side: const BorderSide(
                                color: Colors.black,
                                width: 1,
                              ),
                            ),
                            minimumSize: const Size(double.infinity, 60),
                          ),
                          icon: const Icon(Icons.check),
                          label: const Text('Completa Intervento'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


Widget _buildButton({
  required VoidCallback onPressed,
  required IconData icon,
  required String label,
  required Color color,
  double height = 50.0,
  int badgeCount = 0, // Nuovo parametro per il numero di allegati
}) {
  return Container(
    height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
    ),
    child: TextButton(
      onPressed: onPressed,
      style: buttonStyle.copyWith(
        backgroundColor: MaterialStateProperty.all(color),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.black),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
          if (badgeCount > 0) // Condizione per mostrare il badge
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}



  final buttonStyle = TextButton.styleFrom(
    foregroundColor: Colors.black,
    textStyle: const TextStyle(
      fontSize: 15.0,
      fontWeight: FontWeight.bold,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.0),
      side: const BorderSide(
        color: Colors.black,
        width: 1,
      ),
    ),
  );

bool chiudiGiornata = false;

Future<void> _showAllegatiDialog(
  BuildContext context,
  List<PlatformFile> files,
  String rifMatricolaCliente,
  WidgetRef ref,
  int idTestata,
) async {
  String? tipoAllegato;
  String descrizioneAllegato = '';
  Intervento? intervento;
  
  var interventiDbProvider = ref.watch(interventiDbRepositoryProvider.notifier);
  var interventi = await interventiDbProvider.build();
  
  intervento = interventi.firstWhereOrNull((intervento) => intervento.idTestata == idTestata);

  if (intervento == null) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.dangerous),
                SizedBox(width: 2),
                Text('Errore'),
              ],
          ),
          content: const Text('Impossibile trovare l\'intervento'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    return;
  }

  var riga;
  var docId;

  if (idTestata < 0) {
    if (!chiudiGiornata) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.dangerous),
                SizedBox(width: 2),
                Text('Attenzione'),
              ],
            ),
            content: const Text("Devi chiudere la giornata o completare l'intervento prima di poter aggiungere allegati"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }
    riga = intervento.righe.lastWhereOrNull((riga) => riga.idTestata == idTestata);
    docId = riga?.docId;
  } else {
    docId = intervento.idTestata;
  }

  AllegatiManager.allegatiTemporanei.addAll(files);

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.attach_file),
                const SizedBox(width: 2),
                Text('ALLEGATI'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (AllegatiManager.allegatiTemporanei.isNotEmpty) ...[
                  for (int i = 0; i < AllegatiManager.allegatiTemporanei.length; i++)
                    InkWell(
                      onTap: () {
                        _openFile(AllegatiManager.allegatiTemporanei[i].path!);
                      },
                      child: Row(
                        children: [
                          Expanded(child: Text(AllegatiManager.allegatiTemporanei[i].name)),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                AllegatiManager.allegatiTemporanei.removeAt(i);
                              });
                            },
                            icon: const Icon(Icons.delete),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                ],
                Align(
                  alignment: Alignment.center,
                  child: IconButton(
                    onPressed: () async {
                      final result = await showDialog<String>(
                        context: context,
                        builder: (BuildContext context) {
                          return SimpleDialog(
                            title: const Text('Aggiungi Allegati'),
                            children: <Widget>[
                              SimpleDialogOption(
                                onPressed: () async {
                                  final imagePicker = ImagePicker();
                                  final XFile? pickedImage =
                                      await imagePicker.pickImage(
                                    source: ImageSource.camera,
                                  );
                                  if (pickedImage != null) {
                                    File newFile = File(pickedImage.path);
                                    PlatformFile platformFile = PlatformFile(
                                      name: pickedImage.path.split('/').last,
                                      path: pickedImage.path,
                                      size: await newFile.length(),
                                    );
                                    setState(() {
                                      AllegatiManager.allegatiTemporanei.add(platformFile);
                                    });
                                    Navigator.pop(context, 'ScattaFoto');
                                    Navigator.pop(context);
                                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RegistrazioneInterventoPage()));
                                    
                                  }
                                },
                                child: const Text('Scatta Foto'),
                              ),
                              SimpleDialogOption(
                                onPressed: () async {
                                  final result =
                                      await FilePicker.platform.pickFiles(
                                    allowMultiple: true,
                                    type: FileType.custom,
                                    allowedExtensions: [
                                      'jpg',
                                      'pdf',
                                      'doc',
                                      'docx'
                                    ],
                                  );

                                  if (result != null) {
                                    setState(() {
                                      AllegatiManager.allegatiTemporanei.addAll(result.files);
                                    });
                                  }
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RegistrazioneInterventoPage()));
                                },
                                child: const Text('Scegli File'),
                              ),
                            ],
                          );
                        },
                      );

                      if (result == 'ScattaFoto') {
                      } else if (result == 'VisualizzaAllegati') {
                      }
                    },
                    icon: const Icon(Icons.add),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Descrizione Allegato',
                  ),
                  onChanged: (value) {
                    descrizioneAllegato = value;
                  },
                ),
              ],
            ),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: const BorderSide(color: Colors.grey),
                        ),
                      ),
                      child: const Text(
                        'Annulla',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        for (var allegato in AllegatiManager.allegatiTemporanei) {
                          File file = File(allegato.path!);
                          List<int> fileBytes = await file.readAsBytes();
                          String base64File = base64Encode(fileBytes);
                          String extension = path.extension(allegato.name).toUpperCase().substring(1);

                          String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

                          final result = await ref
                              .read(invioAllegatoApiRepositoryProvider)
                              .sendAttachment(
                                docId: docId,
                                tipoAll: 'OR',
                                nomeAllegato: allegato.name,
                                descrizioneAllegato: descrizioneAllegato,
                                tipoAllegato: extension,
                                fileSize: allegato.size.toString(),
                                created: formattedDate,
                                base64File: base64File,
                              );

                          if (result != null) {
                            final resultMap = result as Map<String, dynamic>;
                            final resultValue = resultMap['result'] as String;

                            if (resultValue == 'OK') {
                              // Mostriamo un messaggio di successo
                              AllegatiManager.allegatiTemporanei.clear();
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Allegato inviato'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } 
                          } else {
                            // Gestisci il caso in cui result sia null
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Errore durante l\'invio dell\'allegato.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: const BorderSide(color: Colors.grey),
                        ),
                      ),
                      child: const Text(
                        'Invia',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _openFile(String path) async {
  final url = 'file://$path';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Impossibile aprire il file';
  }
}



void _showMainDialog(BuildContext context, WidgetRef ref, String rifMatricolaCliente) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return SimpleDialog(
        title: Text('Scegli un opzione'),
        children: [
          SimpleDialogOption(
            onPressed: () async {
              final result = await ref
                  .read(elencoMatricoleApiRepositoryProvider)
                  .getMatricola(utente: 'ADMIN', rifMatricolaCliente: rifMatricolaCliente);

              if (result != null && result is List) {
                for (final item in result) {
                  if (item is Map<String, dynamic>) {
                    final marca = item['marca'] as String?;
                    if (marca != null) {
                      final marcaResult = await ref
                          .read(allegatiMarcaApiRepositoryProvider)
                          .getMarca(codice: marca);
                          
                      if (marcaResult != null && marcaResult is List) {
                        final List<dynamic> allegati = marcaResult[0]['allegati'];
                        final List<Widget> allegatiWidgets = [];

                        for (final allegato in allegati) {
                          final idAllegato = allegato['id'] as int?;
                          final nomeAllegato = allegato['nome'] as String?;
                          if (idAllegato != null && nomeAllegato != null) {
                            final idAllegatoResult = await ref
                                .read(getAllegatoApiRepositoryProvider)
                                .getAllegato(utente: 'ADMIN', idAllegato: idAllegato);
                            if (idAllegatoResult != null && idAllegatoResult is List) {
                              allegatiWidgets.add(
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(nomeAllegato),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.download),
                                      onPressed: () async {
                                        final directory = await getTemporaryDirectory();
                                        final savePath = '${directory.path}/$nomeAllegato';

                                        await FlutterDownloader.enqueue(
                                          url: idAllegatoResult[0]['base64File'], // Assicurati che questo sia l'URL base64 corretto
                                          savedDir: directory.path,
                                          fileName: nomeAllegato,
                                          showNotification: true,
                                          openFileFromNotification: true,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        }

                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Marca: $marca'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 10),
                                  Column(
                                    children: allegatiWidgets,
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text('Chiudi'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    }
                  }
                }
              }
            },
            child: Text('MARCA'),
          ),
          SimpleDialogOption(
            onPressed: () async {
              final result = await ref
                  .read(elencoMatricoleApiRepositoryProvider)
                  .getMatricola(utente: 'ADMIN', rifMatricolaCliente: rifMatricolaCliente);

              if (result != null && result is List) {
                for (final item in result) {
                  if (item is Map<String, dynamic>) {
                    final modello = item['modello'] as String?;
                    if (modello != null) {
                      final marcaResult = await ref
                          .read(allegatiModelloApiRepositoryProvider)
                          .getModello(codice: modello);
                          
                      if (marcaResult != null && marcaResult is List) {
                        final List<dynamic> allegati = marcaResult[0]['allegati'];
                        final List<Widget> allegatiWidgets = [];

                        for (final allegato in allegati) {
                          final idAllegato = allegato['id'] as int?;
                          final nomeAllegato = allegato['nome'] as String?;
                          if (idAllegato != null && nomeAllegato != null) {
                            final idAllegatoResult = await ref
                                .read(getAllegatoApiRepositoryProvider)
                                .getAllegato(utente: 'ADMIN', idAllegato: idAllegato);
                            if (idAllegatoResult != null && idAllegatoResult is List) {
                              allegatiWidgets.add(
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(nomeAllegato),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.download),
                                      onPressed: () async {
  // Ottieni la directory temporanea
  final directory = await getTemporaryDirectory();
  final savePath = '${directory.path}/$nomeAllegato';

  // Decodifica la stringa base64
  final decodedBytes = base64Decode(idAllegatoResult[0]['base64File']);

  // Scrivi i byte decodificati in un file
  final file = File(savePath);
  await file.writeAsBytes(decodedBytes);

  // Utilizza Flutter Downloader per notifiche e apertura del file
  await FlutterDownloader.enqueue(
    url: 'file://$savePath', // Usa il percorso del file locale
    savedDir: directory.path,
    fileName: nomeAllegato,
    showNotification: true,
    openFileFromNotification: true,
  );
}
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        }

                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Modello: $modello'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 10),
                                  Column(
                                    children: allegatiWidgets,
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text('Chiudi'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    }
                  }
                }
              }
            },
            child: Text('MODELLO'),
          ),
          SimpleDialogOption(
            onPressed: () async {
              final result = await ref
                  .read(elencoMatricoleApiRepositoryProvider)
                  .getMatricola(utente: 'ADMIN', rifMatricolaCliente: rifMatricolaCliente);

              if (result != null && result is List) {
                for (final item in result) {
                  if (item is Map<String, dynamic>) {
                    final rifMatricolaCliente = item['rifMatricolaCliente'] as String?;
                    if (rifMatricolaCliente != null) {
                      final marcaResult = await ref
                  .read(elencoMatricoleApiRepositoryProvider)
                  .getMatricola(utente: 'ADMIN', rifMatricolaCliente: rifMatricolaCliente);
                          
                      if (marcaResult != null && marcaResult is List) {
                        final List<dynamic> allegati = marcaResult[0]['allegati'];
                        final List<Widget> allegatiWidgets = [];

                        for (final allegato in allegati) {
                          final idAllegato = allegato['id'] as int?;
                          final nomeAllegato = allegato['nome'] as String?;
                          if (idAllegato != null && nomeAllegato != null) {
                            final idAllegatoResult = await ref
                                .read(getAllegatoApiRepositoryProvider)
                                .getAllegato(utente: 'ADMIN', idAllegato: idAllegato);
                            if (idAllegatoResult != null && idAllegatoResult is List) {
                              allegatiWidgets.add(
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(nomeAllegato),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.download),
                                      onPressed: () async {
  // Ottieni la directory temporanea
  final directory = await getTemporaryDirectory();
  final savePath = '${directory.path}/$nomeAllegato';

  // Decodifica la stringa base64
  final decodedBytes = base64Decode(idAllegatoResult[0]['base64File']);

  // Scrivi i byte decodificati in un file
  final file = File(savePath);
  await file.writeAsBytes(decodedBytes);

  // Utilizza Flutter Downloader per notifiche e apertura del file
  await FlutterDownloader.enqueue(
    url: 'file://$savePath', // Usa il percorso del file locale
    savedDir: directory.path,
    fileName: nomeAllegato,
    showNotification: true,
    openFileFromNotification: true,
  );
}
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        }

                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('MATRICOLA: $rifMatricolaCliente'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 10),
                                  Column(
                                    children: allegatiWidgets,
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text('Chiudi'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    }
                  }
                }
              }
            },
            child: Text('MATRICOLA'),
          ),
        ],
      );
    },
  );
}


void _showBrandDialog(BuildContext context, WidgetRef ref, String marca) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Scelta marca'),
        content: Text('Qui vengono viene visualizzato allegato'),
        actions: [
          TextButton(
            onPressed: () async {

            },
            child: Text('Chiudi'),
          ),
        ],
      );
    },
  );
}


  void _showModelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Scelta modello'),
          content: Text('Qui puoi selezionare un modello'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Chiudi'),
            ),
          ],
        );
      },
    );
  }

  void _showSerialDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Inserisci la matricola'),
          content: TextField(
            decoration: InputDecoration(labelText: 'Matricola'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Chiudi'),
            ),
          ],
        );
      },
    );
  }



  void _showAggiungiArticoloDialog(
      BuildContext context, WidgetRef ref, Intervento intervento) {
    String searchQuery = '';
    final TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.construction),
                  SizedBox(width: 2),
                  Text('Articoli'),
                ],
              ),
              content: SizedBox(
                width: 400,
                height: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            autofocus: true,
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                              });
                              ref
                                  .read(articoliControllerProvider.notifier)
                                  .applyFilterArticoli(filterText: value);
                            },
                            onSubmitted: (_) {
                              _aggiungiArticoloIfSingle(
                                  context, ref, intervento);
                            },
                            decoration: InputDecoration(
                              labelText: 'Cerca per codice o descrizione',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide:
                                    const BorderSide(color: Colors.orange),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 16.0,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ref.watch(articoliControllerProvider).when(
                          data: (data) {
                            if (searchQuery.isEmpty) {
                              return const SizedBox();
                            } else {
                              final filteredData = data.where((articolo) {
                                final codice =
                                    articolo.codice.toString().toLowerCase();
                                final descrizione = articolo.descrizione
                                    .toString()
                                    .toLowerCase();
                                final searchWords =
                                    searchQuery.toLowerCase().split(' ');
                                return searchWords.every((word) =>
                                    codice.contains(word) ||
                                    descrizione.contains(word));
                              }).toList();

                              return Expanded(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: filteredData.length,
                                  itemBuilder: (context, index) {
                                    var articolo = filteredData[index];
                                    //final articoloJson = articoloObj.toJson();
                                    //final articolo =
                                    //    InterventoArticoloState.fromJson(
                                    //        articoloJson);
                                    return ListTile(
                                      title: Text(articolo.descrizione),
                                      subtitle: Text(articolo.codice),
                                      onTap: () {
                                        final intervento = ref.read(
                                            interventoApertoStateProvider);
                                        _showAggiungiDettagliDialog(
                                            context, articolo, intervento, ref);
                                      },
                                    );
                                  },
                                ),
                              );
                            }
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (error, stackTrace) {
                            return Text('Error: $error');
                          },
                        ),
                  ],
                ),
              ),
              actions: [
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ButtonStyle(
                      side: MaterialStateProperty.all<BorderSide>(
                        const BorderSide(color: Colors.grey),
                      ),
                      minimumSize: MaterialStateProperty.all<Size>(
                          const Size(double.infinity, 60)),
                    ),
                    child: const Text(
                      'Chiudi',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    Future.delayed(Duration.zero, () {
      FocusScope.of(context).requestFocus(FocusNode());
      searchController.clear();
    });
  }

  void _aggiungiArticoloIfSingle(
      BuildContext context, WidgetRef ref, Intervento intervento) async {
    // final filteredData = ref.watch(articoliControllerProvider);
    // if (filteredData is AsyncData<List<Map<String, dynamic>>>) {
    //   if (filteredData.value.length == 1) {
    //     _showAggiungiDettagliDialog(context, filteredData.value.first, ref);
    //   }
    // }

    final filteredData = await ref.watch(articoliControllerProvider.future);
    final articolo = filteredData.first;
    _showAggiungiDettagliDialog(context, articolo, intervento, ref);
  }

  void addRiga(Articolo articolo, WidgetRef ref, Map<String, dynamic> params, Map<String, dynamic> resultMapDocId) {
    ref.read(interventoApertoStateProvider.notifier).addRiga(articolo, params, resultMapDocId);
  }

  void addRigaQuantita(Articolo? articolo, WidgetRef ref, Map<String, dynamic> params, Map<String, dynamic> resultMapDocId) {
    ref.read(interventoApertoStateProvider.notifier).addRigaQuantita(articolo, params, resultMapDocId);
  }

  void updateRiga(Riga riga, double nuovaQuantita, WidgetRef ref) {
    ref.read(interventoApertoStateProvider.notifier).updateRigaQuantita(riga, nuovaQuantita, ref);
  }

    void addNota(
      WidgetRef ref, Map<String, dynamic> params) {
    ref
        .read(interventoApertoStateProvider.notifier)
        .addOrUpdateNota(params);
  }

  void _showAggiungiDettagliDialog(BuildContext context, Articolo articolo,
      Intervento intervento, WidgetRef ref) async {
    if ([
      'SMANCAR',
      'SMANCLI',
      'SMANEST',
      'SMANEST+40%',
      'SMANESTFES',
      'SMANFES',
      'SMANINT',
      'SMANSTD'
    ].contains(articolo.codice)) {
      _showDurataDialog(context, articolo, intervento, ref);
    } else {
      _showQuantitaDialog(context, articolo, intervento, ref);
    }
  }

  String calculateDuration(TimeOfDay start, TimeOfDay end) {
    DateTime startDate = DateTime(2022, 1, 1, start.hour, start.minute);
    DateTime endDate = DateTime(2022, 1, 1, end.hour, end.minute);

    Duration difference = endDate.difference(startDate);
    int hours = difference.inHours;
    int minutes = difference.inMinutes.remainder(60);

    if (minutes <= 14) {
      minutes = 0;
    } else if (minutes <= 44) {
      minutes = 30;
    } else {
      minutes = 0;
      hours++;
    }

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  void _showDurataDialog(BuildContext context, Articolo articolo,
      Intervento intervento, WidgetRef ref) async {
    TimeOfDay? startTime = initialStartTime;
    TimeOfDay? endTime = initialEndTime;
    int quantity = 1;
    String notes = '';
    TextEditingController notesController = TextEditingController();
    TextEditingController startTimeController = TextEditingController();
    TextEditingController endTimeController = TextEditingController();
    TextEditingController quantityController =
        TextEditingController(text: quantity.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.post_add),
              SizedBox(width: 2),
              Text('Dettagli'),
            ],
          ),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () async {
                    TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: startTime ?? TimeOfDay.now(),
                    );
                    if (picked != null) {
                      startTime = picked;
                      startTimeController.text = _formatTimeOfDay(startTime!);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Inizio',
                      labelStyle: const TextStyle(fontSize: 16.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(
                            color: Color.fromARGB(255, 243, 159, 33),
                            width: 2.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: startTimeController,
                            enabled: false,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: () async {
                            TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: startTime ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              startTime = picked;
                              startTimeController.text =
                                  _formatTimeOfDay(startTime!);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () async {
                    TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: startTime ?? TimeOfDay.now(),
                    );
                    if (picked != null) {
                      endTime = picked;
                      endTimeController.text = _formatTimeOfDay(endTime!);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Fine',
                      labelStyle: const TextStyle(fontSize: 16.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: const BorderSide(
                            color: Color.fromARGB(255, 243, 159, 33),
                            width: 2.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: endTimeController,
                            enabled: false,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: () async {
                            TimeOfDay? picked = await showTimePicker(
                              context: context,
                              initialTime: endTime ?? TimeOfDay.now(),
                            );
                            if (picked != null) {
                              endTime = picked;
                              endTimeController.text =
                                  _formatTimeOfDay(endTime!);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ButtonStyle(
                      side: MaterialStateProperty.all<BorderSide>(
                        const BorderSide(color: Colors.grey),
                      ),
                      minimumSize: MaterialStateProperty.all<Size>(
                          const Size(double.infinity, 40)),
                    ),
                    child: const Text(
                      'Annulla',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (startTime != null && endTime != null) {
                        String duration =
                            calculateDuration(startTime!, endTime!);
                        double parseDuration(String durationString) {
                          if (durationString.contains(':')) {
                            final parts = durationString.split(':');
                            final hours = double.parse(parts[0]);
                            final minutes = double.parse(parts[1]);
                            return hours + (minutes / 60);
                          } else {
                            return double.parse(durationString);
                          }
                        }

String formatHour(int hour) {
  if (hour < 10) {
    return '0$hour';
  }
  return '$hour';
}

String formatMinute(int minute) {
  if (minute < 10) {
    return '0$minute';
  }
  return '$minute';
}

  // Formatta l'ora di inizio aggiungendo lo zero iniziale se necessario
  String formattedStartTime = '${formatHour(startTime!.hour)}:${formatMinute(startTime!.minute)}';
  
  // Formatta l'ora di fine aggiungendo lo zero iniziale se necessario
  String formattedFinTime = '${formatHour(endTime!.hour)}:${formatMinute(endTime!.minute)}';
  
  // Forma le stringhe nel formato "yyyy-MM-dd HH:mm"
  String dateTimeStringIni = '${DateFormat('yyyy-MM-dd').format(DateTime.now())} $formattedStartTime';
  String dateTimeStringFin = '${DateFormat('yyyy-MM-dd').format(DateTime.now())} $formattedFinTime';
  
  // Converte le stringhe in oggetti DateTime
  DateTime dtOraIni = DateTime.parse(dateTimeStringIni);
  DateTime dtOraFin = DateTime.parse(dateTimeStringFin);
  
  print(dtOraIni); // Stampa la data e l'ora di inizio
  print(dtOraFin); // Stampa la data e l'ora di fine

                        // double quantityDouble =
                        //     double.parse(quantity.toString());
                        double durationDouble = parseDuration(duration);
                        var prefs =
                            await ref.read(sharedPreferencesProvider.future);
                        final operatore = prefs.getString('user')?.toUpperCase();

                        Map<String, dynamic> params = {
                          'dataInserimento':
                              DateFormat('yyyy-MM-dd').format(DateTime.now()),
                          'quantita': durationDouble,
                          'durataIni': dtOraIni,
                          'durataFin' : dtOraFin,
                          'note': notes,
                          'operatore': operatore,
                        };

                        Map<String, dynamic> resultMapDocId = {
                          //'docId':
                        };
                        // var interventoArticolo =
                        //     InterventoArticoloState.fromJson(articoloJson);
                        addRiga(articolo, ref, params, resultMapDocId);

                        initialStartTime = startTime;
                        initialEndTime = endTime;
                      }

                      final result = ref
                          .read(movimentoMagazzinoApiRepositoryProvider)
                          .updateQuantity(
                            codArt: articolo.codice,
                            desMov: articolo.descrizione,
                            note: notes,
                            tipoMov: 40,
                            mag: articolo.magazzino.codice ?? '',
                            umMov: articolo.unimis.codice ?? '',
                            qtaMov: quantity.toDouble(),
                          );

                      if (result != null) {
                        Navigator.pop(context);

                        return;
                      } else {}

                      Navigator.pop(context);
                    },
                    style: ButtonStyle(
                      side: MaterialStateProperty.all<BorderSide>(
                        const BorderSide(color: Colors.grey), // Bordo grigio
                      ),
                      minimumSize: MaterialStateProperty.all<Size>(const Size(
                          double.infinity,
                          40)), // Larghezza espansa e altezza 50
                    ),
                    child: const Text(
                      'Conferma',
                      style: TextStyle(
                          color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.Hm().format(dateTime);
  }

  final sendEmailProvider = StateProvider<bool>((ref) => false);

  void _showQuantitaDialog(
    BuildContext context,
    Articolo articolo,
    Intervento intervento,
    WidgetRef ref,
  ) async {
    double quantity = 1;
    String notes = '';
    TextEditingController quantityController =
        TextEditingController(text: quantity.toString());
    TextEditingController notesController = TextEditingController();

    final disponibilitaRepository =
        ref.read(disponibilitaArticoliApiRepositoryProvider);
    final dataLim = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String codArt = articolo.codice;

    var sendEmailState = ref.watch(sendEmailProvider);

    double disp = 0;
    double giac = 0;
    double scorta = articolo.mtsScSic ?? 0.0;

    final qtaResiduaResponse =
        await disponibilitaRepository.getDisponibilitaArticoli(dataLim, codArt);

    if (qtaResiduaResponse != null) {
      final magazzinoSede = qtaResiduaResponse.firstWhere(
        (element) => element['magazzino'] == 'SEDE',
        orElse: () => null,
      );
      if (magazzinoSede != null) {
        disp = magazzinoSede['disp'];
        giac = magazzinoSede['giac'];
        //scorta = magazzinoSede['scoSic'];
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 2),
                  Text('${articolo.codice} (${articolo.unimis?.codice})'),
                ],
              ),
              const Divider(),
              Text(
                articolo.descrizione,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      iconSize: 20,
                      onPressed: () {
                        if (quantity > 1) {
                          quantity--;
                          quantityController.text = quantity.toString();
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
  controller: quantityController,
  keyboardType: TextInputType.numberWithOptions(decimal: true),
  textAlign: TextAlign.center,
  onChanged: (value) {
    // Sostituisce la virgola con il punto se presente
    String sanitizedValue = value.replaceAll(',', '.');

    // Converte il valore in double
    quantity = double.tryParse(sanitizedValue) ?? 1;
  },
  decoration: const InputDecoration(
    labelText: 'Quantità',
  ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.add),
                      iconSize: 20,
                      onPressed: () {
                        quantity++;
                        quantityController.text = quantity.toString();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    DataTable(
      columns: const [
        DataColumn(label: Text('Disp.')),
        DataColumn(label: Text('Scorta')),
        DataColumn(label: Text('Giac.')),
      ],
      rows: [
        DataRow(cells: [
          DataCell(Text(disp.toInt().toString())),
          DataCell(Text(scorta.toInt().toString())),
          DataCell(Text(giac.toInt().toString())),
        ]),
      ],
    ),
    Row(
      children: [
        const SizedBox(height: 20),
RoundCheckBox(  
                  onTap: (selected) {
                      // Inverti lo stato della checkbox
                      sendEmailState = !sendEmailState;
                  },
                  size: 25,
                  isChecked: sendEmailState, // Passa lo stato attuale alla checkbox
                ),
        const SizedBox(width: 10,),
        const Text('Invia segnalazione'),
      ],
    ),
  ],
),
                const SizedBox(height: 20),
                TextField(
                  controller: notesController,
                  onChanged: (value) {
                    notes = value;
                  },
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                  ),
                  maxLength: 500,
                  buildCounter: (BuildContext context,
                      {required int currentLength,
                      required bool isFocused,
                      required int? maxLength}) {
                    return Text('$currentLength/$maxLength');
                  },
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ButtonStyle(
                      side: MaterialStateProperty.all<BorderSide>(
                        const BorderSide(color: Colors.grey),
                      ),
                      minimumSize: MaterialStateProperty.all<Size>(
                          const Size(double.infinity, 40)),
                    ),
                    child: const Text(
                      'Annulla',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      var prefs =
                          await ref.read(sharedPreferencesProvider.future);
                      var operatore = prefs.getString('user')?.toUpperCase();

                      double quantityDouble = double.parse(quantity.toString());
                      Map<String, dynamic> params = {
                        'operatore': operatore,
                        'dataInserimento':
                            DateFormat('yyyy-MM-dd').format(DateTime.now()),
                        'quantita': quantityDouble,
                        'note': notes,
                      };

                      Map<String, dynamic> resultMapDocId = {
                        //'docId': docId,
                      };

                      addRigaQuantita(articolo, ref, params, resultMapDocId);


if (sendEmailState) {
                  await _sendEmail(context, ref, articolo);
                }

                      final result = ref
                          .read(movimentoMagazzinoApiRepositoryProvider)
                          .updateQuantity(
                            codArt: articolo.codice,
                            desMov: articolo.descrizione,
                            note: notes,
                            tipoMov: 40,
                            mag: articolo.magazzino?.codice ?? '',
                            umMov: articolo.unimis?.codice ?? '',
                            qtaMov: quantity.toDouble(),
                          );

                      if (result != null) {
                        Navigator.pop(context);

                        return;
                        
                      } else {}
                      Navigator.pop(context);
                    },
                    style: ButtonStyle(
                      side: MaterialStateProperty.all<BorderSide>(
                        const BorderSide(color: Colors.grey),
                      ),
                      minimumSize: MaterialStateProperty.all<Size>(
                          const Size(double.infinity, 40)),
                    ),
                    child: const Text(
                      'Conferma',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

Future<void> _sendEmail(BuildContext context, WidgetRef ref, Articolo articolo) async {
  final smtpServer = SmtpServer(
    'mail.smtp2go.com',
    username: 'edonis,morina@icoldo.it',
    password: 'Edonis.19',
    port: 2525,
    ssl: false,
    allowInsecure: false,
  );

  final message = Message()
    ..from = Address('assistenza@icoldo.it', 'Assistenza')
    ..recipients.add('assistenza@icoldo.it')
    ..subject = 'Segnalazione Articolo ${articolo.codice} - ${articolo.descrizione}'
    ..text = 'Questà è una mail inviata dal sistema per una segnalazione all\'articolo: ${articolo.codice} - ${articolo.descrizione} ';

  try {
    final sendReport = await send(message, smtpServer);

    print('Message sent: ${sendReport.messageSendingEnd}');
    print('Preview URL: ${sendReport.mail}'); // Email inviata correttamente
  } catch (e) {
    print('Error occurred: $e');
  }
}




   void modifyDettagliDialog(
       BuildContext context,
       Articolo? articolo,
       Intervento intervento,
       WidgetRef ref,
       Riga riga,
       double? nuovaQuantita,
       double quantity,
       String notes) async {
     TextEditingController quantityController =
         TextEditingController(text: quantity.toString());
     TextEditingController notesController = TextEditingController(text: notes);


     final double initialQuantity = quantity;

     TextEditingController quantityControllerNew =
         TextEditingController(text: initialQuantity.toString());

     final disponibilitaRepository =
         ref.read(disponibilitaArticoliApiRepositoryProvider);
     final dataLim = DateFormat('yyyy-MM-dd').format(DateTime.now());
     String? codArt = intervento.righe.firstWhere(
    (element) => element.riga == riga.riga,).articolo?.codice;
    String? artUnimis= intervento.righe.firstWhereOrNull(
    (element) => element.riga == riga.riga)?.articolo?.umPrincipale;
    String? descrArt = intervento.righe.firstWhere(
    (element) => element.riga == riga.riga,).articolo?.descrizione;
     if (codArt == null) {
       return;
     }

     double disp = 0;
     double giac = 0;
     double scorta = 0;
     String? unimis;

     final qtaResiduaResponse =
         await disponibilitaRepository.getDisponibilitaArticoli(dataLim, codArt);

     if (qtaResiduaResponse != null) {
       final magazzinoSede = qtaResiduaResponse.firstWhere(
           (element) => element['magazzino'] == 'SEDE',
           orElse: () => null);
       if (magazzinoSede != null) {
         disp = magazzinoSede['disp'];
         giac = magazzinoSede['giac'];
         scorta = magazzinoSede['scoSic'];
         unimis = magazzinoSede['unimis'];
       }
     }

     double difference = disp - quantity;
     TextEditingController differenceController =
         TextEditingController(text: difference.toString());

     showDialog(
       context: context,
       builder: (BuildContext context) {
         return AlertDialog(
           title: Column(
             children: [
               Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const SizedBox(width: 2),
                   Text('$codArt ${artUnimis != null ? '($artUnimis)' : ''}'),
                 ],
               ),
               const Divider(),
                Text(
                  
                  '$descrArt',
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
             ],
           ),
           content: SizedBox(
             width: 300,
             child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Row(
                   children: [
                     IconButton(
                       icon: const Icon(Icons.remove),
                       iconSize: 20,
                       onPressed: () {
                         if (quantity > 1) {
                           quantity--;
                           quantityController.text = quantity.toString();
                         }
                       },
                     ),
                     const SizedBox(width: 10),
                     Expanded(
                       child: TextField(
                         controller: quantityController,
                         keyboardType: TextInputType.number,
                         textAlign: TextAlign.center,
                         onChanged: (value) {
                           quantity = double.tryParse(value) ?? 1;
                           difference = disp - quantity;
                           differenceController.text = difference.toString();
                         },
                         decoration: const InputDecoration(
                           labelText: 'Quantità',
                         ),
                       ),
                     ),
                     const SizedBox(width: 10),
                     IconButton(
                       icon: const Icon(Icons.add),
                       iconSize: 20,
                       onPressed: () {
                         quantity++;
                         quantityController.text = quantity.toString();
                         difference = disp - quantity;
                         differenceController.text =
                             difference.toInt().toString();
                       },
                     ),
                   ],
                 ),
                 const SizedBox(height: 20),
                 DataTable(
                   columns: const [
                     DataColumn(label: Text('Disp.')),
                     DataColumn(label: Text('Scorta')),
                     DataColumn(label: Text('Giac.')),
                   ],
                   rows: [
                     DataRow(cells: [
                       DataCell(Text(disp.toInt().toString())),
                       DataCell(Text(scorta.toInt().toString())),
                       DataCell(Text(giac.toInt().toString())),
                     ]),
                   ],
                 ),
                 const SizedBox(height: 20),
                 TextField(
                     controller: notesController,
                     onChanged: (value) {
                       notes = value;
                     },
                     maxLines: 3,
                     decoration: const InputDecoration(
                       labelText: 'Note',
                     ),
                     maxLength: 500,
                     buildCounter: (BuildContext context,
                         {required int currentLength,
                         required bool isFocused,
                         required int? maxLength}) {
                       return Text('$currentLength/$maxLength');
                     }),
               ],
             ),
           ),
           actions: [
             ElevatedButton(
               onPressed: () {
                 double parseDuration(String durationString) {
                   if (durationString.contains(':')) {
                     final parts = durationString.split(':');
                    final hours = double.parse(parts[0]);
                    final minutes = double.parse(parts[1]);
                    return hours + (minutes / 60);
                  } else {
                    return double.parse(durationString);
                  }
                }

                //double quantityDouble = double.parse(quantity.toString());
                riga.qta = quantity;
                riga.note = notes;
                ref
                    .read(interventoApertoStateProvider.notifier).updateRigaQuantita(riga, quantity, ref);

                final int quantityValue =
                    int.tryParse(quantityControllerNew.text) ?? 0;
                final int tipoMov =
                    riga.qta! > quantityValue ? 40 : 41;

                int quantityDifferenceReso = 0;
                if (tipoMov == 41) {
                  quantityDifferenceReso = quantityValue - quantity.toInt();
                }

                int quantityDifferencePrelievo = 0;
                if (tipoMov == 40) {
                  quantityDifferencePrelievo = quantity.toInt() - quantityValue;
                }

                final double qtaMov = tipoMov == 40
                    ? quantityDifferencePrelievo.toDouble()
                    : quantityDifferenceReso.toDouble();

                final result = ref
                    .read(movimentoMagazzinoApiRepositoryProvider)
                    .updateQuantity(
                        codArt: articolo!.codice,
                        desMov: articolo.descrizione,
                        note: notes,
                        tipoMov: tipoMov,
                        mag: articolo.magazzino.descrizione ?? '',
                        umMov: articolo.unimis.codice ?? '',
                        qtaMov: qtaMov);

                if (result != null) {
                  Navigator.pop(context);

                  return;
                } else {}

                Navigator.pop(context);
              },
              child: const Text('Conferma'),
            ),
          ],
        );
      },
    );
  }

  TimeOfDay? lastStartTime;
  TimeOfDay? lastEndTime;

void modifyDurataDialog(BuildContext context, Riga riga, double? nuovaQuantita, WidgetRef ref) async {
  double quantity = riga.qta ?? 1;
  String notes = riga.note ?? '';
  double nuovaQuantita = riga.qta ?? 1;
  
  TimeOfDay? savedStartTime = lastStartTime;
  TimeOfDay? savedEndTime = lastEndTime;

  TextEditingController notesController = TextEditingController(text: notes);
  TextEditingController startTimeController = TextEditingController(
    text: savedStartTime != null
      ? DateFormat.Hm().format(DateTime(
          2022, 1, 1, savedStartTime.hour, savedStartTime.minute))
      : ''
  );
  TextEditingController endTimeController = TextEditingController(
    text: savedEndTime != null
      ? DateFormat.Hm().format(DateTime(
          2022, 1, 1, savedEndTime.hour, savedEndTime.minute))
      : ''
  );
  TextEditingController quantityController =
    TextEditingController(text: quantity.toString());

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit),
            SizedBox(width: 2),
            Text('Modifica Durata'),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () async {
                  TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: savedStartTime ?? TimeOfDay.now(),
                  );
                  if (picked != null) {
                    lastStartTime = picked;
                    savedStartTime = picked;
                    startTimeController.text = DateFormat.Hm().format(
                      DateTime(2022, 1, 1, picked.hour, picked.minute));
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Orario di Inizio',
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: startTimeController,
                          enabled: false,
                          decoration: const InputDecoration(
                            hintText: 'Seleziona orario',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.access_time),
                        onPressed: () {
                          TimeOfDay now = TimeOfDay.now();
                          lastStartTime = now;
                          savedStartTime = now;
                          startTimeController.text = DateFormat.Hm().format(
                            DateTime(2022, 1, 1, now.hour, now.minute));
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () async {
                  TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: savedEndTime ?? TimeOfDay.now(),
                  );
                  if (picked != null) {
                    lastEndTime = picked;
                    savedEndTime = picked;
                    endTimeController.text = DateFormat.Hm().format(
                      DateTime(2022, 1, 1, picked.hour, picked.minute));
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Orario di Fine',
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: endTimeController,
                          enabled: false,
                          decoration: const InputDecoration(
                            hintText: 'Seleziona orario',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.access_time),
                        onPressed: () {
                          TimeOfDay now = TimeOfDay.now();
                          lastEndTime = now;
                          savedEndTime = now;
                          endTimeController.text = DateFormat.Hm().format(
                            DateTime(2022, 1, 1, now.hour, now.minute));
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
       onPressed: () {
  if (lastStartTime != null && lastEndTime != null) {
    String duration = calculateDuration(lastStartTime!, lastEndTime!);

    double parseDuration(String durationString) {
      if (durationString.contains(':')) {
        final parts = durationString.split(':');
        final hours = double.parse(parts[0]);
        final minutes = double.parse(parts[1]);
        return hours + (minutes / 60);
      } else {
        return double.parse(durationString);
      }
    }

    double durationDouble = parseDuration(duration);
    nuovaQuantita = durationDouble;
    riga.note = notes;

    updateRiga(riga, nuovaQuantita, ref);

    Navigator.pop(context);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RegistrazioneInterventoPage()));
  }
},

            child: const Text('Conferma'),
          ),
        ],
      );
    },
  );
}



  void _showAggiungiNotaDialog(BuildContext context, WidgetRef ref) async {
    String notaText = '';
    final TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.note_add),
              SizedBox(width: 2),
              Text('Nota'),
            ],
          ),
          content: Container(
            width: 300,
            child: TextField(
              controller: controller,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Inserisci una nota',
                contentPadding: EdgeInsets.all(16.0),
              ),
              buildCounter: (BuildContext context,
                  {required int currentLength,
                  required bool isFocused,
                  required int? maxLength}) {
                return Text('$currentLength/$maxLength');
              },
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ButtonStyle(
                      side: MaterialStateProperty.all<BorderSide>(
                        const BorderSide(color: Colors.grey),
                      ),
                      minimumSize: MaterialStateProperty.all<Size>(const Size(
                          double.infinity,
                          40)),
                    ),
                    child: const Text('Annulla',
                        style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // if (controller.text.isNotEmpty) {
                      //   notaText = controller.text;
                      //   _stampaNellaPage('$notaText', ref);
                      //   Navigator.pop(context);
                      // }

                      notaText = controller.text;

                       var prefs =
                           await ref.read(sharedPreferencesProvider.future);
                       var operatore = prefs.getString('user')?.toUpperCase();

                       Map<String, dynamic> params = {
                         'operatore': operatore,
                         'dataInserimento':
                             DateFormat('yyyy-MM-dd').format(DateTime.now()),
                         'quantita': 0,
                          //'durata': duration,
                         'note': notaText,
                       };

                      addNota(ref, params);
    Navigator.pop(context);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RegistrazioneInterventoPage()));
                    },
                    style: ButtonStyle(
                      side: MaterialStateProperty.all<BorderSide>(
                        const BorderSide(color: Colors.grey),
                      ),
                      minimumSize: MaterialStateProperty.all<Size>(const Size(
                          double.infinity,
                          40)), 
                    ),
                    child: const Text('Salva',
                        style: TextStyle(color: Colors.black)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class AllegatiManager {
  static List<PlatformFile> allegatiTemporanei = [];

  int numeroAllegati = AllegatiManager.allegatiTemporanei.length;
  
}
