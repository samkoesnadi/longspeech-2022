import 'package:collection/collection.dart';
import 'package:document_analysis/document_analysis.dart';
import 'package:scidart/numdart.dart';
import 'package:sicantik/helpers/matrix_creator.dart';
import 'package:sicantik/utils.dart';

Map<String, dynamic> summarize(
    {required String paragraph, int amountOfSentences = 10}) {
  logger.d("Summarize: $paragraph");

  List<String> docs = splitIntoSentences(paragraph);

  if (docs.isEmpty) {
    return {"summarized": "", "keywords": []};
  }

  TokenizationOutput tokenOut = TokenizationOutput();
  List<List<double?>> tfidf = myHybridTfIdfMatrix(docs, tokenOut: tokenOut);

  List keywordsCandidates = [];
  tokenOut.bagOfWords.forEach((key, value) {
    if (!commonEnglishWords.contains(key)) {
      keywordsCandidates.add([key, value]);
    }
  });

  keywordsCandidates
      .sort((elemTwo, elemOne) => elemOne[1].compareTo(elemTwo[1]));

  if (keywordsCandidates.length > amountOfSentences) {
    keywordsCandidates = keywordsCandidates.sublist(0, amountOfSentences);
  }
  List keywords =
      keywordsCandidates.map((elem) => elem[0]).toList().cast<String>();

  List<Array> inp =
      tfidf.map((elem) => Array(elem.map((x) => x!).toList())).toList();
  Array2d inp2d = Array2d(inp);

  var svd = SVD(matrixTranspose(inp2d));
  List<double> ranks = [];
  for (var columnVector in matrixTranspose(svd.V())) {
    double rank = 0;
    for (List<double> sv in IterableZip([svd.singularValues(), columnVector])) {
      rank += sv[0] * sv[1];
    }
    ranks.add(rank);
  }

  // Get the threshold probability
  List<double> sortedRanks = [...ranks];
  sortedRanks.sort((b, a) => a.compareTo(b));
  double thresholdProbability = sortedRanks.last;

  if (sortedRanks.length > amountOfSentences) {
    thresholdProbability = sortedRanks[amountOfSentences - 1];
  }

  String summarized = "";
  for (int i = 0; i < docs.length; i++) {
    if (thresholdProbability <= ranks[i]) {
      docs[i] = docs[i].trim();

      if (!allPossibleSymbols.contains(docs[i][docs[i].length - 1])) {
        docs[i] = "${docs[i].trim()}.";
      }

      summarized += "${docs[i]} ";
    }
  }

  return {"summarized": summarized, "keywords": keywords};
}

List<String> splitIntoSentences(String text, {int minLength = 5}) {
  const alphabets = "([A-Za-z])";
  const prefixes = "(Mr|St|Mrs|Ms|Dr)[.]";
  const suffixes = "(Inc|Ltd|Jr|Sr|Co)";
  const starters =
      "(Mr|Mrs|Ms|Dr|He\s|She\s|It\s|They\s|Their\s|Our\s|We\s|But\s|However\s|That\s|This\s|Wherever)";
  const acronyms = "([A-Z][.][A-Z][.](?:[A-Z][.])?)";
  const websites = "[.](com|net|org|io|gov)";
  const digits = "([0-9])";

  text = " " + text + "  ";
  text = text.replaceAll("\n", ".");
  text = text.replaceAllMapped(
      RegExp(digits + "[.]" + digits), (Match m) => "${m[1]}<prd>${m[2]}");
  text = text.replaceAllMapped(RegExp(prefixes), (Match m) => "${m[1]}<prd>");
  text = text.replaceAllMapped(RegExp(websites), (Match m) => "<prd>${m[1]}");
  text = text.replaceAll("Ph.D.", "Ph<prd>D<prd>");
  text = text.replaceAllMapped(
      RegExp("\s\b" + alphabets + "[.] "), (Match m) => " ${m[1]}<prd> ");
  text = text.replaceAllMapped(
      RegExp(acronyms + " " + starters), (Match m) => "${m[1]}<stop> ${m[2]}");
  text = text.replaceAllMapped(
      RegExp(alphabets + "[.]" + alphabets + "[.]" + alphabets + "[.]"),
      (Match m) => "${m[1]}<prd>${m[2]}<prd>\\3<prd>");
  text = text.replaceAllMapped(RegExp(alphabets + "[.]" + alphabets + "[.]"),
      (Match m) => "${m[1]}<prd>${m[2]}<prd>");
  text = text.replaceAllMapped(RegExp(" " + suffixes + "[.] " + starters),
      (Match m) => " ${m[1]}<stop> ${m[2]}");
  text = text.replaceAllMapped(
      RegExp(" " + suffixes + "[.]"), (Match m) => " ${m[1]}<prd>");
  text = text.replaceAllMapped(
      RegExp(" " + alphabets + "[.]"), (Match m) => " ${m[1]}<prd>");
  text = text.replaceAll(".”", "”.");
  text = text.replaceAll(".\"", "\".");
  text = text.replaceAll("!\"", "\"!");
  text = text.replaceAll("?\"", "\"?");
  text = text.replaceAll(".", ".<stop>");
  text = text.replaceAll("?", "?<stop>");
  text = text.replaceAll("!", "!<stop>");
  text = text.replaceAll("<prd>", ".");
  text += "<stop>";
  List<String> sentences = text.split("<stop>");
  // sentences.removeLast();
  sentences = sentences
      .map((e) => e
          .replaceAll(
              RegExp(r"[^\w !'§<>|$%&/()=?\\`´+*#öäüÜÖÄ,.\-;:_^{}\[\]]"), "")
          .trim())
      .toList();
  sentences
      .removeWhere((element) => element == "" || element.length < minLength);
  return sentences;
}
