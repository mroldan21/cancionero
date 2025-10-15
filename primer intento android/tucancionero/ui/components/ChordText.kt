package com.tucancionero.ui.components

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun ChordText(
    lyricsWithChords: String,
    fontSize: androidx.compose.ui.unit.TextUnit = 16.sp,
    chordColor: Color = Color(0xFFE91E63),
    modifier: Modifier = Modifier
) {
    val lines = lyricsWithChords.split("\n")
    
    Column(modifier = modifier) {
        lines.forEachIndexed { index, line ->
            if (line.isNotBlank()) {
                val trimmedLine = line.trim()
                val isChordLine = isChordLine(trimmedLine)
                
                if (isChordLine) {
                    // Línea de acordes - mostrar en color especial
                    Text(
                        text = buildAnnotatedString {
                            val words = line.split(" ").filter { it.isNotBlank() }
                            words.forEachIndexed { wordIndex, word ->
                                val trimmedWord = word.trim()
                                if (isChord(trimmedWord)) {
                                    withStyle(
                                        SpanStyle(
                                            color = chordColor,
                                            fontWeight = FontWeight.Bold,
                                            fontSize = fontSize - 2.sp
                                        )
                                    ) {
                                        append(trimmedWord)
                                    }
                                } else {
                                    append(trimmedWord)
                                }
                                if (wordIndex < words.size - 1) {
                                    append(" ")
                                }
                            }
                        },
                        modifier = Modifier.padding(vertical = 2.dp),
                        lineHeight = fontSize * 0.8
                    )
                } else {
                    // Línea de letra - mostrar normal
                    Text(
                        text = line,
                        modifier = Modifier.padding(vertical = 4.dp),
                        fontSize = fontSize,
                        lineHeight = fontSize * 1.2
                    )
                }
            } else {
                // Línea vacía - espacio adicional
                Spacer(modifier = Modifier.height(8.dp))
            }
        }
    }
}

private fun isChordLine(line: String): Boolean {
    val words = line.split(" ").filter { it.isNotBlank() }
    if (words.isEmpty()) return false
    
    // Si más del 50% de las palabras son acordes, es una línea de acordes
    val chordCount = words.count { isChord(it.trim()) }
    return chordCount > words.size / 2
}

private fun isChord(text: String): Boolean {
    if (text.isEmpty()) return false
    
    // Patrones para acordes americanos
    val americanChord = Regex("^[A-G][#b]?(m|m7|7|maj7|9|11|13|sus2|sus4|dim|aug|add)?[0-9]*$")
    
    // Patrones para acordes latinos
    val latinChord = Regex("^(Do|Re|Mi|Fa|Sol|La|Si)[#b]?(m|m7|7|maj7|9|11|13|sus2|sus4|dim|aug|add)?[0-9]*$")
    
    return americanChord.matches(text) || latinChord.matches(text)
}

@Composable
private fun Spacer(modifier: Modifier) {
    androidx.compose.foundation.layout.Spacer(modifier = modifier)
}

@Preview
@Composable
fun ChordTextPreview() {
    ChordText(
        lyricsWithChords = """
            C          G           Am
        Alabado sea el Señor nuestro Dios
            F         C           G
        Por su inmenso amor y compasión
            
            C          Em         F
        Gloria al Padre, gloria al Hijo
            G          C          G
        Y gloria al Espíritu Santo
        """.trimIndent()
    )
}