type document
  = Text
  | Drawing
  | Spreadsheet

fun draw (Text)        = (* draw text doc... *)
  | draw (Drawing)     = (* draw drawing doc... *)
  | draw (Spreadsheet) = (* draw spreadsheet... *)

fun load (Text)        = (* load text doc... *)
  | load (Drawing)     = (* load drawing doc... *)
  | load (Spreadsheet) = (* load spreadsheet... *)

fun save (Text)        = (* save text doc... *)
  | save (Drawing)     = (* save drawing doc... *)
  | save (Spreadsheet) = (* save spreadsheet... *)
