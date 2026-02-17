module SpreadsheetImportsHelper
  def row_classes(row)
    classes = []
    classes << "bg-gray-50 text-gray-400" if row.has_gray_text?
    classes << "bg-amber-50" if row.duplicate?
    classes << "bg-green-50" if row.accepted?
    classes << "bg-blue-50" if row.modified?
    classes << "bg-red-50 opacity-60" if row.rejected?
    classes.join(" ")
  end
end
