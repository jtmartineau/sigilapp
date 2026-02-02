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

  static List<List<String>> assignLetters(
    List<String> letters,
    String layoutType,
    int sides,
  ) {
    if (layoutType == 'Circle' || sides < 2) {
      return letters.map((l) => [l]).toList();
    }

    // Polygon: Sequential distribution (Chunking)
    List<List<String>> result = List.generate(sides, (_) => []);

    int total = letters.length;
    if (total == 0) return result;

    int baseCount = total ~/ sides;
    int remainder = total % sides;

    int currentLetterIdx = 0;
    for (int i = 0; i < sides; i++) {
      // Distribute remainder one by one to the first 'remainder' vertices
      int count = baseCount + (i < remainder ? 1 : 0);
      for (int j = 0; j < count; j++) {
        if (currentLetterIdx < total) {
          result[i].add(letters[currentLetterIdx]);
          currentLetterIdx++;
        }
      }
    }

    return result;
  }
}
