package com.tucancionero.ui.components

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDownward
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@Composable
fun TranspositionControls(
    currentTransposition: Int,
    originalKey: String,
    currentKey: String,
    onTransposeUp: () -> Unit,
    onTransposeDown: () -> Unit,
    onReset: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "Transposición",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
                modifier = Modifier.fillMaxWidth()
            ) {
                // Controles de transposición
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(
                        onClick = onTransposeDown,
                        enabled = currentTransposition > -11
                    ) {
                        Icon(Icons.Default.ArrowDownward, contentDescription = "Bajar semitono")
                    }
                    
                    Text(
                        text = if (currentTransposition == 0) "Original" 
                              else if (currentTransposition > 0) "+$currentTransposition" 
                              else "$currentTransposition",
                        style = MaterialTheme.typography.titleMedium,
                        modifier = Modifier.padding(horizontal = 8.dp)
                    )
                    
                    IconButton(
                        onClick = onTransposeUp,
                        enabled = currentTransposition < 11
                    ) {
                        Icon(Icons.Default.ArrowUpward, contentDescription = "Subir semitono")
                    }
                }
                
                // Información de tonalidad
                Column(
                    horizontalAlignment = Alignment.End
                ) {
                    Text(
                        text = "Tono: $currentKey",
                        style = MaterialTheme.typography.bodySmall
                    )
                    if (currentTransposition != 0) {
                        Text(
                            text = "Original: $originalKey",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
            
            if (currentTransposition != 0) {
                Spacer(modifier = Modifier.height(8.dp))
                Button(
                    onClick = onReset,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                ) {
                    Icon(Icons.Default.Refresh, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Resetear a original")
                }
            }
        }
    }
}

@Preview
@Composable
fun TranspositionControlsPreview() {
    TranspositionControls(
        currentTransposition = 2,
        originalKey = "C",
        currentKey = "D",
        onTransposeUp = {},
        onTransposeDown = {},
        onReset = {}
    )
}