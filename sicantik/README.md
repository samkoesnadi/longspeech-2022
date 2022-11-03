# sicantik

## Data structure

* Notes box
  * noteIds : list of all noteId
  * starred : list of all favorites
  * {noteId} : {editedAt, title, summarized}
  * {noteId}-full : the full text
  * {noteId}-ners : list of ner
  * {noteId}-detectedLanguages : list of detected language
  * {noteId}-reminders
  * currentUntitledId : int

* Reminders
  * lastId
  * {reminderId} : the date
  * currentFreeId : int
