class SigilProcessor {
  static List<String> processIncantation(String incantation) {
    // 1. Convert to uppercase
    String text = incantation.toUpperCase();

    // 2. Remove non-alphabetic characters (optional, but good for safety)
    text = text.replaceAll(RegExp(r'[^A-Z]'), '');

    // 3. Define vowels
    const vowels = ['A', 'E', 'I', 'O', 'U'];

    // 4. Filter consonants and keep unique ones preserving order
    List<String> consonants = [];
    Set<String> seen = {};

    for (int i = 0; i < text.length; i++) {
      String char = text[i];
      if (!vowels.contains(char) && !seen.contains(char)) {
        consonants.add(char);
        seen.add(char);
      }
    }

    return consonants;
  }
}
