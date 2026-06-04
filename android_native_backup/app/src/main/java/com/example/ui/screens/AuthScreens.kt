package com.example.ui.screens

import android.widget.Toast
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.rememberAsyncImagePainter

@Composable
fun OnboardingScreen(onFinish: () -> Unit) {
    Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Row(modifier = Modifier.fillMaxWidth().padding(top = 16.dp), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Surface(modifier = Modifier.size(24.dp), shape = CircleShape, color = MaterialTheme.colorScheme.primary) {
                        Box(contentAlignment = Alignment.Center) {
                            Text("?", color = MaterialTheme.colorScheme.onPrimary, fontWeight = FontWeight.Bold, style = MaterialTheme.typography.labelSmall)
                        }
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("ডাক", style = MaterialTheme.typography.titleLarge, color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold)
                }
                TextButton(onClick = onFinish) { Text("Skip", color = MaterialTheme.colorScheme.primary) }
            }
            Spacer(modifier = Modifier.height(48.dp))
            Image(
                painter = rememberAsyncImagePainter("https://images.unsplash.com/photo-1544787219-7f47ccb76574"),
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(300.dp)
                    .clip(RoundedCornerShape(24.dp))
            )
            Spacer(modifier = Modifier.height(32.dp))
            Text(
                text = "সবাইকে ডাকুন",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center
            )
            Text(
                text = "Connect with Everyone",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "আপনার মনের কথা শেয়ার করুন সবার সাথে।",
                style = MaterialTheme.typography.bodyLarge,
                textAlign = TextAlign.Center,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Text(
                text = "Share your thoughts with the community.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
            )
            Spacer(modifier = Modifier.weight(1f))
            Button(
                onClick = onFinish,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp),
                shape = RoundedCornerShape(24.dp)
            ) {
                Text("পরবর্তী (Next)")
            }
            Spacer(modifier = Modifier.height(16.dp))
            Text("বাংলা ও English সাপোর্ট করে", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            Spacer(modifier = Modifier.height(16.dp))
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AuthScreen(onLoginSuccess: () -> Unit, viewModel: AuthViewModel = viewModel()) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var isSignUp by remember { mutableStateOf(false) }

    val context = LocalContext.current
    val authState by viewModel.authState.collectAsState()

    LaunchedEffect(authState) {
        if (authState is AuthResultState.Error) {
            Toast.makeText(context, (authState as AuthResultState.Error).message, Toast.LENGTH_LONG).show()
        }
    }

    Surface(modifier = Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Spacer(modifier = Modifier.height(48.dp))
            Surface(modifier = Modifier.size(80.dp), shape = RoundedCornerShape(20.dp), color = MaterialTheme.colorScheme.secondaryContainer.copy(alpha=0.5f)) {
                Box(contentAlignment = Alignment.Center) {
                    Text("?", style = MaterialTheme.typography.displaySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            Spacer(modifier = Modifier.height(16.dp))
            Text("ডাক", style = MaterialTheme.typography.displayMedium, color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold)
            Text(
                if (isSignUp) "নতুন ডাক অ্যাকাউন্ট খুলুন" else "আপনার আড্ডা শুরু হোক এখানেই",
                style = MaterialTheme.typography.titleMedium,
                modifier = Modifier.padding(top = 8.dp, bottom = 32.dp)
            )

            Column(modifier = Modifier.fillMaxWidth(), horizontalAlignment = Alignment.Start) {
                Text("ইমেইল", fontWeight = FontWeight.Bold, modifier = Modifier.padding(bottom = 4.dp))
                OutlinedTextField(
                    value = email,
                    onValueChange = { email = it },
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text("email@example.com") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email)
                )
                Spacer(modifier = Modifier.height(16.dp))
                Text("পাসওয়ার্ড", fontWeight = FontWeight.Bold, modifier = Modifier.padding(bottom = 4.dp))
                OutlinedTextField(
                    value = password,
                    onValueChange = { password = it },
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text("••••••••") },
                    visualTransformation = PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password)
                )
            }
            
            if (!isSignUp) {
                TextButton(onClick = { /* TODO */ }, modifier = Modifier.align(Alignment.End)) {
                    Text("পাসওয়ার্ড ভুলে গেছেন?", color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold)
                }
            } else {
                Spacer(modifier = Modifier.height(24.dp))
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            if (authState is AuthResultState.Loading) {
                CircularProgressIndicator()
            } else {
                Button(
                    onClick = {
                        if (email.isNotBlank() && password.isNotBlank()) {
                            if (isSignUp) {
                                viewModel.handleSignup(email, password, onLoginSuccess)
                            } else {
                                viewModel.handleLogin(email, password, onLoginSuccess)
                            }
                        } else {
                            Toast.makeText(context, "অনুগ্রহ করে সব তথ্য দিন", Toast.LENGTH_SHORT).show()
                        }
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(48.dp),
                    shape = RoundedCornerShape(24.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                ) {
                    Text(if (isSignUp) "নিবন্ধন করুন (Sign Up)" else "লগইন করুন")
                }
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            Text("অথবা", color = MaterialTheme.colorScheme.onSurfaceVariant, style = MaterialTheme.typography.bodySmall)
            Spacer(modifier = Modifier.height(24.dp))
            
            OutlinedButton(
                onClick = onLoginSuccess,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp),
                shape = RoundedCornerShape(12.dp)
            ) {
                Text("Continue with Google", color = MaterialTheme.colorScheme.onSurface)
            }
            Spacer(modifier = Modifier.height(12.dp))
            Button(
                onClick = onLoginSuccess,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp),
                shape = RoundedCornerShape(12.dp),
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.errorContainer, contentColor = MaterialTheme.colorScheme.error)
            ) {
                Text("মোবাইল নম্বর (OTP) দিয়ে লগইন")
            }
            
            Spacer(modifier = Modifier.height(24.dp))
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center) {
                Text(if (isSignUp) "ইতিমধ্যে অ্যাকাউন্ট আছে? " else "অ্যাকাউন্ট নেই? ", color = MaterialTheme.colorScheme.onSurfaceVariant)
                TextButton(
                    onClick = { isSignUp = !isSignUp },
                    contentPadding = PaddingValues(0.dp),
                    modifier = Modifier.height(20.dp)
                ) {
                    Text(
                        if (isSignUp) "লগইন করুন" else "নতুন ডাক তৈরি করুন",
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
            Spacer(modifier = Modifier.weight(1f))
            Surface(modifier = Modifier.fillMaxWidth(), color = MaterialTheme.colorScheme.surfaceVariant, shape = RoundedCornerShape(4.dp)) {
                Text("বাংলা (বাংলাদেশ)", modifier = Modifier.padding(8.dp), style = MaterialTheme.typography.bodySmall, textAlign = TextAlign.Center)
            }
            Text("মেড ইন বাংলাদেশ by NGST", modifier = Modifier.padding(vertical = 16.dp), style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}
