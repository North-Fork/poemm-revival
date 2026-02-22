import Foundation

struct PoemWord {
    let text: String
    let phase: TimePhase
    let isFocus: Bool   // reserved: set by leading * in poem.txt
}

enum PoemLoader {

    /// Loads and parses poem.txt from the main bundle.
    static func load(resource: String = "poem", extension ext: String = "txt") -> [PoemWord] {
        guard
            let url = Bundle.main.url(forResource: resource, withExtension: ext),
            let content = try? String(contentsOf: url, encoding: .utf8)
        else {
            assertionFailure("PoemLoader: poem.txt not found in bundle")
            return []
        }
        return parse(content)
    }

    /// Parses a ##phase-sectioned string into PoemWord values.
    static func parse(_ content: String) -> [PoemWord] {
        var words: [PoemWord] = []
        var currentPhase: TimePhase = .morning

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            if trimmed.hasPrefix("##") {
                let name = String(trimmed.dropFirst(2)).lowercased()
                currentPhase = TimePhase(rawValue: name) ?? currentPhase
                continue
            }

            for token in trimmed.components(separatedBy: .whitespaces) where !token.isEmpty {
                let isFocus = token.hasPrefix("*")
                let text = isFocus ? String(token.dropFirst()) : token
                guard !text.isEmpty else { continue }
                words.append(PoemWord(text: text, phase: currentPhase, isFocus: isFocus))
            }
        }
        return words
    }
}
