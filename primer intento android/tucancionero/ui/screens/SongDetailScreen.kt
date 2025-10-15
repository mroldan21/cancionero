package com.tucancionero.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.tucancionero.domain.models.Song
import com.tucancionero.ui.components.ChordText
import com.tucancionero.ui.components.TranspositionControls
import com.tucancionero.ui.viewmodels.SongViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SongDetailScreen(
    song: Song?,
    viewModel: SongViewModel,
    onBack: () -> Unit,
    onEdit: (Long) -> Unit,
    onPlay: (Song) -> Unit
) {
    val transposition by viewModel.transposition.collectAsState()
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(song?.title ?: "Canción") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Atrás")
                    }
                },
                actions = {
                    IconButton(onClick = { song?.let { onPlay(it) } }) {
                        Icon(Icons.Default.PlayArrow, contentDescription = "Presentación")
                    }
                    IconButton(onClick = { song?.id?.let { onEdit(it) } }) {
                        Icon(Icons.Default.Edit, contentDescription = "Editar")
                    }
                }
            )
        }
    ) { padding ->
        if (song == null) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
                contentAlignment = Alignment.Center
            ) {
                Text("Canción no encontrada")
            }
        } else {
            val transposedLyrics = viewModel.getTransposedLyrics(song.lyricsWithChords)
            val currentKey = viewModel.getCurrentKey(song.originalKey)
            
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .verticalScroll(rememberScrollState())
            ) {
                // Controles de transposición
                TranspositionControls(
                    currentTransposition = transposition,
                    originalKey = song.originalKey,
                    currentKey = currentKey,
                    onTransposeUp = { viewModel.transposeUp() },
                    onTransposeDown = { viewModel.transposeDown() },
                    onReset = { viewModel.resetTransposition() },
                    modifier = Modifier.padding(16.dp)
                )
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Información de la canción
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp)
                    ) {
                        if (song.artist.isNotEmpty()) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "Artista: ",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                Text(
                                    text = song.artist,
                                    style = MaterialTheme.typography.bodyMedium
                                )
                            }
                            Spacer(modifier = Modifier.height(4.dp))
                        }
                        
                        Row(
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "Tonalidad: ",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                text = if (transposition == 0) song.originalKey 
                                      else "$song.originalKey → $currentKey",
                                style = MaterialTheme.typography.bodyMedium
                            )
                        }
                        
                        if (song.tempoBpm != null) {
                            Spacer(modifier = Modifier.height(4.dp))
                            Row(
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "Tempo: ",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                Text(
                                    text = "${song.tempoBpm} BPM",
                                    style = MaterialTheme.typography.bodyMedium
                                )
                            }
                        }
                    }
                }
                
                Spacer(modifier = Modifier.height(16.dp))
                
                // Letra con acordes
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp)
                ) {
                    ChordText(
                        lyricsWithChords = transposedLyrics,
                        modifier = Modifier.padding(16.dp)
                    )
                }
                
                Spacer(modifier = Modifier.height(16.dp))
            }
        }
    }
}