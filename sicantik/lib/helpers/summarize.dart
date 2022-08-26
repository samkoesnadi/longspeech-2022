import 'package:collection/collection.dart';
import 'package:document_analysis/document_analysis.dart';
import 'package:scidart/numdart.dart';
import 'package:sicantik/helpers/matrix_creator.dart';
import 'package:stemmer/stemmer.dart';

String summarize({required String paragraph, int amount_of_sentences = 10}) {
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
  for (var column_vector in matrixTranspose(svd.V())) {
    double rank = 0;
    for (List<double> sv
        in IterableZip([svd.singularValues(), column_vector])) {
      rank += sv[0] * sv[1];
    }
    ranks.add(rank);
  }

  List<Sentence> sentences_reordered = [];
  for (int i = 0; i < docs.length; i++) {
    sentences_reordered.add(Sentence(docs[i], ranks[i], i));
  }
  sentences_reordered.sort((b, a) => a.probability.compareTo(b.probability));

  // just take the top-n amount
  sentences_reordered =
      sentences_reordered.getRange(0, amount_of_sentences).toList();
  sentences_reordered.sort((a, b) => a.order.compareTo(b.order));

  String result = sentences_reordered.join(" ");

  return result;
}

class Sentence {
  String sentence;
  double probability;
  int order;

  Sentence(this.sentence, this.probability, this.order);

  @override
  String toString() {
    return '{ ${this.order}: ${this.sentence}, ${this.probability} }';
  }
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
