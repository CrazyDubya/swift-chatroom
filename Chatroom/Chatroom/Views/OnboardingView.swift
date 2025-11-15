//
//  OnboardingView.swift
//  Chatroom
//
//  Created by Claude on 2025-11-15.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            image: "message.circle.fill",
            title: "Stay Connected",
            description: "Chat with friends and family in real-time with instant message delivery"
        ),
        OnboardingPage(
            image: "arrow.up.arrow.down.circle.fill",
            title: "Works Offline",
            description: "Send messages even when you're offline. They'll be delivered automatically when you're back online"
        ),
        OnboardingPage(
            image: "lock.shield.fill",
            title: "Private & Secure",
            description: "Your conversations are encrypted and stored securely on your device"
        ),
        OnboardingPage(
            image: "photo.on.rectangle.fill",
            title: "Share Anything",
            description: "Share photos, videos, voice messages, and files with ease"
        ),
        OnboardingPage(
            image: "bell.badge.fill",
            title: "Stay Notified",
            description: "Get instant notifications for new messages so you never miss important conversations"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Pages
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Page Indicator
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            .padding(.bottom, 24)

            // Action Buttons
            VStack(spacing: 12) {
                if currentPage == pages.count - 1 {
                    Button(action: {
                        completeOnboarding()
                    }) {
                        Text("Get Started")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        completeOnboarding()
                    }) {
                        Text("Skip")
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)
                } else {
                    Button(action: {
                        withAnimation {
                            currentPage += 1
                        }
                    }) {
                        Text("Next")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        completeOnboarding()
                    }) {
                        Text("Skip")
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 8)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true

        // Track completion
        AnalyticsService.shared.logEvent(.featureDiscovered, parameters: [
            "feature": "onboarding_completed",
            "pages_viewed": currentPage + 1
        ])
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: page.image)
                .font(.system(size: 100))
                .foregroundColor(.blue)

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
    }
}

struct OnboardingPage {
    let image: String
    let title: String
    let description: String
}

#Preview {
    OnboardingView()
}
