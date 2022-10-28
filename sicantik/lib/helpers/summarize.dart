import 'package:collection/collection.dart';
import 'package:document_analysis/document_analysis.dart';
import 'package:scidart/numdart.dart';
import 'package:sicantik/helpers/matrix_creator.dart';
import 'package:stemmer/stemmer.dart';

class Sentence {
  String sentence;
  bool summarized;

  Sentence(this.sentence, this.summarized);

  @override
  String toString() {
    return '{ ${this.sentence}, ${this.summarized} }';
  }
}

List<Sentence> summarize({required String paragraph, int amountOfSentences = 10}) {
  PorterStemmer stemmer = PorterStemmer();

  List<String> docs = split_into_sentences(paragraph);
  TokenizationOutput tokenOut = TokenizationOutput();
  List<List<double?>> tfidf =
      myHybridTfIdfMatrix(docs, stemmer: stemmer.stem, tokenOut: tokenOut);

  List<Array> inp =
      tfidf.map((elem) => Array(elem.map((x) => x!).toList())).toList();
  Array2d inp2d = Array2d(inp);

  var svd = SVD(matrixTranspose(inp2d));
  List<double> ranks = [];
  for (var columnVector in matrixTranspose(svd.V())) {
    double rank = 0;
    for (List<double> sv
        in IterableZip([svd.singularValues(), columnVector])) {
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

  List<Sentence> sentences = [];
  for (int i = 0; i < docs.length; i++) {
    sentences.add(Sentence(docs[i], thresholdProbability <= ranks[i]));
  }

  return sentences;
}

List<String> split_into_sentences(String text) {
  const alphabets = "([A-Za-z])";
  const prefixes = "(Mr|St|Mrs|Ms|Dr)[.]";
  const suffixes = "(Inc|Ltd|Jr|Sr|Co)";
  const starters =
      "(Mr|Mrs|Ms|Dr|He\s|She\s|It\s|They\s|Their\s|Our\s|We\s|But\s|However\s|That\s|This\s|Wherever)";
  const acronyms = "([A-Z][.][A-Z][.](?:[A-Z][.])?)";
  const websites = "[.](com|net|org|io|gov)";
  const digits = "([0-9])";

  text = " " + text + "  ";
  text = text.replaceAll("\n", " ");
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
  List<String> sentences = text.split("<stop>");
  sentences.removeLast();
  sentences = sentences.map((e) => e.trim()).toList();
  return sentences;
}
