package com.tucancionero.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.ZoomIn
import androidx.compose.material.icons.filled.ZoomOut
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.tucancionero.domain.models.Song
import com.tucancionero.ui.components.ChordText
import com.tucancionero.ui.viewmodels.SongViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PresentationScreen(
    song: Song,
    viewModel: SongViewModel,
    onClose: () -> Unit
) {
    var fontSize by remember { mutableStateOf(20.sp) }
    var isPlaying by remember { mutableStateOf(false) }
    val transposition by viewModel.transposition.collectAsState()
    
    val transposedLyrics = viewModel.getTransposedLyrics(song.lyricsWithChords)
    val currentKey = viewModel.getCurrentKey(song.originalKey)
    
    // Mantener pantalla activa (se implementará después)
    // KeepScreenOn()
    
    Scaffold(
        topBar = {
            CenterAlignedTopAppBar(
                title = { 
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(
                            song.title, 
                            fontSize = 16.sp,
                            maxLines = 1
                        ) 
                        if (transposition != 0) {
                            Text(
                                "Tono: $currentKey (+$transposition)",
                                fontSize = 12.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onClose) {
                        Icon(Icons.Default.Close, contentDescription = "Cerrar")
                    }
                },
                actions = {
                    // Control de tamaño de fuente
                    IconButton(
                        onClick = { fontSize = (fontSize.value - 2).sp },
                        enabled = fontSize > 14.sp
                    ) {
                        Icon(Icons.Default.ZoomOut, contentDescription = "Texto más pequeño")
                    }
                    
                    IconButton(
                        onClick = { fontSize = (fontSize.value + 2).sp },
                        enabled = fontSize < 32.sp
                    ) {
                        Icon(Icons.Default.ZoomIn, contentDescription = "Texto más grande")
                    }
                    
                    // Control de scroll automático (placeholder)
                    IconButton(onClick = { isPlaying = !isPlaying }) {
                        Icon(
                            if (isPlaying) Icons.Default.Pause else Icons.Default.PlayArrow,
                            contentDescription = if (isPlaying) "Pausar" else "Play"
                        )
                    }
                },
                colors = TopAppBarDefaults.centerAlignedTopAppBarColors(
                    containerColor = Color.Black.copy(alpha = 0.7f)
                )
            )
        },
        containerColor = Color.Black
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color.Black)
                .padding(padding)
        ) {
            ChordText(
                lyricsWithChords = transposedLyrics,
                fontSize = fontSize,
                chordColor = Color(0xFF4FC3F7), // Azul claro para mejor contraste en oscuro
                modifier = Modifier
                    .fillMaxSize()
                    .padding(24.dp)
            )
            
            // Indicador de scroll automático (placeholder)
            if (isPlaying) {
                Box(
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .padding(bottom = 16.dp)
                ) {
                    Card {
                        Text(
                            text = "▶ Reproduciendo",
                            modifier = Modifier.padding(8.dp),
                            color = Color.Green,
                            fontSize = 12.sp
                        )
                    }
                }
            }
        }
    }
}