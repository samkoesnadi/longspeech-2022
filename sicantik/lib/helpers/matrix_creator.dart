import 'package:document_analysis/src/probability.dart';
import 'package:document_analysis/src/structure.dart';
import 'package:document_analysis/src/vector_measurement.dart';
import 'package:sicantik/helpers/tokenizer.dart';

///Create word-vector matrix using Hybrid TF-IDF metric
List<List<double?>> myHybridTfIdfMatrix(List<String> documentList,
    {measureFunction = cosineDistance,
    String Function(String)? stemmer,
    List<String>? stopwords,
    TokenizationOutput? tokenOut}) {
  tokenOut = tokenOut ?? TokenizationOutput();
  documentTokenizer(documentList,
      stemmer: stemmer, stopwords: stopwords, tokenOut: tokenOut);

  List<List<double?>> matrix2d = List.generate(documentList.length, (_) => []);
  Map<String, double> wordProbability = hybridTfIdfProbability(tokenOut);

  //for all distinct words
  tokenOut.bagOfWords.forEach((key, val) {
    for (int i = 0; i < documentList.length; i++) {
      if (tokenOut!.documentBOW[i].containsKey(key)) {
        matrix2d[i].add(wordProbability[key]);
      } else {
        matrix2d[i].add(0);
      }
    }
  });

  return matrix2d;
}
