package com.tucancionero.domain.usecases

class TransposeUseCase {
    
    fun transposeChord(chord: String, semitones: Int): String {
        if (chord.isEmpty()) return chord
        
        val americanNotes = listOf("C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B")
        val latinNotes = listOf("Do", "Do#", "Re", "Re#", "Mi", "Fa", "Fa#", "Sol", "Sol#", "La", "La#", "Si")
        
        // Encontrar la nota base y el resto del acorde
        val (baseNote, modifier) = extractBaseNote(chord)
        if (baseNote.isEmpty()) return chord
        
        // Determinar si es notación americana o latina
        val isAmerican = americanNotes.any { it.equals(baseNote, ignoreCase = true) }
        val noteList = if (isAmerican) americanNotes else latinNotes
        
        // Encontrar índice actual
        val currentIndex = noteList.indexOfFirst { it.equals(baseNote, ignoreCase = true) }
        if (currentIndex == -1) return chord
        
        // Calcular nuevo índice
        val newIndex = (currentIndex + semitones + noteList.size) % noteList.size
        val newBaseNote = noteList[newIndex]
        
        return newBaseNote + modifier
    }
    
    fun transposeLyrics(lyrics: String, semitones: Int): String {
        if (semitones == 0) return lyrics
        
        return lyrics.split("\n").joinToString("\n") { line ->
            if (line.trim().split(" ").any { isChord(it.trim()) }) {
                // Es una línea de acordes
                line.split(" ").joinToString(" ") { word ->
                    if (isChord(word.trim())) {
                        transposeChord(word.trim(), semitones)
                    } else {
                        word
                    }
                }
            } else {
                // Es una línea de letra
                line
            }
        }
    }
    
    private fun extractBaseNote(chord: String): Pair<String, String> {
        val chordPattern = Regex("^([A-G]|Do|Re|Mi|Fa|Sol|La|Si)([#b]?)(.*)$")
        val match = chordPattern.find(chord) ?: return Pair("", chord)
        
        val (base, accidental, rest) = match.destructured
        return Pair(base + accidental, rest)
    }
    
    private fun isChord(text: String): Boolean {
        if (text.isEmpty()) return false
        val chordPattern = Regex("^([A-G][#b]?|Do|Re|Mi|Fa|Sol|La|Si)(m|m7|7|maj7|9|11|13|sus2|sus4|dim|aug)?.*$")
        return chordPattern.matches(text)
    }
}