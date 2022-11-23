
jsonToHtml(List delta) {
  StringBuffer html = StringBuffer();
  bool listActivated = false;
  String listClosing = "";

  //! End Loop Implementation
  delta.add({'insert': ' '});

  for (var element in delta) {
    //! Embedded Implementation
    if (element['insert'] is Map<String, dynamic>) {
      //~ Image Implementation
      if (element['insert'].containsKey('image')) {
        String imageLink = element['insert']['image'].toString();
        if (element.containsKey('attributes')) {
          String style = element['attributes']['style']
              .toString()
              .replaceAll('mobile', '')
              .replaceAll(':', "='")
              .replaceAll(';', "'")
              .toLowerCase();
          html.write("<p style='text-align:center'><img src='$imageLink' $style></p>");
        } else {
          html.write("<p style='text-align:center'><img src='$imageLink'></p>");
        }

        //~ Video Implementation
      } else if (element['insert'].containsKey('video')) {
        String videoLink = element['insert']['video'].toString();
        html.write("<p style='text-align:center'><embed type='video/webm' src='$videoLink'></p>");

        //~ Line Implementation
      } else if (element['insert'].containsKey('line')) {
        html.write("<hr>");
      }
    } else {
      //! Rich Text Implementation

      //~ Normal Text Implementation
      if (!element.containsKey('attributes')) {
        String currentText = element['insert'].toString();
        if (listActivated == true && currentText[0] == '\n') {
          listActivated = false;
          currentText = listClosing + currentText;
          listClosing = "";
        }

        html.write(currentText);
      } else {
        List blockElements = [
          'header',
          'align',
          'direction',
          'list',
          'blockquote',
          'code-block',
          'indent'
        ];
        String currentText = element['insert'].toString();
        Map currentAttributeMap = element['attributes'] as Map;

        //~ Inline Text Implementation
        if (!blockElements.contains(currentAttributeMap.keys.first)) {
          currentAttributeMap.forEach((key, value) {
            switch (key.toString()) {
              case "color":
                currentText = "<span style='color:$value'>$currentText</span>";
                break;
              case "background":
                currentText =
                "<span style='background-color:$value'>$currentText</span>";
                break;
              case "font":
                currentText =
                "<span style='font-family:$value'>$currentText</span>";
                break;

              case "bold":
                currentText = "<b>$currentText</b>";
                break;
              case "italic":
                currentText = "<i>$currentText</i>";
                break;
              case "underline":
                currentText = "<u>$currentText</u>";
                break;
              case "strike":
                currentText = "<s>$currentText</s>";
                break;

              case "size":
                switch (value) {
                  case "small":
                    currentText = "<small>$currentText</small>";
                    break;
                  case "large":
                    currentText = "<big>$currentText</big>";
                    break;
                  case "huge":
                    currentText =
                    "<span style='font-size:150%'>$currentText</span>";
                    break;
                  default:
                    currentText =
                    "<span style='font-size:${value}px'>$currentText</span>";
                    break;
                }
                break;

              case "link":
                currentText = "<a href='$value'>$currentText</a>";
                break;

              case "code":
                currentText =
                "<code style='color:#e1103a; background-color:#f1f1f1; padding: 0px 4px;'>$currentText</code>";
                break;
              default:
            }
          });

          html.write(currentText);
        } else {
          //~ Block Text Implementation
          String rawHtml = html.toString();
          String blockString = '';
          if (rawHtml.contains('\\Þ')) {
            List dumpyStringList = rawHtml.split('\\Þ');
            blockString = dumpyStringList.last;
            dumpyStringList.removeLast();
            String dumpyString = dumpyStringList.join();
            html.clear();
            html.write(dumpyString);
          } else {
            List dumpyStringList = rawHtml.split('\n');
            blockString = dumpyStringList.last;
            dumpyStringList.removeLast();
            String dumpyString = dumpyStringList.join('\n');
            html.clear();
            html.write(dumpyString);
          }

          String key = "header";
          if (currentAttributeMap.containsKey(key)) {
            var value = currentAttributeMap[key];
            currentText = "<h$value>$blockString</h$value>";
          }

          key = "align";
          if (currentAttributeMap.containsKey(key)) {
            var value = currentAttributeMap[key];
            currentText = "<p style='text-align:$value'>$blockString</p>";
          }

          key = "direction";
          if (currentAttributeMap.containsKey(key)) {
            var value = currentAttributeMap[key];
            currentText = "<p style='direction:$value'>$blockString</p>";
          }

          key = "code-block";
          if (currentAttributeMap.containsKey(key)) {
            currentText =
            "<pre><code style='color:#3F51B5; background-color:#f1f1f1; padding: 0px 4px;'>$blockString</code></pre>";
          }

          key = "blockquote";
          if (currentAttributeMap.containsKey(key)) {
            currentText = "<blockquote>$blockString</blockquote>";
          }

          key = "list";
          if (currentAttributeMap.containsKey(key)) {
            var value = currentAttributeMap[key];

            currentText = '';

            int indexPreText = blockString.lastIndexOf('\n');
            String preText = "";
            if (indexPreText != -1) {
              preText = blockString.substring(0, indexPreText + 1);
              blockString = blockString.substring(indexPreText + 1);
            }

            if (value == "checked") {
              currentText +=
              "<input type='checkbox' checked><label>$blockString</label><br>";
            } else if (value == "unchecked") {
              currentText +=
              "<input type='checkbox' ><label>$blockString</label><br>";
            } else {
              if (listActivated) {
                currentText += "<li>$blockString</li>";
              } else {
                listActivated = true;
                switch (value) {
                  case "ordered":
                    if (listClosing != "</ol>") {
                      currentText += listClosing;
                      listClosing = "";
                    }
                    currentText += "<ol><li>$blockString</li>";
                    listClosing = "</ol>";
                    break;
                  case "bullet":
                    if (listClosing != "</ul>") {
                      currentText += listClosing;
                      listClosing = "";
                    }
                    currentText += "<ul><li>$blockString</li>";
                    listClosing = "</ul>";
                    break;
                }
              }
            }

            currentText = "$preText$currentText";
          }

          key = "indent";
          if (currentAttributeMap.containsKey(key)) {
            var value = currentAttributeMap[key];
            currentText = "${'&emsp;' * value * 2} $blockString</br>";
            if (!listActivated) {
              currentText = "<br>$currentText";
            }
          }

          html.write('$currentText\\Þ');
        }
      }
    }
  }

  return html.toString().replaceAll('\\Þ', '').replaceAll('\n', '<br>');
}
