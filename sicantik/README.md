# sicantik

## Data structure

* box
  * speechToTextLanguage
  * inkRecognitionLanguage
  * fullversion

* Notes box
  * noteIds : list of all noteId
  * starred : list of all favorites
  * {noteId} : {editedAt, title, summarized, category}
  * {noteId}-full : the full text
  * {noteId}-ners : list of ner
  * {noteId}-detectedLanguages : list of detected language
  * {noteId}-reminders
  * {noteId}-imageClassifications : dictionary {imagePath: list of classifications}
  * {noteId}-videos : list of videos
  * {noteId}-voiceRecordings : list of voice recordings
  * {noteId}-inAppReviewTrack : dictionary {done, datetime}
  * currentUntitledId : int

* Reminders
  * lastId
  * {reminderId} : the date
  * currentFreeId : int
