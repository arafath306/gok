package com.example.ui.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.rememberAsyncImagePainter
import com.example.domain.model.Notification

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NotificationsScreen(viewModel: NotificationsViewModel = viewModel()) {
    val notifications by viewModel.notifications.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("খবর (Activity)", fontWeight = FontWeight.Bold) }
            )
        }
    ) { padding ->
        Column(modifier = Modifier.padding(padding).fillMaxSize()) {
            Row(modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                FilterChip(selected = true, onClick = {}, label = { Text("সব") })
                FilterChip(selected = false, onClick = {}, label = { Text("লাইক") })
                FilterChip(selected = false, onClick = {}, label = { Text("উত্তর") })
                FilterChip(selected = false, onClick = {}, label = { Text("মেনশন") })
                FilterChip(selected = false, onClick = {}, label = { Text("ফলো") })
            }
            
            LazyColumn(modifier = Modifier.weight(1f)) {
                items(notifications) { notification ->
                    NotificationItem(notification)
                    HorizontalDivider()
                }
            }
        }
    }
}

@Composable
fun NotificationItem(notification: Notification) {
    Row(modifier = Modifier.fillMaxWidth().padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
        Image(
            painter = rememberAsyncImagePainter(notification.actor.avatarUrl ?: "https://i.pravatar.cc/150"),
            contentDescription = null,
            modifier = Modifier.size(48.dp).clip(CircleShape),
            contentScale = ContentScale.Crop
        )
        Spacer(modifier = Modifier.width(16.dp))
        Column(modifier = Modifier.weight(1f)) {
            Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                Text(notification.actor.fullName, fontWeight = FontWeight.Bold)
                Text(notification.createdAt, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Text(notification.content, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            if (notification.type == "FOLLOW") {
                Spacer(modifier = Modifier.height(8.dp))
                Button(onClick = {}, shape = MaterialTheme.shapes.small, modifier = Modifier.height(36.dp)) {
                    Text("ফলো ব্যাক")
                }
            }
        }
    }
}
