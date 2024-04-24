String listAsString(List<String> listOfStrings) {
  String returnString = '';
  for (var element in listOfStrings) {returnString += '$element, '; }
  return returnString;
}