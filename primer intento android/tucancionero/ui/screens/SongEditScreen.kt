package com.tucancionero.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Save
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.tucancionero.domain.models.Song
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SongEditScreen(
    onBack: () -> Unit,
    onSave: (Song) -> Unit,
    existingSong: Song? = null
) {
    var title by remember { 
        mutableStateOf(TextFieldValue(existingSong?.title ?: "")) 
    }
    var artist by remember { 
        mutableStateOf(TextFieldValue(existingSong?.artist ?: "")) 
    }
    var lyrics by remember { 
        mutableStateOf(TextFieldValue(existingSong?.lyricsWithChords ?: "")) 
    }
    var key by remember { 
        mutableStateOf(TextFieldValue(existingSong?.originalKey ?: "C")) 
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (existingSong == null) "Nueva Canción" else "Editar Canción") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Atrás")
                    }
                },
                actions = {
                    IconButton(
                        onClick = {
                            val newSong = Song(
                                id = existingSong?.id ?: 0,
                                title = title.text,
                                artist = artist.text,
                                lyricsWithChords = lyrics.text,
                                originalKey = key.text,
                                updatedAt = Date()
                            )
                            onSave(newSong)
                            onBack()
                        },
                        enabled = title.text.isNotEmpty() && lyrics.text.isNotEmpty()
                    ) {
                        Icon(Icons.Default.Save, contentDescription = "Guardar")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp)
        ) {
            OutlinedTextField(
                value = title,
                onValueChange = { title = it },
                label = { Text("Título *") },
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(8.dp))

            OutlinedTextField(
                value = artist,
                onValueChange = { artist = it },
                label = { Text("Artista") },
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(8.dp))

            OutlinedTextField(
                value = key,
                onValueChange = { key = it },
                label = { Text("Tonalidad") },
                modifier = Modifier.fillMaxWidth()
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                "Letra con acordes:",
                style = MaterialTheme.typography.titleSmall
            )

            Spacer(modifier = Modifier.height(8.dp))

            OutlinedTextField(
                value = lyrics,
                onValueChange = { lyrics = it },
                placeholder = { Text("Ejemplo:\n    C          G\nAlabado sea el Señor...") },
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f),
                singleLine = false,
                maxLines = Int.MAX_VALUE
            )
        }
    }
}

@Preview
@Composable
fun SongEditScreenPreview() {
    SongEditScreen(
        onBack = {},
        onSave = {}
    )
}