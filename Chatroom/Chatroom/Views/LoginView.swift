//
//  LoginView.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    @State private var username = ""
    @State private var displayName = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Logo/Header
                    Image(systemName: "message.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                        .padding(.top, 40)

                    Text("Chatroom")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    // Form Fields
                    VStack(spacing: 16) {
                        if isRegistering {
                            TextField("Username", text: $username)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()

                            TextField("Display Name", text: $displayName)
                                .textFieldStyle(.roundedBorder)
                        }

                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)

                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal)

                    // Error Message
                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Action Button
                    Button(action: {
                        Task {
                            if isRegistering {
                                await authViewModel.register(
                                    username: username,
                                    email: email,
                                    password: password,
                                    displayName: displayName
                                )
                            } else {
                                await authViewModel.login(email: email, password: password)
                            }
                        }
                    }) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isRegistering ? "Register" : "Login")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .disabled(authViewModel.isLoading || !isFormValid)

                    // Toggle between Login/Register
                    Button(action: {
                        isRegistering.toggle()
                    }) {
                        Text(isRegistering ? "Already have an account? Login" : "Don't have an account? Register")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }

    private var isFormValid: Bool {
        if isRegistering {
            return !email.isEmpty && !password.isEmpty && !username.isEmpty && !displayName.isEmpty
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
